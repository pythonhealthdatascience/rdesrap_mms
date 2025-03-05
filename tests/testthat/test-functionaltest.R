# Functional testing for the Discrete-Event Simulation (DES) Model.
#
# These verify that the system or components perform their intended
# functionality.


test_that("values are non-negative", {
  # Run model with standard parameters
  param = parameters()
  raw_results <- model(run_number = 0L, param)
  results <- get_run_results(raw_results, param)

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
    results <- get_run_results(raw_results, param)

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
    init_result <- get_run_results(runner(init_param), init_param)

    # Run model with adjusted value
    adj_param <- default_param
    adj_param[[param_name]] <- adj_value
    adj_result <- get_run_results(runner(adj_param), adj_param)

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
    init_result <- get_run_results(
      model(run_number = 1L, init_param), init_param)

    # Run model with adjusted value
    adj_param <- default_param
    adj_param[[param_name]] <- adj_value
    adj_result <- get_run_results(
      model(run_number = 1L, adj_param), adj_param)

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
  param = parameters()
  raw1 <- model(run_number = 0L, param = param)
  raw2 <- model(run_number = 0L, param = param)
  expect_identical(get_run_results(raw1, param), get_run_results(raw2, param))

  # Conversely, if run with different run number, expect different
  raw1 <- model(run_number = 0L, param = param)
  raw2 <- model(run_number = 1L, param = param)
  expect_failure(
    expect_identical(get_run_results(raw1, param), get_run_results(raw2, param))
  )

  # Repeat experiment, but with multiple replications
  raw1 <- runner(param = param)
  raw2 <- runner(param = param)
  expect_identical(get_run_results(raw1, param), get_run_results(raw2, param))
})


test_that("columns that are expected to be complete have no NA", {
  # Run model with low resources and definite arrivals
  param = parameters(
    number_of_nurses = 1L,
    data_collection_period = 300L,
    patient_inter = 1L)
  raw_results <- runner(param)

  # Helper function to check for NA in data
  check_no_na <- function(data) {
    expect_true(all(colSums(is.na(data)) == 0))
  }

  # Check raw and processed results, excluding columns where expect NA
  check_no_na(raw_results[["arrivals"]][, !names(
    raw_results[["arrivals"]]) %in% c(
      "end_time", "activity_time", "q_time_unseen")])
  check_no_na(raw_results[["resources"]])
  check_no_na(get_run_results(raw_results, param))
})


test_that("all patients are seen when there are plenty nurses", {
  # Run model with extremely large number of nurses
  param <- parameters(
    patient_inter = 4L,
    mean_n_consult_time = 10L,
    number_of_nurses = 10000000,
    data_collection_period = 100L,
    number_of_runs = 1
  )
  result <- get_run_results(runner(param), param)

  # Check that no patients wait
  expect_equal(result[["mean_waiting_time_nurse"]], 0)
})


test_that("the model can cope with having no arrivals", {
  # Run with extremely high inter-arrival time and short length
  param <- parameters(patient_inter = 99999999L, data_collection_period = 10L)
  raw_result <- model(run_number = 1, param = param)
  result <- get_run_results(raw_result, param)

  # Check that the raw result are two empty dataframes
  expect_equal(nrow(raw_result[["arrivals"]]), 0)
  expect_equal(nrow(raw_result[["resources"]]), 0)

  # Check that the processed result is NULL
  expect_equal(result, NULL)
})


test_that("the model can cope with some replications having no arrivals", {
  # Run model with conditions that will ensure some replications see an arrival,
  # and some do not
  param <- parameters(
    patient_inter = 200L,
    data_collection_period = 100L,
    number_of_runs = 5
  )

  # Run for replications and process results
  run_result <- get_run_results(runner(param), param)

  # Check there are rows for each replication
  expect_equal(nrow(run_result), param[["number_of_runs"]])

  # Check that arrivals is either 0 or 1 (with at least one of each)
  expect_true(all(run_result[["arrivals"]] %in% c(0,1)))
  expect_true(any(run_result[["arrivals"]] == 0))
  expect_true(any(run_result[["arrivals"]] == 1))
})
