# Unit testing for the Discrete-Event Simulation (DES) Model.
#
# These check specific parts of the simulation and code, ensuring they work
# correctly and as expected.

test_that("the same seed returns the same result", {

  # Run model twice using same run number (which will set the seed)
  env1 <- model(run_number = 0L, param_class = defaults())
  env2 <- model(run_number = 0L, param_class = defaults())
  expect_identical(process_replications(env1), process_replications(env2))

  # Conversely, if run with different run number, expect different
  env1 <- model(run_number = 0L, param_class = defaults())
  env2 <- model(run_number = 1L, param_class = defaults())
  expect_failure(
    expect_identical(process_replications(env1), process_replications(env2))
  )

  # Repeat experiment, but with multiple replications
  envs1 <- trial(param_class = defaults())
  envs2 <- trial(param_class = defaults())
  expect_identical(process_replications(envs1), process_replications(envs2))
})
