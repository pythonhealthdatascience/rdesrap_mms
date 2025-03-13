# Unit testing for objects in choose_replications.R

test_that("WelfordStats calculations are correct", {

  # Initialise with three values
  values <- c(10L, 20L, 30L)
  stats <- WelfordStats$new(data = values, alpha = 0.05)

  # Check statistics(expected results from online calculators)
  expect_identical(stats$mean, 20.0)
  expect_identical(stats$sq, 200.0)
  expect_identical(stats$variance(), 100.0)
  expect_identical(stats$std(), 10.0)
  expect_identical(round(stats$std_error(), 10L), 5.7735026919)

  # Check that statistics (expected results from python st.t.interval())
  expect_identical(round(stats$lci(), 4L), -4.8414)
  expect_identical(round(stats$uci(), 4L), 44.8414)
  expect_identical(round(stats$deviation(), 4L), 1.2421)
})


test_that("WelfordStats doesn't return some calculations for small samples", {

  # Initialise with two values
  values <- c(10L, 20L)
  stats <- WelfordStats$new(data = values)

  # Check that statistics meet our expectations
  # (expected results based on online calculators)
  expect_identical(stats$mean, 15.0)
  expect_identical(stats$sq, 50.0)
  expect_identical(stats$variance(), 50.0)
  expect_true(is.na(stats$std()))
  expect_true(is.na(stats$std_error()))
  expect_true(is.na(stats$half_width()))
  expect_true(is.na(stats$lci()))
  expect_true(is.na(stats$uci()))
  expect_true(is.na(stats$deviation()))
})


test_that("ReplicationTaubliser's update method appends new data + makes df", {
  # Data to be stored by ReplicationTabuliser
  mock_stats <- list(
    latest_data = 10L,
    mean = 5L,
    std = function() 1.2,
    lci = function() 4.8,
    uci = function() 6.2,
    deviation = function() 0.1
  )

  # Create and add data to the class twice
  tab <- ReplicationTabuliser$new()
  tab$update(mock_stats)
  tab$update(mock_stats)

  # Check stored lists
  expect_identical(tab$data_points, c(10L, 10L))
  expect_identical(tab$cumulative_mean, c(5L, 5L))
  expect_identical(tab$std, c(1.2, 1.2))
  expect_identical(tab$lci, c(4.8, 4.8))
  expect_identical(tab$uci, c(6.2, 6.2))
  expect_identical(tab$deviation, c(0.1, 0.1))

  # Check summary table
  mock_df <- data.frame(
    replications = c(1L, 2L),
    data = rep(mock_stats$latest_data, 2L),
    cumulative_mean = rep(mock_stats$mean, 2L),
    stdev = rep(mock_stats$std(), 2L),
    lower_ci = rep(mock_stats$lci(), 2L),
    upper_ci = rep(mock_stats$uci(), 2L),
    deviation = rep(mock_stats$deviation(), 2L)
  )
  expect_identical(tab$summary_table(), mock_df)
})
