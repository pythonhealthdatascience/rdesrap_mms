# Back testing for the Discrete-Event Simulation (DES) Model.
#
# These check that the model code produces results consistent with prior code.


test_that("results from a new run match those previously generated", {
  # Choose a specific set of parameters (ensuring test remains on the same
  # set, regardless of any changes to parameters())
  param <- parameters(
    patient_inter = 4L,
    mean_n_consult_time = 10L,
    number_of_nurses = 5L,
    data_collection_period = 80L,
    number_of_runs = 10L,
    cores = 1L
  )

  # Run the replications then get the monitored arrivals and resources
  results <- as.data.frame(runner(param)[["run_results"]])

  # Import the expected results
  exp_results <- read.csv(test_path("testdata", "base_results.csv"))

  # Compare results
  expect_equal(results, exp_results) # nolint: expect_identical_linter
})


test_that("results from scenario analysis match those previously generated", {
  # Choose a specific set of parameters (ensuring test remains on the same
  # set, regardless of any changes to parameters())
  param <- parameters(
    patient_inter = 4L,
    mean_n_consult_time = 10L,
    number_of_nurses = 5L,
    data_collection_period = 80L,
    number_of_runs = 10L,
    cores = 1L
  )

  # Run scenario analysis
  scenarios <- list(
    patient_inter = c(3L, 4L, 5L),
    number_of_nurses = c(6L, 7L)
  )

  scenario_results <- as.data.frame(
    run_scenarios(scenarios, base_list = parameters())
  )

  # Import the expected results
  exp_results <- read.csv(test_path("testdata", "scenario_results.csv"))

  # Compare results
  expect_equal(scenario_results, exp_results) # nolint: expect_identical_linter
})
