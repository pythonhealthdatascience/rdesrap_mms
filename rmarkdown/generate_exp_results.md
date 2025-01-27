Generate expected results
================
Amy Heather
2025-01-27

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
devtools::install()
```

    ## 
    ## ── R CMD build ─────────────────────────────────────────────────────────────────
    ##      checking for file ‘/home/amy/Documents/stars/rap_template_r_des/DESCRIPTION’ ...  ✔  checking for file ‘/home/amy/Documents/stars/rap_template_r_des/DESCRIPTION’
    ##   ─  preparing ‘simulation’:
    ##    checking DESCRIPTION meta-information ...  ✔  checking DESCRIPTION meta-information
    ##   ─  checking for LF line-endings in source and make files and shell scripts
    ## ─  checking for empty or unneeded directories
    ##      Omitted ‘LazyData’ from DESCRIPTION
    ##   ─  building ‘simulation_0.1.0.tar.gz’
    ##      
    ## Running /opt/R/4.4.1/lib/R/bin/R CMD INSTALL \
    ##   /tmp/RtmpfNXwLp/simulation_0.1.0.tar.gz --install-tests 
    ## * installing to library ‘/home/amy/.cache/R/renv/library/rap_template_r_des-cd7d6844/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu’
    ## * installing *source* package ‘simulation’ ...
    ## ** using staged installation
    ## ** R
    ## ** tests
    ## ** byte-compile and prepare package for lazy loading
    ## ** help
    ## *** installing help indices
    ## ** building package indices
    ## ** testing if installed package can be loaded from temporary location
    ## ** testing if installed package can be loaded from final location
    ## ** testing if installed package keeps a record of temporary installation path
    ## * DONE (simulation)

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
param_class <- defaults()
param_class[["update"]](list())
param_class[["update"]](list(patient_inter = 4L,
                             mean_n_consult_time = 10L,
                             number_of_nurses = 5L,
                             data_collection_period = 80L,
                             number_of_runs = 10L,
                             cores = 1L))

# Run the trial
raw_results <- trial(param_class)
```

``` r
# Process results
results <- process_replications(raw_results)

# Preview
head(results)
```

    ## # A tibble: 6 × 5
    ##   replication arrivals mean_waiting_time_nurse mean_activity_time_nurse
    ##         <int>    <int>                   <dbl>                    <dbl>
    ## 1           1       15                  0                          8.92
    ## 2           2       16                  0                          7.73
    ## 3           3       14                  0                          7.56
    ## 4           4       19                  1.54                       8.06
    ## 5           5       21                  0.0520                     9.35
    ## 6           6       29                  0.384                      8.21
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
