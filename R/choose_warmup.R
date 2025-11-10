#' Time series inspection method for determining length of warm-up.
#'
#' Find the cumulative mean results and plot over time (overall and per run).
#'
#' @param result Named list with `arrivals` containing output from
#' `get_mon_arrivals()` and `resources` containing output from
#' `get_mon_resources()` (`per_resource = TRUE` and `ongoing = TRUE`).
#' @param simulation_end_time Time at end of simulation run.
#' @param file_path Path to save figure to.
#' @param interval Time interval in minutes for calculating cumulative means.
#' @param warm_up Location on X axis to plot vertical red line indicating the
#' chosen warm-up period. Defaults to NULL, which will not plot a line.
#'
#' @importFrom dplyr arrange group_by mutate rename select ungroup
#' @importFrom ggplot2 aes_string annotate geom_line geom_vline ggsave labs
#' @importFrom ggplot2 theme_minimal ggplot
#' @importFrom gridExtra marrangeGrob
#' @importFrom rlang .data
#' @importFrom tidyselect all_of
#'
#' @export

time_series_inspection <- function(
  result, simulation_end_time, file_path, interval = 120L, warm_up = NULL
) {

  plot_list <- list()

  # Collect dataframes with metrics at each timepoint (relabelled "time" for
  # all). If you have multiple resources, would need to run time series
  # inspection on each resource. As this is not the case here, have just
  # selected replication, time and the metric.
  metrics <- list()

  # Wait time of each patient at each time point
  metrics[[1L]] <- result[["arrivals"]] |>
    rename(time = .data[["serve_start"]]) |>
    dplyr::select(all_of(c("replication", "time", "wait_time")))

  # Utilisation at each time point
  metrics[[2L]] <- calc_utilisation(result[["resources"]],
                                    simulation_end_time = simulation_end_time,
                                    groups = c("resource", "replication"),
                                    summarise = FALSE) |>
    dplyr::select(all_of(c("replication", "time", "utilisation")))

  # Queue length at each timepoint
  metrics[[3L]] <- result[["arrivals"]] |>
    rename(time = .data[["start_time"]]) |>
    dplyr::select(all_of(c("replication", "time", "queue_on_arrival")))

  # Time in system at each timepoint
  metrics[[4L]] <- result[["arrivals"]] |>
    rename(time = .data[["start_time"]]) |>
    dplyr::select(all_of(c("replication", "time", "time_in_system")))

  # Patients in system at each timepoint
  metrics[[5L]] <- rename(result[["patients_in_service"]],
                          patients_in_system = .data[["count"]])

  # Create sequence of time intervals
  time_breaks <- seq(0L, simulation_end_time + interval, by = interval)

  # Loop through all the dataframes in df_list
  for (i in seq_along(metrics)) {

    # Get name of the metric
    metric <- setdiff(names(metrics[[i]]), c("time", "replication"))

    # Aggregate data to time intervals (calculate mean within each interval)
    aggregated <- metrics[[i]] |>
      mutate(time_bin = as.numeric(as.character(
        cut(time, breaks = time_breaks, labels = time_breaks[-1L])
      ))) |>
      group_by(.data[["replication"]], .data[["time_bin"]]) |>
      summarise(metric_mean = mean(.data[[metric]])) |>
      ungroup() |>
      rename(time = .data[["time_bin"]])

    # Calculate cumulative mean for the current metric per replication
    cumulative <- aggregated |>
      arrange(.data[["replication"]], .data[["time"]]) |>
      group_by(.data[["replication"]]) |>
      mutate(cumulative_mean = (cumsum(.data[["metric_mean"]]) /
                                  seq_along(.data[["metric_mean"]]))) |>
      ungroup()

    # Repeat calculation, but including all replications in one
    overall_aggregated <- metrics[[i]] |>
      mutate(time_bin = as.numeric(as.character(
        cut(time, breaks = time_breaks, labels = time_breaks[-1L])
      ))) |>
      group_by(.data[["time_bin"]]) |>
      summarise(metric_mean = mean(.data[[metric]])) |>
      ungroup() |>
      rename(time = .data[["time_bin"]])

    overall_cumulative <- overall_aggregated |>
      arrange(.data[["time"]]) |>
      mutate(cumulative_mean = cumsum(.data[["metric_mean"]]) /
               seq_along(.data[["metric_mean"]])) |>
      ungroup()

    # Create plot
    p <- ggplot() +
      geom_line(data = cumulative,
                aes_string(x = "time", y = "cumulative_mean",
                           group = "replication"),
                color = "lightblue", alpha = 0.8) +
      geom_line(data = overall_cumulative,
                aes_string(x = "time", y = "cumulative_mean"),
                color = "darkblue") +
      labs(x = "Run time (minutes)", y = paste("Cumulative mean", metric)) +
      theme_minimal()

    # Add line to indicate suggested warm-up length if provided
    if (!is.null(warm_up)) {
      p <- p +
        geom_vline(xintercept = warm_up, linetype = "dashed", color = "red") +
        annotate("text", x = warm_up, y = Inf,
                 label = "Suggested warm-up length",
                 color = "red", hjust = -0.1, vjust = 1L)
    }
    # Store the plot
    plot_list[[i]] <- p
  }

  # Arrange plots in a single column
  combined_plot <- marrangeGrob(plot_list, ncol = 1L, nrow = length(plot_list),
                                top = NULL)

  # Save to file
  ggsave(file_path, combined_plot, width = 8L, height = 4L * length(plot_list))
}
