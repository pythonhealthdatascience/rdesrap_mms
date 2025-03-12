#' Find the mean results per interval in each replication in the results.
#'
#' @param result Named list with `arrivals` and `resources` containing results
#' from the run of a simulation for the desired number of replications.
#' @param interval_size Size of batch intervals.
#'
#' @return List containing results from each interval and replication for
#' each metric.
#' @export

get_interval_means <- function(result, interval_size) {

  # Label intervals based on the start_time (used for count of arrivals)
  arrivals_arrive <- result[["arrivals"]] %>%
    mutate(interval = (ceiling(.data[["start_time"]] / interval_size) *
                         interval_size))

  # Label interval based on serve_time (used for all other metrics)
  arrivals_serve <- result[["arrivals"]] %>%
    mutate(interval = (ceiling(.data[["serve_start"]] / interval_size) *
                         interval_size))
  resources <- result[["resources"]] %>%
    mutate(interval = (ceiling(.data[["time"]] / interval_size) *
                         interval_size))

  # Calculate metrics
  group_vars <- c("interval", "replication")
  list(
    calc_arrivals(arrivals_arrive, group_vars),
    calc_mean_wait(arrivals_serve, resources, group_vars),
    calc_mean_serve_length(arrivals_serve, resources, group_vars),
    calc_utilisation(resources, group_vars),
    calc_unseen_n(arrivals_serve, group_vars),
    calc_unseen_mean(arrivals_serve, group_vars)
  )
}


#' Time series inspection method for determining length of warm-up.
#'
#' For each metric in the provided dataframes (from `get_interval_means()`),
#' find the cumulative mean results and plot over time (overall and per run).
#'
#' @param df_list List of dataframes, as output by `get_interval_means()`.
#' @param file_path Path to save figure to.
#' @param warm_up Location on X axis to plot vertical red line indicating the
#' chosen warm-up period. Defaults to NULL, which will not plot a line.
#'
#' @importFrom ggplot2 ggplot geom_line aes_string labs theme_minimal geom_vline
#' @importFrom ggplot2 annotate ggsave
#' @importFrom gridExtra marrangeGrob
#'
#' @export

time_series_inspection <- function(df_list, file_path, warm_up = NULL) {

  plot_list <- list()

  # Loop through all the dataframes in df_list
  for (i in seq_along(df_list)) {

    # Get name of the metric
    metric <- setdiff(names(df_list[[i]]), c("interval", "replication"))

    # Calculate cumulative mean for the current metric
    cumulative <- df_list[[i]] %>%
      arrange(.data[["replication"]], .data[["interval"]]) %>%
      group_by(.data[["replication"]]) %>%
      mutate(cumulative_mean = cumsum(.data[[metric]]) /
               seq_along(.data[[metric]])) %>%
      ungroup()

    # Calculate overall cumulative mean at each interval, across replications
    overall_mean <- cumulative %>%
      arrange(.data[["interval"]]) %>%
      group_by(.data[["interval"]]) %>%
      summarise(cumulative_mean = mean(.data[["cumulative_mean"]]))

    # Create plot
    p <- ggplot() +
      geom_line(data = cumulative,
                aes_string(x = "interval", y = "cumulative_mean",
                           group = "replication"),
                color = "lightblue", alpha = 0.8) +
      geom_line(data = overall_mean,
                aes_string(x = "interval", y = "cumulative_mean"),
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
  combined_plot <- marrangeGrob(plot_list, ncol = 1L, nrow = length(df_list))

  # Save to file
  ggsave(file_path, combined_plot, width = 8L, height = 4L * length(df_list))
}
