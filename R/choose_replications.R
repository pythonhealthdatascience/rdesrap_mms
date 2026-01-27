# nolint start: cyclocomp_linter

#' Create a Welford Statistics Tracker
#'
#' @description
#' Computes running sample mean and variance using Welford's algorithm.
#' They are computed via updates to a stored value, rather than storing lots of
#' data and repeatedly taking the mean after new values have been added.
#'
#' Implements Welford's algorithm for updating mean and variance.
#' See Knuth. D `The Art of Computer Programming` Vol 2. 2nd ed. Page 216.
#'
#' This function is based on the Python class `OnlineStatistics` from Tom Monks
#' (2021) sim-tools: fundamental tools to support the simulation process in
#' python (https://github.com/sim-tools/sim-tools) (MIT Licence).
#'
#' @param data Initial data sample (optional).
#' @param alpha Significance level for confidence interval calculations.
#'   For example, if alpha is 0.05, then the confidence level is 95%.
#' @param observer Observer function to notify on updates (optional).
#'   If provided, will be called with the state list after each update.
#'
#' @return A list of functions with the following methods:
#'   - `welford_update(x)`: Add a new data point
#'   - `get_n()`: Get number of observations
#'   - `get_mean()`: Get running mean
#'   - `get_latest_data()`: Get most recent data point
#'   - `get_sum_sq()`: Get sum of squared differences
#'   - `variance()`: Compute variance
#'   - `std()`: Compute standard deviation
#'   - `std_error()`: Compute standard error of the mean
#'   - `half_width()`: Compute half-width of confidence interval
#'   - `lci()`: Compute lower confidence interval bound
#'   - `uci()`: Compute upper confidence interval bound
#'   - `deviation()`: Compute precision as percentage deviation
#'
#' @export

create_welford_stats <- function(data = NULL, alpha = 0.05, observer = NULL) {

  # Use an environment to store mutable state
  # This avoids <<- while allowing proper state mutation
  state_env <- new.env()

  state_env$n <- 0L
  state_env$latest_data <- NA
  state_env$mean <- NA
  state_env$sq <- NA
  state_env$alpha <- alpha
  state_env$observer <- observer

  # Notify observer if present
  notify_observer <- function() {
    if (is.null(state_env$observer)) return(invisible(NULL))
    observer_state <- list(
      n = state_env$n,
      latest_data = state_env$latest_data,
      mean = state_env$mean,
      sq = state_env$sq
    )
    state_env$observer(observer_state)
    invisible(NULL)
  }

  # Update running statistics with a new data point
  welford_update <- function(x) {
    state_env$n <- state_env$n + 1L
    state_env$latest_data <- x

    # Calculate the mean and sq using Welford's algorithm and notify observer
    if (state_env$n == 1L) {
      state_env$mean <- x
      state_env$sq <- 0L
      notify_observer()
      return(invisible(NULL))
    }

    updated_mean <- state_env$mean + ((x - state_env$mean) / state_env$n)
    state_env$sq <- state_env$sq + ((x - state_env$mean) * (x - updated_mean))
    state_env$mean <- updated_mean

    notify_observer()
    invisible(NULL)
  }

  # Compute variance
  variance <- function() {
    if (state_env$n < 2L) return(NA_real_)
    state_env$sq / (state_env$n - 1L)
  }

  # Compute standard deviation
  std <- function() {
    if (state_env$n < 3L) return(NA_real_)
    sqrt(variance())
  }

  # Compute standard error of the mean
  std_error <- function() {
    s <- std()
    if (is.na(s)) return(NA_real_)
    s / sqrt(state_env$n)
  }

  # Compute half-width of confidence interval
  half_width <- function() {
    if (state_env$n < 3L) return(NA_real_)
    dof <- state_env$n - 1L
    t_value <- qt(1L - (state_env$alpha / 2L), df = dof)
    t_value * std_error()
  }

  # Compute lower confidence interval bound
  lci <- function() {
    hw <- half_width()
    if (is.na(hw)) return(NA_real_)
    state_env$mean - hw
  }

  # Compute upper confidence interval bound
  uci <- function() {
    hw <- half_width()
    if (is.na(hw)) return(NA_real_)
    state_env$mean + hw
  }

  # Compute precision of confidence interval (percentage deviation)
  deviation <- function() {
    mw <- state_env$mean
    if (is.na(mw) || mw == 0L) return(NA_real_)
    hw <- half_width()
    if (is.na(hw)) return(NA_real_)
    hw / mw
  }

  # If initial data supplied, process it
  if (!is.null(data)) {
    for (x in as.vector(data)) {
      welford_update(x)
    }
  }

  # Return public API
  list(
    welford_update = welford_update,
    get_n = function() state_env$n,
    get_mean = function() state_env$mean,
    get_latest_data = function() state_env$latest_data,
    get_sum_sq = function() state_env$sq,
    get_alpha = function() state_env$alpha,
    variance = variance,
    std = std,
    std_error = std_error,
    half_width = half_width,
    lci = lci,
    uci = uci,
    deviation = deviation
  )
}


