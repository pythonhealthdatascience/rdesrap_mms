Generate expected results
================
Amy Heather
2025-03-10

- [Set-up](#set-up)
- [Base case](#base-case)
- [Model with a warm-up period](#model-with-a-warm-up-period)
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

Install the latest version of the local simulation package. If running
sequentially, `devtools::load_all()` is sufficient. If running in
parallel, you must use `devtools::install()`.

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
  warm_up_period = 0L,
  data_collection_period = 80L,
  number_of_runs = 10L,
  cores = 1L
)

# Run the replications
results <- runner(param)[["run_results"]]

results
```

    ## # A tibble: 10 × 7
    ##    replication arrivals mean_waiting_time_nurse mean_serve_time_nurse
    ##          <int>    <int>                   <dbl>                 <dbl>
    ##  1           1       17                  0.0361                  6.49
    ##  2           2       19                  0.107                   9.05
    ##  3           3       28                  0                       9.55
    ##  4           4       15                  0                       9.41
    ##  5           5       25                  0.323                   8.89
    ##  6           6       17                  0                       7.55
    ##  7           7       23                  0                       4.19
    ##  8           8       20                  0.0147                  9.58
    ##  9           9       18                  0                       4.77
    ## 10          10       18                  0                       8.03
    ## # ℹ 3 more variables: utilisation_nurse <dbl>, count_unseen_nurse <int>,
    ## #   mean_waiting_time_unseen_nurse <dbl>

``` r
# Save to csv
write.csv(results, file.path(testdata_dir, "base_results.csv"),
          row.names = FALSE)
```

## Model with a warm-up period

``` r
# Define model parameters
param <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  warm_up_period = 40L,
  data_collection_period = 80L,
  number_of_runs = 10L,
  cores = 1L
)

# Run the replications
results <- runner(param)[["run_results"]]

# Preview
head(results)
```

    ## # A tibble: 6 × 7
    ##   replication arrivals mean_waiting_time_nurse mean_serve_time_nurse
    ##         <int>    <int>                   <dbl>                 <dbl>
    ## 1           1       19                  0.0361                  6.85
    ## 2           2       15                  0.175                  10.6 
    ## 3           3       26                  0.103                   7.68
    ## 4           4       16                  0.0891                  9.36
    ## 5           5       20                  0.0842                  6.30
    ## 6           6       19                  0                       6.23
    ## # ℹ 3 more variables: utilisation_nurse <dbl>, count_unseen_nurse <int>,
    ## #   mean_waiting_time_unseen_nurse <dbl>

``` r
# Save to csv
write.csv(results, file.path(testdata_dir, "warm_up_results.csv"),
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
  number_of_runs = 3L,
  cores = 1L
)

# Run scenario analysis
scenarios <- list(
  patient_inter = c(3L, 4L),
  number_of_nurses = c(6L, 7L)
)
scenario_results <- run_scenarios(scenarios, base_list = param)
```

    ## There are 4 scenarios. Running:

    ## Scenario: patient_inter = 3, number_of_nurses = 6

    ## Scenario: patient_inter = 4, number_of_nurses = 6

    ## Scenario: patient_inter = 3, number_of_nurses = 7

    ## Scenario: patient_inter = 4, number_of_nurses = 7

``` r
# Preview
head(scenario_results)
```

    ## # A tibble: 6 × 10
    ##   replication arrivals mean_waiting_time_nurse mean_serve_time_nurse
    ##         <int>    <int>                   <dbl>                 <dbl>
    ## 1           1       27                  0.0821                  8.38
    ## 2           2       29                  0.558                  10.5 
    ## 3           3       39                  0.0135                  9.62
    ## 4           1       17                  0                       6.83
    ## 5           2       21                  0.218                  11.2 
    ## 6           3       28                  0                       9.55
    ## # ℹ 6 more variables: utilisation_nurse <dbl>, count_unseen_nurse <int>,
    ## #   mean_waiting_time_unseen_nurse <dbl>, scenario <int>, patient_inter <int>,
    ## #   number_of_nurses <int>

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

    ## Notebook run time: 0m 2s
