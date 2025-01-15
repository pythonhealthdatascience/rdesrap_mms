#' Run simulation for multiple replications, sequentially or in parallel.
#'
#' @param param List containing parameters for the simulations.
#'
#' @importFrom parallel detectCores makeCluster stopCluster clusterEvalQ
#' @importFrom parallel clusterExport parLapply
#'
#' @return A list of Simmer environment objects, one for each run.
#' @export

trial <- function(param) {
  if (param[["cores"]] == 1L) {

    # Sequential execution
    envs <- lapply(
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

    # Load required libraries and export variables to workers
    clusterEvalQ(cl, library(simmer))
    clusterExport(cl, varlist = c("param", "model"))

    # Run simulations in parallel
    envs <- parLapply(
      cl, 1L:param[["number_of_runs"]],
      function(i) simulation::model(run_number = i, param = param)
    )
  }
  return(envs)
}
