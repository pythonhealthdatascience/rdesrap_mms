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

  #' @field latest_data Latest data point.
  latest_data = NA,

  #' @field mean Running mean.
  mean = NA,

  #' @field sq Running sum of squares of differences.
  sq = NA,

  #' @field alpha Significance level for confidence interval calculations.
  #' For example, if alpha is 0.05, then the confidence level is 95\%.
  alpha = NA,

  #' @field observer Observer to notify on updates.
  observer = NULL,

  #' @description Initialise the WelfordStats object.
  #' @param data Initial data sample.
  #' @param alpha Significance level for confidence interval calculations.
  #' @param observer Observer to notify on updates.
  #' @return A new `WelfordStats` object.
  initialize = function(data = NULL, alpha = 0.05, observer = NULL) {
    # Set alpha and observer using the provided values/objects
    self$alpha <- alpha
    self$observer <- observer
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
    # Increment counter and save the latest data point
    self$n <- self$n + 1L
    self$latest_data <- x
    # Calculate the mean and sq
    if (self$n == 1L) {
      self$mean <- x
      self$sq <- 0L
    } else {
      updated_mean <- self$mean + ((x - self$mean) / self$n)
      self$sq <- self$sq + ((x - self$mean) * (x - updated_mean))
      self$mean <- updated_mean
    }
    # Update observer if present
    if (!is.null(self$observer)) {
      self$observer$update(self)
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


#' Observes and records results from WelfordStats.
#'
#' @description
#' Updates each time new data is processed. Can generate a results dataframe.
#'
#' @docType class
#' @importFrom R6 R6Class
ReplicationTabuliser <- R6Class("ReplicationTabuliser", list( # nolint: object_name_linter

  #' @field data_points List containing each data point.
  data_points = NULL,

  #' @field cumulative_mean List of the running mean.
  cumulative_mean = NULL,

  #' @field std List of the standard deviation.
  std = NULL,

  #' @field lci List of the lower confidence interval bound.
  lci = NULL,

  #' @field uci List of the upper confidence interval bound.
  uci = NULL,

  #' @field deviation List of the percentage deviation of the confidence
  #' interval half width from the mean.
  deviation = NULL,

  #' @description Add new results from WelfordStats to the appropriate lists.
  #' @param stats An instance of WelfordStats containing updated statistical
  #' measures like the mean, standard deviation and confidence intervals.
  update = function(stats) {
    self$data_points <- c(self$data_points, stats$latest_data)
    self$cumulative_mean <- c(self$cumulative_mean, stats$mean)
    self$std <- c(self$std, stats$std())
    self$lci <- c(self$lci, stats$lci())
    self$uci <- c(self$uci, stats$uci())
    self$deviation <- c(self$deviation, stats$deviation())
  },

  #' @description Creates a results table from the stored lists.
  #' @return Stored results compiled into a dataframe.
  summary_table = function() {
    data.frame(
      replications = seq_len(length(self$data_points)),
      data = self$data_points,
      cumulative_mean = self$cumulative_mean,
      stdev = self$std,
      lower_ci = self$lci,
      upper_ci = self$uci,
      deviation = self$deviation
    )
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
