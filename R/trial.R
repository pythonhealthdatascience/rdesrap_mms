#' Run simulation for multiple replications, sequentially or in parallel.
#'
#' @param param_class Instance of Defaults containing model parameters.
#'
#' @importFrom future plan multisession sequential
#' @importFrom future.apply future_lapply
#'
#' @return Named list with two tables: monitored arrivals and resources.
#' @export

trial <- function(param_class) {
  # Get specified number of cores
  n_cores <- param_class[["get"]]()[["cores"]]
  n_runs <- param_class[["get"]]()[["number_of_runs"]]

  # Determine the parallel execution plan
  if (n_cores == 1L) {
    plan(sequential)  # Sequential execution
  } else {
    if (n_cores == -1L) {
      cores <- future::availableCores() - 1L
    } else {
      cores <- n_cores
    }
    plan(multisession, workers = cores)  # Parallel execution
  }

  # Run simulations (sequentially or in parallel)
  results <- future_lapply(
    1L:n_runs,
    function(i) simulation::model(run_number = i, param_class = param_class),
    future.seed = TRUE
  )

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
