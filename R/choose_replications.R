#' Computes running sample mean and variance using Welford's algorithm.
#'
#' @description
#' They are computed via updates to a stored value, rather than storing lots of
#' data and repeatedly taking the mean after new values have been added.
#' Implements Welford's algorithm for updating mean and variance.
#' See Knuth. D `The Art of Computer Programming` Vol 2. 2nd ed. Page 216.
#'
#' @docType class
#' @importFrom R6 R6Class
#'
#' @return Object of `R6Class` with methods for running mean and variance
#' calculation.
#' @export

WelfordStats <- R6Class("WelfordStats", list( # nolint: object_name_linter

  #' @field n Number of observations.
  n = 0L,

  #' @field mean Running mean.
  mean = NA,

  #' @field sq Running sum of squares of differences.
  sq = NA,

  #' @field alpha Significance level for confidence interval calculations.
  #' For example, if alpha is 0.05, then confidence level is 95 \%.
  alpha = NA,

  #' @description Initialise the WelfordStats object.
  #' @param data Initial data sample.
  #' @param alpha Significance level for confidence interval calculations.
  #' @return A new `WelfordStats` object.
  initialize = function(data = NULL, alpha = 0.05) {
    # Set alpha using the provided value
    self$alpha <- alpha
    # If an initial data sample is supplied, then run update()
    if (!is.null(data)) {
      for (x in as.matrix(data)) {
        self$update(x)
      }
    }
  },

  #' @description Update running statistics with a new data point.
  #' @param x A new data point.
  update = function(x) {
    self$n <- self$n + 1L
    if (self$n == 1L) {
      self$mean <- x
      self$sq <- 0L
    } else {
      updated_mean <- self$mean + ((x - self$mean) / self$n)
      self$sq <- self$sq + ((x - self$mean) * (x - updated_mean))
      self$mean <- updated_mean
    }
  },

  #' @description Computes the variance of the data points.
  variance = function() {
    self$sq / (self$n - 1L)
  },

  #' @description Computes the standard deviation.
  std = function() {
    if (self$n < 3L) return(NA_real_)
    sqrt(self$variance())
  },

  #' @description Computes the standard error of the mean.
  std_error = function() {
    self$std() / sqrt(self$n)
  },

  #' @description Computes the half-width of the confidence interval.
  half_width = function() {
    if (self$n < 3L) return(NA_real_)
    dof <- self$n - 1L
    t_value <- qt(1L - (self$alpha / 2L), df = dof)
    t_value * self$std_error()
  },

  #' @description Computes the lower confidence interval bound.
  lci = function() {
    self$mean - self$half_width()
  },

  #' @description Computes the upper confidence interval bound.
  uci = function() {
    self$mean + self$half_width()
  },

  #' @description Computes the precision of the confidence interval expressed
  #' as the percentage deviation of the half width from the mean.
  deviation = function() {
    self$half_width() / self$mean
  }
))


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
