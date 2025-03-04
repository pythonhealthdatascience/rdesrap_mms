# Functional testing for the Discrete-Event Simulation (DES) Model.
#
# These verify that the system or components perform their intended
# functionality.


test_that("values are non-negative", {
  # Run model with standard parameters
  raw_results <- model(run_number = 0L, param = parameters())
  results <- get_run_results(raw_results)

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
    param <- parameters(
      number_of_nurses = 1L,
      patient_inter = 0.1,
      number_of_runs = 1L,
      cores = 1L
    )
    raw_results <- runner(param)
    results <- get_run_results(raw_results)

    # Check that utilisation does not exceed 1 or drop below 0
    expect_lte(results[["utilisation_nurse"]], 1L)
    expect_gte(results[["utilisation_nurse"]], 0L)

    # Check that final patient is not seen by the nurse
    expect_identical(
      tail(raw_results[["arrivals"]], 1L)[["end_time"]], NA_real_
    )
    expect_identical(
      tail(raw_results[["arrivals"]], 1L)[["activity_time"]], NA_real_
    )
  }
)


test_that("runner outputs a named list with length 2 and correct names", {
  # Simple run of the model
  param <- parameters(
    data_collection_period = 50L, number_of_runs = 1L, cores = 1L
  )
  result <- runner(param)

  # Check the structure
  expect_type(result, "list")
  expect_length(result, 2L)
  expect_named(result, c("arrivals", "resources"))

  # Check that arrivals and resources are dataframes
  expect_s3_class(result[["arrivals"]], "data.frame")
  expect_s3_class(result[["resources"]], "data.frame")
})


patrick::with_parameters_test_that(
  "adjusting parameters decreases the wait time and utilisation",
  {
    # Set some defaults which will ensure sufficient arrivals/capacity to see
    # variation in wait time and utilisation
    default_param <- parameters(number_of_nurses = 4L,
                                patient_inter = 3L,
                                mean_n_consult_time = 15L,
                                data_collection_period = 200L,
                                number_of_runs = 1L)

    # Run model with initial value
    init_param <- default_param
    init_param[[param_name]] <- init_value
    init_result <- get_run_results(runner(init_param))

    # Run model with adjusted value
    adj_param <- default_param
    adj_param[[param_name]] <- adj_value
    adj_result <- get_run_results(runner(adj_param))

    # Check that waiting times in the adjusted model are lower
    expect_lt(adj_result[["mean_waiting_time_nurse"]],
              init_result[["mean_waiting_time_nurse"]])

    # Check that utilisation in the adjusted model is lower
    expect_lt(adj_result[["utilisation_nurse"]],
              init_result[["utilisation_nurse"]])
  },
  patrick::cases(
    list(param_name = "number_of_nurses", init_value = 3L, adj_value = 9L),
    list(param_name = "patient_inter", init_value = 2L, adj_value = 15L),
    list(param_name = "mean_n_consult_time", init_value = 30L, adj_value = 3L)
  )
)


patrick::with_parameters_test_that(
  "adjusting parameters reduces the number of arrivals",
  {
    # Set some default parameters
    default_param <- parameters(data_collection_period = 200L,
                                number_of_runs = 1L)

    # Run model with initial value
    init_param <- default_param
    init_param[[param_name]] <- init_value
    init_result <- get_run_results(model(run_number = 1L, init_param))

    # Run model with adjusted value
    adj_param <- default_param
    adj_param[[param_name]] <- adj_value
    adj_result <- get_run_results(model(run_number = 1L, adj_param))

    # Check that arrivals in the adjusted model are lower
    expect_lt(adj_result[["arrivals"]], init_result[["arrivals"]])
  },
  patrick::cases(
    list(param_name = "patient_inter", init_value = 2L, adj_value = 15L),
    list(param_name = "data_collection_period", init_value = 2000L,
         adj_value = 500L)
  )
)


test_that("the same seed returns the same result", {
  # Run model twice using same run number (which will set the seed)
  raw1 <- model(run_number = 0L, param = parameters())
  raw2 <- model(run_number = 0L, param = parameters())
  expect_identical(get_run_results(raw1), get_run_results(raw2))

  # Conversely, if run with different run number, expect different
  raw1 <- model(run_number = 0L, param = parameters())
  raw2 <- model(run_number = 1L, param = parameters())
  expect_failure(
    expect_identical(get_run_results(raw1), get_run_results(raw2))
  )

  # Repeat experiment, but with multiple replications
  raw1 <- runner(param = parameters())
  raw2 <- runner(param = parameters())
  expect_identical(get_run_results(raw1), get_run_results(raw2))
})
