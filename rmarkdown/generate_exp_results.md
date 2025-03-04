Generate expected results
================
Amy Heather
2025-03-04

- [Set-up](#set-up)
- [Run model and save results](#run-model-and-save-results)
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

## Run model and save results

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
raw_results <- runner(param)
```

``` r
# Process results
results <- get_run_results(raw_results)

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
write.csv(results, file.path(testdata_dir, "results.csv"), row.names = FALSE)
```

## Calculate run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
print(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## [1] "Notebook run time: 0m 0s"
