#' Run simulation for multiple replications, sequentially or in parallel.
#'
#' Note: The parallel processing is implemented using `parLapply` because
#' `mcLapply`` does not work on Windows and `future_lapply`` would often get
#' stuck.
#'
#' @param param List containing parameters for the simulations.
#'
#' @importFrom parallel detectCores makeCluster stopCluster clusterEvalQ
#' @importFrom parallel clusterExport parLapply
#'
#' @return Named list with two tables: monitored arrivals and resources.
#' @export

trial <- function(param) {
  if (param[["cores"]] == 1L) {

    # Sequential execution
    results <- lapply(
      1L:param[["number_of_runs"]],
      function(i) simulation::model(run_number = i, param = param)
    )

  } else {
    # Parallel execution

    # Create a cluster with specified number of cores
    if (param[["cores"]] == -1L) {
      cores <- detectCores() - 1L
    } else {
      cores <- param[["cores"]]
    }
    cl <- makeCluster(cores)

    # Ensure the cluster is stopped upon exit
    on.exit(stopCluster(cl))

    # Run simulations in parallel
    results <- parLapply(
      cl, 1L:param[["number_of_runs"]],
      function(i) simulation::model(run_number = i, param = param)
    )
  }

  # Combine the results from multiple replications into just two dataframes
  if (param[["number_of_runs"]] > 1L) {
    all_arrivals <- do.call(
      rbind, lapply(results, function(x) x[["arrivals"]])
    )
    all_resources <- do.call(
      rbind, lapply(results, function(x) x[["resources"]])
    )
    results <- list(arrivals = all_arrivals, resources = all_resources)
  }

  return(results)
}