#' Create a Replication Tabuliser
#'
#' @description
#' Observes and records results from Welford statistics tracker.
#' Updates each time new data is processed. Can generate a results dataframe.
#'
#' This function is based on the Python class `ReplicationTabulizer` from Tom
#' Monks (2021) sim-tools: fundamental tools to support the simulation process
#' in python (https://github.com/sim-tools/sim-tools) (MIT Licence).
#'
#' @return A list of functions with the following methods:
#'   - `tab_update(state)`: Record results from Welford tracker state
#'   - `summary_table()`: Get accumulated results as a dataframe
#'   - `get_data_points()`: Get raw data points
#'   - `get_cumulative_means()`: Get running means
#'   - `get_std_devs()`: Get standard deviations
#'   - `get_lcis()`: Get lower confidence bounds
#'   - `get_ucis()`: Get upper confidence bounds
#'   - `get_deviations()`: Get precision deviations
#'
#' @export

create_replication_tabuliser <- function() {

  # Use an environment to store mutable state
  state_env <- new.env()

  state_env$data_points <- NULL
  state_env$cumulative_mean <- NULL
  state_env$std <- NULL
  state_env$lci <- NULL
  state_env$uci <- NULL
  state_env$deviation <- NULL

  # Add new results from Welford stats
  tab_update <- function(stats) {
    # stats is a list with n, latest_data, mean, sq
    # We need to compute std, lci, uci, deviation

    # Get values from state
    n <- stats$n
    latest_data <- stats$latest_data
    mean_val <- stats$mean
    sq <- stats$sq

    # Compute derived values (same as Welford methods)
    variance <- if (n < 2L) NA_real_ else sq / (n - 1L)
    std_val <- if (n < 3L) NA_real_ else sqrt(variance)

    std_error_val <- if (is.na(std_val)) {
      NA_real_
    } else {
      std_val / sqrt(n)
    }

    half_width_val <- if (n < 3L) {
      NA_real_
    } else {
      dof <- n - 1L
      t_value <- qt(0.975, df = dof)  # 95% CI, so 0.975 quantile
      t_value * std_error_val
    }

    lci_val <- if (is.na(half_width_val)) {
      NA_real_
    } else {
      mean_val - half_width_val
    }

    uci_val <- if (is.na(half_width_val)) {
      NA_real_
    } else {
      mean_val + half_width_val
    }

    deviation_val <- if (is.na(mean_val) || mean_val == 0L ||
                           is.na(half_width_val)) {
      NA_real_
    } else {
      half_width_val / mean_val
    }

    # Append to state
    state_env$data_points <- c(state_env$data_points, latest_data)
    state_env$cumulative_mean <- c(state_env$cumulative_mean, mean_val)
    state_env$std <- c(state_env$std, std_val)
    state_env$lci <- c(state_env$lci, lci_val)
    state_env$uci <- c(state_env$uci, uci_val)
    state_env$deviation <- c(state_env$deviation, deviation_val)
  }

  # Create results table from stored lists
  summary_table <- function() {
    data.frame(
      replications = seq_len(length(state_env$data_points)),
      data = state_env$data_points,
      cumulative_mean = state_env$cumulative_mean,
      stdev = state_env$std,
      lower_ci = state_env$lci,
      upper_ci = state_env$uci,
      deviation = state_env$deviation
    )
  }

  # Return public API
  list(
    tab_update = tab_update,
    summary_table = summary_table,
    get_data_points = function() state_env$data_points,
    get_cumulative_means = function() state_env$cumulative_mean,
    get_std_devs = function() state_env$std,
    get_lcis = function() state_env$lci,
    get_ucis = function() state_env$uci,
    get_deviations = function() state_env$deviation
  )
}


