Analysis
================
Amy Heather
2025-03-11

- [Set up](#set-up)
- [Default run](#default-run)
- [View spread of results across
  replication](#view-spread-of-results-across-replication)
- [Scenario analysis](#scenario-analysis)
  - [Running a basic example (which can compare to Python
    template)](#running-a-basic-example-which-can-compare-to-python-template)
- [Sensitivity analysis](#sensitivity-analysis)
- [NaN results](#nan-results)
- [Calculate run time](#calculate-run-time)

This notebook presents execution and results from:

- Base case analysis
- Scenario analysis
- Sensitivity analysis

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

Import required packages.

``` r
# nolint start: undesirable_function_linter.
library(dplyr, warn.conflicts = FALSE)
library(ggplot2)
library(knitr)
library(simmer, warn.conflicts = FALSE)
library(simulation)
library(tidyr, warn.conflicts = FALSE)
library(xtable)

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

## Default run

Run with default parameters and save to `.csv`.

``` r
run_results <- runner(param = parameters())[["run_results"]]
head(run_results)
```

    ## # A tibble: 6 × 7
    ##   replication arrivals mean_waiting_time_nurse mean_serve_time_nurse
    ##         <int>    <int>                   <dbl>                 <dbl>
    ## 1           1       17                  0.0361                  6.49
    ## 2           2       19                  0.107                   9.05
    ## 3           3       28                  0                       9.55
    ## 4           4       15                  0                       9.41
    ## 5           5       25                  0.323                   8.89
    ## 6           6       17                  0                       7.55
    ## # ℹ 3 more variables: utilisation_nurse <dbl>, count_unseen_nurse <int>,
    ## #   mean_waiting_time_unseen_nurse <dbl>

``` r
write.csv(run_results, file.path(output_dir, "base_run_results.csv"))
```

## View spread of results across replication

``` r
#' Plot spread of results from across replications, for chosen column.
#'
#' Generate figure, show it, and then save under specified file name.
#'
#' @param run_results The dataframe from the model results `run_results`.
#' @param column Name of column to plot.
#' @param x_label X axis label.
#' @param file Filename to save figure to.

plot_results_spread <- function(run_results, column, x_label, file) {

  # Generate plot
  p <- ggplot(run_results, aes(.data[[column]])) +
    geom_histogram(bins = 10L) +
    labs(x = x_label, y = "Frequency") +
    theme_minimal()

  # Save plot
  full_path <- file.path(output_dir, file)
  ggsave(filename = full_path, plot = p,
         width = 6.5, height = 4L, bg = "white")

  # View the plot
  include_graphics(full_path)
}
```

``` r
plot_results_spread(run_results = run_results,
                    column = "arrivals",
                    x_label = "Arrivals",
                    file = "spread_arrivals.png")
```

![](../outputs/spread_arrivals.png)<!-- -->

``` r
plot_results_spread(run_results = run_results,
                    column = "mean_waiting_time_nurse",
                    x_label = "Mean wait time for nurse",
                    file = "spread_nurse_wait.png")
```

![](../outputs/spread_nurse_wait.png)<!-- -->

``` r
plot_results_spread(run_results = run_results,
                    column = "mean_serve_time_nurse",
                    x_label = "Mean length of nurse consultation",
                    file = "spread_nurse_time.png")
```

![](../outputs/spread_nurse_time.png)<!-- -->

``` r
plot_results_spread(run_results = run_results,
                    column = "utilisation_nurse",
                    x_label = "Mean nurse utilisation",
                    file = "spread_nurse_util.png")
```

![](../outputs/spread_nurse_util.png)<!-- -->

## Scenario analysis

``` r
# Run scenario analysis
scenarios <- list(
  patient_inter = c(3L, 4L, 5L, 6L, 7L),
  number_of_nurses = c(5L, 6L, 7L, 8L)
)

scenario_results <- run_scenarios(scenarios, base_list = parameters())
```

    ## There are 20 scenarios. Running:

    ## Scenario: patient_inter = 3, number_of_nurses = 5

    ## Scenario: patient_inter = 4, number_of_nurses = 5

    ## Scenario: patient_inter = 5, number_of_nurses = 5

    ## Scenario: patient_inter = 6, number_of_nurses = 5

    ## Scenario: patient_inter = 7, number_of_nurses = 5

    ## Scenario: patient_inter = 3, number_of_nurses = 6

    ## Scenario: patient_inter = 4, number_of_nurses = 6

    ## Scenario: patient_inter = 5, number_of_nurses = 6

    ## Scenario: patient_inter = 6, number_of_nurses = 6

    ## Scenario: patient_inter = 7, number_of_nurses = 6

    ## Scenario: patient_inter = 3, number_of_nurses = 7

    ## Scenario: patient_inter = 4, number_of_nurses = 7

    ## Scenario: patient_inter = 5, number_of_nurses = 7

    ## Scenario: patient_inter = 6, number_of_nurses = 7

    ## Scenario: patient_inter = 7, number_of_nurses = 7

    ## Scenario: patient_inter = 3, number_of_nurses = 8

    ## Scenario: patient_inter = 4, number_of_nurses = 8

    ## Scenario: patient_inter = 5, number_of_nurses = 8

    ## Scenario: patient_inter = 6, number_of_nurses = 8

    ## Scenario: patient_inter = 7, number_of_nurses = 8

``` r
# Preview scenario results dataframe
print(dim(scenario_results))
```

    ## [1] 2000   10

``` r
head(scenario_results)
```

    ## # A tibble: 6 × 10
    ##   replication arrivals mean_waiting_time_nurse mean_serve_time_nurse
    ##         <int>    <int>                   <dbl>                 <dbl>
    ## 1           1       25                  0.164                   7.42
    ## 2           2       22                  0.183                   9.19
    ## 3           3       31                  0.103                   8.54
    ## 4           4       25                  0.154                  10.7 
    ## 5           5       27                  0.0817                  6.77
    ## 6           6       24                  0                       7.35
    ## # ℹ 6 more variables: utilisation_nurse <dbl>, count_unseen_nurse <int>,
    ## #   mean_waiting_time_unseen_nurse <dbl>, scenario <int>, patient_inter <int>,
    ## #   number_of_nurses <int>

Example plot

``` r
#' Plot results from different model scenarios.
#'
#' @param results Dataframe with results from each replication of scenarios.
#' @param x_var Name of variable to plot on X axis.
#' @param result_var Name of variable with results, to plot on Y axis.
#' @param colour_var Name of variable to colour lines with (or set to NULL).
#' @param xaxis_title Title for X axis.
#' @param yaxis_title Title for Y axis.
#' @param legend_title Title for figure legend.
#' @param path Path inc. filename to save figure to.
#'
#' @return Dataframe with the average results calculated.

plot_scenario <- function(results, x_var, result_var, colour_var, xaxis_title,
                          yaxis_title, legend_title, path) {
  # If x_var and colour_var are provided, combine both in a list to use
  # as grouping variables when calculating average results
  if (!is.null(colour_var)) {
    group_vars <- c(x_var, colour_var)
  } else {
    group_vars <- c(x_var)
  }

  # Calculate average results from each scenario
  avg_results <- results %>%
    group_by_at(group_vars) %>%
    summarise(mean = mean(.data[[result_var]]),
              std_dev = sd(.data[[result_var]]),
              ci_lower = t.test(.data[[result_var]])[["conf.int"]][[1L]],
              ci_upper = t.test(.data[[result_var]])[["conf.int"]][[2L]])

  # Generate plot - with or without colour, depending on whether it was given
  if (!is.null(colour_var)) {
    # Convert colour variable to factor so it is treated like categorical
    avg_results[[colour_var]] <- as.factor(avg_results[[colour_var]])
    # Create plot
    p <- ggplot(avg_results, aes(x = .data[[x_var]], y = mean,
                                 group = .data[[colour_var]])) +
      geom_line(aes(color = .data[[colour_var]])) +
      geom_ribbon(aes(ymin = .data[["ci_lower"]], ymax = .data[["ci_upper"]],
                      fill = .data[[colour_var]]), alpha = 0.1)
  } else {
    # Create plot
    p <- ggplot(avg_results, aes(x = .data[[x_var]], y = mean)) +
      geom_line() +
      geom_ribbon(aes(ymin = .data[["ci_lower"]], ymax = .data[["ci_upper"]]),
                  alpha = 0.1)
  }

  # Modify labels and style
  p <- p +
    labs(x = xaxis_title, y = yaxis_title, color = legend_title,
         fill = legend_title) +
    theme_minimal()

  # Save plot
  ggsave(filename = path, width = 6.5, height = 4L, bg = "white")

  # Return the results dataframe
  return(avg_results) # nolint: object_overwrite_linter
}
```

``` r
# Define path
path <- file.path(output_dir, "scenario_nurse_wait.png")

# Calculate results and generate plot
result <- plot_scenario(
  results = scenario_results,
  x_var = "patient_inter",
  result_var = "mean_waiting_time_nurse",
  colour_var = "number_of_nurses",
  xaxis_title = "Patient inter-arrival time",
  yaxis_title = "Mean wait time for nurse (minutes)",
  legend_title = "Nurses",
  path = path
)

# View plot
include_graphics(path)
```

![](../outputs/scenario_nurse_wait.png)<!-- -->

``` r
# Define path
path <- file.path(output_dir, "scenario_nurse_util.png")

# Calculate results and generate plot
result <- plot_scenario(
  results = scenario_results,
  x_var = "patient_inter",
  result_var = "utilisation_nurse",
  colour_var = "number_of_nurses",
  xaxis_title = "Patient inter-arrival time",
  yaxis_title = "Mean nurse utilisation",
  legend_title = "Nurses",
  path = path
)

# View plot
include_graphics(path)
```

![](../outputs/scenario_nurse_util.png)<!-- -->

Example table.

``` r
# Process table
table <- result %>%
  # Combine mean and CI into single column, and round
  mutate(mean_ci = sprintf("%.2f (%.2f, %.2f)", mean, ci_lower, ci_upper),
         nurses = sprintf("% s nurses", number_of_nurses)) %>%
  dplyr::select(patient_inter, nurses, mean_ci) %>%
  # Convert from long to wide format
  pivot_wider(names_from = nurses, values_from = mean_ci) %>%
  rename(`Patient inter-arrival time` = patient_inter)

# Convert to latex, display and save
table_latex <- xtable(table)
print(table_latex)
```

    ## % latex table generated in R 4.4.1 by xtable 1.8-4 package
    ## % Tue Mar 11 09:43:36 2025
    ## \begin{table}[ht]
    ## \centering
    ## \begin{tabular}{rrllll}
    ##   \hline
    ##  & Patient inter-arrival time & 5 nurses & 6 nurses & 7 nurses & 8 nurses \\ 
    ##   \hline
    ## 1 &   3 & 0.59 (0.56, 0.62) & 0.50 (0.47, 0.53) & 0.43 (0.40, 0.45) & 0.37 (0.35, 0.39) \\ 
    ##   2 &   4 & 0.46 (0.43, 0.49) & 0.38 (0.35, 0.40) & 0.33 (0.31, 0.35) & 0.29 (0.27, 0.30) \\ 
    ##   3 &   5 & 0.38 (0.35, 0.41) & 0.31 (0.29, 0.33) & 0.27 (0.25, 0.29) & 0.23 (0.22, 0.25) \\ 
    ##   4 &   6 & 0.32 (0.29, 0.34) & 0.27 (0.25, 0.29) & 0.23 (0.21, 0.25) & 0.20 (0.18, 0.22) \\ 
    ##   5 &   7 & 0.28 (0.25, 0.30) & 0.23 (0.21, 0.25) & 0.20 (0.18, 0.22) & 0.17 (0.16, 0.19) \\ 
    ##    \hline
    ## \end{tabular}
    ## \end{table}

``` r
print(table_latex,
      comment = FALSE,
      file = file.path(output_dir, "scenario_nurse_util.tex"))
```

### Running a basic example (which can compare to Python template)

To enable comparison between the templates, this section runs the model
with a simple set of base case parameters (matched to Python), and then
running some scenarios on top of that base case.

``` r
# Define the base param for this altered run
new_base <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  # No warm-up (not possible in R, but set to 0 in Python)
  data_collection_period = 1440L,
  number_of_runs = 10L,
  cores = 1L
)

# Define scenarios
scenarios <- list(
  patient_inter = c(3L, 4L, 5L, 6L, 7L),
  number_of_nurses = c(5L, 6L, 7L, 8L)
)

# Run scenarios
compare_template_results <- run_scenarios(scenarios, new_base)
```

    ## There are 20 scenarios. Running:

    ## Scenario: patient_inter = 3, number_of_nurses = 5

    ## Scenario: patient_inter = 4, number_of_nurses = 5

    ## Scenario: patient_inter = 5, number_of_nurses = 5

    ## Scenario: patient_inter = 6, number_of_nurses = 5

    ## Scenario: patient_inter = 7, number_of_nurses = 5

    ## Scenario: patient_inter = 3, number_of_nurses = 6

    ## Scenario: patient_inter = 4, number_of_nurses = 6

    ## Scenario: patient_inter = 5, number_of_nurses = 6

    ## Scenario: patient_inter = 6, number_of_nurses = 6

    ## Scenario: patient_inter = 7, number_of_nurses = 6

    ## Scenario: patient_inter = 3, number_of_nurses = 7

    ## Scenario: patient_inter = 4, number_of_nurses = 7

    ## Scenario: patient_inter = 5, number_of_nurses = 7

    ## Scenario: patient_inter = 6, number_of_nurses = 7

    ## Scenario: patient_inter = 7, number_of_nurses = 7

    ## Scenario: patient_inter = 3, number_of_nurses = 8

    ## Scenario: patient_inter = 4, number_of_nurses = 8

    ## Scenario: patient_inter = 5, number_of_nurses = 8

    ## Scenario: patient_inter = 6, number_of_nurses = 8

    ## Scenario: patient_inter = 7, number_of_nurses = 8

``` r
# Preview scenario results dataframe
print(dim(compare_template_results))
```

    ## [1] 200  10

``` r
head(compare_template_results)
```

    ## # A tibble: 6 × 10
    ##   replication arrivals mean_waiting_time_nurse mean_serve_time_nurse
    ##         <int>    <int>                   <dbl>                 <dbl>
    ## 1           1      464                   2.75                  10.1 
    ## 2           2      457                   1.67                   9.35
    ## 3           3      470                   1.79                   9.86
    ## 4           4      443                   0.580                  9.97
    ## 5           5      485                   2.11                   9.97
    ## 6           6      446                   0.862                  9.77
    ## # ℹ 6 more variables: utilisation_nurse <dbl>, count_unseen_nurse <int>,
    ## #   mean_waiting_time_unseen_nurse <dbl>, scenario <int>, patient_inter <int>,
    ## #   number_of_nurses <int>

``` r
# Define path
path <- file.path(output_dir, "scenario_nurse_wait_compare_templates.png")

# Calculate results and generate plot
result <- plot_scenario(
  results = compare_template_results,
  x_var = "patient_inter",
  result_var = "mean_waiting_time_nurse",
  colour_var = "number_of_nurses",
  xaxis_title = "Patient inter-arrival time",
  yaxis_title = "Mean wait time for nurse (minutes)",
  legend_title = "Nurses",
  path = path
)

# View plot
include_graphics(path)
```

![](../outputs/scenario_nurse_wait_compare_templates.png)<!-- -->

``` r
# Define path
path <- file.path(output_dir, "scenario_nurse_util_compare_templates.png")

# Calculate results and generate plot
result <- plot_scenario(
  results = compare_template_results,
  x_var = "patient_inter",
  result_var = "utilisation_nurse",
  colour_var = "number_of_nurses",
  xaxis_title = "Patient inter-arrival time",
  yaxis_title = "Mean nurse utilisation",
  legend_title = "Nurses",
  path = path
)

# View plot
include_graphics(path)
```

![](../outputs/scenario_nurse_util_compare_templates.png)<!-- -->

## Sensitivity analysis

Can use similar code to perform sensitivity analyses.

**How does sensitivity analysis differ from scenario analysis?**

- Scenario analysis focuses on a set of predefined situations which are
  plausible or relevant to the problem being studied. It can often
  involve varying multiple parameters simulatenously. The purpose is to
  understand how the system operates under different hypothetical
  scenarios.
- Sensitivity analysis varies one (or a small group) of parameters and
  assesses the impact of small changes in that parameter on outcomes.
  The purpose is to understand how uncertainty in the inputs affects the
  model, and how robust results are to variation in those inputs.

``` r
# Run sensitivity analysis
consult <- list(mean_n_consult_time = c(8L, 9L, 10L, 11L, 12L, 13L, 14L, 15L))
sensitivity_consult <- run_scenarios(consult, base_list = parameters())
```

    ## There are 8 scenarios. Running:

    ## Scenario: mean_n_consult_time = 8

    ## Scenario: mean_n_consult_time = 9

    ## Scenario: mean_n_consult_time = 10

    ## Scenario: mean_n_consult_time = 11

    ## Scenario: mean_n_consult_time = 12

    ## Scenario: mean_n_consult_time = 13

    ## Scenario: mean_n_consult_time = 14

    ## Scenario: mean_n_consult_time = 15

``` r
# Preview result
head(sensitivity_consult)
```

    ## # A tibble: 6 × 9
    ##   replication arrivals mean_waiting_time_nurse mean_serve_time_nurse
    ##         <int>    <int>                   <dbl>                 <dbl>
    ## 1           1       17                   0                      6.39
    ## 2           2       19                   0                      8.38
    ## 3           3       28                   0                      7.64
    ## 4           4       15                   0                      7.53
    ## 5           5       26                   0.151                  7.33
    ## 6           6       17                   0                      6.04
    ## # ℹ 5 more variables: utilisation_nurse <dbl>, count_unseen_nurse <int>,
    ## #   mean_waiting_time_unseen_nurse <dbl>, scenario <int>,
    ## #   mean_n_consult_time <int>

``` r
# Define path
path <- file.path(output_dir, "sensitivity_consult_time.png")

# Calculate results and generate plot
sensitivity_result <- plot_scenario(
  results = sensitivity_consult,
  x_var = "mean_n_consult_time",
  result_var = "mean_waiting_time_nurse",
  colour_var = NULL,
  xaxis_title = "Mean nurse consultation time (minutes)",
  yaxis_title = "Mean wait time for nurse (minutes)",
  legend_title = "Nurses",
  path = path
)

# View plot
include_graphics(path)
```

![](../outputs/sensitivity_consult_time.png)<!-- -->

``` r
# Process table
sensitivity_table <- sensitivity_result  %>%
  # Combine mean and CI into single column, and round
  mutate(mean_ci = sprintf("%.2f (%.2f, %.2f)", mean, ci_lower, ci_upper)) %>%
  # Select and rename columns
  dplyr::select(mean_n_consult_time, mean_ci) %>%
  rename(`Mean nurse consultation time` = mean_n_consult_time,
         `Mean wait time for nurse (95 percent confidence interval)` = mean_ci)

# Convert to latex, display and save
sensitivity_table_latex <- xtable(sensitivity_table)
print(sensitivity_table_latex)
```

    ## % latex table generated in R 4.4.1 by xtable 1.8-4 package
    ## % Tue Mar 11 09:44:14 2025
    ## \begin{table}[ht]
    ## \centering
    ## \begin{tabular}{rrl}
    ##   \hline
    ##  & Mean nurse consultation time & Mean wait time for nurse (95 percent confidence interval) \\ 
    ##   \hline
    ## 1 &   8 & 0.07 (0.01, 0.13) \\ 
    ##   2 &   9 & 0.14 (0.07, 0.21) \\ 
    ##   3 &  10 & 0.23 (0.10, 0.36) \\ 
    ##   4 &  11 & 0.28 (0.15, 0.40) \\ 
    ##   5 &  12 & 0.40 (0.18, 0.62) \\ 
    ##   6 &  13 & 0.52 (0.31, 0.74) \\ 
    ##   7 &  14 & 0.84 (0.51, 1.17) \\ 
    ##   8 &  15 & 1.03 (0.66, 1.39) \\ 
    ##    \hline
    ## \end{tabular}
    ## \end{table}

``` r
print(sensitivity_table_latex,
      comment = FALSE,
      file = file.path(output_dir, "sensitivity_consult_time.tex"))
```

## NaN results

If patients are still waiting to be seen at the end of the simulation,
or are still busy with the resource at the end of the simulation, they
will have NaN results for `end_time` and `activity_time` (and so for the
calculated nurse wait and activity times).

These patients are captured in the `wait_time_unseen` column in
`arrivals`, and in the `count_unseen_nurse` and
`mean_waiting_time_unseen_nurse` columns in `run_results`.

These patients will be ignored in calculation of metrics like mean time
with nurse (as they don’t get to see nurse) - but it’s important we
still have measures for those unseen, as lots of patients waiting at the
end of the simulation reveals large backlogs in the system.

``` r
nan_experiment <- runner(parameters(patient_inter = 0.5))
tail(nan_experiment[["arrivals"]])
```

    ##             name start_time end_time activity_time resource replication
    ## 16136 patient139   66.41747       NA            NA    nurse         100
    ## 16137  patient74   37.63360       NA            NA    nurse         100
    ## 16138  patient64   33.83536       NA            NA    nurse         100
    ## 16139 patient140   66.66795       NA            NA    nurse         100
    ## 16140  patient75   38.54559       NA            NA    nurse         100
    ## 16141  patient77   38.74436       NA            NA    nurse         100
    ##       serve_start serve_length wait_time wait_time_unseen
    ## 16136          NA           NA        NA         13.58253
    ## 16137          NA           NA        NA         42.36640
    ## 16138          NA           NA        NA         46.16464
    ## 16139          NA           NA        NA         13.33205
    ## 16140          NA           NA        NA         41.45441
    ## 16141          NA           NA        NA         41.25564

``` r
nan_experiment[["run_results"]][c(
  "replication", "count_unseen_nurse", "mean_waiting_time_nurse"
)]
```

    ## # A tibble: 100 × 3
    ##    replication count_unseen_nurse mean_waiting_time_nurse
    ##          <int>              <int>                   <dbl>
    ##  1           1                112                    21.7
    ##  2           2                110                    15.2
    ##  3           3                127                    22.3
    ##  4           4                 95                    22.6
    ##  5           5                106                    23.4
    ##  6           6                 99                    22.2
    ##  7           7                130                    20.2
    ##  8           8                107                    24.5
    ##  9           9                119                    18.1
    ## 10          10                113                    21.3
    ## # ℹ 90 more rows

``` r
plot_results_spread(
  run_results = nan_experiment[["run_results"]],
  column = "count_unseen_nurse",
  x_label = "Patients still unseen by nurse at end of simulation (n)",
  file = "spread_nan_count_unseen.png"
)
```

![](../outputs/spread_nan_count_unseen.png)<!-- -->

``` r
plot_results_spread(
  run_results = nan_experiment[["run_results"]],
  column = "mean_waiting_time_nurse",
  x_label = "Mean nurse wait time by patients unseen at simulation end (min)",
  file = "spread_nan_wait_unseen.png"
)
```

![](../outputs/spread_nan_wait_unseen.png)<!-- -->

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

    ## Notebook run time: 1m 56s
