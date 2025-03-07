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
#' @importFrom dplyr ungroup arrange slice n filter
#'
#' @return Named list with two tables: three tables: monitored arrivals,
#' monitored resources, and the processed results from the run.
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
      simmer::run(param[["warm_up_period"]] +
                    param[["data_collection_period"]]) %>%
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

  if (nrow(result[["arrivals"]]) > 0L) {

    # Filter the output results if a warm-up period was specified...
    if (param[["warm_up_period"]] > 0L) {

      # For arrivals, just remove all entries for warm-up patients
      result[["arrivals"]] <- result[["arrivals"]] %>%
        group_by(.data[["name"]]) %>%
        filter(all(.data[["start_time"]] >= param[["warm_up_period"]])) %>%
        ungroup()

      # For resources, filter to resource events in the data collection period
      dc_resources <- filter(result[["resources"]],
                             .data[["time"]] >= param[["warm_up_period"]])

      # Get the last event for each resource prior to the warm-up
      last_usage <- result[["resources"]] %>%
        filter(.data[["time"]] < param[["warm_up_period"]]) %>%
        arrange(.data[["time"]]) %>%
        group_by(.data[["resource"]]) %>%
        slice(n()) %>%
        # Replace time with 50
        mutate(time = param[["warm_up_period"]])

      # Set the last event as the first row in the filtered resources dataframe
      result[["resources"]] <- rbind(last_usage, dc_resources)
    }

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
  }

  # Calculate the average results for that run and add to result list
  result[["run_results"]] <- get_run_results(result, run_number)

  return(result)
}
