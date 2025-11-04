# Unit testing for the Discrete-Event Simulation (DES) Model.
#
# Unit tests are a type of functional testing that focuses on individual
# components (e.g. functions) and tests them in isolation to ensure they
# work as intended.
#
# In some cases, we check for a specific error message. This is because the
# test could otherwise pass with any error (and not necessarily the specific
# error we are checking for).


# -----------------------------------------------------------------------------
# 1. Parallel processing
# -----------------------------------------------------------------------------

test_that("parallel processing runs successfully", {

  # Mock simulation model function so it can run without other dependencies
  # This will allows us to execute runner, but when it calls model(), instead
  # of attempting to run a simulation, it will just return a list of dataframes
  test_model <- function(run_number, param, set_seed) {
    list(
      arrivals = data.frame(run = run_number, value = rnorm(1L)),
      resources = data.frame(run = run_number, value = rnorm(1L)),
      run_results = data.frame(run = run_number, success = TRUE)
    )
  }
  mockery::stub(runner, "simulation::model", test_model)
  param <- list(cores = 2L, number_of_runs = 5L, seed_offset = 0L)

  # Attempt parallel processing
  result <- tryCatch({
    runner(param, use_future_seeding = TRUE)
  }, error = function(e) {
    # Check if this is a parallel processing error
    if (grepl("Failed to find a functional cluster workers|FutureError",
              e$message)) {
      # Skip test on macOS if parallel processing fails
      if (Sys.info()[["sysname"]] == "Darwin") {
        skip(paste("Parallel processing not available on this macOS system",
                   "- this is expected in CI environments"))
      }
      # Else throw an error
      stop(e, call. = FALSE)
    } else {
      # Re-throw if it's a different error
      stop(e, call. = FALSE)
    }
  })

  # Check if results contain expected structure
  expect_true("arrivals" %in% names(result))
  expect_true("resources" %in% names(result))
  expect_true("run_results" %in% names(result))

  # Ensure results have 5 runs worth of data
  expect_identical(nrow(result$arrivals), 5L)
  expect_identical(nrow(result$resources), 5L)
  expect_identical(nrow(result$run_results), 5L)
})


# -----------------------------------------------------------------------------
# 2. Warm-up
# -----------------------------------------------------------------------------

test_that("warm-up filtering works as expected", {
  mock_result <- list(
    arrivals = data.frame(name = c("p1", "p2", "p3"),
                          start_time = c(5L, 10L, 14L),
                          stringsAsFactors = FALSE),
    resources = data.frame(resource = "nurse",
                           time = c(5L, 14L),
                           stringsAsFactors = FALSE)
  )

  # With no warm-up...
  # > Check that no entries are removed
  no_warm_up <- filter_warmup(mock_result, warm_up_period = 0L)
  expect_identical(no_warm_up, mock_result)

  # With warm-up of 10...
  # > Check that two arrivals remain (10 + 15)
  # > Check that resources starts from time 10
  filtered <- filter_warmup(mock_result, warm_up_period = 10L)
  expect_identical(nrow(filtered[["arrivals"]]), 2L)
  expect_true(all(filtered[["arrivals"]][["start_time"]] >= 10L))
  expect_identical(nrow(filtered[["resources"]]), 2L)
  expect_identical(filtered[["resources"]][["time"]], c(10L, 14L))

  # Emulating run with no data collection period...
  # > Check that no data remains
  full_length <- filter_warmup(mock_result, warm_up_period = 15L)
  expect_identical(nrow(full_length[["arrivals"]]), 0L)
  expect_identical(nrow(full_length[["resources"]]), 0L)

  # If warm-up ends before any resources are used...
  # > Check that no entries are removed from arrivals
  # > Check that no rows are add to resources (as no need for the first row to
  # equal warm_up_period if no active resources).
  short_warm_up <- filter_warmup(mock_result, warm_up_period = 3L)
  expect_identical(as.data.frame(short_warm_up[["arrivals"]]),
                   mock_result[["arrivals"]])
  expect_identical(short_warm_up[["resources"]], mock_result[["resources"]])
})

# -----------------------------------------------------------------------------
# 3. Metrics
# -----------------------------------------------------------------------------

test_that("Mean queue length accounts for final interval", {
  # Create test data with known final interval gap
  test_arrivals <- data.frame(
    resource = "nurse",
    start_time = c(0, 5, 10),
    queue_on_arrival = c(0, 1, 2)
  )

  # Simulation ran until time=15
  simulation_end_time <- 15

  # Manual calculation:
  # Intervals: [0-5), [5-10), [10-15)
  # Queue durations: 5*0 + 5*1 + 5*2 = 0 + 5 + 10 = 15
  # Total time: 15
  # Expected mean: 15/15 = 1.0

  # Function calculation (with fix for final interval)
  result <- calc_mean_queue(test_arrivals,
                            simulation_end_time = simulation_end_time)

  # Test nurse mean queue length
  expect_equal(result$mean_queue_length_nurse, 1.0)
})


test_that("Mean number of patients in service accounts for final interval", {
  # Create test data with known final interval gap
  test_patient_count <- data.frame(
    time = c(0, 5, 10),
    count = c(0, 1, 2)
  )

  # Simulation ran until time=15
  simulation_end_time <- 15

  # Manual calculation:
  # Intervals: [0-5), [5-10), [10-15)
  # Patient time: 5*0 + 5*1 + 5*2 = 0 + 5 + 10 = 15
  # Total time: 15
  # Expected mean: 15/15 = 1.0

  # Function calculation
  result <- calc_mean_patients_in_service(test_patient_count)

  # Test mean patients in service
  expect_equal(result$mean_patients_in_service, 1.0)
})


test_that("Time-weighted utilisation accounts for final interval", {
  # Create test data for resource utilisation
  test_resources <- data.frame(
    resource = "nurse",
    time = c(0, 5, 10),
    server = c(0, 1, 2),
    capacity = c(2, 2, 2)
  )

  # Simulation ran until time=15
  simulation_end_time <- 15

  # Manual calculation:
  # Intervals: [0-5), [5-10), [10-15)
  # Utilisation per interval:
  # utilisation = server / capacity = c(0, 0.5, 1)
  # time-weighted: 5*0 + 5*0.5 + 5*1 = 0 + 2.5 + 5 = 7.5
  # Total time: 15
  # Expected mean: 7.5 / 15 = 0.5

  # Function calculation
  result <- calc_utilisation(test_resources)

  # Test nurse utilisation
  expect_equal(result$utilisation_nurse, 0.5)
})