#' Replication Algorithm for Automatic Selection
#'
#' @description
#' Implements an adaptive replication algorithm for selecting the
#' appropriate number of simulation replications based on statistical
#' precision.
#'
#' Uses the "Replications Algorithm" from Hoad, Robinson, & Davies (2010).
#' Automated selection of the number of replications for a discrete-event
#' simulation. Journal of the Operational Research Society.
#' https://www.jstor.org/stable/40926090.
#'
#' Given a model's performance measure and a user-set confidence interval
#' half width precision, automatically select the number of replications.
#' Combines the "confidence intervals" method with a sequential look-ahead
#' procedure to determine if a desired precision in the confidence interval
#' is maintained.
#'
#' This function is based on the Python class `ReplicationsAlgorithm` from Tom
#' Monks (2021) sim-tools: fundamental tools to support the simulation process
#' in python (https://github.com/sim-tools/sim-tools) (MIT Licence).
#'
#' @param param Model parameters (list).
#' @param metrics List of performance measure names to track (should correspond
#'   to column names from the run results dataframe).
#' @param desired_precision Target half width precision for the algorithm
#'   (i.e. percentage deviation of the confidence interval from the mean,
#'   expressed as a proportion, e.g. 0.1 = 10%). Choice is fairly arbitrary.
#' @param initial_replications Number of initial replications to perform
#'   (default: 3).
#' @param look_ahead Minimum additional replications to look ahead to assess
#'   stability of precision. When replications are <= 100, the value of
#'   look_ahead is used. When > 100, then look_ahead / 100 * max(n, 100)
#'   is used (default: 5).
#' @param replication_budget Maximum allowed replications. Use for larger
#'   models where replication runtime is a constraint (default: 1000).
#' @param verbose Boolean, whether to print messages about parameters
#'   (default: TRUE).
#'
#' @return A list of functions with the following methods:
#'   - `select()`: Execute the replication algorithm
#'   - `get_nreps()`: Get minimum replications required for each metric
#'   - `get_summary_table()`: Get full results table with cumulative
#'     statistics for each replication
#'   - `get_reps()`: Get number of replications performed
#'
#' @export

