# Validates a discrete event simulation of a healthcare M/M/S queue by
# comparing simulation results to analytical queueing theory.
#
# Metrics (using standard queueing theory notation):
# - ρ (rho): utilisation
# - Lq: mean queue length
# - W: mean time in system
# - Wq: mean waiting
#
# Results must match theory with a 15% tolerance (accomodates stochasticity).
# Tests are run across diverse parameter combinations and utilisation levels.
# System stability requires arrival rate < number_of_servers * service_rate.


#' Run simulation and return key performance indicators using standard queueing
#' theory notation.
#'
#' The warm-up period should be sufficiently long to allow the system to reach
#' steady-state before data collection begins.

run_simulation_model <- function(
    patient_inter, mean_n_consult_time, number_of_nurses
) {
  # Run simulation
  param <- parameters(
    patient_inter = patient_inter,
    mean_n_consult_time = mean_n_consult_time,
    number_of_nurses = number_of_nurses,
    warm_up_period = 500L,
    data_collection_period = 1500L,
    number_of_runs = 100L,
    scenario_name = 0L,
    cores = 1L
  )
  run_results <- runner(param)[["run_results"]]

  # Get overall results, using queueing theory notation in column names
  results <- run_results |>
    summarise(
      RO = mean(utilisation_nurse),
      Lq = mean(mean_queue_length_nurse),
      # W = mean(mean_time_in_system),
      Wq = mean(mean_waiting_time_nurse)
    )
  return(results)
}


patrick::with_parameters_test_that(
  "simulation is consistent with theoretical M/M/s queue calculations.",
  {
    # Create theoretical M/M/s queue model
    lambda <- 1 / patient_inter
    mu <- 1 / mean_n_consult_time
    i_mmc <- queueing::NewInput.MMC(
      lambda=lambda, mu=mu, c=number_of_nurses, n=0, method=0
    )
    theory <- queueing::QueueingModel(i_mmc)

    # Run simulation
    sim <- run_simulation_model(
      patient_inter = patient_inter,
      mean_n_consult_time = mean_n_consult_time,
      number_of_nurses = number_of_nurses
    )

    # Compare results with appropriate tolerance (round to 3dp + 15% tolerance)
    metrics <- list(
      c("RO", "Utilisation"),
      c("Lq", "Queue length"),
      # c("W", "System time"),
      c("Wq", "Wait time")
    )
    for (metric in metrics) {
      key <- metric[1]
      label <- metric[2]

      sim_val <- round(sim[[key]], 3)
      theory_val <- round(theory[[key]], 3)

      expect_equal(
        sim_val,
        theory_val,
        tolerance = 0.15,  # 15% relative tolerance
        info = sprintf(
          "%s mismatch: sim=%.3f, theory=%.3f", label, sim_val, theory_val
        )
      )
    }
  },
  patrick::cases(
    # Test case 1: Low utilisation (ρ ≈ 0.3)
    list(patient_inter = 10, mean_n_consult_time = 3, number_of_nurses = 2),
    # Test case 2: Medium utilisation (ρ ≈ 0.67)
    list(patient_inter = 6, mean_n_consult_time = 4, number_of_nurses = 2),
    # Test case 3: M/M/1 (ρ = 0.75)
    list(patient_inter = 4, mean_n_consult_time = 3, number_of_nurses = 1),
    # Test case 4: Multiple servers, high utilisation (ρ ≈ 0.91)
    list(patient_inter = 5.5, mean_n_consult_time = 5, number_of_nurses = 3),
    # Test case 5: Balanced system (ρ = 0.5)
    list(patient_inter = 8, mean_n_consult_time = 4, number_of_nurses = 1),
    # Test case 6: Many servers, low individual utilisation (ρ ≈ 0.63)
    list(patient_inter = 4, mean_n_consult_time = 10, number_of_nurses = 4),
    # Test case 7: Very low utilisation (ρ ≈ 0.167)
    list(patient_inter = 60, mean_n_consult_time = 10, number_of_nurses = 15)
  )
)
