# Back testing for the Discrete-Event Simulation (DES) Model.
#
# These check that the model code produces results consistent with prior code.

test_that("results from a new run match those previously generated", {
  # Choose a specific set of parameters (ensuring test remains on the same
  # set, regardless of any changes to Defaults)
  param_class <- defaults()
  param_class[["update"]](list(patient_inter = 4L,
                               mean_n_consult_time = 10L,
                               number_of_nurses = 5L,
                               data_collection_period = 80L,
                               number_of_runs = 10L,
                               cores = 1L))

  # Run the trial then get the monitored arrivals and resources
  envs <- trial(param_class)
  results <- as.data.frame(process_replications(envs))

  # Import the expected results
  exp_results <- read.csv(test_path("testdata", "results.csv"))

  # Compare results
  # nolint start: expect_identical_linter.
  expect_equal(results, exp_results)
  # nolint end
})
