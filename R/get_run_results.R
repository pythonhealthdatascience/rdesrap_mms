#' Process the raw monitored arrivals and resources.
#'
#' For the provided replication, calculate the:
#' (1) number of arrivals
#' (2) mean wait time for each resource
#' (3) mean activity time for each resource
#' (4) mean resource utilisation.
#'
#' Credit: The utilisation calculation is taken from the
#' `plot.resources.utilization()` function in simmer.plot 0.1.18, which is
#' shared under an MIT Licence (Ucar I, Smeets B (2023). simmer.plot: Plotting
#' Methods for 'simmer'. https://r-simmer.org
#' https://github.com/r-simmer/simmer.plot.).
#'
#' Note: When calculating the mean wait time, it is rounded to 10 decimal
#' places. This is to resolve an issue that occurs because `start_time`,
#' `end_time` and `activity_time` are all to 14 decimal places, but the
#' calculations can produce tiny negative values due to floating-point errors.
#'
#' @param results Named list with `arrivals` containing output from
#' `get_mon_arrivals()` and `resources` containing output from
#' `get_mon_resources()` (`per_resource = TRUE` and `ongoing = TRUE`).
#' @param run_number Integer representing index of current simulation run.
#'
#' @importFrom dplyr group_by summarise n_distinct mutate lead full_join
#' @importFrom dplyr bind_cols
#' @importFrom purrr reduce
#' @importFrom rlang .data
#' @importFrom simmer get_mon_resources get_mon_arrivals now
#' @importFrom tidyr pivot_wider drop_na
#' @importFrom tidyselect any_of
#' @importFrom tibble tibble
#'
#' @return Tibble with processed results from replication.
#' @export

get_run_results <- function(results, run_number) {

  # Remove patients who were still waiting and had not completed
  results[["arrivals"]] <- results[["arrivals"]] %>%
    drop_na(any_of("end_time"))

  # If there are any arrivals...
  if (nrow(results[["arrivals"]]) > 0L) {

    # Calculate the number of arrivals
    calc_arr <- results[["arrivals"]] %>%
      summarise(arrivals = n_distinct(.data[["name"]]))

    # Calculate the mean wait time for each resource
    calc_wait <- results[["arrivals"]] %>%
      mutate(
        waiting_time = round(
          .data[["end_time"]] - (
            .data[["start_time"]] + .data[["activity_time"]]
          ), 10L
        )
      ) %>%
      group_by(.data[["resource"]]) %>%
      summarise(mean_waiting_time = mean(.data[["waiting_time"]])) %>%
      pivot_wider(names_from = "resource",
                  values_from = "mean_waiting_time",
                  names_glue = "mean_waiting_time_{resource}")

    # Calculate the mean time spent with each resource
    calc_act <- results[["arrivals"]] %>%
      group_by(.data[["resource"]]) %>%
      summarise(mean_activity_time = mean(.data[["activity_time"]])) %>%
      pivot_wider(names_from = "resource",
                  values_from = "mean_activity_time",
                  names_glue = "mean_activity_time_{resource}")

    # Calculate the mean resource utilisation
    # Utilisation is given by the total effective usage time (`in_use`) over the
    # total time intervals considered (`dt`).
    calc_util <- results[["resources"]] %>%
      group_by(.data[["resource"]]) %>%
      # nolint start
      mutate(dt = lead(.data[["time"]]) - .data[["time"]]) %>%
      mutate(capacity = pmax(.data[["capacity"]], .data[["server"]])) %>%
      mutate(dt = ifelse(.data[["capacity"]] > 0L, .data[["dt"]], 0L)) %>%
      mutate(in_use = (.data[["dt"]] * .data[["server"]] /
                       .data[["capacity"]])) %>%
      # nolint end
      summarise(
        utilisation = sum(.data[["in_use"]], na.rm = TRUE) /
          sum(.data[["dt"]], na.rm = TRUE)
      ) %>%
      pivot_wider(names_from = "resource",
                  values_from = "utilisation",
                  names_glue = "utilisation_{resource}")

    # Combine all calculated metrics into a single dataframe, and along with
    # the replication number
    processed_result <- dplyr::bind_cols(
      tibble(replication = run_number),
      calc_arr, calc_wait, calc_act, calc_util
    )
  } else {
    # If there were no arrivals, return dataframe row with just the replication
    # number and arrivals column set to 0
    processed_result <- tibble(replication = run_number,
                               arrivals = nrow(results[["arrivals"]]))
  }

  return(processed_result) # nolint
}
