#' Run simulation
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param List containing parameters for the simulation.
#'
#' @importFrom simmer trajectory seize timeout release simmer add_resource
#' @importFrom simmer add_generator run wrap get_mon_arrivals
#' @importFrom magrittr %>%
#' @importFrom stats rexp
#'
#' @return Named list with two tables: monitored arrivals and resources
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

  # Create simmer environment
  env <- simmer("simulation", verbose = param[["verbose"]]) %>%
    # Add nurse resource and patient generator
    add_resource("nurse", param[["number_of_nurses"]]) %>%
    add_generator("patient", patient, function() {
      rexp(n = 1L, rate = 1L / param[["patient_inter"]])
    }) %>%
    simmer::run(param[["data_collection_period"]]) %>%
    wrap()

  # Extract the monitored arrivals and resources information from the simmer
  # environment object
  result <- list(
    arrivals = get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE),
    resources = get_mon_resources(env)
  )
  # Replace replication with appropriate run number (as these functions
  # assume, if not supplied with list of envs, that there was one replication)
  result[["arrivals"]][["replication"]] <- run_number
  result[["resources"]][["replication"]] <- run_number

  return(result)
}

# TODO: Save output of verbose=TRUE to a .log file

# TODO: Add some validation rules for parameters to check not 0 / negative

# TODO: Alternative to use of R6 class would be to have validation rule within
# model function that checks that param only contains allowed names? That
# might be a simpler solution?
