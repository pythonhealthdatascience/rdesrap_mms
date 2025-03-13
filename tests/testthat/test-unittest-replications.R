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
