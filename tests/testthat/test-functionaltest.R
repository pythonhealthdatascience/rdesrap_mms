# Functional testing for the Discrete-Event Simulation (DES) Model.
#
# These verify that the system or components perform their intended
# functionality.

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