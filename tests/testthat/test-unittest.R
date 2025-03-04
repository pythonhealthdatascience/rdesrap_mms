# Unit testing for the Discrete-Event Simulation (DES) Model.
#
# Unit tests are a type of functional testing that focuses on individual
# components (e.g. functions) and tests them in isolation to ensure they
# work as intended.

library(patrick)

with_parameters_test_that(
  "the model produces an error for invalid inputs",
  {
    # Create parameter list, with the modified input
    param = do.call(parameters, setNames(list(param_value), param_name))

    # Construct expected error message
    expected_message <- if (rule == "p") {
      sprintf('The parameter "%s" must be greater than 0.', param_name)
    } else {
      sprintf(
        'The parameter "%s" must be an integer greater than or equal to 0.',
        param_name)
    }

    # Verify that attempting to run the model raises the correct error message
    expect_error(model(param, run_number=0), expected_message)
  },
  cases(
    # Parameters which should be positive (p)
    list(param_name = "patient_inter", param_value = 0, rule="p"),
    list(param_name = "mean_n_consult_time", param_value = 0, rule="p"),
    list(param_name = "number_of_runs", param_value = 0, rule="p"),
    # Parameters which should be non-negative integers (n)
    list(param_name = "number_of_nurses", param_value = -1, rule="n"),
    list(param_name = "data_collection_period", param_value = -1, rule = "n")
  )
)

#test_that("the model produces an error if a new parameter name is used", {
#
#})

#test_that("the model produces an error if parameters are missing", {
#
#})
