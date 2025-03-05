#' Run simulation for multiple replications, sequentially or in parallel.
#'
#' @param param Named list of model parameters.
#'
#' @importFrom future plan multisession sequential
#' @importFrom future.apply future_lapply
#'
#' @return Named list with two tables: monitored arrivals and resources.
#' @export

runner <- function(param) {
  # Determine the parallel execution plan
  if (param[["cores"]] == 1L) {
    plan(sequential)  # Sequential execution
  } else {
    if (param[["cores"]] == -1L) {
      cores <- future::availableCores() - 1L
    } else {
      cores <- param[["cores"]]
    }
    plan(multisession, workers = cores)  # Parallel execution
  }

  # Run simulations (sequentially or in parallel)
  # Mark set_seed as FALSE as we handle this using future.seed(), rather than
  # within the function, and we don't want to override future.seed
  results <- future_lapply(
    1L:param[["number_of_runs"]],
    function(i) {
      simulation::model(run_number = i,
                        param = param,
                        set_seed = FALSE)
    },
    future.seed = 123456L
  )

  # Combine the results from multiple replications into just two dataframes
  if (param[["number_of_runs"]] == 1L) {
    results <- results[[1L]]
  } else {
    all_arrivals <- do.call(
      rbind, lapply(results, function(x) x[["arrivals"]])
    )
    all_resources <- do.call(
      rbind, lapply(results, function(x) x[["resources"]])
    )
    results <- list(arrivals = all_arrivals, resources = all_resources)
  }

  return(results) # nolint
}
