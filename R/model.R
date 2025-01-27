#' Run simulation
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param_class Instance of Defaults containing model parameters.
#' @param set_seed Whether to set seed within the model function (which we
#' may not wish to do if being set elsewhere - such as done in trial()).
#' Default is TRUE.
#'
#' @importFrom simmer trajectory seize timeout release simmer add_resource
#' @importFrom simmer add_generator run wrap get_mon_arrivals
#' @importFrom magrittr %>%
#' @importFrom stats rexp
#' @importFrom utils capture.output
#'
#' @return Named list with two tables: monitored arrivals and resources
#' @export

model <- function(run_number, param_class, set_seed = TRUE) {

  # Extract parameter list from the parameter class
  # It is important to do this within the model function (rather than
  # beforehand), to ensure any updates to the parameter list undergo
  # checks from the Defaults R6 class (i.e. ensuring they are replacing
  # existing keys in the list)
  param <- param_class[["get"]]()

  # Check all inputs are valid
  valid_inputs(run_number, param)

  # Set random seed based on run number
  if (set_seed) {
    set.seed(run_number)
  }

  # Define the patient trajectory
  patient <- trajectory("appointment") %>%
    seize("nurse", 1L) %>%
    timeout(function() {
      rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
    }) %>%
    release("nurse", 1L)

  # Determine whether to get verbose activity logs
  verbose <- any(c(param[["log_to_console"]], param[["log_to_file"]]))

  # Create simmer environment, add nurse resource and patient generator, and
  # run the simulation. Capture output, which will save a log if verbose=TRUE
  log <- capture.output(
    env <- simmer("simulation", verbose = verbose) %>% # nolint
      add_resource("nurse", param[["number_of_nurses"]]) %>%
      add_generator("patient", patient, function() {
        rexp(n = 1L, rate = 1L / param[["patient_inter"]])
      }) %>%
      simmer::run(param[["data_collection_period"]]) %>%
      wrap()
  )

  # Save and/or display the log
  if (isTRUE(verbose)) {
    # Create full log message by adding parameters
    param_string <- paste(names(param), param, sep = "=", collapse = "; ")
    full_log <- append(c("Parameters:", param_string, "Log:"), log)
    # Print to console
    if (isTRUE(param[["log_to_console"]])) {
      print(full_log)
    }
    # Save to file
    if (isTRUE(param[["log_to_file"]])) {
      writeLines(full_log, param[["file_path"]])
    }
  }

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


#' Check validity of input parameters
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param List containing parameters for the simulation.
#'
#' @export

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
