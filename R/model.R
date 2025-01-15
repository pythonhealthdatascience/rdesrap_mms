#' Run simulation
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param List containing parameters for the simulation.
#'
#' @importFrom simmer trajectory seize timeout release simmer add_resource
#' @importFrom simmer add_generator run wrap
#' @importFrom magrittr %>%
#' @importFrom stats rexp
#'
#' @return Simmer environment object containing the simulation results.
#' @export

model <- function(run_number, param) {

  # Set random seed based on run number
  set.seed(run_number)

  # Define the patient trajectory
  patient <- trajectory("appointment") %>%
    seize("nurse", 1L) %>%
    timeout(function() {
      rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
    }) %>%
    release("nurse", 1L)

  # Create and run a simmer environment
  simmer("simulation", verbose = param[["verbose"]]) %>%
    add_resource("nurse", param[["number_of_nurses"]]) %>%
    add_generator("patient", patient, function() {
      rexp(n = 1L, rate = 1L / param[["patient_inter"]])
    }) %>%
    simmer::run(param[["data_collection_period"]]) %>%
    wrap()
}
