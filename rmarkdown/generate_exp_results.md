Generate expected results
================
Amy Heather
2025-03-06

- [Set-up](#set-up)
- [Base case](#base-case)
- [Scenario analysis](#scenario-analysis)
- [Calculate run time](#calculate-run-time)

This notebook is used to run a specific version of the model and save
each results dataframe as a csv. These are used in `test-backtest.R` to
verify that the model produces consistent results.

The `.Rmd` file is provided as it is possible that results may change
due to alterations to the model structure and operations. Once it has
been confirmed that changes are intentional and not any introduced
errors, this script can be run to regenerate the `.csv` files used in
the test.

The run time is provided at the end of this notebook.

## Set-up

Install the latest version of the local simulation package.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Load required packages.

``` r
# nolint start: undesirable_function_linter.
library(simulation)
# nolint end
```

Start timer.

``` r
start_time <- Sys.time()
```

Define path to expected results.

``` r
testdata_dir <- file.path("..", "tests", "testthat", "testdata")
```

## Base case

``` r
# Define model parameters
param <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  data_collection_period = 80L,
  number_of_runs = 10L,
  cores = 1L
)

# Run the replications
results <- runner(param)[["run_results"]]

# Preview
head(results)
```

    ## # A tibble: 6 × 5
    ##   replication arrivals mean_waiting_time_nurse mean_activity_time_nurse
    ##         <int>    <int>                   <dbl>                    <dbl>
    ## 1           1       21                  0.173                     10.7 
    ## 2           2       16                  0                          7.10
    ## 3           3       13                  0                          6.89
    ## 4           4       16                  0.0177                     9.29
    ## 5           5       17                  0                          4.79
    ## 6           6       18                  0.393                      8.12
    ## # ℹ 1 more variable: utilisation_nurse <dbl>

``` r
# Save to csv
write.csv(results, file.path(testdata_dir, "base_results.csv"),
          row.names = FALSE)
```

## Scenario analysis

``` r
# Define model parameters
param <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  data_collection_period = 80L,
  number_of_runs = 10L,
  cores = 1L
)

# Run scenario analysis
scenarios <- list(
  patient_inter = c(3L, 4L, 5L),
  number_of_nurses = c(6L, 7L)
)
scenario_results <- run_scenarios(scenarios, base_list = parameters())
```

    ## There are 6 scenarios. Running:

    ## Scenario: patient_inter = 3, number_of_nurses = 6

    ## Scenario: patient_inter = 4, number_of_nurses = 6

    ## Scenario: patient_inter = 5, number_of_nurses = 6

    ## Scenario: patient_inter = 3, number_of_nurses = 7

    ## Scenario: patient_inter = 4, number_of_nurses = 7

    ## Scenario: patient_inter = 5, number_of_nurses = 7

``` r
# Preview
head(scenario_results)
```

    ## # A tibble: 6 × 8
    ##   replication arrivals mean_waiting_time_nurse mean_activity_time_nurse
    ##         <int>    <int>                   <dbl>                    <dbl>
    ## 1           1       27                0.0865                       9.31
    ## 2           2       19                0                            7.83
    ## 3           3       22                0                            6.74
    ## 4           4       21                0                            7.97
    ## 5           5       25                0.000130                     5.35
    ## 6           6       29                0.822                        8.88
    ## # ℹ 4 more variables: utilisation_nurse <dbl>, scenario <int>,
    ## #   patient_inter <int>, number_of_nurses <int>

``` r
# Save to csv
write.csv(scenario_results, file.path(testdata_dir, "scenario_results.csv"),
          row.names = FALSE)
```

## Calculate run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
cat(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## Notebook run time: 0m 13s
