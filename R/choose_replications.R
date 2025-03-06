#' Use the confidence interval method to select the number of replications.
#'
#' @param replications Number of times to run the model.
#' @param desired_precision Desired mean deviation from confidence interval.
#' @param metric Name of performance metric to assess.
#' @param yaxis_title Label for y axis.
#' @param path Path inc. filename to save figure to.
#' @param min_rep A suggested minimum number of replications (default=NULL).
#'
#' @return Dataframe with results from each replication.
#' @export

confidence_interval_method <- function(replications, desired_precision, metric,
                                       yaxis_title, path, min_rep = NULL) {
  # Run model for specified number of replications
  param <- parameters(number_of_runs = replications)
  results <- runner(param)[["run_results"]]

  # If mean of metric is less than 1, multiply by 100
  if (mean(results[[metric]]) < 1L) {
    results[[paste0("adj_", metric)]] <- results[[metric]] * 100L
    metric <- paste0("adj_", metric)
  }

  # Initialise list to store the results
  cumulative_list <- list()

  # For each row in the dataframe, filter to rows up to the i-th replication
  # then perform calculations
  for (i in 1L:replications) {

    # Filter rows up to the i-th replication
    subset_data <- results[[metric]][1L:i]

    # Calculate mean
    mean_value <- mean(subset_data)

    # Some calculations require a few observations else will error...
    if (i < 3L) {
      # When only one observation, set to NA
      std_dev <- NA
      ci_lower <- NA
      ci_upper <- NA
      deviation <- NA
    } else {
      # Else, calculate standard deviation, 95% confidence interval, and
      # percentage deviation
      std_dev <- stats::sd(subset_data)
      ci <- stats::t.test(subset_data)[["conf.int"]]
      ci_lower <- ci[[1L]]
      ci_upper <- ci[[2L]]
      deviation <- ((ci_upper - mean_value) / mean_value) * 100L
    }

    # Append to the cumulative list
    cumulative_list[[i]] <- data.frame(
      replications = i,
      cumulative_mean = mean_value,
      cumulative_std = std_dev,
      ci_lower = ci_lower,
      ci_upper = ci_upper,
      perc_deviation = deviation
    )
  }

  # Combine the list into a single data frame
  cumulative <- do.call(rbind, cumulative_list)

  # Get the minimum number of replications where deviation is less than target
  compare <- dplyr::filter(
    cumulative, .data[["perc_deviation"]] <= desired_precision * 100L
  )
  if (nrow(compare) > 0L) {
    # Get minimum number
    n_reps <- compare %>%
      dplyr::slice_head() %>%
      dplyr::select(replications) %>%
      dplyr::pull()
    message("Reached desired precision (", desired_precision, ") in ",
            n_reps, " replications.")
  } else {
    warning("Running ", replications, " replications did not reach ",
            "desired precision (", desired_precision, ").", call. = FALSE)
  }

  # Plot the cumulative mean and confidence interval
  p <- ggplot2::ggplot(cumulative,
                       ggplot2::aes(x = .data[["replications"]],
                                    y = .data[["cumulative_mean"]])) +
    ggplot2::geom_line() +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = ci_lower, ymax = ci_upper),
      alpha = 0.2
    )

  # If specified, plot the minimum suggested number of replications
  if (!is.null(min_rep)) {
    p <- p +
      ggplot2::geom_vline(
        xintercept = min_rep, linetype = "dashed", color = "red"
      )
  }

  # Modify labels and style
  p <- p +
    ggplot2::labs(x = "Replications", y = yaxis_title) +
    ggplot2::theme_minimal()

  # Save the plot
  ggplot2::ggsave(filename = path, width = 6.5, height = 4L, bg = "white")

  return(cumulative)
}
