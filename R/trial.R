#' Run simulation for multiple replications, sequentially or in parallel.
#'
#' Note: The parallel processing is implemented using `parLapply` because
#' `mcLapply`` does not work on Windows and `future_lapply`` would often get
#' stuck.
#'
#' @param param_class Instance of Defaults containing model parameters.
#'
#' @importFrom parallel detectCores makeCluster stopCluster clusterEvalQ
#' @importFrom parallel clusterExport parLapply
#'
#' @return Named list with two tables: monitored arrivals and resources.
#' @export

trial <- function(param_class) {
  # Get specified number of cores
  n_cores <- param_class[["get"]]()[["cores"]]
  n_runs <- param_class[["get"]]()[["number_of_runs"]]

  if (n_cores == 1L) {

    # Sequential execution
    results <- lapply(
      1L:n_runs,
      function(i) simulation::model(run_number = i, param_class = param_class)
    )

  } else {
    # Parallel execution

    # Create a cluster with specified number of cores
    if (n_cores == -1L) {
      cores <- detectCores() - 1L
    } else {
      cores <- n_cores
    }
    cl <- makeCluster(cores)

    # Ensure the cluster is stopped upon exit
    on.exit(stopCluster(cl))

    # Run simulations in parallel
    results <- parLapply(
      cl, 1L:n_runs,
      function(i) simulation::model(run_number = i, param_class = param_class)
    )
  }

  # Combine the results from multiple replications into just two dataframes
  if (n_runs > 1L) {
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
