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
  raw_results <- runner(param)
  results <- as.data.frame(process_replications(raw_results))

  # Import the expected results
  exp_results <- read.csv(test_path("testdata", "results.csv"))

  # Compare results
  # nolint start: expect_identical_linter.
  expect_equal(results, exp_results)
  # nolint end
})
