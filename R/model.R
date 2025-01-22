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
#' @rdname model

model <- function(run_number, param) {

  # Check all inputs are valid
  valid_inputs(run_number, param)

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


#' Check validity of inputs to `model()`
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param List containing parameters for the simulation.
#'
#' @export
#' @rdname model

valid_inputs <- function(run_number, param) {

  # Check that the run number is an non-negative integer
  if (run_number < 0L || run_number %% 1L != 0L) {
    stop("The run number must be a non-negative integer. Provided: ",
         run_number)
  }

  # Check that listed parameters are always positive
  p_list <- c("patient_inter", "mean_n_consult_time", "number_of_runs")
  for (p in p_list) {
    if (param[[p]] <= 0L) {
      stop("The parameter '", p,
           "' must be positive. Provided: ", param[[p]])
    }
  }

  # Check that listed parameters are non-negative integers
  n_list <- c("data_collection_period", "number_of_nurses")
  for (n in n_list) {
    if (param[[n]] < 0L || param[[n]] %% 1L != 0L) {
      stop("The parameter '", n,
           "' must not be a non-negative integer. Provided: ", param[[n]])
    }
  }
}

# TODO: Save output of verbose=TRUE to a .log file

# TODO: Alternative to use of R6 class would be to have validation rule within
# model function that checks that param only contains allowed names? That
# might be a simpler solution?

# TODO: Check validity of approach to seeds...
# https://www.r-bloggers.com/2020/09/future-1-19-1-making-sure-proper-random-numbers-are-produced-in-parallel-processing/)