create_replications_algorithm <- function(
    param,
    metrics,
    desired_precision = 0.1,
    initial_replications = 3L,
    look_ahead = 5L,
    replication_budget = 1000L,
    verbose = TRUE) {

  # Use an environment to store mutable state
  state_env <- new.env()

  state_env$param <- param
  state_env$metrics <- metrics
  state_env$desired_precision <- desired_precision
  state_env$initial_replications <- initial_replications
  state_env$look_ahead <- look_ahead
  state_env$replication_budget <- replication_budget
  state_env$reps <- initial_replications
  state_env$nreps <- NA
  state_env$summary_table <- NA

  # Validate inputs
  validate_inputs <- function() {
    for (p in c("initial_replications", "look_ahead")) {
      if (state_env[[p]] %% 1L != 0L || state_env[[p]] < 0L) {
        stop(
          p, " must be a non-negative integer, but provided ",
          state_env[[p]], ".",
          call. = FALSE
        )
      }
    }
    if (state_env$desired_precision <= 0L) {
      stop("desired_precision must be greater than 0.", call. = FALSE)
    }
    if (state_env$replication_budget < state_env$initial_replications) {
      stop(
        "replication_budget must be greater than initial_replications.",
        call. = FALSE
      )
    }
  }

  # Calculate the klimit (lookahead window)
  klimit <- function() {
    as.integer((state_env$look_ahead / 100L) * max(state_env$reps, 100L))
  }

  # Find first position where element is below deviation and maintained
  find_position <- function(lst) {
    # Ensure input is a list
    if (!is.list(lst)) {
      stop(
        "find_position requires a list but was supplied: ", typeof(lst),
        call. = FALSE
      )
    }

    # Check if list is empty or no values below threshold
    if (length(lst) == 0L || all(is.na(lst)) || !any(unlist(lst) < 0.5)) {
      return(NULL)
    }

    # Find first non-NA value in list
    start_index <- which(
      !vapply(lst, is.na, logical(1L))
    )[1L]

    # Iterate through list, stopping when at last point where we still
    # have enough elements to look ahead
    max_index <- length(lst) - state_env$look_ahead
    if (start_index > max_index) {
      return(NULL)
    }

    for (i in start_index:max_index) {
      # Trim to list with current value + lookahead
      # Check if all fall below desired deviation
      segment <- lst[i:(i + state_env$look_ahead)]
      if (all(vapply(
        segment,
        function(x) x < state_env$desired_precision,
        logical(1L)
      ))) {
        return(i)
      }
    }
    NULL
  }

  # Execute the replication algorithm
  select <- function() {
    # Create instances of observers for each metric
    observers <- setNames(
      lapply(state_env$metrics, function(x) create_replication_tabuliser()),
      state_env$metrics
    )

    # Create nested list to store record for each metric
    solutions <- setNames(
      lapply(state_env$metrics, function(x) {
        list(nreps = NA, target_met = 0L, solved = FALSE)
      }),
      state_env$metrics
    )

    # If no initial replications, create empty Welford instances
    if (state_env$initial_replications == 0L) {
      stats <- setNames(
        lapply(
          state_env$metrics,
          function(x) {
            create_welford_stats(
              observer = function(s) observers[[x]]$tab_update(s)
            )
          }
        ),
        state_env$metrics
      )
    } else {
      # Run initial replications
      state_env$param[["number_of_runs"]] <- state_env$initial_replications
      result <- runner(state_env$param)[["run_results"]]

      # Create Welford instances pre-loaded with initial data
      stats <- setNames(
        lapply(state_env$metrics, function(x) {
          create_welford_stats(
            data = result[[x]],
            observer = function(s) observers[[x]]$tab_update(s)
          )
        }),
        state_env$metrics
      )

      # Check if any have met precision after initial replications
      for (metric in state_env$metrics) {
        if (isTRUE(stats[[metric]]$deviation() <
                     state_env$desired_precision)) {
          solutions[[metric]]$nreps <- state_env$reps
          solutions[[metric]]$target_met <- 1L
          if (klimit() == 0L) {
            solutions[[metric]]$solved <- TRUE
          }
        }
      }
    }

    # Check if all metrics are solved
    is_all_solved <- function() {
      statuses <- unlist(lapply(solutions, function(x) x$solved))
      all(statuses)
    }

    # Main algorithm loop
    while (!is_all_solved() &&
             state_env$reps < state_env$replication_budget + klimit()) {

      # Increment counter
      state_env$reps <- state_env$reps + 1L

      # Run another replication
      result <- model(
        run_number = state_env$reps,
        param = state_env$param
      )[["run_results"]]

      # Loop through metrics
      for (metric in state_env$metrics) {
        # If not yet solved
        if (!solutions[[metric]]$solved) {
          # Update running statistics
          stats[[metric]]$welford_update(result[[metric]])

          # If precision achieved
          if (isTRUE(stats[[metric]]$deviation() <
                       state_env$desired_precision)) {
            # Record solution if not previously met
            if (solutions[[metric]]$target_met == 0L) {
              solutions[[metric]]$nreps <- state_env$reps
            }

            # Update how many times precision met in row
            solutions[[metric]]$target_met <-
              solutions[[metric]]$target_met + 1L

            # Mark solved if lookahead period passed
            if (solutions[[metric]]$target_met > klimit()) {
              solutions[[metric]]$solved <- TRUE
            }
          } else {
            # If precision not achieved, reset
            solutions[[metric]]$nreps <- NA
            solutions[[metric]]$target_met <- 0L
          }
        }
      }
    }

    # Correction using find_position
    for (metric in names(solutions)) {
      adj_nreps <- find_position(
        as.list(observers[[metric]]$get_deviations())
      )
      # If maintained solution found, replace in solutions
      if (!is.null(adj_nreps) && !is.na(solutions[[metric]]$nreps)) {
        solutions[[metric]]$nreps <- adj_nreps
      }
    }

    # Extract minimum replications for each metric
    state_env$nreps <- lapply(solutions, function(x) x$nreps)

    # Extract metrics that were not solved and return warning
    if (anyNA(state_env$nreps)) {
      unsolved <- names(state_env$nreps)[
        vapply(state_env$nreps, is.na, logical(1L))
      ]
      warning(
        "The replications did not reach the desired precision ",
        "for the following metrics - ", toString(unsolved),
        call. = FALSE
      )
    }

    # Combine observer summary frames into single table
    summary_tables <- lapply(names(observers), function(name) {
      tab <- observers[[name]]$summary_table()
      tab$metric <- name
      tab
    })
    state_env$summary_table <- do.call(rbind, summary_tables)

    invisible(NULL)
  }

  # Initialize validation
  validate_inputs()

  # Print parameters if verbose
  if (isTRUE(verbose)) {
    cat("Model parameters:\n")
    print(state_env$param)
  }

  # Return public API
  list(
    select = select,
    get_nreps = function() state_env$nreps,
    get_summary_table = function() state_env$summary_table,
    get_reps = function() state_env$reps,
    get_param = function() state_env$param,
    get_metrics = function() state_env$metrics,
    get_desired_precision = function() state_env$desired_precision
  )
}

