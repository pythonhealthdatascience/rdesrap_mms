#' Run a set of scenarios
#'
#' @param scenarios List where key is name of parameter and value is a list of
#' different values to run in scenarios
#' @param base_list List of parameters to use as base for scenarios, which can
#' be partial (as will input to parameters() function).
#'
#' @return Tibble with results from each replication for each scenario.
#' @export

run_scenarios <- function(scenarios, base_list) {
  # Generate all permutations of the scenarios
  all_scenarios <- expand.grid(scenarios)

  # Preview the number of scenarios
  print(sprintf("There are %d scenarios. Running:", nrow(all_scenarios)))

  results <- list()

  # Iterate through each scenario
  for (index in seq_len(nrow(all_scenarios))) {

    # Filter to one of the scenarios
    scenario_to_run <- all_scenarios[index, , drop = FALSE]

    # Print the scenario parameters
    formatted_scenario <- toString(
      paste0(names(scenario_to_run), " = ", scenario_to_run)
    )
    print(paste0("Scenario: ", formatted_scenario))

    # Create parameter list with scenario-specific values
    args <- c(scenario_to_run, list(scenario_name = index))

    # Create instance of parameter class with specified base parameters
    param <- do.call(parameters, base_list)

    # Update parameter list with the scenario parameters
    for (name in names(args)) {
      param[[name]] <- args[[name]]
    }

    # Run replications for the current scenario and process results
    raw_results <- runner(param)
    scenario_result <- process_replications(raw_results)

    # Append scenario parameters to the results
    scenario_result[["scenario"]] <- index
    for (key in names(scenario_to_run)) {
      scenario_result[[key]] <- scenario_to_run[[key]]
    }

    # Append to results list
    results[[index]] <- scenario_result
  }
  return(do.call(rbind, results))
}
