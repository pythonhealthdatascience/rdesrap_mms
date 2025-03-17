# Back testing for objects in choose_replications.R

test_that("results from confidence_interval_method are consistent", {
  # Specify parameters (so consistent even if defaults change)
  param <- parameters(
    patient_inter = 4L,
    mean_n_consult_time = 10L,
    number_of_nurses = 5L,
    warm_up_period = 0L,
    data_collection_period = 80L
  )

  # Run the confidence_interval_method()
  rep_results <- suppressWarnings(confidence_interval_method(
    replications = 15,
    desired_precision = 0.05,
    metric = "mean_serve_time_nurse"
  ))

  # Import the expected results
  exp_results <- read.csv(test_path("testdata", "choose_rep_results.csv"))

  # Compare to those generated
  expect_equal(rep_results, exp_results)
})


test_that("results from ReplicationsAlgorithm are consistent", {
  # Specify parameters (so consistent even if defaults change)
  param <- parameters(
    patient_inter = 4L,
    mean_n_consult_time = 10L,
    number_of_nurses = 5L,
    warm_up_period = 0L,
    data_collection_period = 80L
  )

  # Run the confidence_interval_method()
  alg <- ReplicationsAlgorithm$new(
    param = param,
    metrics = c("mean_serve_time_nurse"),
    desired_precision = 0.05,
    initial_replications = 15,
    look_ahead = 0,
    replication_budget = 15)
  suppressWarnings(alg$select())
  rep_results <- alg$summary_table

  # Import the expected results
  exp_results <- read.csv(test_path("testdata", "choose_rep_results.csv"))

  # Compare to those generated
  expect_equal(rep_results, exp_results)
})
