# Back testing for the Discrete-Event Simulation (DES) Model.
#
# These check that the model code produces results consistent with prior code.

test_that("results from a new run match those previously generated", {
  # Choose a specific set of parameters (ensuring test remains on the same
  # set, regardless of any changes to defaults())
  param <- defaults()
  param["patient_inter"] <- 4.0
  param["mean_n_consult_time"] <- 10.0
  param["number_of_nurses"] <- 5.0
  param["data_collection_period"] <- 80.0
  param["number_of_runs"] <- 10.0
  param["cores"] <- 1.0

  # Run the trial then get the monitored arrivals and resources
  envs <- trial(param = param)
  arrivals <- do.call(rbind, lapply(envs, simmer::get_mon_arrivals))
  resources <- do.call(rbind, lapply(envs, simmer::get_mon_resources))

  # Import the expected results
  exp_arrivals <- read.csv(test_path("testdata", "arrivals.csv"))
  exp_resources <- read.csv(test_path("testdata", "resources.csv"))

  # Remove the na.action attribute before comparing
  attr(arrivals, "na.action") <- NULL
  attr(resources, "na.action") <- NULL

  # Compare results
  expect_equal(arrivals, exp_arrivals)
  expect_equal(resources, exp_resources)
})
