# Unit testing for the Discrete-Event Simulation (DES) Model.
#
# These check specific parts of the simulation and code, ensuring they work
# correctly and as expected.

test_that("the same seed returns the same result", {

  # Run model twice using same run number (which will set the seed)
  env1 <- model(run_number = 0L, param = defaults())
  env2 <- model(run_number = 0L, param = defaults())

  # Compare output results
  expect_identical(
    env1 %>% simmer::get_mon_arrivals(),
    env2 %>% simmer::get_mon_arrivals()
  )
  expect_identical(
    env1 %>% simmer::get_mon_resources(),
    env2 %>% simmer::get_mon_resources()
  )

  # Conversely, if run with different run number, expect different
  env1 <- model(run_number = 0L, param = defaults())
  env2 <- model(run_number = 1L, param = defaults())

  # Compare output results
  expect_failure(
    expect_identical(
      env1 %>% simmer::get_mon_arrivals(),
      env2 %>% simmer::get_mon_arrivals()
    )
  )
  expect_failure(
    expect_identical(
      env1 %>% simmer::get_mon_resources(),
      env2 %>% simmer::get_mon_resources()
    )
  )

  # Repeat experiment, but with multiple replications
  envs1 <- trial(param = defaults())
  envs2 <- trial(param = defaults())

  # Aggregate results from replications in each trial, then compare full trial
  expect_identical(
    do.call(rbind, lapply(envs1, simmer::get_mon_arrivals)),
    do.call(rbind, lapply(envs2, simmer::get_mon_arrivals))
  )
  expect_identical(
    do.call(rbind, lapply(envs1, simmer::get_mon_resources)),
    do.call(rbind, lapply(envs2, simmer::get_mon_resources))
  )
})
