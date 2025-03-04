# Functional testing for the Discrete-Event Simulation (DES) Model.
#
# These verify that the system or components perform their intended
# functionality.

test_that("values are non-negative", {
  # Run model with standard parameters
  env <- model(run_number = 0L, param = parameters())
  results <- process_replications(env)

  # Check that at least one patient was processed
  expect_gt(results[["arrivals"]], 0L)

  # Check that the wait time is not negative
  expect_gte(results[["mean_waiting_time_nurse"]], 0L)

  # Check that the activity time and utilisation are greater than 0
  expect_gt(results[["mean_activity_time_nurse"]], 0L)
  expect_gt(results[["utilisation_nurse"]], 0L)
})

test_that("under high demand, utilisation is valid and last patient is unseen",
  {
    # Run model with high number of arrivals and only one nurse
    param = parameters(
      number_of_nurses = 1,
      patient_inter = 0.1,
      number_of_runs = 1,
      cores = 1)
    env <- runner(param)
    results <- process_replications(env)

    # Check that utilisation does not exceed 1 or drop below 0
    expect_lte(results[["utilisation_nurse"]], 1)
    expect_gte(results[["utilisation_nurse"]], 0)

    # Check that final patient is not seen by the nurse
    expect_equal(tail(env[["arrivals"]], 1)[["end_time"]], NA_real_)
    expect_equal(tail(env[["arrivals"]], 1)[["activity_time"]], NA_real_)
  }
)

test_that("the same seed returns the same result", {
  # Run model twice using same run number (which will set the seed)
  env1 <- model(run_number = 0L, param = parameters())
  env2 <- model(run_number = 0L, param = parameters())
  expect_identical(process_replications(env1), process_replications(env2))

  # Conversely, if run with different run number, expect different
  env1 <- model(run_number = 0L, param = parameters())
  env2 <- model(run_number = 1L, param = parameters())
  expect_failure(
    expect_identical(process_replications(env1), process_replications(env2))
  )

  # Repeat experiment, but with multiple replications
  envs1 <- runner(param = parameters())
  envs2 <- runner(param = parameters())
  expect_identical(process_replications(envs1), process_replications(envs2))
})

test_that("runner outputs a named list with length 2 and correct names", {
  # Simple run of the model
  param <- parameters(
    data_collection_period = 50L, number_of_runs = 1L, cores = 1L)
  result <- runner(param)

  # Check the structure
  expect_type(result, "list")
  expect_length(result, 2)
  expect_named(result, c("arrivals", "resources"))

  # Check that arrivals and resources are dataframes
  expect_s3_class(result[["arrivals"]], "data.frame")
  expect_s3_class(result[["resources"]], "data.frame")
})
