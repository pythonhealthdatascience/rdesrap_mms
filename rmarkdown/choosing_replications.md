Choosing replications
================
Amy Heather
2025-03-10

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

    ##   replications cumulative_mean cumulative_std ci_lower ci_upper perc_deviation
    ## 1            1        6.486585             NA       NA       NA             NA
    ## 2            2        7.765904             NA       NA       NA             NA
    ## 3            3        8.360267       1.642090 4.281088 12.43945       48.79245
    ## 4            4        8.623889       1.440704 6.331408 10.91637       26.58291
    ## 5            5        8.677132       1.253353 7.120889 10.23338       17.93500
    ## 6            6        8.490040       1.211089 7.219080  9.76100       14.97001

``` r
# View first ten rows were percentage deviation is below 5
ci_df %>%
  filter(perc_deviation < 5L) %>%
  head(10L)
```

    ##    replications cumulative_mean cumulative_std ci_lower ci_upper perc_deviation
    ## 1            86        8.123779       1.892516 7.718022 8.529535       4.994675
    ## 2            87        8.110926       1.885296 7.709115 8.512738       4.953948
    ## 3            88        8.142942       1.898338 7.740723 8.545162       4.939485
    ## 4            89        8.171550       1.906718 7.769895 8.573205       4.915281
    ## 5            90        8.165945       1.896722 7.768684 8.563206       4.864846
    ## 6            91        8.147768       1.894109 7.753301 8.542235       4.841415
    ## 7            92        8.133673       1.888518 7.742573 8.524774       4.808417
    ## 8            93        8.120481       1.882530 7.732778 8.508183       4.774378
    ## 9            94        8.149747       1.893759 7.761867 8.537626       4.759405
    ## 10           95        8.183308       1.911851 7.793844 8.572772       4.759248

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

    ## Notebook run time: 0m 28s
