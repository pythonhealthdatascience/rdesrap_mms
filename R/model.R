#' Run simulation.
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param Named list of model parameters.
#' @param set_seed Whether to set seed within the model function (which we
#' may not wish to do if being set elsewhere - such as done in runner()).
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

model <- function(run_number, param, set_seed = TRUE) {

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
  sim_log <- capture.output(
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
    full_log <- append(c("Parameters:", param_string, "Log:"), sim_log)
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

  # Add a column with the wait time of patients who remained unseen at the end
  # of the simulation
  result[["arrivals"]] <- result[["arrivals"]] %>%
    mutate(q_time_unseen = ifelse(is.na(.data[["activity_time"]]),
                                  now(env) - .data[["start_time"]],
                                  NA))
  return(result)
}

#' Validate input parameters for the simulation.
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param List containing parameters for the simulation.
#'
#' @return Throws an error if any parameter is invalid.
#' @export

valid_inputs <- function(run_number, param) {
  check_run_number(run_number)
  check_param_names(param)
  check_param_values(param)
}

#' Checks if the run number is a non-negative integer.
#'
#' @param run_number Integer representing index of current simulation run.
#'
#' @return Throws an error if the run number is invalid.

check_run_number <- function(run_number) {
  if (run_number < 0L || run_number %% 1L != 0L) {
    stop("The run number must be a non-negative integer. Provided: ",
         run_number, call. = FALSE)
  }
}

#' Validate parameter names.
#'
#' Ensure that all required parameters are present, and no extra parameters are
#' provided.
#'
#' @param param List containing parameters for the simulation.
#'
#' @return Throws an error if there are missing or extra parameters.

check_param_names <- function(param) {
  # Get valid argument names from the function
  valid_names <- names(formals(parameters))

  # Get names from input parameter list
  input_names <- names(param)

  # Find missing keys (i.e. are there things in valid_names not in input)
  # and extra keys (i.e. are there things in input not in valid_names)
  missing_keys <- setdiff(valid_names, input_names)
  extra_keys <- setdiff(input_names, valid_names)

  # If there are any missing or extra keys, throw an error
  if (length(missing_keys) > 0L || length(extra_keys) > 0L) {
    error_message <- ""
    if (length(missing_keys) > 0L) {
      error_message <- paste0(
        error_message, "Missing keys: ", toString(missing_keys), ". "
      )
    }
    if (length(extra_keys) > 0L) {
      error_message <- paste0(
        error_message, "Extra keys: ", toString(extra_keys), ". "
      )
    }
    stop(error_message, call. = FALSE)
  }
}

#' Validate parameter values.
#'
#' Ensure that specific parameters are positive numbers, or non-negative
#' integers.
#'
#' @param param List containing parameters for the simulation.
#'
#' @return Throws an error if any specified parameter value is invalid.

check_param_values <- function(param) {

  # Check that listed parameters are always positive
  p_list <- c("patient_inter", "mean_n_consult_time", "number_of_runs")
  for (p in p_list) {
    if (param[[p]] <= 0L) {
      stop('The parameter "', p, '" must be greater than 0.', call. = FALSE)
    }
  }

  # Check that listed parameters are non-negative integers
  n_list <- c("data_collection_period", "number_of_nurses")
  for (n in n_list) {
    if (param[[n]] < 0L || param[[n]] %% 1L != 0L) {
      stop('The parameter "', n,
           '" must be an integer greater than or equal to 0.', call. = FALSE)
    }
  }
}
