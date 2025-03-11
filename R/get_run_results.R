#' Process the raw monitored arrivals and resources.
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
#' @importFrom stats setNames
#' @importFrom tidyr pivot_wider drop_na
#' @importFrom tidyselect any_of
#' @importFrom tibble tibble
#'
#' @return Tibble with processed results from replication.
#' @export

get_run_results <- function(results, run_number) {

  # If there were no arrivals, return dataframe row with just the replication
  # number and arrivals column set to 0
  if (nrow(results[["arrivals"]]) == 0L) {
    tibble(replication = run_number, arrivals = 0L)

  } else {

    # Otherwise, if there are some arrivals...
    # Calculate metrics of interest
    metrics <- list(
      calc_arrivals(results[["arrivals"]]),
      calc_mean_wait(results[["arrivals"]], results[["resources"]]),
      calc_mean_serve_length(results[["arrivals"]], results[["resources"]]),
      calc_utilisation(results[["resources"]]),
      calc_unseen_n(results[["arrivals"]]),
      calc_unseen_mean(results[["arrivals"]])
    )
    # Combine metrics + replication number in a single dataframe
    dplyr::bind_cols(tibble(replication = run_number), metrics)
  }
}


#' Calculate the number of arrivals
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @return Tibble with column containing total number of arrivals.

calc_arrivals <- function(arrivals) {
  arrivals %>%
    summarise(arrivals = n_distinct(.data[["name"]]))
}


#' Calculate the mean wait time for each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param resources Dataframe with times patients use or queue for resources.
#'
#' @importFrom dplyr group_by summarise
#' @importFrom tibble tibble
#' @importFrom tidyr pivot_wider drop_na
#'
#' @return Tibble with columns containing result for each resource.

calc_mean_wait <- function(arrivals, resources) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("wait_time"))

  # If there are any patients who were seen, calculate mean wait times...
  if (nrow(complete_arrivals) > 0L) {
    complete_arrivals %>%
      group_by(.data[["resource"]]) %>%
      summarise(mean_waiting_time = mean(.data[["wait_time"]])) %>%
      pivot_wider(names_from = "resource",
                  values_from = "mean_waiting_time",
                  names_glue = "mean_waiting_time_{resource}")
  } else {
    # But if no patients are seen, create same tibble with values set to NA
    unique_resources <- unique(resources["resource"])
    tibble::tibble(
      !!!setNames(rep(list(NA_real_), length(unique_resources)),
                  paste0("mean_waiting_time_", unique_resources))
    )
  }
}


#' Calculate the mean length of time patients spent with each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param resources Dataframe with times patients use or queue for resources.
#'
#' @importFrom dplyr group_by summarise
#' @importFrom tibble tibble
#' @importFrom tidyr pivot_wider drop_na
#'
#' @return Tibble with columns containing result for each resource.

calc_mean_serve_length <- function(arrivals, resources) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("wait_time"))

  # If there are any patients who were seen, calculate mean service length...
  if (nrow(complete_arrivals) > 0L) {
    complete_arrivals %>%
      group_by(.data[["resource"]]) %>%
      summarise(mean_serve_time = mean(.data[["serve_length"]])) %>%
      pivot_wider(names_from = "resource",
                  values_from = "mean_serve_time",
                  names_glue = "mean_serve_time_{resource}")
  } else {
    # But if no patients are seen, create same tibble with values set to NA
    unique_resources <- unique(resources["resource"])
    tibble::tibble(
      !!!setNames(rep(list(NA_real_), length(unique_resources)),
                  paste0("mean_serve_time_", unique_resources))
    )
  }
}


#' Calculate the resource utilisation
#'
#' Utilisation is given by the total effective usage time (`in_use`) over
#' the total time intervals considered (`dt`).
#'
#' Credit: The utilisation calculation is taken from the
#' `plot.resources.utilization()` function in simmer.plot 0.1.18, which is
#' shared under an MIT Licence (Ucar I, Smeets B (2023). simmer.plot: Plotting
#' Methods for 'simmer'. https://r-simmer.org
#' https://github.com/r-simmer/simmer.plot.).
#'
#' @param resources Dataframe with times patients use or queue for resources.
#'
#' @return Tibble with columns containing result for each resource.

calc_utilisation <- function(resources) {
  resources %>%
    group_by(.data[["resource"]]) %>%
    mutate(dt = lead(.data[["time"]]) - .data[["time"]],
           capacity = pmax(.data[["capacity"]], .data[["server"]]),
           dt = ifelse(.data[["capacity"]] > 0L, .data[["dt"]], 0L),
           in_use = (.data[["dt"]] * .data[["server"]] /
                       .data[["capacity"]])) %>%
    summarise(
      utilisation = sum(.data[["in_use"]], na.rm = TRUE) /
        sum(.data[["dt"]], na.rm = TRUE)
    ) %>%
    pivot_wider(names_from = "resource",
                values_from = "utilisation",
                names_glue = "utilisation_{resource}")
}


#' Calculate the number of patients still waiting for resource at end
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @return Tibble with columns containing result for each resource.

calc_unseen_n <- function(arrivals) {
  arrivals %>%
    group_by(.data[["resource"]]) %>%
    summarise(value = sum(!is.na(.data[["wait_time_unseen"]]))) %>%
    pivot_wider(names_from = "resource",
                values_from = "value",
                names_glue = "count_unseen_{resource}")
}


#' Calculate the mean wait time of patients who are still waiting for a
#' resource at the end of the simulation
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @return Tibble with columns containing result for each resource.

calc_unseen_mean <- function(arrivals) {
  arrivals %>%
    group_by(.data[["resource"]]) %>%
    summarise(value = mean(.data[["wait_time_unseen"]], na.rm = TRUE)) %>%
    pivot_wider(names_from = "resource",
                values_from = "value",
                names_glue = "mean_waiting_time_unseen_{resource}")
}
