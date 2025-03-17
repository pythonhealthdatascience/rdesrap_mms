Choosing replications
================
Amy Heather
2025-03-17

- [Set up](#set-up)
- [Choosing the number of
  replications](#choosing-the-number-of-replications)
- [Automated detection of the number of
  replications](#automated-detection-of-the-number-of-replications)
- [Run time](#run-time)

This notebook documents the choice of the number of replications.

The generated images are saved and then loaded, so that we view the
image as saved (i.e. with the dimensions set in `ggsave()`). This also
avoids the creation of a `_files/` directory when knitting the document
(which would save all previewed images into that folder also, so they
can be rendered and displayed within the output `.md` file, even if we
had not specifically saved them). These are viewed using
`include_graphics()`, which must be the last command in the cell (or
last in the plotting function).

The run time is provided at the end of the notebook.

## Set up

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
library(data.table)
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:data.table':
    ## 
    ##     between, first, last

    ## The following object is masked from 'package:testthat':
    ## 
    ##     matches

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(knitr)
library(simulation)
library(tidyr)
```

    ## 
    ## Attaching package: 'tidyr'

    ## The following object is masked from 'package:testthat':
    ## 
    ##     matches

``` r
options(data.table.summarise.inform = FALSE)
options(dplyr.summarise.inform = FALSE)
# nolint end
```

Start timer.

``` r
start_time <- Sys.time()
```

Define path to outputs folder.

``` r
output_dir <- file.path("..", "outputs")
```

## Choosing the number of replications

The **confidence interval method** can be used to select the number of
replications to run. The more replications you run, the narrower your
confidence interval becomes, leading to a more precise estimate of the
model’s mean performance.

First, you select a desired confidence interval - for example, 95%.
Then, run the model with an increasing number of replications, and
identify the number required to achieve that precision in the estimate
of a given metric - and also, to maintain that precision (as the
intervals may converge or expand again later on).

This method is less useful for values very close to zero - so, for
example, when using utilisation (which ranges from 0 to 1) it is
recommended to multiple values by 100.

When selecting the number of replications you should repeat the analysis
for all performance measures and select the highest value as your number
of replications.

It’s important to check ahead, to check that the 5% precision is
maintained - which is fine in this case - it doesn’t go back up to
future deviation.

``` r
# Run calculations and produce plot
ci_df <- confidence_interval_method(
  replications = 150L,
  desired_precision = 0.05,
  metric = "mean_serve_time_nurse"
)
```

    ## Reached desired precision (0.05) in 86 replications.

``` r
# Preview dataframe
head(ci_df)
```

    ##   replications      data cumulative_mean     stdev lower_ci  upper_ci deviation
    ## 1            1  7.631520        7.631520        NA       NA        NA        NA
    ## 2            2  9.188790        8.410155        NA       NA        NA        NA
    ## 3            3 10.470118        9.096810 1.4215325 5.565527 12.628092 0.3881891
    ## 4            4  9.188619        9.119762 1.1615839 7.271423 10.968101 0.2026741
    ## 5            5  8.890105        9.073830 1.0111905 7.818272 10.329389 0.1383714
    ## 6            6  8.239924        8.934846 0.9663877 7.920684  9.949008 0.1135063
    ##                  metric
    ## 1 mean_serve_time_nurse
    ## 2 mean_serve_time_nurse
    ## 3 mean_serve_time_nurse
    ## 4 mean_serve_time_nurse
    ## 5 mean_serve_time_nurse
    ## 6 mean_serve_time_nurse

``` r
# View first ten rows where percentage deviation is below 5
ci_df %>%
  filter(deviation < 5L) %>%
  head(10L)
```

    ##    replications      data cumulative_mean     stdev lower_ci  upper_ci
    ## 1             3 10.470118        9.096810 1.4215325 5.565527 12.628092
    ## 2             4  9.188619        9.119762 1.1615839 7.271423 10.968101
    ## 3             5  8.890105        9.073830 1.0111905 7.818272 10.329389
    ## 4             6  8.239924        8.934846 0.9663877 7.920684  9.949008
    ## 5             7  5.537885        8.449566 1.5577971 7.008844  9.890288
    ## 6             8  9.689668        8.604579 1.5074109 7.344352  9.864806
    ## 7             9  5.694695        8.281258 1.7114546 6.965718  9.596799
    ## 8            10  7.866917        8.239824 1.6188859 7.081743  9.397905
    ## 9            11 10.411363        8.437237 1.6695514 7.315617  9.558857
    ## 10           12 12.147762        8.746447 1.9186805 7.527376  9.965519
    ##    deviation                metric
    ## 1  0.3881891 mean_serve_time_nurse
    ## 2  0.2026741 mean_serve_time_nurse
    ## 3  0.1383714 mean_serve_time_nurse
    ## 4  0.1135063 mean_serve_time_nurse
    ## 5  0.1705084 mean_serve_time_nurse
    ## 6  0.1464601 mean_serve_time_nurse
    ## 7  0.1588576 mean_serve_time_nurse
    ## 8  0.1405468 mean_serve_time_nurse
    ## 9  0.1329369 mean_serve_time_nurse
    ## 10 0.1393790 mean_serve_time_nurse

``` r
# Create plot
path <- file.path(output_dir, "conf_int_method_serve_time.png")
plot_replication_ci(
  conf_ints = ci_df,
  yaxis_title = "Mean time with nurse",
  file_path = path,
  min_rep = 86L
)
# View plot
include_graphics(path)
```

![](../outputs/conf_int_method_serve_time.png)<!-- -->

It is also important to check across multiple metrics.

``` r
# Run calculations
ci_df <- confidence_interval_method(
  replications = 1000L,
  desired_precision = 0.05,
  metric = "mean_waiting_time_nurse"
)
```

    ## Warning: Running 1000 replications did not reach desired precision (0.05).

``` r
# Preview dataframe
tail(ci_df)
```

    ##      replications      data cumulative_mean     stdev  lower_ci  upper_ci
    ## 995           995 1.4282777       0.2589276 0.6058864 0.2212350 0.2966203
    ## 996           996 0.0000000       0.2586677 0.6056374 0.2210094 0.2963259
    ## 997           997 0.0000000       0.2584082 0.6053888 0.2207844 0.2960320
    ## 998           998 0.1405404       0.2582901 0.6050966 0.2207033 0.2958769
    ## 999           999 0.0000000       0.2580316 0.6048485 0.2204790 0.2955841
    ## 1000         1000 0.0000000       0.2577735 0.6046008 0.2202552 0.2952918
    ##      deviation                  metric
    ## 995  0.1455722 mean_waiting_time_nurse
    ## 996  0.1455853 mean_waiting_time_nurse
    ## 997  0.1455984 mean_waiting_time_nurse
    ## 998  0.1455215 mean_waiting_time_nurse
    ## 999  0.1455346 mean_waiting_time_nurse
    ## 1000 0.1455476 mean_waiting_time_nurse

``` r
# Create plot
path <- file.path(output_dir, "conf_int_method_wait_time.png")
plot_replication_ci(
  conf_ints = ci_df,
  yaxis_title = "Mean wait time for the nurse",
  file_path = path
)
# View plot
include_graphics(path)
```

![](../outputs/conf_int_method_wait_time.png)<!-- -->

``` r
# Run calculations
ci_df <- confidence_interval_method(
  replications = 200L,
  desired_precision = 0.05,
  metric = "utilisation_nurse"
)
```

    ## Reached desired precision (0.05) in 151 replications.

``` r
# Preview dataframe
head(ci_df)
```

    ##   replications      data cumulative_mean     stdev   lower_ci  upper_ci
    ## 1            1 0.3217813       0.3217813        NA         NA        NA
    ## 2            2 0.4523824       0.3870818        NA         NA        NA
    ## 3            3 0.6514928       0.4752188 0.1660378 0.06275804 0.8876796
    ## 4            4 0.3515349       0.4442978 0.1490083 0.20719243 0.6814033
    ## 5            5 0.5970808       0.4748544 0.1460176 0.29354969 0.6561592
    ## 6            6 0.3610194       0.4558819 0.1386241 0.31040487 0.6013590
    ##   deviation            metric
    ## 1        NA utilisation_nurse
    ## 2        NA utilisation_nurse
    ## 3 0.8679387 utilisation_nurse
    ## 4 0.5336632 utilisation_nurse
    ## 5 0.3818112 utilisation_nurse
    ## 6 0.3191113 utilisation_nurse

``` r
# View first ten rows where percentage deviation is below 5
ci_df %>%
  filter(deviation < 5L) %>%
  head(10L)
```

    ##    replications      data cumulative_mean     stdev   lower_ci  upper_ci
    ## 1             3 0.6514928       0.4752188 0.1660378 0.06275804 0.8876796
    ## 2             4 0.3515349       0.4442978 0.1490083 0.20719243 0.6814033
    ## 3             5 0.5970808       0.4748544 0.1460176 0.29354969 0.6561592
    ## 4             6 0.3610194       0.4558819 0.1386241 0.31040487 0.6013590
    ## 5             7 0.3213952       0.4366695 0.1363733 0.31054527 0.5627938
    ## 6             8 0.4477631       0.4380562 0.1263180 0.33245170 0.5436608
    ## 7             9 0.2719785       0.4196031 0.1304851 0.31930340 0.5199029
    ## 8            10 0.4053346       0.4181763 0.1231053 0.33011209 0.5062405
    ## 9            11 0.5388238       0.4291442 0.1223220 0.34696721 0.5113213
    ## 10           12 0.7091560       0.4524786 0.1419025 0.36231803 0.5426391
    ##    deviation            metric
    ## 1  0.8679387 utilisation_nurse
    ## 2  0.5336632 utilisation_nurse
    ## 3  0.3818112 utilisation_nurse
    ## 4  0.3191113 utilisation_nurse
    ## 5  0.2888323 utilisation_nurse
    ## 6  0.2410753 utilisation_nurse
    ## 7  0.2390348 utilisation_nurse
    ## 8  0.2105911 utilisation_nurse
    ## 9  0.1914905 utilisation_nurse
    ## 10 0.1992592 utilisation_nurse

``` r
# Create plot
path <- file.path(output_dir, "conf_int_method_utilisation.png")
plot_replication_ci(
  conf_ints = ci_df,
  yaxis_title = "Mean nurse utilisation",
  file_path = path,
  min_rep = 151L
)
# View plot
include_graphics(path)
```

![](../outputs/conf_int_method_utilisation.png)<!-- -->

## Automated detection of the number of replications

Run the algorithm (which will run model with increasing reps) for a few
different metrics.

``` r
# Set up and run algorithm
alg <- ReplicationsAlgorithm$new(param = parameters())
alg$select()
```

    ## Warning: The replications did not reach the desired precision for the following
    ## metrics - mean_waiting_time_nurse

``` r
# View results
alg$nreps
```

    ## $mean_waiting_time_nurse
    ## [1] NA
    ## 
    ## $mean_serve_time_nurse
    ## [1] 84
    ## 
    ## $utilisation_nurse
    ## [1] 128

``` r
head(alg$summary_table)
```

    ##   replications       data cumulative_mean      stdev    lower_ci   upper_ci
    ## 1            1 0.02971107      0.02971107         NA          NA         NA
    ## 2            2 0.10104057      0.06537582         NA          NA         NA
    ## 3            3 0.00000000      0.04358388 0.05192919 -0.08541538 0.17258314
    ## 4            4 0.00000000      0.03268791 0.04767231 -0.04316937 0.10854519
    ## 5            5 0.00000000      0.02615033 0.04379711 -0.02823096 0.08053162
    ## 6            6 0.00000000      0.02179194 0.04060200 -0.02081725 0.06440113
    ##   deviation                  metric
    ## 1        NA mean_waiting_time_nurse
    ## 2        NA mean_waiting_time_nurse
    ## 3  2.959793 mean_waiting_time_nurse
    ## 4  2.320653 mean_waiting_time_nurse
    ## 5  2.079564 mean_waiting_time_nurse
    ## 6  1.955273 mean_waiting_time_nurse

Visualise results for each metric…

``` r
path <- file.path(output_dir, "reps_algorithm_wait_time.png")
plot_replication_ci(
  conf_ints = filter(alg$summary_table, metric == "mean_waiting_time_nurse"),
  yaxis_title = "Mean wait time for nurse",
  file_path = path
)
include_graphics(path)
```

![](../outputs/reps_algorithm_wait_time.png)<!-- -->

``` r
path <- file.path(output_dir, "reps_algorithm_serve_time.png")
plot_replication_ci(
  conf_ints = filter(alg$summary_table, metric == "mean_serve_time_nurse"),
  yaxis_title = "Mean time with nurse",
  file_path = path,
  min_rep = alg$nreps[["mean_serve_time_nurse"]])
include_graphics(path)
```

![](../outputs/reps_algorithm_serve_time.png)<!-- -->

``` r
path <- file.path(output_dir, "reps_algorithm_utilisation.png")
plot_replication_ci(
  conf_ints = filter(alg$summary_table, metric == "utilisation_nurse"),
  yaxis_title = "Mean nurse utilisation",
  file_path = path,
  min_rep = alg$nreps[["utilisation_nurse"]]
)
include_graphics(path)
```

![](../outputs/reps_algorithm_utilisation.png)<!-- -->

## Run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
cat(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## Notebook run time: 1m 36s
