Choosing replications
================
Amy Heather
2025-03-11

- [Set up](#set-up)
- [Choosing the number of
  replications](#choosing-the-number-of-replications)
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
path <- file.path(output_dir, "choose_param_conf_int_1.png")

# Run calculations and produce plot
ci_df <- confidence_interval_method(
  replications = 150L,
  desired_precision = 0.05,
  metric = "mean_serve_time_nurse",
  yaxis_title = "Mean time with nurse",
  path = path,
  min_rep = 98L
)
```

    ## Reached desired precision (0.05) in 86 replications.

``` r
# Preview dataframe
head(ci_df)
```

    ##   replications cumulative_mean cumulative_std ci_lower  ci_upper perc_deviation
    ## 1            1        7.631520             NA       NA        NA             NA
    ## 2            2        8.410155             NA       NA        NA             NA
    ## 3            3        9.096810      1.4215325 5.565527 12.628092       38.81891
    ## 4            4        9.119762      1.1615839 7.271423 10.968101       20.26741
    ## 5            5        9.073830      1.0111905 7.818272 10.329389       13.83714
    ## 6            6        8.934846      0.9663877 7.920684  9.949008       11.35063

``` r
# View first ten rows were percentage deviation is below 5
ci_df %>%
  filter(perc_deviation < 5L) %>%
  head(10L)
```

    ##    replications cumulative_mean cumulative_std ci_lower ci_upper perc_deviation
    ## 1            86        9.337477       2.175400 8.871071 9.803884       4.994996
    ## 2            87        9.335636       2.162783 8.874685 9.796588       4.937549
    ## 3            88        9.383374       2.196453 8.917990 9.848758       4.959666
    ## 4            89        9.423444       2.216412 8.956552 9.890336       4.954583
    ## 5            90        9.403929       2.211688 8.940700 9.867158       4.925909
    ## 6            91        9.376650       2.214708 8.915415 9.837885       4.918976
    ## 7            92        9.389447       2.205923 8.932613 9.846281       4.865395
    ## 8            93        9.365730       2.205791 8.911453 9.820007       4.850421
    ## 9            94        9.381749       2.199390 8.931270 9.832228       4.801650
    ## 10           95        9.415707       2.212557 8.964986 9.866428       4.786905

``` r
# View plot
include_graphics(path)
```

![](../outputs/choose_param_conf_int_1.png)<!-- -->

It is also important to check across multiple metrics.

``` r
path <- file.path(output_dir, "choose_param_conf_int_3.png")

# Run calculations and produce plot
ci_df <- confidence_interval_method(
  replications = 200L,
  desired_precision = 0.05,
  metric = "utilisation_nurse",
  yaxis_title = "Mean nurse utilisation",
  path = path,
  min_rep = 148L
)
```

    ## Reached desired precision (0.05) in 151 replications.

``` r
# View first ten rows were percentage deviation is below 5
ci_df %>%
  filter(perc_deviation < 5L) %>%
  head(10L)
```

    ##    replications cumulative_mean cumulative_std ci_lower ci_upper perc_deviation
    ## 1           151        46.19744       14.35729 43.88883 48.50605       4.997262
    ## 2           154        46.26876       14.45690 43.96726 48.57027       4.974207
    ## 3           155        46.11886       14.53024 43.81327 48.42444       4.999226
    ## 4           156        46.01632       14.53980 43.71674 48.31590       4.997313
    ## 5           158        45.85531       14.54490 43.56976 48.14086       4.984266
    ## 6           159        45.86608       14.49943 43.59496 48.13719       4.951630
    ## 7           160        45.93341       14.47884 43.67272 48.19409       4.921656
    ## 8           161        45.95768       14.43680 43.71068 48.20468       4.889286
    ## 9           162        46.07486       14.46898 43.82992 48.31980       4.872380
    ## 10          163        46.12769       14.44001 43.89423 48.36115       4.841908

``` r
# View plot
include_graphics(path)
```

![](../outputs/choose_param_conf_int_3.png)<!-- -->

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

    ## Notebook run time: 0m 12s
