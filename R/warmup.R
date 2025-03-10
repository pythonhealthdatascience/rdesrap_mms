#' Filters arrivals and resources to remove warm-up patients.
#'
#' @param result Named list with two tables: monitored arrivals & resources.
#' @param warm_up_period Length of warm-up period.
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr ungroup arrange slice n filter
#'
#' @return The name list `result`, but with the tables (`arrivals` and
#' `resources`) filtered to remove warm-up patients.
#' @export

filter_warmup <- function(result, warm_up_period) {

  # For arrivals, just remove all entries for warm-up patients
  result[["arrivals"]] <- result[["arrivals"]] %>%
    group_by(.data[["name"]]) %>%
    filter(all(.data[["start_time"]] >= warm_up_period)) %>%
    ungroup()

  # For resources, filter to resource events in the data collection period
  dc_resources <- filter(result[["resources"]],
                         .data[["time"]] >= warm_up_period)

  # Get the last event for each resource prior to the warm-up
  last_usage <- result[["resources"]] %>%
    filter(.data[["time"]] < warm_up_period) %>%
    arrange(.data[["time"]]) %>%
    group_by(.data[["resource"]]) %>%
    slice(n()) %>%
    # Replace time with start of data collection period (which will be the
    # length of the warm-up period)
    mutate(time = warm_up_period)

  # Set the last event as the first row in the filtered resources dataframe
  # to account for active resources ensuring calculations start from the
  # first time point. Without warm-up, this isn't an issue as the
  # calculations would just return 0 between the start and first event
  # as no resources are active.
  result[["resources"]] <- rbind(last_usage, dc_resources)

  return(result) # nolint: return_linter
}
