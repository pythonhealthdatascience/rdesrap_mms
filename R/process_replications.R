#' Process results from each replication.
#'
#' For each replication (there can be one or many), calculate the: (1) number
#' of arrivals, (2) mean wait time for each resource, (3) mean activity time
#' for each resource, and (4) mean resource utilisation.
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
#'
#' @importFrom dplyr group_by summarise n_distinct mutate lead full_join
#' @importFrom purrr reduce
#' @importFrom rlang .data
#' @importFrom simmer get_mon_resources get_mon_arrivals
#' @importFrom tidyr pivot_wider drop_na
#'
#' @return Tibble with results from each replication.
#' @export

process_replications <- function(results) {

  # Remove patients who were still waiting and had not completed
  results[["arrivals"]] <- results[["arrivals"]] %>%
    drop_na(.data[["end_time"]])

  # Calculate the number of arrivals
  calc_arr <- results[["arrivals"]] %>%
    group_by(.data[["replication"]]) %>%
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
    group_by(.data[["resource"]], .data[["replication"]]) %>%
    summarise(mean_waiting_time = mean(.data[["waiting_time"]])) %>%
    pivot_wider(names_from = "resource",
                values_from = "mean_waiting_time",
                names_glue = "mean_waiting_time_{resource}")

  # Calculate the mean time spent with each resource
  calc_act <- results[["arrivals"]] %>%
    group_by(.data[["resource"]], .data[["replication"]]) %>%
    summarise(mean_activity_time = mean(.data[["activity_time"]])) %>%
    pivot_wider(names_from = "resource",
                values_from = "mean_activity_time",
                names_glue = "mean_activity_time_{resource}")

  # Calculate the mean resource utilisation
  # Utilisation is given by the total effective usage time (`in_use`) over the
  # total time intervals considered (`dt`).
  calc_util <- results[["resources"]] %>%
    group_by(.data[["resource"]], .data[["replication"]]) %>%
    mutate(dt = lead(.data[["time"]]) - .data[["time"]]) %>%
    mutate(capacity = pmax(.data[["capacity"]], .data[["server"]])) %>%
    mutate(dt = ifelse(.data[["capacity"]] > 0L, .data[["dt"]], 0L)) %>%
    mutate(in_use = .data[["dt"]] * .data[["server"]] / .data[["capacity"]]) %>%
    summarise(
      utilisation = sum(.data[["in_use"]], na.rm = TRUE) /
        sum(.data[["dt"]], na.rm = TRUE)
    ) %>%
    pivot_wider(names_from = "resource",
                values_from = "utilisation",
                names_glue = "utilisation_{resource}")

  # Combine all calculated metrics into a single dataframe
  processed_result <- list(calc_arr, calc_wait, calc_act, calc_util) %>%
    reduce(full_join, by = "replication")

  return(processed_result)
}
