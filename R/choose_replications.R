#' Use the confidence interval method to select the number of replications.
#'
#' @param replications Number of times to run the model.
#' @param desired_precision Desired mean deviation from confidence interval.
#' @param metric Name of performance metric to assess.
#' @param yaxis_title Label for y axis.
#' @param path Path inc. filename to save figure to.
#' @param min_rep A suggested minimum number of replications (default=NULL).
#'
#' @importFrom stats sd t.test
#' @importFrom dplyr filter slice_head select pull
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon geom_vline labs
#' theme_minimal ggsave
#' @importFrom rlang .data
#'
#' @return Dataframe with results from each replication.
#' @export

confidence_interval_method <- function(replications, desired_precision, metric,
                                       yaxis_title, path, min_rep = NULL) {
  # Run model for specified number of replications
  param <- parameters(number_of_runs = replications)
  envs <- runner(param)
  results <- process_replications(envs)

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
    subset <- results[[metric]][1L:i]

    # Calculate mean
    mean <- mean(subset)

    # Some calculations require more than 1 observation else will error...
    if (i == 1L) {
      # When only one observation, set to NA
      std_dev <- NA
      ci_lower <- NA
      ci_upper <- NA
      deviation <- NA
    } else {
      # Else, calculate standard deviation, 95% confidence interval, and
      # percentage deviation
      std_dev <- sd(subset)
      ci <- t.test(subset)[["conf.int"]]
      ci_lower <- ci[[1L]]
      ci_upper <- ci[[2L]]
      deviation <- ((ci_upper - mean) / mean) * 100L
    }

    # Append to the cumulative list
    cumulative_list[[i]] <- data.frame(
      replications = i,
      cumulative_mean = mean,
      cumulative_std = std_dev,
      ci_lower = ci_lower,
      ci_upper = ci_upper,
      perc_deviation = deviation
    )
  }

  # Combine the list into a single data frame
  cumulative <- do.call(rbind, cumulative_list)

  # Get the minimum number of replications where deviation is less than target
  compare <- cumulative %>%
    filter(.data[["perc_deviation"]] <= desired_precision * 100L)
  if (nrow(compare) > 0L) {
    # Get minimum number
    n_reps <- compare %>%
      slice_head() %>%
      dplyr::select(replications) %>%
      pull()
    print(paste0("Reached desired precision (", desired_precision, ") in ",
                 n_reps, " replications."))
  } else {
    warning("Running ", replications, " replications did not reach ",
            "desired precision (", desired_precision, ").")
  }

  # Plot the cumulative mean and confidence interval
  p <- ggplot(cumulative, aes(x = .data[["replications"]],
                              y = .data[["cumulative_mean"]])) +
    geom_line() +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2)

  # If specified, plot the minimum suggested number of replications
  if (!is.null(min_rep)) {
    p <- p +
      geom_vline(xintercept = min_rep, linetype = "dashed", color = "red")
  }

  # Modify labels and style
  p <- p +
    labs(x = "Replications", y = yaxis_title) +
    theme_minimal()

  # Save the plot
  ggsave(filename = path, width = 6.5, height = 4L, bg = "white")

  return(cumulative)
}