# nolint end


#' Use the confidence interval method to select the number of replications.
#'
#' This could be altered to use WelfordStats and ReplicationTabuliser if
#' desired, but currently is independent.
#'
#' @param replications Number of times to run the model.
#' @param desired_precision Desired mean deviation from confidence interval.
#' @param metric Name of performance metric to assess.
#' @param verbose Boolean, whether to print messages about parameters.
#'
#' @return Dataframe with results from each replication.
#' @export

confidence_interval_method <- function(replications, desired_precision,
                                       metric, verbose = TRUE) {
  # Run model for specified number of replications
  param <- parameters(number_of_runs = replications)
  if (isTRUE(verbose)) {
    print(param)
  }
  results <- runner(param, use_future_seeding = FALSE)[["run_results"]]

  # Initialise list to store the results
  cumulative_list <- list()

  # For each row in the dataframe, filter to rows up to the i-th replication
  # then perform calculations
  for (i in 1L:replications) {

    # Filter rows up to the i-th replication
    subset_data <- results[[metric]][1L:i]

    # Get latest data point
    last_data_point <- tail(subset_data, n = 1L)

    # Calculate mean
    mean_value <- mean(subset_data)

    # Some calculations require a few observations else will error...
    if (i < 3L) {
      # When only one observation, set to NA
      stdev <- NA
      lower_ci <- NA
      upper_ci <- NA
      deviation <- NA
    } else {
      # Else, calculate standard deviation, 95% confidence interval, and
      # percentage deviation
      stdev <- stats::sd(subset_data)
      ci <- stats::t.test(subset_data)[["conf.int"]]
      lower_ci <- ci[[1L]]
      upper_ci <- ci[[2L]]
      deviation <- ((upper_ci - mean_value) / mean_value)
    }

    # Append to the cumulative list
    cumulative_list[[i]] <- data.frame(
      replications = i,
      data = last_data_point,
      cumulative_mean = mean_value,
      stdev = stdev,
      lower_ci = lower_ci,
      upper_ci = upper_ci,
      deviation = deviation
    )
  }

  # Combine the list into a single data frame
  cumulative <- do.call(rbind, cumulative_list)
  cumulative[["metric"]] <- metric

  # Get the minimum number of replications where deviation is less than target
  compare <- dplyr::filter(
    cumulative, .data[["deviation"]] <= desired_precision
  )
  if (nrow(compare) > 0L) {
    # Get minimum number
    n_reps <- compare |>
      dplyr::slice_head() |>
      dplyr::select(replications) |>
      dplyr::pull()
    message("Reached desired precision (", desired_precision, ") in ",
            n_reps, " replications.")
  } else {
    warning("Running ", replications, " replications did not reach ",
            "desired precision (", desired_precision, ").", call. = FALSE)
  }
  cumulative
}


#' Generate a plot of metric and confidence intervals with increasing
#' simulation replications
#'
#' @param conf_ints A dataframe containing confidence interval statistics,
#' including cumulative mean, upper/lower bounds, and deviations. As returned
#' by ReplicationTabuliser summary_table() method.
#' @param yaxis_title Label for y axis.
#' @param file_path Path and filename to save the plot to.
#' @param min_rep The number of replications required to meet the desired
#' precision.

plot_replication_ci <- function(
  conf_ints, yaxis_title, file_path = NULL, min_rep = NULL
) {
  # Plot the cumulative mean and confidence interval
  p <- ggplot2::ggplot(conf_ints,
                       ggplot2::aes(x = .data[["replications"]],
                                    y = .data[["cumulative_mean"]])) +
    ggplot2::geom_line() +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data[["lower_ci"]], ymax = .data[["upper_ci"]]),
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
  if (!is.null(file_path)) {
    ggplot2::ggsave(filename = file_path,
                    width = 6.5, height = 4L, bg = "white")
  } else {
    p
  }
}
