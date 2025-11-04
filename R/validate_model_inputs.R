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
  check_log_file_path(param)
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
  n_list <- c("warm_up_period", "data_collection_period", "number_of_nurses")
  for (n in n_list) {
    if (param[[n]] < 0L || param[[n]] %% 1L != 0L) {
      stop('The parameter "', n,
           '" must be an integer greater than or equal to 0.', call. = FALSE)
    }
  }
}

#' Check logging file path
#'
#' @param param List containing parameters for the simulation.
#'
#' @return None. Throws an error if valid file path not provided, when
#' log_to_file = TRUE.
#' @export

check_log_file_path <- function(param) {
  log_to_file <- param[["log_to_file"]]
  file_path <- param[["file_path"]]
  if (isTRUE(log_to_file) && (is.null(file_path) || !nzchar(file_path))) {
    stop(
      "If 'log_to_file' is TRUE, you must provide a non-NULL, ",
      "non-empty 'file_path'.",
      call. = FALSE
    )
  }
}
