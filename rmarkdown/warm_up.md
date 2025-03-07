Warm up period
================
Amy Heather
2025-03-07

- [Set up](#set-up)
- [Attempt at incorporating a warm-up period into
  `model.py`](#attempt-at-incorporating-a-warm-up-period-into-modelpy)
  - [Run the model](#run-the-model)
  - [Trim the `arrivals` and `resources` dataframes
    produced](#trim-the-arrivals-and-resources-dataframes-produced)
  - [Revisiting this approach](#revisiting-this-approach)
  - [Matching without end_time](#matching-without-end_time)
  - [Why does arrivals have duplicate
    rows?](#why-does-arrivals-have-duplicate-rows)
  - [Returning to the warm-up
    calculations](#returning-to-the-warm-up-calculations)
- [Attempt using `reset()`](#attempt-using-reset)

## Set up

Install the latest version of the local simulation package.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Import required packages.

``` r
# nolint start: undesirable_function_linter.
library(simulation)
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

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
library(tidyr)
```

    ## 
    ## Attaching package: 'tidyr'

    ## The following object is masked from 'package:testthat':
    ## 
    ##     matches

``` r
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

## Attempt at incorporating a warm-up period into `model.py`

### Run the model

Run the model for `warm_up_period` + `data_collection_period`…

To illustrate our problem, have temporarily add another resource:
doctor.

``` r
run_number <- 1
param <- parameters()
set_seed <- TRUE
number_of_doctors <- 3

param$warm_up_period
```

    ## [1] 50

``` r
param$data_collection_period
```

    ## [1] 80

``` r
# Check all inputs are valid
valid_inputs(run_number, param)

# Set random seed based on run number
if (set_seed) {
  set.seed(run_number)
}

# Define the patient trajectory
patient <- trajectory("appointment") %>%
  seize("nurse", 1L) %>%
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("nurse", 1L) %>%
  seize("doctor", 1L) %>%
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("doctor", 1L)

# Determine whether to get verbose activity logs
verbose <- any(c(param[["log_to_console"]], param[["log_to_file"]]))

# Create simmer environment, add nurse resource and patient generator, and
# run the simulation. Capture output, which will save a log if verbose=TRUE
sim_log <- capture.output(
  env <- simmer("simulation", verbose = verbose) %>% # nolint
    add_resource("nurse", param[["number_of_nurses"]]) %>%
    add_resource("doctor", number_of_doctors) %>%
    add_generator("patient", patient, function() {
      rexp(n = 1L, rate = 1L / param[["patient_inter"]])
    }) %>%
    simmer::run(param[["warm_up_period"]] +
                param[["data_collection_period"]]) %>%
    wrap()
)
```

### Trim the `arrivals` and `resources` dataframes produced

Label warm-up and data-collection patients in the `arrivals` dataframe.

``` r
arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE)

# Add column marking warm-up (wu) and data-collection (dc) patients
arrivals <- arrivals %>%
  group_by(name) %>%
  # filter(all(start_time >= param[["warm_up_period"]])) %>%
  mutate(period = if_else(
    any(start_time < param[["warm_up_period"]]), "wu", "dc"
  )) %>%
  ungroup()
arrivals
```

    ## # A tibble: 62 × 7
    ##    name     start_time end_time activity_time resource replication period
    ##    <chr>         <dbl>    <dbl>         <dbl> <chr>          <int> <chr> 
    ##  1 patient0       3.02     4.48          1.46 nurse              1 wu    
    ##  2 patient0       4.48     5.88          1.40 doctor             1 wu    
    ##  3 patient2       9.49    14.9           5.40 nurse              1 wu    
    ##  4 patient3      14.4     15.9           1.47 nurse              1 wu    
    ##  5 patient3      15.9     23.5           7.62 doctor             1 wu    
    ##  6 patient2      14.9     28.8          13.9  doctor             1 wu    
    ##  7 patient5      23.2     33.5          10.4  nurse              1 wu    
    ##  8 patient6      27.4     34.0           6.55 nurse              1 wu    
    ##  9 patient1       7.75    36.7          28.9  nurse              1 wu    
    ## 10 patient5      33.5     36.9           3.37 doctor             1 wu    
    ## # ℹ 52 more rows

As `resources` does not contain only information on which patient they
were associated with, we need to match the resource start time with the
patient activity start times.

First, we must calculate the `resource_start_time` (as the `start_time`
in `arrivals` may be earlier if the patient had to wait for the
resource).

``` r
# Add column recording the resource start time (excluding wait time for resource)
arrivals[["resource_start_time"]] <- (
  arrivals[["end_time"]] - arrivals[["activity_time"]]
)
arrivals
```

    ## # A tibble: 62 × 8
    ##    name     start_time end_time activity_time resource replication period
    ##    <chr>         <dbl>    <dbl>         <dbl> <chr>          <int> <chr> 
    ##  1 patient0       3.02     4.48          1.46 nurse              1 wu    
    ##  2 patient0       4.48     5.88          1.40 doctor             1 wu    
    ##  3 patient2       9.49    14.9           5.40 nurse              1 wu    
    ##  4 patient3      14.4     15.9           1.47 nurse              1 wu    
    ##  5 patient3      15.9     23.5           7.62 doctor             1 wu    
    ##  6 patient2      14.9     28.8          13.9  doctor             1 wu    
    ##  7 patient5      23.2     33.5          10.4  nurse              1 wu    
    ##  8 patient6      27.4     34.0           6.55 nurse              1 wu    
    ##  9 patient1       7.75    36.7          28.9  nurse              1 wu    
    ## 10 patient5      33.5     36.9           3.37 doctor             1 wu    
    ## # ℹ 52 more rows
    ## # ℹ 1 more variable: resource_start_time <dbl>

**Question:** Is `resource_start_time` just the same as start time? If
patients had to wait for a resource, does activity_time include that?

**Answer:** No.

``` r
# Instances where start_time is different from resource_start_time
arrivals[round(arrivals$start_time, 10) != round(arrivals$resource_start_time, 10),]
```

    ## # A tibble: 14 × 8
    ##    name      start_time end_time activity_time resource replication period
    ##    <chr>          <dbl>    <dbl>         <dbl> <chr>          <int> <chr> 
    ##  1 patient15       60.4     74.4         12.9  nurse              1 dc    
    ##  2 patient24      110.     116.           3.89 doctor             1 dc    
    ##  3 patient22      105.     129.          23.1  doctor             1 dc    
    ##  4 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ##  5 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ##  6 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ##  7 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ##  8 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ##  9 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ## 10 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ## 11 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ## 12 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ## 13 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ## 14 <NA>            NA       NA           NA    <NA>              NA <NA>  
    ## # ℹ 1 more variable: resource_start_time <dbl>

In the `resources` dataframe, we just has `time` (which is for an
event - including start time or end time).

``` r
resources <- get_mon_resources(env)
resources
```

    ##     resource       time server queue capacity queue_size system limit
    ## 1      nurse   3.020727      1     0        5        Inf      1   Inf
    ## 2      nurse   4.477795      0     0        5        Inf      0   Inf
    ## 3     doctor   4.477795      1     0        3        Inf      1   Inf
    ## 4     doctor   5.875747      0     0        3        Inf      0   Inf
    ## 5      nurse   7.747298      1     0        5        Inf      1   Inf
    ## 6      nurse   9.491573      2     0        5        Inf      2   Inf
    ## 7      nurse  14.409821      3     0        5        Inf      3   Inf
    ## 8      nurse  14.888401      2     0        5        Inf      2   Inf
    ## 9     doctor  14.888401      1     0        3        Inf      1   Inf
    ## 10     nurse  15.880281      1     0        5        Inf      1   Inf
    ## 11    doctor  15.880281      2     0        3        Inf      2   Inf
    ## 12     nurse  18.236091      2     0        5        Inf      2   Inf
    ## 13     nurse  23.186505      3     0        5        Inf      3   Inf
    ## 14    doctor  23.500580      1     0        3        Inf      1   Inf
    ## 15     nurse  27.404678      4     0        5        Inf      4   Inf
    ## 16    doctor  28.795753      0     0        3        Inf      0   Inf
    ## 17     nurse  33.538945      3     0        5        Inf      3   Inf
    ## 18    doctor  33.538945      1     0        3        Inf      1   Inf
    ## 19     nurse  33.952144      2     0        5        Inf      2   Inf
    ## 20    doctor  33.952144      2     0        3        Inf      2   Inf
    ## 21     nurse  34.908819      3     0        5        Inf      3   Inf
    ## 22     nurse  36.696984      2     0        5        Inf      2   Inf
    ## 23    doctor  36.696984      3     0        3        Inf      3   Inf
    ## 24    doctor  36.908280      2     0        3        Inf      2   Inf
    ## 25    doctor  39.638188      1     0        3        Inf      1   Inf
    ## 26    doctor  39.836942      0     0        3        Inf      0   Inf
    ## 27     nurse  41.327745      1     0        5        Inf      1   Inf
    ## 28    doctor  41.327745      1     0        3        Inf      1   Inf
    ## 29     nurse  44.366880      2     0        5        Inf      2   Inf
    ## 30     nurse  44.791170      3     0        5        Inf      3   Inf
    ## 31     nurse  44.961271      2     0        5        Inf      2   Inf
    ## 32    doctor  44.961271      2     0        3        Inf      2   Inf
    ## 33    doctor  46.986400      1     0        3        Inf      1   Inf
    ## 34     nurse  47.106020      3     0        5        Inf      3   Inf
    ## 35     nurse  51.093272      4     0        5        Inf      4   Inf
    ## 36     nurse  51.242346      5     0        5        Inf      5   Inf
    ## 37     nurse  53.277449      4     0        5        Inf      4   Inf
    ## 38    doctor  53.277449      2     0        3        Inf      2   Inf
    ## 39     nurse  54.333373      3     0        5        Inf      3   Inf
    ## 40    doctor  54.333373      3     0        3        Inf      3   Inf
    ## 41     nurse  56.524218      4     0        5        Inf      4   Inf
    ## 42    doctor  56.694392      2     0        3        Inf      2   Inf
    ## 43    doctor  57.350783      1     0        3        Inf      1   Inf
    ## 44     nurse  59.425075      5     0        5        Inf      5   Inf
    ## 45     nurse  60.365185      5     1        5        Inf      6   Inf
    ## 46     nurse  61.458873      5     0        5        Inf      5   Inf
    ## 47    doctor  61.458873      2     0        3        Inf      2   Inf
    ## 48     nurse  62.475433      4     0        5        Inf      4   Inf
    ## 49    doctor  62.475433      3     0        3        Inf      3   Inf
    ## 50    doctor  63.504708      2     0        3        Inf      2   Inf
    ## 51     nurse  64.039645      3     0        5        Inf      3   Inf
    ## 52    doctor  64.039645      3     0        3        Inf      3   Inf
    ## 53     nurse  64.478172      4     0        5        Inf      4   Inf
    ## 54    doctor  67.052475      2     0        3        Inf      2   Inf
    ## 55    doctor  68.021847      1     0        3        Inf      1   Inf
    ## 56     nurse  69.650671      5     0        5        Inf      5   Inf
    ## 57     nurse  70.223886      4     0        5        Inf      4   Inf
    ## 58    doctor  70.223886      2     0        3        Inf      2   Inf
    ## 59     nurse  71.707368      5     0        5        Inf      5   Inf
    ## 60    doctor  73.989927      1     0        3        Inf      1   Inf
    ## 61     nurse  74.381490      4     0        5        Inf      4   Inf
    ## 62    doctor  74.381490      2     0        3        Inf      2   Inf
    ## 63     nurse  74.423730      3     0        5        Inf      3   Inf
    ## 64    doctor  74.423730      3     0        3        Inf      3   Inf
    ## 65    doctor  74.446311      2     0        3        Inf      2   Inf
    ## 66    doctor  79.959784      1     0        3        Inf      1   Inf
    ## 67    doctor  80.369907      0     0        3        Inf      0   Inf
    ## 68     nurse  80.422458      4     0        5        Inf      4   Inf
    ## 69     nurse  82.521124      3     0        5        Inf      3   Inf
    ## 70    doctor  82.521124      1     0        3        Inf      1   Inf
    ## 71     nurse  84.332042      4     0        5        Inf      4   Inf
    ## 72     nurse  84.380499      3     0        5        Inf      3   Inf
    ## 73    doctor  84.380499      2     0        3        Inf      2   Inf
    ## 74    doctor  85.277240      1     0        3        Inf      1   Inf
    ## 75    doctor  85.615603      0     0        3        Inf      0   Inf
    ## 76     nurse  88.755787      4     0        5        Inf      4   Inf
    ## 77     nurse  89.728995      3     0        5        Inf      3   Inf
    ## 78    doctor  89.728995      1     0        3        Inf      1   Inf
    ## 79     nurse  91.228429      2     0        5        Inf      2   Inf
    ## 80    doctor  91.228429      2     0        3        Inf      2   Inf
    ## 81     nurse  92.073919      1     0        5        Inf      1   Inf
    ## 82    doctor  92.073919      3     0        3        Inf      3   Inf
    ## 83     nurse  93.188493      2     0        5        Inf      2   Inf
    ## 84    doctor  96.385241      2     0        3        Inf      2   Inf
    ## 85     nurse 103.885258      1     0        5        Inf      1   Inf
    ## 86    doctor 103.885258      3     0        3        Inf      3   Inf
    ## 87     nurse 104.110051      2     0        5        Inf      2   Inf
    ## 88     nurse 104.556807      1     0        5        Inf      1   Inf
    ## 89    doctor 104.556807      3     1        3        Inf      4   Inf
    ## 90    doctor 105.448863      3     0        3        Inf      3   Inf
    ## 91     nurse 107.458077      2     0        5        Inf      2   Inf
    ## 92     nurse 110.313986      1     0        5        Inf      1   Inf
    ## 93    doctor 110.313986      3     1        3        Inf      4   Inf
    ## 94    doctor 112.018941      3     0        3        Inf      3   Inf
    ## 95    doctor 115.906809      2     0        3        Inf      2   Inf
    ## 96     nurse 119.097626      2     0        5        Inf      2   Inf
    ## 97     nurse 119.305847      3     0        5        Inf      3   Inf
    ## 98     nurse 121.957705      2     0        5        Inf      2   Inf
    ## 99    doctor 121.957705      3     0        3        Inf      3   Inf
    ## 100    nurse 122.616331      1     0        5        Inf      1   Inf
    ## 101   doctor 122.616331      3     1        3        Inf      4   Inf
    ## 102    nurse 125.566813      2     0        5        Inf      2   Inf
    ## 103    nurse 127.111587      3     0        5        Inf      3   Inf
    ## 104    nurse 127.451205      2     0        5        Inf      2   Inf
    ## 105   doctor 127.451205      3     2        3        Inf      5   Inf
    ## 106    nurse 127.704199      1     0        5        Inf      1   Inf
    ## 107   doctor 127.704199      3     3        3        Inf      6   Inf
    ## 108   doctor 128.573580      3     2        3        Inf      5   Inf
    ##     replication
    ## 1             1
    ## 2             1
    ## 3             1
    ## 4             1
    ## 5             1
    ## 6             1
    ## 7             1
    ## 8             1
    ## 9             1
    ## 10            1
    ## 11            1
    ## 12            1
    ## 13            1
    ## 14            1
    ## 15            1
    ## 16            1
    ## 17            1
    ## 18            1
    ## 19            1
    ## 20            1
    ## 21            1
    ## 22            1
    ## 23            1
    ## 24            1
    ## 25            1
    ## 26            1
    ## 27            1
    ## 28            1
    ## 29            1
    ## 30            1
    ## 31            1
    ## 32            1
    ## 33            1
    ## 34            1
    ## 35            1
    ## 36            1
    ## 37            1
    ## 38            1
    ## 39            1
    ## 40            1
    ## 41            1
    ## 42            1
    ## 43            1
    ## 44            1
    ## 45            1
    ## 46            1
    ## 47            1
    ## 48            1
    ## 49            1
    ## 50            1
    ## 51            1
    ## 52            1
    ## 53            1
    ## 54            1
    ## 55            1
    ## 56            1
    ## 57            1
    ## 58            1
    ## 59            1
    ## 60            1
    ## 61            1
    ## 62            1
    ## 63            1
    ## 64            1
    ## 65            1
    ## 66            1
    ## 67            1
    ## 68            1
    ## 69            1
    ## 70            1
    ## 71            1
    ## 72            1
    ## 73            1
    ## 74            1
    ## 75            1
    ## 76            1
    ## 77            1
    ## 78            1
    ## 79            1
    ## 80            1
    ## 81            1
    ## 82            1
    ## 83            1
    ## 84            1
    ## 85            1
    ## 86            1
    ## 87            1
    ## 88            1
    ## 89            1
    ## 90            1
    ## 91            1
    ## 92            1
    ## 93            1
    ## 94            1
    ## 95            1
    ## 96            1
    ## 97            1
    ## 98            1
    ## 99            1
    ## 100           1
    ## 101           1
    ## 102           1
    ## 103           1
    ## 104           1
    ## 105           1
    ## 106           1
    ## 107           1
    ## 108           1

``` r
# Create arrivals dataframe with rows for each patient's resource start and end time
arrivals_times <- arrivals %>%
  select(name, resource, resource_start_time, end_time, replication, period) %>%
  pivot_longer(cols = c(resource_start_time, end_time),
               names_to = "time_type",
               values_to = "time_value")

arrivals_times
```

    ## # A tibble: 124 × 6
    ##    name     resource replication period time_type           time_value
    ##    <chr>    <chr>          <int> <chr>  <chr>                    <dbl>
    ##  1 patient0 nurse              1 wu     resource_start_time       3.02
    ##  2 patient0 nurse              1 wu     end_time                  4.48
    ##  3 patient0 doctor             1 wu     resource_start_time       4.48
    ##  4 patient0 doctor             1 wu     end_time                  5.88
    ##  5 patient2 nurse              1 wu     resource_start_time       9.49
    ##  6 patient2 nurse              1 wu     end_time                 14.9 
    ##  7 patient3 nurse              1 wu     resource_start_time      14.4 
    ##  8 patient3 nurse              1 wu     end_time                 15.9 
    ##  9 patient3 doctor             1 wu     resource_start_time      15.9 
    ## 10 patient3 doctor             1 wu     end_time                 23.5 
    ## # ℹ 114 more rows

``` r
# Sort both dataframes by time and round (otherwise everything doesn't match
# due to floating point differences)
decimal_places <- 10

arrivals_times <- arrivals_times %>%
  arrange(time_value) %>%
  mutate(time_value_r = round(time_value, decimal_places))

resources <- resources %>%
  mutate(time_r = round(time, decimal_places))

# Preview
arrivals_times
```

    ## # A tibble: 124 × 7
    ##    name     resource replication period time_type        time_value time_value_r
    ##    <chr>    <chr>          <int> <chr>  <chr>                 <dbl>        <dbl>
    ##  1 patient0 nurse              1 wu     resource_start_…       3.02         3.02
    ##  2 patient0 nurse              1 wu     end_time               4.48         4.48
    ##  3 patient0 doctor             1 wu     resource_start_…       4.48         4.48
    ##  4 patient0 doctor             1 wu     end_time               5.88         5.88
    ##  5 patient1 nurse              1 wu     resource_start_…       7.75         7.75
    ##  6 patient2 nurse              1 wu     resource_start_…       9.49         9.49
    ##  7 patient3 nurse              1 wu     resource_start_…      14.4         14.4 
    ##  8 patient2 nurse              1 wu     end_time              14.9         14.9 
    ##  9 patient2 doctor             1 wu     resource_start_…      14.9         14.9 
    ## 10 patient3 nurse              1 wu     end_time              15.9         15.9 
    ## # ℹ 114 more rows

``` r
resources
```

    ##     resource       time server queue capacity queue_size system limit
    ## 1      nurse   3.020727      1     0        5        Inf      1   Inf
    ## 2      nurse   4.477795      0     0        5        Inf      0   Inf
    ## 3     doctor   4.477795      1     0        3        Inf      1   Inf
    ## 4     doctor   5.875747      0     0        3        Inf      0   Inf
    ## 5      nurse   7.747298      1     0        5        Inf      1   Inf
    ## 6      nurse   9.491573      2     0        5        Inf      2   Inf
    ## 7      nurse  14.409821      3     0        5        Inf      3   Inf
    ## 8      nurse  14.888401      2     0        5        Inf      2   Inf
    ## 9     doctor  14.888401      1     0        3        Inf      1   Inf
    ## 10     nurse  15.880281      1     0        5        Inf      1   Inf
    ## 11    doctor  15.880281      2     0        3        Inf      2   Inf
    ## 12     nurse  18.236091      2     0        5        Inf      2   Inf
    ## 13     nurse  23.186505      3     0        5        Inf      3   Inf
    ## 14    doctor  23.500580      1     0        3        Inf      1   Inf
    ## 15     nurse  27.404678      4     0        5        Inf      4   Inf
    ## 16    doctor  28.795753      0     0        3        Inf      0   Inf
    ## 17     nurse  33.538945      3     0        5        Inf      3   Inf
    ## 18    doctor  33.538945      1     0        3        Inf      1   Inf
    ## 19     nurse  33.952144      2     0        5        Inf      2   Inf
    ## 20    doctor  33.952144      2     0        3        Inf      2   Inf
    ## 21     nurse  34.908819      3     0        5        Inf      3   Inf
    ## 22     nurse  36.696984      2     0        5        Inf      2   Inf
    ## 23    doctor  36.696984      3     0        3        Inf      3   Inf
    ## 24    doctor  36.908280      2     0        3        Inf      2   Inf
    ## 25    doctor  39.638188      1     0        3        Inf      1   Inf
    ## 26    doctor  39.836942      0     0        3        Inf      0   Inf
    ## 27     nurse  41.327745      1     0        5        Inf      1   Inf
    ## 28    doctor  41.327745      1     0        3        Inf      1   Inf
    ## 29     nurse  44.366880      2     0        5        Inf      2   Inf
    ## 30     nurse  44.791170      3     0        5        Inf      3   Inf
    ## 31     nurse  44.961271      2     0        5        Inf      2   Inf
    ## 32    doctor  44.961271      2     0        3        Inf      2   Inf
    ## 33    doctor  46.986400      1     0        3        Inf      1   Inf
    ## 34     nurse  47.106020      3     0        5        Inf      3   Inf
    ## 35     nurse  51.093272      4     0        5        Inf      4   Inf
    ## 36     nurse  51.242346      5     0        5        Inf      5   Inf
    ## 37     nurse  53.277449      4     0        5        Inf      4   Inf
    ## 38    doctor  53.277449      2     0        3        Inf      2   Inf
    ## 39     nurse  54.333373      3     0        5        Inf      3   Inf
    ## 40    doctor  54.333373      3     0        3        Inf      3   Inf
    ## 41     nurse  56.524218      4     0        5        Inf      4   Inf
    ## 42    doctor  56.694392      2     0        3        Inf      2   Inf
    ## 43    doctor  57.350783      1     0        3        Inf      1   Inf
    ## 44     nurse  59.425075      5     0        5        Inf      5   Inf
    ## 45     nurse  60.365185      5     1        5        Inf      6   Inf
    ## 46     nurse  61.458873      5     0        5        Inf      5   Inf
    ## 47    doctor  61.458873      2     0        3        Inf      2   Inf
    ## 48     nurse  62.475433      4     0        5        Inf      4   Inf
    ## 49    doctor  62.475433      3     0        3        Inf      3   Inf
    ## 50    doctor  63.504708      2     0        3        Inf      2   Inf
    ## 51     nurse  64.039645      3     0        5        Inf      3   Inf
    ## 52    doctor  64.039645      3     0        3        Inf      3   Inf
    ## 53     nurse  64.478172      4     0        5        Inf      4   Inf
    ## 54    doctor  67.052475      2     0        3        Inf      2   Inf
    ## 55    doctor  68.021847      1     0        3        Inf      1   Inf
    ## 56     nurse  69.650671      5     0        5        Inf      5   Inf
    ## 57     nurse  70.223886      4     0        5        Inf      4   Inf
    ## 58    doctor  70.223886      2     0        3        Inf      2   Inf
    ## 59     nurse  71.707368      5     0        5        Inf      5   Inf
    ## 60    doctor  73.989927      1     0        3        Inf      1   Inf
    ## 61     nurse  74.381490      4     0        5        Inf      4   Inf
    ## 62    doctor  74.381490      2     0        3        Inf      2   Inf
    ## 63     nurse  74.423730      3     0        5        Inf      3   Inf
    ## 64    doctor  74.423730      3     0        3        Inf      3   Inf
    ## 65    doctor  74.446311      2     0        3        Inf      2   Inf
    ## 66    doctor  79.959784      1     0        3        Inf      1   Inf
    ## 67    doctor  80.369907      0     0        3        Inf      0   Inf
    ## 68     nurse  80.422458      4     0        5        Inf      4   Inf
    ## 69     nurse  82.521124      3     0        5        Inf      3   Inf
    ## 70    doctor  82.521124      1     0        3        Inf      1   Inf
    ## 71     nurse  84.332042      4     0        5        Inf      4   Inf
    ## 72     nurse  84.380499      3     0        5        Inf      3   Inf
    ## 73    doctor  84.380499      2     0        3        Inf      2   Inf
    ## 74    doctor  85.277240      1     0        3        Inf      1   Inf
    ## 75    doctor  85.615603      0     0        3        Inf      0   Inf
    ## 76     nurse  88.755787      4     0        5        Inf      4   Inf
    ## 77     nurse  89.728995      3     0        5        Inf      3   Inf
    ## 78    doctor  89.728995      1     0        3        Inf      1   Inf
    ## 79     nurse  91.228429      2     0        5        Inf      2   Inf
    ## 80    doctor  91.228429      2     0        3        Inf      2   Inf
    ## 81     nurse  92.073919      1     0        5        Inf      1   Inf
    ## 82    doctor  92.073919      3     0        3        Inf      3   Inf
    ## 83     nurse  93.188493      2     0        5        Inf      2   Inf
    ## 84    doctor  96.385241      2     0        3        Inf      2   Inf
    ## 85     nurse 103.885258      1     0        5        Inf      1   Inf
    ## 86    doctor 103.885258      3     0        3        Inf      3   Inf
    ## 87     nurse 104.110051      2     0        5        Inf      2   Inf
    ## 88     nurse 104.556807      1     0        5        Inf      1   Inf
    ## 89    doctor 104.556807      3     1        3        Inf      4   Inf
    ## 90    doctor 105.448863      3     0        3        Inf      3   Inf
    ## 91     nurse 107.458077      2     0        5        Inf      2   Inf
    ## 92     nurse 110.313986      1     0        5        Inf      1   Inf
    ## 93    doctor 110.313986      3     1        3        Inf      4   Inf
    ## 94    doctor 112.018941      3     0        3        Inf      3   Inf
    ## 95    doctor 115.906809      2     0        3        Inf      2   Inf
    ## 96     nurse 119.097626      2     0        5        Inf      2   Inf
    ## 97     nurse 119.305847      3     0        5        Inf      3   Inf
    ## 98     nurse 121.957705      2     0        5        Inf      2   Inf
    ## 99    doctor 121.957705      3     0        3        Inf      3   Inf
    ## 100    nurse 122.616331      1     0        5        Inf      1   Inf
    ## 101   doctor 122.616331      3     1        3        Inf      4   Inf
    ## 102    nurse 125.566813      2     0        5        Inf      2   Inf
    ## 103    nurse 127.111587      3     0        5        Inf      3   Inf
    ## 104    nurse 127.451205      2     0        5        Inf      2   Inf
    ## 105   doctor 127.451205      3     2        3        Inf      5   Inf
    ## 106    nurse 127.704199      1     0        5        Inf      1   Inf
    ## 107   doctor 127.704199      3     3        3        Inf      6   Inf
    ## 108   doctor 128.573580      3     2        3        Inf      5   Inf
    ##     replication     time_r
    ## 1             1   3.020727
    ## 2             1   4.477795
    ## 3             1   4.477795
    ## 4             1   5.875747
    ## 5             1   7.747298
    ## 6             1   9.491573
    ## 7             1  14.409821
    ## 8             1  14.888401
    ## 9             1  14.888401
    ## 10            1  15.880281
    ## 11            1  15.880281
    ## 12            1  18.236091
    ## 13            1  23.186505
    ## 14            1  23.500580
    ## 15            1  27.404678
    ## 16            1  28.795753
    ## 17            1  33.538945
    ## 18            1  33.538945
    ## 19            1  33.952144
    ## 20            1  33.952144
    ## 21            1  34.908819
    ## 22            1  36.696984
    ## 23            1  36.696984
    ## 24            1  36.908280
    ## 25            1  39.638188
    ## 26            1  39.836942
    ## 27            1  41.327745
    ## 28            1  41.327745
    ## 29            1  44.366880
    ## 30            1  44.791170
    ## 31            1  44.961271
    ## 32            1  44.961271
    ## 33            1  46.986400
    ## 34            1  47.106020
    ## 35            1  51.093272
    ## 36            1  51.242346
    ## 37            1  53.277449
    ## 38            1  53.277449
    ## 39            1  54.333373
    ## 40            1  54.333373
    ## 41            1  56.524218
    ## 42            1  56.694392
    ## 43            1  57.350783
    ## 44            1  59.425075
    ## 45            1  60.365185
    ## 46            1  61.458873
    ## 47            1  61.458873
    ## 48            1  62.475433
    ## 49            1  62.475433
    ## 50            1  63.504708
    ## 51            1  64.039645
    ## 52            1  64.039645
    ## 53            1  64.478172
    ## 54            1  67.052475
    ## 55            1  68.021847
    ## 56            1  69.650671
    ## 57            1  70.223886
    ## 58            1  70.223886
    ## 59            1  71.707368
    ## 60            1  73.989927
    ## 61            1  74.381490
    ## 62            1  74.381490
    ## 63            1  74.423730
    ## 64            1  74.423730
    ## 65            1  74.446311
    ## 66            1  79.959784
    ## 67            1  80.369907
    ## 68            1  80.422458
    ## 69            1  82.521124
    ## 70            1  82.521124
    ## 71            1  84.332042
    ## 72            1  84.380499
    ## 73            1  84.380499
    ## 74            1  85.277240
    ## 75            1  85.615603
    ## 76            1  88.755787
    ## 77            1  89.728995
    ## 78            1  89.728995
    ## 79            1  91.228429
    ## 80            1  91.228429
    ## 81            1  92.073919
    ## 82            1  92.073919
    ## 83            1  93.188493
    ## 84            1  96.385241
    ## 85            1 103.885258
    ## 86            1 103.885258
    ## 87            1 104.110051
    ## 88            1 104.556807
    ## 89            1 104.556807
    ## 90            1 105.448863
    ## 91            1 107.458077
    ## 92            1 110.313986
    ## 93            1 110.313986
    ## 94            1 112.018941
    ## 95            1 115.906809
    ## 96            1 119.097626
    ## 97            1 119.305847
    ## 98            1 121.957705
    ## 99            1 121.957705
    ## 100           1 122.616331
    ## 101           1 122.616331
    ## 102           1 125.566813
    ## 103           1 127.111587
    ## 104           1 127.451205
    ## 105           1 127.451205
    ## 106           1 127.704199
    ## 107           1 127.704199
    ## 108           1 128.573580

``` r
# Merge the dataframes
matched_data <- left_join(
  resources, arrivals_times,
  by = c("time_r" = "time_value_r",
         "resource" = "resource",
         "replication" = "replication")
)
matched_data
```

    ##     resource       time server queue capacity queue_size system limit
    ## 1      nurse   3.020727      1     0        5        Inf      1   Inf
    ## 2      nurse   4.477795      0     0        5        Inf      0   Inf
    ## 3     doctor   4.477795      1     0        3        Inf      1   Inf
    ## 4     doctor   5.875747      0     0        3        Inf      0   Inf
    ## 5      nurse   7.747298      1     0        5        Inf      1   Inf
    ## 6      nurse   9.491573      2     0        5        Inf      2   Inf
    ## 7      nurse  14.409821      3     0        5        Inf      3   Inf
    ## 8      nurse  14.888401      2     0        5        Inf      2   Inf
    ## 9     doctor  14.888401      1     0        3        Inf      1   Inf
    ## 10     nurse  15.880281      1     0        5        Inf      1   Inf
    ## 11    doctor  15.880281      2     0        3        Inf      2   Inf
    ## 12     nurse  18.236091      2     0        5        Inf      2   Inf
    ## 13     nurse  23.186505      3     0        5        Inf      3   Inf
    ## 14    doctor  23.500580      1     0        3        Inf      1   Inf
    ## 15     nurse  27.404678      4     0        5        Inf      4   Inf
    ## 16    doctor  28.795753      0     0        3        Inf      0   Inf
    ## 17     nurse  33.538945      3     0        5        Inf      3   Inf
    ## 18    doctor  33.538945      1     0        3        Inf      1   Inf
    ## 19     nurse  33.952144      2     0        5        Inf      2   Inf
    ## 20    doctor  33.952144      2     0        3        Inf      2   Inf
    ## 21     nurse  34.908819      3     0        5        Inf      3   Inf
    ## 22     nurse  36.696984      2     0        5        Inf      2   Inf
    ## 23    doctor  36.696984      3     0        3        Inf      3   Inf
    ## 24    doctor  36.908280      2     0        3        Inf      2   Inf
    ## 25    doctor  39.638188      1     0        3        Inf      1   Inf
    ## 26    doctor  39.836942      0     0        3        Inf      0   Inf
    ## 27     nurse  41.327745      1     0        5        Inf      1   Inf
    ## 28    doctor  41.327745      1     0        3        Inf      1   Inf
    ## 29     nurse  44.366880      2     0        5        Inf      2   Inf
    ## 30     nurse  44.791170      3     0        5        Inf      3   Inf
    ## 31     nurse  44.961271      2     0        5        Inf      2   Inf
    ## 32    doctor  44.961271      2     0        3        Inf      2   Inf
    ## 33    doctor  46.986400      1     0        3        Inf      1   Inf
    ## 34     nurse  47.106020      3     0        5        Inf      3   Inf
    ## 35     nurse  51.093272      4     0        5        Inf      4   Inf
    ## 36     nurse  51.242346      5     0        5        Inf      5   Inf
    ## 37     nurse  53.277449      4     0        5        Inf      4   Inf
    ## 38    doctor  53.277449      2     0        3        Inf      2   Inf
    ## 39     nurse  54.333373      3     0        5        Inf      3   Inf
    ## 40    doctor  54.333373      3     0        3        Inf      3   Inf
    ## 41     nurse  56.524218      4     0        5        Inf      4   Inf
    ## 42    doctor  56.694392      2     0        3        Inf      2   Inf
    ## 43    doctor  57.350783      1     0        3        Inf      1   Inf
    ## 44     nurse  59.425075      5     0        5        Inf      5   Inf
    ## 45     nurse  60.365185      5     1        5        Inf      6   Inf
    ## 46     nurse  61.458873      5     0        5        Inf      5   Inf
    ## 47     nurse  61.458873      5     0        5        Inf      5   Inf
    ## 48    doctor  61.458873      2     0        3        Inf      2   Inf
    ## 49     nurse  62.475433      4     0        5        Inf      4   Inf
    ## 50    doctor  62.475433      3     0        3        Inf      3   Inf
    ## 51    doctor  63.504708      2     0        3        Inf      2   Inf
    ## 52     nurse  64.039645      3     0        5        Inf      3   Inf
    ## 53    doctor  64.039645      3     0        3        Inf      3   Inf
    ## 54     nurse  64.478172      4     0        5        Inf      4   Inf
    ## 55    doctor  67.052475      2     0        3        Inf      2   Inf
    ## 56    doctor  68.021847      1     0        3        Inf      1   Inf
    ## 57     nurse  69.650671      5     0        5        Inf      5   Inf
    ## 58     nurse  70.223886      4     0        5        Inf      4   Inf
    ## 59    doctor  70.223886      2     0        3        Inf      2   Inf
    ## 60     nurse  71.707368      5     0        5        Inf      5   Inf
    ## 61    doctor  73.989927      1     0        3        Inf      1   Inf
    ## 62     nurse  74.381490      4     0        5        Inf      4   Inf
    ## 63    doctor  74.381490      2     0        3        Inf      2   Inf
    ## 64     nurse  74.423730      3     0        5        Inf      3   Inf
    ## 65    doctor  74.423730      3     0        3        Inf      3   Inf
    ## 66    doctor  74.446311      2     0        3        Inf      2   Inf
    ## 67    doctor  79.959784      1     0        3        Inf      1   Inf
    ## 68    doctor  80.369907      0     0        3        Inf      0   Inf
    ## 69     nurse  80.422458      4     0        5        Inf      4   Inf
    ## 70     nurse  82.521124      3     0        5        Inf      3   Inf
    ## 71    doctor  82.521124      1     0        3        Inf      1   Inf
    ## 72     nurse  84.332042      4     0        5        Inf      4   Inf
    ## 73     nurse  84.380499      3     0        5        Inf      3   Inf
    ## 74    doctor  84.380499      2     0        3        Inf      2   Inf
    ## 75    doctor  85.277240      1     0        3        Inf      1   Inf
    ## 76    doctor  85.615603      0     0        3        Inf      0   Inf
    ## 77     nurse  88.755787      4     0        5        Inf      4   Inf
    ## 78     nurse  89.728995      3     0        5        Inf      3   Inf
    ## 79    doctor  89.728995      1     0        3        Inf      1   Inf
    ## 80     nurse  91.228429      2     0        5        Inf      2   Inf
    ## 81    doctor  91.228429      2     0        3        Inf      2   Inf
    ## 82     nurse  92.073919      1     0        5        Inf      1   Inf
    ## 83    doctor  92.073919      3     0        3        Inf      3   Inf
    ## 84     nurse  93.188493      2     0        5        Inf      2   Inf
    ## 85    doctor  96.385241      2     0        3        Inf      2   Inf
    ## 86     nurse 103.885258      1     0        5        Inf      1   Inf
    ## 87    doctor 103.885258      3     0        3        Inf      3   Inf
    ## 88     nurse 104.110051      2     0        5        Inf      2   Inf
    ## 89     nurse 104.556807      1     0        5        Inf      1   Inf
    ## 90    doctor 104.556807      3     1        3        Inf      4   Inf
    ## 91    doctor 105.448863      3     0        3        Inf      3   Inf
    ## 92    doctor 105.448863      3     0        3        Inf      3   Inf
    ## 93     nurse 107.458077      2     0        5        Inf      2   Inf
    ## 94     nurse 110.313986      1     0        5        Inf      1   Inf
    ## 95    doctor 110.313986      3     1        3        Inf      4   Inf
    ## 96    doctor 112.018941      3     0        3        Inf      3   Inf
    ## 97    doctor 112.018941      3     0        3        Inf      3   Inf
    ## 98    doctor 115.906809      2     0        3        Inf      2   Inf
    ## 99     nurse 119.097626      2     0        5        Inf      2   Inf
    ## 100    nurse 119.305847      3     0        5        Inf      3   Inf
    ## 101    nurse 121.957705      2     0        5        Inf      2   Inf
    ## 102   doctor 121.957705      3     0        3        Inf      3   Inf
    ## 103    nurse 122.616331      1     0        5        Inf      1   Inf
    ## 104   doctor 122.616331      3     1        3        Inf      4   Inf
    ## 105    nurse 125.566813      2     0        5        Inf      2   Inf
    ## 106    nurse 127.111587      3     0        5        Inf      3   Inf
    ## 107    nurse 127.451205      2     0        5        Inf      2   Inf
    ## 108   doctor 127.451205      3     2        3        Inf      5   Inf
    ## 109    nurse 127.704199      1     0        5        Inf      1   Inf
    ## 110   doctor 127.704199      3     3        3        Inf      6   Inf
    ## 111   doctor 128.573580      3     2        3        Inf      5   Inf
    ##     replication     time_r      name period           time_type time_value
    ## 1             1   3.020727  patient0     wu resource_start_time   3.020727
    ## 2             1   4.477795  patient0     wu            end_time   4.477795
    ## 3             1   4.477795  patient0     wu resource_start_time   4.477795
    ## 4             1   5.875747  patient0     wu            end_time   5.875747
    ## 5             1   7.747298  patient1     wu resource_start_time   7.747298
    ## 6             1   9.491573  patient2     wu resource_start_time   9.491573
    ## 7             1  14.409821  patient3     wu resource_start_time  14.409821
    ## 8             1  14.888401  patient2     wu            end_time  14.888401
    ## 9             1  14.888401  patient2     wu resource_start_time  14.888401
    ## 10            1  15.880281  patient3     wu            end_time  15.880281
    ## 11            1  15.880281  patient3     wu resource_start_time  15.880281
    ## 12            1  18.236091  patient4     wu resource_start_time  18.236091
    ## 13            1  23.186505  patient5     wu resource_start_time  23.186505
    ## 14            1  23.500580  patient3     wu            end_time  23.500580
    ## 15            1  27.404678  patient6     wu resource_start_time  27.404678
    ## 16            1  28.795753  patient2     wu            end_time  28.795753
    ## 17            1  33.538945  patient5     wu            end_time  33.538945
    ## 18            1  33.538945  patient5     wu resource_start_time  33.538945
    ## 19            1  33.952144  patient6     wu            end_time  33.952144
    ## 20            1  33.952144  patient6     wu resource_start_time  33.952144
    ## 21            1  34.908819  patient7     wu resource_start_time  34.908819
    ## 22            1  36.696984  patient1     wu            end_time  36.696984
    ## 23            1  36.696984  patient1     wu resource_start_time  36.696984
    ## 24            1  36.908280  patient5     wu            end_time  36.908280
    ## 25            1  39.638188  patient1     wu            end_time  39.638188
    ## 26            1  39.836942  patient6     wu            end_time  39.836942
    ## 27            1  41.327745  patient7     wu            end_time  41.327745
    ## 28            1  41.327745  patient7     wu resource_start_time  41.327745
    ## 29            1  44.366880  patient8     wu resource_start_time  44.366880
    ## 30            1  44.791170  patient9     wu resource_start_time  44.791170
    ## 31            1  44.961271  patient8     wu            end_time  44.961271
    ## 32            1  44.961271  patient8     wu resource_start_time  44.961271
    ## 33            1  46.986400  patient7     wu            end_time  46.986400
    ## 34            1  47.106020 patient10     wu resource_start_time  47.106020
    ## 35            1  51.093272 patient11     dc resource_start_time  51.093272
    ## 36            1  51.242346 patient12     dc resource_start_time  51.242346
    ## 37            1  53.277449 patient12     dc            end_time  53.277449
    ## 38            1  53.277449 patient12     dc resource_start_time  53.277449
    ## 39            1  54.333373 patient11     dc            end_time  54.333373
    ## 40            1  54.333373 patient11     dc resource_start_time  54.333373
    ## 41            1  56.524218 patient13     dc resource_start_time  56.524218
    ## 42            1  56.694392  patient8     wu            end_time  56.694392
    ## 43            1  57.350783 patient11     dc            end_time  57.350783
    ## 44            1  59.425075 patient14     dc resource_start_time  59.425075
    ## 45            1  60.365185      <NA>   <NA>                <NA>         NA
    ## 46            1  61.458873 patient10     wu            end_time  61.458873
    ## 47            1  61.458873 patient15     dc resource_start_time  61.458873
    ## 48            1  61.458873 patient10     wu resource_start_time  61.458873
    ## 49            1  62.475433  patient4     wu            end_time  62.475433
    ## 50            1  62.475433  patient4     wu resource_start_time  62.475433
    ## 51            1  63.504708 patient12     dc            end_time  63.504708
    ## 52            1  64.039645 patient13     dc            end_time  64.039645
    ## 53            1  64.039645 patient13     dc resource_start_time  64.039645
    ## 54            1  64.478172 patient16     dc resource_start_time  64.478172
    ## 55            1  67.052475 patient13     dc            end_time  67.052475
    ## 56            1  68.021847  patient4     wu            end_time  68.021847
    ## 57            1  69.650671 patient17     dc resource_start_time  69.650671
    ## 58            1  70.223886 patient14     dc            end_time  70.223886
    ## 59            1  70.223886 patient14     dc resource_start_time  70.223886
    ## 60            1  71.707368 patient18     dc resource_start_time  71.707368
    ## 61            1  73.989927 patient10     wu            end_time  73.989927
    ## 62            1  74.381490 patient15     dc            end_time  74.381490
    ## 63            1  74.381490 patient15     dc resource_start_time  74.381490
    ## 64            1  74.423730 patient16     dc            end_time  74.423730
    ## 65            1  74.423730 patient16     dc resource_start_time  74.423730
    ## 66            1  74.446311 patient14     dc            end_time  74.446311
    ## 67            1  79.959784 patient15     dc            end_time  79.959784
    ## 68            1  80.369907 patient16     dc            end_time  80.369907
    ## 69            1  80.422458 patient19     dc resource_start_time  80.422458
    ## 70            1  82.521124 patient19     dc            end_time  82.521124
    ## 71            1  82.521124 patient19     dc resource_start_time  82.521124
    ## 72            1  84.332042 patient20     dc resource_start_time  84.332042
    ## 73            1  84.380499  patient9     wu            end_time  84.380499
    ## 74            1  84.380499  patient9     wu resource_start_time  84.380499
    ## 75            1  85.277240  patient9     wu            end_time  85.277240
    ## 76            1  85.615603 patient19     dc            end_time  85.615603
    ## 77            1  88.755787 patient21     dc resource_start_time  88.755787
    ## 78            1  89.728995 patient17     dc            end_time  89.728995
    ## 79            1  89.728995 patient17     dc resource_start_time  89.728995
    ## 80            1  91.228429 patient21     dc            end_time  91.228429
    ## 81            1  91.228429      <NA>   <NA>                <NA>         NA
    ## 82            1  92.073919 patient20     dc            end_time  92.073919
    ## 83            1  92.073919 patient20     dc resource_start_time  92.073919
    ## 84            1  93.188493 patient22     dc resource_start_time  93.188493
    ## 85            1  96.385241 patient20     dc            end_time  96.385241
    ## 86            1 103.885258 patient18     dc            end_time 103.885258
    ## 87            1 103.885258 patient18     dc resource_start_time 103.885258
    ## 88            1 104.110051 patient23     dc resource_start_time 104.110051
    ## 89            1 104.556807 patient22     dc            end_time 104.556807
    ## 90            1 104.556807      <NA>   <NA>                <NA>         NA
    ## 91            1 105.448863 patient17     dc            end_time 105.448863
    ## 92            1 105.448863 patient22     dc resource_start_time 105.448863
    ## 93            1 107.458077 patient24     dc resource_start_time 107.458077
    ## 94            1 110.313986 patient24     dc            end_time 110.313986
    ## 95            1 110.313986      <NA>   <NA>                <NA>         NA
    ## 96            1 112.018941 patient18     dc            end_time 112.018941
    ## 97            1 112.018941 patient24     dc resource_start_time 112.018941
    ## 98            1 115.906809 patient24     dc            end_time 115.906809
    ## 99            1 119.097626 patient25     dc resource_start_time 119.097626
    ## 100           1 119.305847 patient26     dc resource_start_time 119.305847
    ## 101           1 121.957705 patient23     dc            end_time 121.957705
    ## 102           1 121.957705      <NA>   <NA>                <NA>         NA
    ## 103           1 122.616331 patient25     dc            end_time 122.616331
    ## 104           1 122.616331      <NA>   <NA>                <NA>         NA
    ## 105           1 125.566813      <NA>   <NA>                <NA>         NA
    ## 106           1 127.111587 patient28     dc resource_start_time 127.111587
    ## 107           1 127.451205 patient26     dc            end_time 127.451205
    ## 108           1 127.451205      <NA>   <NA>                <NA>         NA
    ## 109           1 127.704199 patient28     dc            end_time 127.704199
    ## 110           1 127.704199      <NA>   <NA>                <NA>         NA
    ## 111           1 128.573580 patient22     dc            end_time 128.573580

Unfortunately, some resources had no match, which is not allowable, as
they must be associated with a patient, remaining the case even if we
round by more decimal places (unshown).

``` r
matched_data[is.na(matched_data[["name"]]),]
```

    ##     resource      time server queue capacity queue_size system limit
    ## 45     nurse  60.36518      5     1        5        Inf      6   Inf
    ## 81    doctor  91.22843      2     0        3        Inf      2   Inf
    ## 90    doctor 104.55681      3     1        3        Inf      4   Inf
    ## 95    doctor 110.31399      3     1        3        Inf      4   Inf
    ## 102   doctor 121.95770      3     0        3        Inf      3   Inf
    ## 104   doctor 122.61633      3     1        3        Inf      4   Inf
    ## 105    nurse 125.56681      2     0        5        Inf      2   Inf
    ## 108   doctor 127.45121      3     2        3        Inf      5   Inf
    ## 110   doctor 127.70420      3     3        3        Inf      6   Inf
    ##     replication    time_r name period time_type time_value
    ## 45            1  60.36518 <NA>   <NA>      <NA>         NA
    ## 81            1  91.22843 <NA>   <NA>      <NA>         NA
    ## 90            1 104.55681 <NA>   <NA>      <NA>         NA
    ## 95            1 110.31399 <NA>   <NA>      <NA>         NA
    ## 102           1 121.95770 <NA>   <NA>      <NA>         NA
    ## 104           1 122.61633 <NA>   <NA>      <NA>         NA
    ## 105           1 125.56681 <NA>   <NA>      <NA>         NA
    ## 108           1 127.45121 <NA>   <NA>      <NA>         NA
    ## 110           1 127.70420 <NA>   <NA>      <NA>         NA

Looking manually…

#### nurse 60.36518

No match in `arrivals_times`

``` r
arrivals_times %>%
  arrange(time_value) %>%
  filter(time_value > 58 & time_value < 62)
```

    ## # A tibble: 4 × 7
    ##   name      resource replication period time_type        time_value time_value_r
    ##   <chr>     <chr>          <int> <chr>  <chr>                 <dbl>        <dbl>
    ## 1 patient14 nurse              1 dc     resource_start_…       59.4         59.4
    ## 2 patient10 nurse              1 wu     end_time               61.5         61.5
    ## 3 patient10 doctor             1 wu     resource_start_…       61.5         61.5
    ## 4 patient15 nurse              1 dc     resource_start_…       61.5         61.5

Does match in `arrivals` - interestingly, to `start_time` rather than
`resource_start_time`.

``` r
arrivals %>%
  arrange(start_time) %>%
  filter(start_time > 58 & start_time < 62)
```

    ## # A tibble: 3 × 8
    ##   name      start_time end_time activity_time resource replication period
    ##   <chr>          <dbl>    <dbl>         <dbl> <chr>          <int> <chr> 
    ## 1 patient14       59.4     70.2          10.8 nurse              1 dc    
    ## 2 patient15       60.4     74.4          12.9 nurse              1 dc    
    ## 3 patient10       61.5     74.0          12.5 doctor             1 wu    
    ## # ℹ 1 more variable: resource_start_time <dbl>

This is because that entry in resources is about someone joining the
queue, and not about a resource being used.

Can check this by seeing that `patient15` has matches for the
resource_start_time and end_time…

``` r
matched_data[matched_data[["name"]] == "patient15",]
```

    ##      resource     time server queue capacity queue_size system limit
    ## NA       <NA>       NA     NA    NA       NA         NA     NA    NA
    ## 47      nurse 61.45887      5     0        5        Inf      5   Inf
    ## 62      nurse 74.38149      4     0        5        Inf      4   Inf
    ## 63     doctor 74.38149      2     0        3        Inf      2   Inf
    ## 67     doctor 79.95978      1     0        3        Inf      1   Inf
    ## NA.1     <NA>       NA     NA    NA       NA         NA     NA    NA
    ## NA.2     <NA>       NA     NA    NA       NA         NA     NA    NA
    ## NA.3     <NA>       NA     NA    NA       NA         NA     NA    NA
    ## NA.4     <NA>       NA     NA    NA       NA         NA     NA    NA
    ## NA.5     <NA>       NA     NA    NA       NA         NA     NA    NA
    ## NA.6     <NA>       NA     NA    NA       NA         NA     NA    NA
    ## NA.7     <NA>       NA     NA    NA       NA         NA     NA    NA
    ## NA.8     <NA>       NA     NA    NA       NA         NA     NA    NA
    ##      replication   time_r      name period           time_type time_value
    ## NA            NA       NA      <NA>   <NA>                <NA>         NA
    ## 47             1 61.45887 patient15     dc resource_start_time   61.45887
    ## 62             1 74.38149 patient15     dc            end_time   74.38149
    ## 63             1 74.38149 patient15     dc resource_start_time   74.38149
    ## 67             1 79.95978 patient15     dc            end_time   79.95978
    ## NA.1          NA       NA      <NA>   <NA>                <NA>         NA
    ## NA.2          NA       NA      <NA>   <NA>                <NA>         NA
    ## NA.3          NA       NA      <NA>   <NA>                <NA>         NA
    ## NA.4          NA       NA      <NA>   <NA>                <NA>         NA
    ## NA.5          NA       NA      <NA>   <NA>                <NA>         NA
    ## NA.6          NA       NA      <NA>   <NA>                <NA>         NA
    ## NA.7          NA       NA      <NA>   <NA>                <NA>         NA
    ## NA.8          NA       NA      <NA>   <NA>                <NA>         NA

Hence, the **solution** could be:

- To have `start_time` as an additional `time_type` ONLY IF they
  experienced a wait, or-
- To filter `resources` to only contain rows from patients capturing or
  releasing a resource and not joining the queue

BUT: note that my plans could have unintended calculations if I remove
rows (either from approach in general, or from the latter item) that are
required by the calculations.

### Revisiting this approach

These are the patients with mismatch between `resource_start_time` and
`start_time`.

``` r
options(digits = 22)

arrivals %>%
  select(name, resource, start_time, resource_start_time, end_time, replication, period) %>%
  filter(start_time != resource_start_time)
```

    ## # A tibble: 9 × 7
    ##   name      resource start_time resource_start_time end_time replication period
    ##   <chr>     <chr>         <dbl>               <dbl>    <dbl>       <int> <chr> 
    ## 1 patient0  nurse          3.02                3.02     4.48           1 wu    
    ## 2 patient2  doctor        14.9                14.9     28.8            1 wu    
    ## 3 patient5  nurse         23.2                23.2     33.5            1 wu    
    ## 4 patient1  nurse          7.75                7.75    36.7            1 wu    
    ## 5 patient13 nurse         56.5                56.5     64.0            1 dc    
    ## 6 patient15 nurse         60.4                61.5     74.4            1 dc    
    ## 7 patient9  nurse         44.8                44.8     84.4            1 wu    
    ## 8 patient24 doctor       110.                112.     116.             1 dc    
    ## 9 patient22 doctor       105.                105.     129.             1 dc

Those with `resource_start_time` \> `start_time` should indicate they
had to wait, but some of these may just be floating point differences,
such as:

- Those very similar
- Those with a slightly higher `resource_start_time`

``` r
arrivals %>%
  select(name, resource, start_time, resource_start_time, end_time, replication, period) %>%
  filter(start_time > resource_start_time)
```

    ## # A tibble: 3 × 7
    ##   name      resource start_time resource_start_time end_time replication period
    ##   <chr>     <chr>         <dbl>               <dbl>    <dbl>       <int> <chr> 
    ## 1 patient5  nurse         23.2                23.2      33.5           1 wu    
    ## 2 patient1  nurse          7.75                7.75     36.7           1 wu    
    ## 3 patient13 nurse         56.5                56.5      64.0           1 dc

We can investigate this by cross-referencing for the equivalent times in
`resources`.

By manual inspection, we can see that those with very close times were
just floating point issues, as there is only one entry in resources.

For those with the larger gaps (60, 105, 110) they have entries in
resources for start_time and resource_start_time, indicating a wait.

- `patient15` (60, 61, 74)
- `patient22` (104, 105, 128)
- `patient24` (110, 112, 115)

``` r
resources <- get_mon_resources(env)
resources %>%
  arrange(time)
```

    ##     resource                      time server queue capacity queue_size system
    ## 1      nurse   3.020727332513380769541      1     0        5        Inf      1
    ## 2      nurse   4.477794599551309318031      0     0        5        Inf      0
    ## 3     doctor   4.477794599551309318031      1     0        3        Inf      1
    ## 4     doctor   5.875747218236287316984      0     0        3        Inf      0
    ## 5      nurse   7.747298448941805304457      1     0        5        Inf      1
    ## 6      nurse   9.491572952058504597517      2     0        5        Inf      2
    ## 7      nurse  14.409821165718078361806      3     0        5        Inf      3
    ## 8      nurse  14.888401352029632107588      2     0        5        Inf      2
    ## 9     doctor  14.888401352029632107588      1     0        3        Inf      1
    ## 10     nurse  15.880281070757604311439      1     0        5        Inf      1
    ## 11    doctor  15.880281070757604311439      2     0        3        Inf      2
    ## 12     nurse  18.236091140511895503096      2     0        5        Inf      2
    ## 13     nurse  23.186505343451216276662      3     0        5        Inf      3
    ## 14    doctor  23.500579625458339450006      1     0        3        Inf      1
    ## 15     nurse  27.404678012693885591489      4     0        5        Inf      4
    ## 16    doctor  28.795752640133933653033      0     0        3        Inf      0
    ## 17     nurse  33.538944803758624857437      3     0        5        Inf      3
    ## 18    doctor  33.538944803758624857437      1     0        3        Inf      1
    ## 19     nurse  33.952144384833637502652      2     0        5        Inf      2
    ## 20    doctor  33.952144384833637502652      2     0        3        Inf      2
    ## 21     nurse  34.908818702326875893505      3     0        5        Inf      3
    ## 22     nurse  36.696983823582542072472      2     0        5        Inf      2
    ## 23    doctor  36.696983823582542072472      3     0        3        Inf      3
    ## 24    doctor  36.908279567605916327011      2     0        3        Inf      2
    ## 25    doctor  39.638187699981045852837      1     0        3        Inf      1
    ## 26    doctor  39.836941599364045885068      0     0        3        Inf      0
    ## 27     nurse  41.327744584644001690776      1     0        5        Inf      1
    ## 28    doctor  41.327744584644001690776      1     0        3        Inf      1
    ## 29     nurse  44.366879714421457947537      2     0        5        Inf      2
    ## 30     nurse  44.791170207552141846463      3     0        5        Inf      3
    ## 31     nurse  44.961271318375594319150      2     0        5        Inf      2
    ## 32    doctor  44.961271318375594319150      2     0        3        Inf      2
    ## 33    doctor  46.986399830432397095592      1     0        3        Inf      1
    ## 34     nurse  47.106020061067766846463      3     0        5        Inf      3
    ## 35     nurse  51.093271882043140408314      4     0        5        Inf      4
    ## 36     nurse  51.242345987589018818653      5     0        5        Inf      5
    ## 37     nurse  53.277449487904675606842      4     0        5        Inf      4
    ## 38    doctor  53.277449487904675606842      2     0        3        Inf      2
    ## 39     nurse  54.333373410397129532612      3     0        5        Inf      3
    ## 40    doctor  54.333373410397129532612      3     0        3        Inf      3
    ## 41     nurse  56.524217704844183174373      4     0        5        Inf      4
    ## 42    doctor  56.694392376583301995652      2     0        3        Inf      2
    ## 43    doctor  57.350782751806931969440      1     0        3        Inf      1
    ## 44     nurse  59.425074918560738979068      5     0        5        Inf      5
    ## 45     nurse  60.365184722044617160464      5     1        5        Inf      6
    ## 46     nurse  61.458873494798524461658      5     0        5        Inf      5
    ## 47    doctor  61.458873494798524461658      2     0        3        Inf      2
    ## 48     nurse  62.475433317340247185712      4     0        5        Inf      4
    ## 49    doctor  62.475433317340247185712      3     0        3        Inf      3
    ## 50    doctor  63.504708261005177405423      2     0        3        Inf      2
    ## 51     nurse  64.039644622095025283670      3     0        5        Inf      3
    ## 52    doctor  64.039644622095025283670      3     0        3        Inf      3
    ## 53     nurse  64.478172337044668438466      4     0        5        Inf      4
    ## 54    doctor  67.052474585841522980445      2     0        3        Inf      2
    ## 55    doctor  68.021847294039361031537      1     0        3        Inf      1
    ## 56     nurse  69.650670961648472712113      5     0        5        Inf      5
    ## 57     nurse  70.223886290510179719604      4     0        5        Inf      4
    ## 58    doctor  70.223886290510179719604      2     0        3        Inf      2
    ## 59     nurse  71.707368145868429110124      5     0        5        Inf      5
    ## 60    doctor  73.989927039331902847152      1     0        3        Inf      1
    ## 61     nurse  74.381489971540119654492      4     0        5        Inf      4
    ## 62    doctor  74.381489971540119654492      2     0        3        Inf      2
    ## 63     nurse  74.423730217771250750047      3     0        5        Inf      3
    ## 64    doctor  74.423730217771250750047      3     0        3        Inf      3
    ## 65    doctor  74.446310739909293374694      2     0        3        Inf      2
    ## 66    doctor  79.959783520437028414563      1     0        3        Inf      1
    ## 67    doctor  80.369906735526043917162      0     0        3        Inf      0
    ## 68     nurse  80.422458418826550996528      4     0        5        Inf      4
    ## 69     nurse  82.521124224360079324470      3     0        5        Inf      3
    ## 70    doctor  82.521124224360079324470      1     0        3        Inf      1
    ## 71     nurse  84.332041642118582558396      4     0        5        Inf      4
    ## 72     nurse  84.380498729176963479404      3     0        5        Inf      3
    ## 73    doctor  84.380498729176963479404      2     0        3        Inf      2
    ## 74    doctor  85.277239512301008517170      1     0        3        Inf      1
    ## 75    doctor  85.615602785903007543311      0     0        3        Inf      0
    ## 76     nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 77     nurse  89.728994984442493887400      3     0        5        Inf      3
    ## 78    doctor  89.728994984442493887400      1     0        3        Inf      1
    ## 79     nurse  91.228429248731231382408      2     0        5        Inf      2
    ## 80    doctor  91.228429248731231382408      2     0        3        Inf      2
    ## 81     nurse  92.073919283227340315534      1     0        5        Inf      1
    ## 82    doctor  92.073919283227340315534      3     0        3        Inf      3
    ## 83     nurse  93.188493342386152562540      2     0        5        Inf      2
    ## 84    doctor  96.385240605102197264387      2     0        3        Inf      2
    ## 85     nurse 103.885258323348807607545      1     0        5        Inf      1
    ## 86    doctor 103.885258323348807607545      3     0        3        Inf      3
    ## 87     nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 88     nurse 104.556807495089344683947      1     0        5        Inf      1
    ## 89    doctor 104.556807495089344683947      3     1        3        Inf      4
    ## 90    doctor 105.448863449860354535303      3     0        3        Inf      3
    ## 91     nurse 107.458076559658692872290      2     0        5        Inf      2
    ## 92     nurse 110.313986403587804829840      1     0        5        Inf      1
    ## 93    doctor 110.313986403587804829840      3     1        3        Inf      4
    ## 94    doctor 112.018940782983236204018      3     0        3        Inf      3
    ## 95    doctor 115.906808503546301380993      2     0        3        Inf      2
    ## 96     nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 97     nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 98     nurse 121.957704642383561122188      2     0        5        Inf      2
    ## 99    doctor 121.957704642383561122188      3     0        3        Inf      3
    ## 100    nurse 122.616330614384665409489      1     0        5        Inf      1
    ## 101   doctor 122.616330614384665409489      3     1        3        Inf      4
    ## 102    nurse 125.566812808094169895412      2     0        5        Inf      2
    ## 103    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 104    nurse 127.451205490135080822256      2     0        5        Inf      2
    ## 105   doctor 127.451205490135080822256      3     2        3        Inf      5
    ## 106    nurse 127.704199118049814387632      1     0        5        Inf      1
    ## 107   doctor 127.704199118049814387632      3     3        3        Inf      6
    ## 108   doctor 128.573579711864510954911      3     2        3        Inf      5
    ##     limit replication
    ## 1     Inf           1
    ## 2     Inf           1
    ## 3     Inf           1
    ## 4     Inf           1
    ## 5     Inf           1
    ## 6     Inf           1
    ## 7     Inf           1
    ## 8     Inf           1
    ## 9     Inf           1
    ## 10    Inf           1
    ## 11    Inf           1
    ## 12    Inf           1
    ## 13    Inf           1
    ## 14    Inf           1
    ## 15    Inf           1
    ## 16    Inf           1
    ## 17    Inf           1
    ## 18    Inf           1
    ## 19    Inf           1
    ## 20    Inf           1
    ## 21    Inf           1
    ## 22    Inf           1
    ## 23    Inf           1
    ## 24    Inf           1
    ## 25    Inf           1
    ## 26    Inf           1
    ## 27    Inf           1
    ## 28    Inf           1
    ## 29    Inf           1
    ## 30    Inf           1
    ## 31    Inf           1
    ## 32    Inf           1
    ## 33    Inf           1
    ## 34    Inf           1
    ## 35    Inf           1
    ## 36    Inf           1
    ## 37    Inf           1
    ## 38    Inf           1
    ## 39    Inf           1
    ## 40    Inf           1
    ## 41    Inf           1
    ## 42    Inf           1
    ## 43    Inf           1
    ## 44    Inf           1
    ## 45    Inf           1
    ## 46    Inf           1
    ## 47    Inf           1
    ## 48    Inf           1
    ## 49    Inf           1
    ## 50    Inf           1
    ## 51    Inf           1
    ## 52    Inf           1
    ## 53    Inf           1
    ## 54    Inf           1
    ## 55    Inf           1
    ## 56    Inf           1
    ## 57    Inf           1
    ## 58    Inf           1
    ## 59    Inf           1
    ## 60    Inf           1
    ## 61    Inf           1
    ## 62    Inf           1
    ## 63    Inf           1
    ## 64    Inf           1
    ## 65    Inf           1
    ## 66    Inf           1
    ## 67    Inf           1
    ## 68    Inf           1
    ## 69    Inf           1
    ## 70    Inf           1
    ## 71    Inf           1
    ## 72    Inf           1
    ## 73    Inf           1
    ## 74    Inf           1
    ## 75    Inf           1
    ## 76    Inf           1
    ## 77    Inf           1
    ## 78    Inf           1
    ## 79    Inf           1
    ## 80    Inf           1
    ## 81    Inf           1
    ## 82    Inf           1
    ## 83    Inf           1
    ## 84    Inf           1
    ## 85    Inf           1
    ## 86    Inf           1
    ## 87    Inf           1
    ## 88    Inf           1
    ## 89    Inf           1
    ## 90    Inf           1
    ## 91    Inf           1
    ## 92    Inf           1
    ## 93    Inf           1
    ## 94    Inf           1
    ## 95    Inf           1
    ## 96    Inf           1
    ## 97    Inf           1
    ## 98    Inf           1
    ## 99    Inf           1
    ## 100   Inf           1
    ## 101   Inf           1
    ## 102   Inf           1
    ## 103   Inf           1
    ## 104   Inf           1
    ## 105   Inf           1
    ## 106   Inf           1
    ## 107   Inf           1
    ## 108   Inf           1

Our options here are to either:

- Filter arrivals to only include `start_time` if difference after
  rounding —\> issue, if there is a true difference, hidden by rounding
- Match all start, resource start and end times.

Trying option 2 first…

``` r
# Create arrivals dataframe with rows for each patient's resource start and end time
arrivals_times <- arrivals %>%
  select(name, resource, start_time, resource_start_time, end_time, replication, period) %>%
  pivot_longer(cols = c(start_time, resource_start_time, end_time),
               names_to = "time_type",
               values_to = "time_value")

arrivals_times <- arrivals_times %>%
  arrange(time_value)

resources <- resources %>%
  arrange(time)

# Merge the dataframes
matched_data <- left_join(
  resources, arrivals_times,
  by = c("time" = "time_value",
         "resource" = "resource",
         "replication" = "replication")
)
matched_data
```

    ##     resource                      time server queue capacity queue_size system
    ## 1      nurse   3.020727332513380769541      1     0        5        Inf      1
    ## 2      nurse   4.477794599551309318031      0     0        5        Inf      0
    ## 3     doctor   4.477794599551309318031      1     0        3        Inf      1
    ## 4     doctor   4.477794599551309318031      1     0        3        Inf      1
    ## 5     doctor   5.875747218236287316984      0     0        3        Inf      0
    ## 6      nurse   7.747298448941805304457      1     0        5        Inf      1
    ## 7      nurse   9.491572952058504597517      2     0        5        Inf      2
    ## 8      nurse   9.491572952058504597517      2     0        5        Inf      2
    ## 9      nurse  14.409821165718078361806      3     0        5        Inf      3
    ## 10     nurse  14.409821165718078361806      3     0        5        Inf      3
    ## 11     nurse  14.888401352029632107588      2     0        5        Inf      2
    ## 12    doctor  14.888401352029632107588      1     0        3        Inf      1
    ## 13     nurse  15.880281070757604311439      1     0        5        Inf      1
    ## 14    doctor  15.880281070757604311439      2     0        3        Inf      2
    ## 15    doctor  15.880281070757604311439      2     0        3        Inf      2
    ## 16     nurse  18.236091140511895503096      2     0        5        Inf      2
    ## 17     nurse  18.236091140511895503096      2     0        5        Inf      2
    ## 18     nurse  23.186505343451216276662      3     0        5        Inf      3
    ## 19    doctor  23.500579625458339450006      1     0        3        Inf      1
    ## 20     nurse  27.404678012693885591489      4     0        5        Inf      4
    ## 21     nurse  27.404678012693885591489      4     0        5        Inf      4
    ## 22    doctor  28.795752640133933653033      0     0        3        Inf      0
    ## 23     nurse  33.538944803758624857437      3     0        5        Inf      3
    ## 24    doctor  33.538944803758624857437      1     0        3        Inf      1
    ## 25    doctor  33.538944803758624857437      1     0        3        Inf      1
    ## 26     nurse  33.952144384833637502652      2     0        5        Inf      2
    ## 27    doctor  33.952144384833637502652      2     0        3        Inf      2
    ## 28    doctor  33.952144384833637502652      2     0        3        Inf      2
    ## 29     nurse  34.908818702326875893505      3     0        5        Inf      3
    ## 30     nurse  34.908818702326875893505      3     0        5        Inf      3
    ## 31     nurse  36.696983823582542072472      2     0        5        Inf      2
    ## 32    doctor  36.696983823582542072472      3     0        3        Inf      3
    ## 33    doctor  36.696983823582542072472      3     0        3        Inf      3
    ## 34    doctor  36.908279567605916327011      2     0        3        Inf      2
    ## 35    doctor  39.638187699981045852837      1     0        3        Inf      1
    ## 36    doctor  39.836941599364045885068      0     0        3        Inf      0
    ## 37     nurse  41.327744584644001690776      1     0        5        Inf      1
    ## 38    doctor  41.327744584644001690776      1     0        3        Inf      1
    ## 39    doctor  41.327744584644001690776      1     0        3        Inf      1
    ## 40     nurse  44.366879714421457947537      2     0        5        Inf      2
    ## 41     nurse  44.366879714421457947537      2     0        5        Inf      2
    ## 42     nurse  44.791170207552141846463      3     0        5        Inf      3
    ## 43     nurse  44.961271318375594319150      2     0        5        Inf      2
    ## 44    doctor  44.961271318375594319150      2     0        3        Inf      2
    ## 45    doctor  44.961271318375594319150      2     0        3        Inf      2
    ## 46    doctor  46.986399830432397095592      1     0        3        Inf      1
    ## 47     nurse  47.106020061067766846463      3     0        5        Inf      3
    ## 48     nurse  47.106020061067766846463      3     0        5        Inf      3
    ## 49     nurse  51.093271882043140408314      4     0        5        Inf      4
    ## 50     nurse  51.093271882043140408314      4     0        5        Inf      4
    ## 51     nurse  51.242345987589018818653      5     0        5        Inf      5
    ## 52     nurse  51.242345987589018818653      5     0        5        Inf      5
    ## 53     nurse  53.277449487904675606842      4     0        5        Inf      4
    ## 54    doctor  53.277449487904675606842      2     0        3        Inf      2
    ## 55    doctor  53.277449487904675606842      2     0        3        Inf      2
    ## 56     nurse  54.333373410397129532612      3     0        5        Inf      3
    ## 57    doctor  54.333373410397129532612      3     0        3        Inf      3
    ## 58    doctor  54.333373410397129532612      3     0        3        Inf      3
    ## 59     nurse  56.524217704844183174373      4     0        5        Inf      4
    ## 60    doctor  56.694392376583301995652      2     0        3        Inf      2
    ## 61    doctor  57.350782751806931969440      1     0        3        Inf      1
    ## 62     nurse  59.425074918560738979068      5     0        5        Inf      5
    ## 63     nurse  59.425074918560738979068      5     0        5        Inf      5
    ## 64     nurse  60.365184722044617160464      5     1        5        Inf      6
    ## 65     nurse  61.458873494798524461658      5     0        5        Inf      5
    ## 66     nurse  61.458873494798524461658      5     0        5        Inf      5
    ## 67    doctor  61.458873494798524461658      2     0        3        Inf      2
    ## 68    doctor  61.458873494798524461658      2     0        3        Inf      2
    ## 69     nurse  62.475433317340247185712      4     0        5        Inf      4
    ## 70    doctor  62.475433317340247185712      3     0        3        Inf      3
    ## 71    doctor  62.475433317340247185712      3     0        3        Inf      3
    ## 72    doctor  63.504708261005177405423      2     0        3        Inf      2
    ## 73     nurse  64.039644622095025283670      3     0        5        Inf      3
    ## 74    doctor  64.039644622095025283670      3     0        3        Inf      3
    ## 75    doctor  64.039644622095025283670      3     0        3        Inf      3
    ## 76     nurse  64.478172337044668438466      4     0        5        Inf      4
    ## 77     nurse  64.478172337044668438466      4     0        5        Inf      4
    ## 78    doctor  67.052474585841522980445      2     0        3        Inf      2
    ## 79    doctor  68.021847294039361031537      1     0        3        Inf      1
    ## 80     nurse  69.650670961648472712113      5     0        5        Inf      5
    ## 81     nurse  69.650670961648472712113      5     0        5        Inf      5
    ## 82     nurse  70.223886290510179719604      4     0        5        Inf      4
    ## 83    doctor  70.223886290510179719604      2     0        3        Inf      2
    ## 84    doctor  70.223886290510179719604      2     0        3        Inf      2
    ## 85     nurse  71.707368145868429110124      5     0        5        Inf      5
    ## 86     nurse  71.707368145868429110124      5     0        5        Inf      5
    ## 87    doctor  73.989927039331902847152      1     0        3        Inf      1
    ## 88     nurse  74.381489971540119654492      4     0        5        Inf      4
    ## 89    doctor  74.381489971540119654492      2     0        3        Inf      2
    ## 90    doctor  74.381489971540119654492      2     0        3        Inf      2
    ## 91     nurse  74.423730217771250750047      3     0        5        Inf      3
    ## 92    doctor  74.423730217771250750047      3     0        3        Inf      3
    ## 93    doctor  74.423730217771250750047      3     0        3        Inf      3
    ## 94    doctor  74.446310739909293374694      2     0        3        Inf      2
    ## 95    doctor  79.959783520437028414563      1     0        3        Inf      1
    ## 96    doctor  80.369906735526043917162      0     0        3        Inf      0
    ## 97     nurse  80.422458418826550996528      4     0        5        Inf      4
    ## 98     nurse  80.422458418826550996528      4     0        5        Inf      4
    ## 99     nurse  82.521124224360079324470      3     0        5        Inf      3
    ## 100   doctor  82.521124224360079324470      1     0        3        Inf      1
    ## 101   doctor  82.521124224360079324470      1     0        3        Inf      1
    ## 102    nurse  84.332041642118582558396      4     0        5        Inf      4
    ## 103    nurse  84.332041642118582558396      4     0        5        Inf      4
    ## 104    nurse  84.380498729176963479404      3     0        5        Inf      3
    ## 105   doctor  84.380498729176963479404      2     0        3        Inf      2
    ## 106   doctor  84.380498729176963479404      2     0        3        Inf      2
    ## 107   doctor  85.277239512301008517170      1     0        3        Inf      1
    ## 108   doctor  85.615602785903007543311      0     0        3        Inf      0
    ## 109    nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 110    nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 111    nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 112    nurse  89.728994984442493887400      3     0        5        Inf      3
    ## 113   doctor  89.728994984442493887400      1     0        3        Inf      1
    ## 114   doctor  89.728994984442493887400      1     0        3        Inf      1
    ## 115    nurse  91.228429248731231382408      2     0        5        Inf      2
    ## 116   doctor  91.228429248731231382408      2     0        3        Inf      2
    ## 117    nurse  92.073919283227340315534      1     0        5        Inf      1
    ## 118   doctor  92.073919283227340315534      3     0        3        Inf      3
    ## 119   doctor  92.073919283227340315534      3     0        3        Inf      3
    ## 120    nurse  93.188493342386152562540      2     0        5        Inf      2
    ## 121    nurse  93.188493342386152562540      2     0        5        Inf      2
    ## 122   doctor  96.385240605102197264387      2     0        3        Inf      2
    ## 123    nurse 103.885258323348807607545      1     0        5        Inf      1
    ## 124   doctor 103.885258323348807607545      3     0        3        Inf      3
    ## 125   doctor 103.885258323348807607545      3     0        3        Inf      3
    ## 126    nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 127    nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 128    nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 129    nurse 104.556807495089344683947      1     0        5        Inf      1
    ## 130   doctor 104.556807495089344683947      3     1        3        Inf      4
    ## 131   doctor 105.448863449860354535303      3     0        3        Inf      3
    ## 132    nurse 107.458076559658692872290      2     0        5        Inf      2
    ## 133    nurse 107.458076559658692872290      2     0        5        Inf      2
    ## 134    nurse 110.313986403587804829840      1     0        5        Inf      1
    ## 135   doctor 110.313986403587804829840      3     1        3        Inf      4
    ## 136   doctor 112.018940782983236204018      3     0        3        Inf      3
    ## 137   doctor 112.018940782983236204018      3     0        3        Inf      3
    ## 138   doctor 115.906808503546301380993      2     0        3        Inf      2
    ## 139    nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 140    nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 141    nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 142    nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 143    nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 144    nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 145    nurse 121.957704642383561122188      2     0        5        Inf      2
    ## 146   doctor 121.957704642383561122188      3     0        3        Inf      3
    ## 147    nurse 122.616330614384665409489      1     0        5        Inf      1
    ## 148   doctor 122.616330614384665409489      3     1        3        Inf      4
    ## 149    nurse 125.566812808094169895412      2     0        5        Inf      2
    ## 150    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 151    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 152    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 153    nurse 127.451205490135080822256      2     0        5        Inf      2
    ## 154   doctor 127.451205490135080822256      3     2        3        Inf      5
    ## 155    nurse 127.704199118049814387632      1     0        5        Inf      1
    ## 156   doctor 127.704199118049814387632      3     3        3        Inf      6
    ## 157   doctor 128.573579711864510954911      3     2        3        Inf      5
    ##     limit replication      name period           time_type
    ## 1     Inf           1  patient0     wu          start_time
    ## 2     Inf           1  patient0     wu            end_time
    ## 3     Inf           1  patient0     wu          start_time
    ## 4     Inf           1  patient0     wu resource_start_time
    ## 5     Inf           1  patient0     wu            end_time
    ## 6     Inf           1  patient1     wu          start_time
    ## 7     Inf           1  patient2     wu          start_time
    ## 8     Inf           1  patient2     wu resource_start_time
    ## 9     Inf           1  patient3     wu          start_time
    ## 10    Inf           1  patient3     wu resource_start_time
    ## 11    Inf           1  patient2     wu            end_time
    ## 12    Inf           1  patient2     wu          start_time
    ## 13    Inf           1  patient3     wu            end_time
    ## 14    Inf           1  patient3     wu          start_time
    ## 15    Inf           1  patient3     wu resource_start_time
    ## 16    Inf           1  patient4     wu          start_time
    ## 17    Inf           1  patient4     wu resource_start_time
    ## 18    Inf           1  patient5     wu          start_time
    ## 19    Inf           1  patient3     wu            end_time
    ## 20    Inf           1  patient6     wu          start_time
    ## 21    Inf           1  patient6     wu resource_start_time
    ## 22    Inf           1  patient2     wu            end_time
    ## 23    Inf           1  patient5     wu            end_time
    ## 24    Inf           1  patient5     wu          start_time
    ## 25    Inf           1  patient5     wu resource_start_time
    ## 26    Inf           1  patient6     wu            end_time
    ## 27    Inf           1  patient6     wu          start_time
    ## 28    Inf           1  patient6     wu resource_start_time
    ## 29    Inf           1  patient7     wu          start_time
    ## 30    Inf           1  patient7     wu resource_start_time
    ## 31    Inf           1  patient1     wu            end_time
    ## 32    Inf           1  patient1     wu          start_time
    ## 33    Inf           1  patient1     wu resource_start_time
    ## 34    Inf           1  patient5     wu            end_time
    ## 35    Inf           1  patient1     wu            end_time
    ## 36    Inf           1  patient6     wu            end_time
    ## 37    Inf           1  patient7     wu            end_time
    ## 38    Inf           1  patient7     wu          start_time
    ## 39    Inf           1  patient7     wu resource_start_time
    ## 40    Inf           1  patient8     wu          start_time
    ## 41    Inf           1  patient8     wu resource_start_time
    ## 42    Inf           1  patient9     wu          start_time
    ## 43    Inf           1  patient8     wu            end_time
    ## 44    Inf           1  patient8     wu          start_time
    ## 45    Inf           1  patient8     wu resource_start_time
    ## 46    Inf           1  patient7     wu            end_time
    ## 47    Inf           1 patient10     wu          start_time
    ## 48    Inf           1 patient10     wu resource_start_time
    ## 49    Inf           1 patient11     dc          start_time
    ## 50    Inf           1 patient11     dc resource_start_time
    ## 51    Inf           1 patient12     dc          start_time
    ## 52    Inf           1 patient12     dc resource_start_time
    ## 53    Inf           1 patient12     dc            end_time
    ## 54    Inf           1 patient12     dc          start_time
    ## 55    Inf           1 patient12     dc resource_start_time
    ## 56    Inf           1 patient11     dc            end_time
    ## 57    Inf           1 patient11     dc          start_time
    ## 58    Inf           1 patient11     dc resource_start_time
    ## 59    Inf           1 patient13     dc          start_time
    ## 60    Inf           1  patient8     wu            end_time
    ## 61    Inf           1 patient11     dc            end_time
    ## 62    Inf           1 patient14     dc          start_time
    ## 63    Inf           1 patient14     dc resource_start_time
    ## 64    Inf           1 patient15     dc          start_time
    ## 65    Inf           1 patient10     wu            end_time
    ## 66    Inf           1 patient15     dc resource_start_time
    ## 67    Inf           1 patient10     wu          start_time
    ## 68    Inf           1 patient10     wu resource_start_time
    ## 69    Inf           1  patient4     wu            end_time
    ## 70    Inf           1  patient4     wu          start_time
    ## 71    Inf           1  patient4     wu resource_start_time
    ## 72    Inf           1 patient12     dc            end_time
    ## 73    Inf           1 patient13     dc            end_time
    ## 74    Inf           1 patient13     dc          start_time
    ## 75    Inf           1 patient13     dc resource_start_time
    ## 76    Inf           1 patient16     dc          start_time
    ## 77    Inf           1 patient16     dc resource_start_time
    ## 78    Inf           1 patient13     dc            end_time
    ## 79    Inf           1  patient4     wu            end_time
    ## 80    Inf           1 patient17     dc          start_time
    ## 81    Inf           1 patient17     dc resource_start_time
    ## 82    Inf           1 patient14     dc            end_time
    ## 83    Inf           1 patient14     dc          start_time
    ## 84    Inf           1 patient14     dc resource_start_time
    ## 85    Inf           1 patient18     dc          start_time
    ## 86    Inf           1 patient18     dc resource_start_time
    ## 87    Inf           1 patient10     wu            end_time
    ## 88    Inf           1 patient15     dc            end_time
    ## 89    Inf           1 patient15     dc          start_time
    ## 90    Inf           1 patient15     dc resource_start_time
    ## 91    Inf           1 patient16     dc            end_time
    ## 92    Inf           1 patient16     dc          start_time
    ## 93    Inf           1 patient16     dc resource_start_time
    ## 94    Inf           1 patient14     dc            end_time
    ## 95    Inf           1 patient15     dc            end_time
    ## 96    Inf           1 patient16     dc            end_time
    ## 97    Inf           1 patient19     dc          start_time
    ## 98    Inf           1 patient19     dc resource_start_time
    ## 99    Inf           1 patient19     dc            end_time
    ## 100   Inf           1 patient19     dc          start_time
    ## 101   Inf           1 patient19     dc resource_start_time
    ## 102   Inf           1 patient20     dc          start_time
    ## 103   Inf           1 patient20     dc resource_start_time
    ## 104   Inf           1  patient9     wu            end_time
    ## 105   Inf           1  patient9     wu          start_time
    ## 106   Inf           1  patient9     wu resource_start_time
    ## 107   Inf           1  patient9     wu            end_time
    ## 108   Inf           1 patient19     dc            end_time
    ## 109   Inf           1 patient21     dc          start_time
    ## 110   Inf           1 patient21     dc resource_start_time
    ## 111   Inf           1 patient21     dc          start_time
    ## 112   Inf           1 patient17     dc            end_time
    ## 113   Inf           1 patient17     dc          start_time
    ## 114   Inf           1 patient17     dc resource_start_time
    ## 115   Inf           1 patient21     dc            end_time
    ## 116   Inf           1 patient21     dc          start_time
    ## 117   Inf           1 patient20     dc            end_time
    ## 118   Inf           1 patient20     dc          start_time
    ## 119   Inf           1 patient20     dc resource_start_time
    ## 120   Inf           1 patient22     dc          start_time
    ## 121   Inf           1 patient22     dc resource_start_time
    ## 122   Inf           1 patient20     dc            end_time
    ## 123   Inf           1 patient18     dc            end_time
    ## 124   Inf           1 patient18     dc          start_time
    ## 125   Inf           1 patient18     dc resource_start_time
    ## 126   Inf           1 patient23     dc          start_time
    ## 127   Inf           1 patient23     dc resource_start_time
    ## 128   Inf           1 patient23     dc          start_time
    ## 129   Inf           1 patient22     dc            end_time
    ## 130   Inf           1 patient22     dc          start_time
    ## 131   Inf           1 patient17     dc            end_time
    ## 132   Inf           1 patient24     dc          start_time
    ## 133   Inf           1 patient24     dc resource_start_time
    ## 134   Inf           1 patient24     dc            end_time
    ## 135   Inf           1 patient24     dc          start_time
    ## 136   Inf           1 patient18     dc            end_time
    ## 137   Inf           1 patient24     dc resource_start_time
    ## 138   Inf           1 patient24     dc            end_time
    ## 139   Inf           1 patient25     dc          start_time
    ## 140   Inf           1 patient25     dc resource_start_time
    ## 141   Inf           1 patient25     dc          start_time
    ## 142   Inf           1 patient26     dc          start_time
    ## 143   Inf           1 patient26     dc resource_start_time
    ## 144   Inf           1 patient26     dc          start_time
    ## 145   Inf           1 patient23     dc            end_time
    ## 146   Inf           1 patient23     dc          start_time
    ## 147   Inf           1 patient25     dc            end_time
    ## 148   Inf           1 patient25     dc          start_time
    ## 149   Inf           1 patient27     dc          start_time
    ## 150   Inf           1 patient28     dc          start_time
    ## 151   Inf           1 patient28     dc resource_start_time
    ## 152   Inf           1 patient28     dc          start_time
    ## 153   Inf           1 patient26     dc            end_time
    ## 154   Inf           1 patient26     dc          start_time
    ## 155   Inf           1 patient28     dc            end_time
    ## 156   Inf           1 patient28     dc          start_time
    ## 157   Inf           1 patient22     dc            end_time

No mismatch!

``` r
matched_data[is.na(matched_data[["name"]]),]
```

    ##  [1] resource    time        server      queue       capacity    queue_size 
    ##  [7] system      limit       replication name        period      time_type  
    ## <0 rows> (or 0-length row.names)

However, we have added duplicate rows, where `start_time` and
`resource_start_time` are the same…

``` r
dim(resources)
```

    ## [1] 108   9

``` r
dim(matched_data)
```

    ## [1] 157  12

This could be addressed by removing duplicates…

``` r
# Remove resource_start_time in cases where it duplicates start_time
arrivals_times_clean <- arrivals_times %>%
  group_by(name, resource, replication, period, time_value) %>%
  filter(!(n() > 1 & any(time_type == "start_time") & time_type == "resource_start_time")) %>%
  ungroup()

# Merge the dataframes
matched_data2 <- left_join(
  resources, arrivals_times_clean,
  by = c("time" = "time_value",
         "resource" = "resource",
         "replication" = "replication")
)
matched_data2
```

    ##     resource                      time server queue capacity queue_size system
    ## 1      nurse   3.020727332513380769541      1     0        5        Inf      1
    ## 2      nurse   4.477794599551309318031      0     0        5        Inf      0
    ## 3     doctor   4.477794599551309318031      1     0        3        Inf      1
    ## 4     doctor   5.875747218236287316984      0     0        3        Inf      0
    ## 5      nurse   7.747298448941805304457      1     0        5        Inf      1
    ## 6      nurse   9.491572952058504597517      2     0        5        Inf      2
    ## 7      nurse  14.409821165718078361806      3     0        5        Inf      3
    ## 8      nurse  14.888401352029632107588      2     0        5        Inf      2
    ## 9     doctor  14.888401352029632107588      1     0        3        Inf      1
    ## 10     nurse  15.880281070757604311439      1     0        5        Inf      1
    ## 11    doctor  15.880281070757604311439      2     0        3        Inf      2
    ## 12     nurse  18.236091140511895503096      2     0        5        Inf      2
    ## 13     nurse  23.186505343451216276662      3     0        5        Inf      3
    ## 14    doctor  23.500579625458339450006      1     0        3        Inf      1
    ## 15     nurse  27.404678012693885591489      4     0        5        Inf      4
    ## 16    doctor  28.795752640133933653033      0     0        3        Inf      0
    ## 17     nurse  33.538944803758624857437      3     0        5        Inf      3
    ## 18    doctor  33.538944803758624857437      1     0        3        Inf      1
    ## 19     nurse  33.952144384833637502652      2     0        5        Inf      2
    ## 20    doctor  33.952144384833637502652      2     0        3        Inf      2
    ## 21     nurse  34.908818702326875893505      3     0        5        Inf      3
    ## 22     nurse  36.696983823582542072472      2     0        5        Inf      2
    ## 23    doctor  36.696983823582542072472      3     0        3        Inf      3
    ## 24    doctor  36.908279567605916327011      2     0        3        Inf      2
    ## 25    doctor  39.638187699981045852837      1     0        3        Inf      1
    ## 26    doctor  39.836941599364045885068      0     0        3        Inf      0
    ## 27     nurse  41.327744584644001690776      1     0        5        Inf      1
    ## 28    doctor  41.327744584644001690776      1     0        3        Inf      1
    ## 29     nurse  44.366879714421457947537      2     0        5        Inf      2
    ## 30     nurse  44.791170207552141846463      3     0        5        Inf      3
    ## 31     nurse  44.961271318375594319150      2     0        5        Inf      2
    ## 32    doctor  44.961271318375594319150      2     0        3        Inf      2
    ## 33    doctor  46.986399830432397095592      1     0        3        Inf      1
    ## 34     nurse  47.106020061067766846463      3     0        5        Inf      3
    ## 35     nurse  51.093271882043140408314      4     0        5        Inf      4
    ## 36     nurse  51.242345987589018818653      5     0        5        Inf      5
    ## 37     nurse  53.277449487904675606842      4     0        5        Inf      4
    ## 38    doctor  53.277449487904675606842      2     0        3        Inf      2
    ## 39     nurse  54.333373410397129532612      3     0        5        Inf      3
    ## 40    doctor  54.333373410397129532612      3     0        3        Inf      3
    ## 41     nurse  56.524217704844183174373      4     0        5        Inf      4
    ## 42    doctor  56.694392376583301995652      2     0        3        Inf      2
    ## 43    doctor  57.350782751806931969440      1     0        3        Inf      1
    ## 44     nurse  59.425074918560738979068      5     0        5        Inf      5
    ## 45     nurse  60.365184722044617160464      5     1        5        Inf      6
    ## 46     nurse  61.458873494798524461658      5     0        5        Inf      5
    ## 47     nurse  61.458873494798524461658      5     0        5        Inf      5
    ## 48    doctor  61.458873494798524461658      2     0        3        Inf      2
    ## 49     nurse  62.475433317340247185712      4     0        5        Inf      4
    ## 50    doctor  62.475433317340247185712      3     0        3        Inf      3
    ## 51    doctor  63.504708261005177405423      2     0        3        Inf      2
    ## 52     nurse  64.039644622095025283670      3     0        5        Inf      3
    ## 53    doctor  64.039644622095025283670      3     0        3        Inf      3
    ## 54     nurse  64.478172337044668438466      4     0        5        Inf      4
    ## 55    doctor  67.052474585841522980445      2     0        3        Inf      2
    ## 56    doctor  68.021847294039361031537      1     0        3        Inf      1
    ## 57     nurse  69.650670961648472712113      5     0        5        Inf      5
    ## 58     nurse  70.223886290510179719604      4     0        5        Inf      4
    ## 59    doctor  70.223886290510179719604      2     0        3        Inf      2
    ## 60     nurse  71.707368145868429110124      5     0        5        Inf      5
    ## 61    doctor  73.989927039331902847152      1     0        3        Inf      1
    ## 62     nurse  74.381489971540119654492      4     0        5        Inf      4
    ## 63    doctor  74.381489971540119654492      2     0        3        Inf      2
    ## 64     nurse  74.423730217771250750047      3     0        5        Inf      3
    ## 65    doctor  74.423730217771250750047      3     0        3        Inf      3
    ## 66    doctor  74.446310739909293374694      2     0        3        Inf      2
    ## 67    doctor  79.959783520437028414563      1     0        3        Inf      1
    ## 68    doctor  80.369906735526043917162      0     0        3        Inf      0
    ## 69     nurse  80.422458418826550996528      4     0        5        Inf      4
    ## 70     nurse  82.521124224360079324470      3     0        5        Inf      3
    ## 71    doctor  82.521124224360079324470      1     0        3        Inf      1
    ## 72     nurse  84.332041642118582558396      4     0        5        Inf      4
    ## 73     nurse  84.380498729176963479404      3     0        5        Inf      3
    ## 74    doctor  84.380498729176963479404      2     0        3        Inf      2
    ## 75    doctor  85.277239512301008517170      1     0        3        Inf      1
    ## 76    doctor  85.615602785903007543311      0     0        3        Inf      0
    ## 77     nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 78     nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 79     nurse  89.728994984442493887400      3     0        5        Inf      3
    ## 80    doctor  89.728994984442493887400      1     0        3        Inf      1
    ## 81     nurse  91.228429248731231382408      2     0        5        Inf      2
    ## 82    doctor  91.228429248731231382408      2     0        3        Inf      2
    ## 83     nurse  92.073919283227340315534      1     0        5        Inf      1
    ## 84    doctor  92.073919283227340315534      3     0        3        Inf      3
    ## 85     nurse  93.188493342386152562540      2     0        5        Inf      2
    ## 86    doctor  96.385240605102197264387      2     0        3        Inf      2
    ## 87     nurse 103.885258323348807607545      1     0        5        Inf      1
    ## 88    doctor 103.885258323348807607545      3     0        3        Inf      3
    ## 89     nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 90     nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 91     nurse 104.556807495089344683947      1     0        5        Inf      1
    ## 92    doctor 104.556807495089344683947      3     1        3        Inf      4
    ## 93    doctor 105.448863449860354535303      3     0        3        Inf      3
    ## 94     nurse 107.458076559658692872290      2     0        5        Inf      2
    ## 95     nurse 110.313986403587804829840      1     0        5        Inf      1
    ## 96    doctor 110.313986403587804829840      3     1        3        Inf      4
    ## 97    doctor 112.018940782983236204018      3     0        3        Inf      3
    ## 98    doctor 112.018940782983236204018      3     0        3        Inf      3
    ## 99    doctor 115.906808503546301380993      2     0        3        Inf      2
    ## 100    nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 101    nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 102    nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 103    nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 104    nurse 121.957704642383561122188      2     0        5        Inf      2
    ## 105   doctor 121.957704642383561122188      3     0        3        Inf      3
    ## 106    nurse 122.616330614384665409489      1     0        5        Inf      1
    ## 107   doctor 122.616330614384665409489      3     1        3        Inf      4
    ## 108    nurse 125.566812808094169895412      2     0        5        Inf      2
    ## 109    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 110    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 111    nurse 127.451205490135080822256      2     0        5        Inf      2
    ## 112   doctor 127.451205490135080822256      3     2        3        Inf      5
    ## 113    nurse 127.704199118049814387632      1     0        5        Inf      1
    ## 114   doctor 127.704199118049814387632      3     3        3        Inf      6
    ## 115   doctor 128.573579711864510954911      3     2        3        Inf      5
    ##     limit replication      name period           time_type
    ## 1     Inf           1  patient0     wu          start_time
    ## 2     Inf           1  patient0     wu            end_time
    ## 3     Inf           1  patient0     wu          start_time
    ## 4     Inf           1  patient0     wu            end_time
    ## 5     Inf           1  patient1     wu          start_time
    ## 6     Inf           1  patient2     wu          start_time
    ## 7     Inf           1  patient3     wu          start_time
    ## 8     Inf           1  patient2     wu            end_time
    ## 9     Inf           1  patient2     wu          start_time
    ## 10    Inf           1  patient3     wu            end_time
    ## 11    Inf           1  patient3     wu          start_time
    ## 12    Inf           1  patient4     wu          start_time
    ## 13    Inf           1  patient5     wu          start_time
    ## 14    Inf           1  patient3     wu            end_time
    ## 15    Inf           1  patient6     wu          start_time
    ## 16    Inf           1  patient2     wu            end_time
    ## 17    Inf           1  patient5     wu            end_time
    ## 18    Inf           1  patient5     wu          start_time
    ## 19    Inf           1  patient6     wu            end_time
    ## 20    Inf           1  patient6     wu          start_time
    ## 21    Inf           1  patient7     wu          start_time
    ## 22    Inf           1  patient1     wu            end_time
    ## 23    Inf           1  patient1     wu          start_time
    ## 24    Inf           1  patient5     wu            end_time
    ## 25    Inf           1  patient1     wu            end_time
    ## 26    Inf           1  patient6     wu            end_time
    ## 27    Inf           1  patient7     wu            end_time
    ## 28    Inf           1  patient7     wu          start_time
    ## 29    Inf           1  patient8     wu          start_time
    ## 30    Inf           1  patient9     wu          start_time
    ## 31    Inf           1  patient8     wu            end_time
    ## 32    Inf           1  patient8     wu          start_time
    ## 33    Inf           1  patient7     wu            end_time
    ## 34    Inf           1 patient10     wu          start_time
    ## 35    Inf           1 patient11     dc          start_time
    ## 36    Inf           1 patient12     dc          start_time
    ## 37    Inf           1 patient12     dc            end_time
    ## 38    Inf           1 patient12     dc          start_time
    ## 39    Inf           1 patient11     dc            end_time
    ## 40    Inf           1 patient11     dc          start_time
    ## 41    Inf           1 patient13     dc          start_time
    ## 42    Inf           1  patient8     wu            end_time
    ## 43    Inf           1 patient11     dc            end_time
    ## 44    Inf           1 patient14     dc          start_time
    ## 45    Inf           1 patient15     dc          start_time
    ## 46    Inf           1 patient10     wu            end_time
    ## 47    Inf           1 patient15     dc resource_start_time
    ## 48    Inf           1 patient10     wu          start_time
    ## 49    Inf           1  patient4     wu            end_time
    ## 50    Inf           1  patient4     wu          start_time
    ## 51    Inf           1 patient12     dc            end_time
    ## 52    Inf           1 patient13     dc            end_time
    ## 53    Inf           1 patient13     dc          start_time
    ## 54    Inf           1 patient16     dc          start_time
    ## 55    Inf           1 patient13     dc            end_time
    ## 56    Inf           1  patient4     wu            end_time
    ## 57    Inf           1 patient17     dc          start_time
    ## 58    Inf           1 patient14     dc            end_time
    ## 59    Inf           1 patient14     dc          start_time
    ## 60    Inf           1 patient18     dc          start_time
    ## 61    Inf           1 patient10     wu            end_time
    ## 62    Inf           1 patient15     dc            end_time
    ## 63    Inf           1 patient15     dc          start_time
    ## 64    Inf           1 patient16     dc            end_time
    ## 65    Inf           1 patient16     dc          start_time
    ## 66    Inf           1 patient14     dc            end_time
    ## 67    Inf           1 patient15     dc            end_time
    ## 68    Inf           1 patient16     dc            end_time
    ## 69    Inf           1 patient19     dc          start_time
    ## 70    Inf           1 patient19     dc            end_time
    ## 71    Inf           1 patient19     dc          start_time
    ## 72    Inf           1 patient20     dc          start_time
    ## 73    Inf           1  patient9     wu            end_time
    ## 74    Inf           1  patient9     wu          start_time
    ## 75    Inf           1  patient9     wu            end_time
    ## 76    Inf           1 patient19     dc            end_time
    ## 77    Inf           1 patient21     dc          start_time
    ## 78    Inf           1 patient21     dc          start_time
    ## 79    Inf           1 patient17     dc            end_time
    ## 80    Inf           1 patient17     dc          start_time
    ## 81    Inf           1 patient21     dc            end_time
    ## 82    Inf           1 patient21     dc          start_time
    ## 83    Inf           1 patient20     dc            end_time
    ## 84    Inf           1 patient20     dc          start_time
    ## 85    Inf           1 patient22     dc          start_time
    ## 86    Inf           1 patient20     dc            end_time
    ## 87    Inf           1 patient18     dc            end_time
    ## 88    Inf           1 patient18     dc          start_time
    ## 89    Inf           1 patient23     dc          start_time
    ## 90    Inf           1 patient23     dc          start_time
    ## 91    Inf           1 patient22     dc            end_time
    ## 92    Inf           1 patient22     dc          start_time
    ## 93    Inf           1 patient17     dc            end_time
    ## 94    Inf           1 patient24     dc          start_time
    ## 95    Inf           1 patient24     dc            end_time
    ## 96    Inf           1 patient24     dc          start_time
    ## 97    Inf           1 patient18     dc            end_time
    ## 98    Inf           1 patient24     dc resource_start_time
    ## 99    Inf           1 patient24     dc            end_time
    ## 100   Inf           1 patient25     dc          start_time
    ## 101   Inf           1 patient25     dc          start_time
    ## 102   Inf           1 patient26     dc          start_time
    ## 103   Inf           1 patient26     dc          start_time
    ## 104   Inf           1 patient23     dc            end_time
    ## 105   Inf           1 patient23     dc          start_time
    ## 106   Inf           1 patient25     dc            end_time
    ## 107   Inf           1 patient25     dc          start_time
    ## 108   Inf           1 patient27     dc          start_time
    ## 109   Inf           1 patient28     dc          start_time
    ## 110   Inf           1 patient28     dc          start_time
    ## 111   Inf           1 patient26     dc            end_time
    ## 112   Inf           1 patient26     dc          start_time
    ## 113   Inf           1 patient28     dc            end_time
    ## 114   Inf           1 patient28     dc          start_time
    ## 115   Inf           1 patient22     dc            end_time

Now less rows, but still 7 more than before! We need to identify which
patients have surplus rows. By filtering to those with 5 + rows, we see
the surplus is for patients who had a wait:

- `patient15` (60, 61, 74)
- `patient22` (104, 105, 128)
- `patient24` (110, 112, 115)

HOWEVER it does not include patient22.

``` r
matched_data2 %>%
  group_by(name) %>%
  filter(n() > 4) %>%
  ungroup()
```

    ## # A tibble: 10 × 12
    ##    resource  time server queue capacity queue_size system limit replication
    ##    <chr>    <dbl>  <int> <int>    <dbl>      <dbl>  <int> <dbl>       <int>
    ##  1 nurse     60.4      5     1        5        Inf      6   Inf           1
    ##  2 nurse     61.5      5     0        5        Inf      5   Inf           1
    ##  3 nurse     74.4      4     0        5        Inf      4   Inf           1
    ##  4 doctor    74.4      2     0        3        Inf      2   Inf           1
    ##  5 doctor    80.0      1     0        3        Inf      1   Inf           1
    ##  6 nurse    107.       2     0        5        Inf      2   Inf           1
    ##  7 nurse    110.       1     0        5        Inf      1   Inf           1
    ##  8 doctor   110.       3     1        3        Inf      4   Inf           1
    ##  9 doctor   112.       3     0        3        Inf      3   Inf           1
    ## 10 doctor   116.       2     0        3        Inf      2   Inf           1
    ## # ℹ 3 more variables: name <chr>, period <chr>, time_type <chr>

For `patient22`’s doctors appointment, it has matched for when they
joined the queue, but not for when they started the appointment.

``` r
matched_data2 %>%
  filter(name == "patient22")
```

    ##   resource                     time server queue capacity queue_size system
    ## 1    nurse  93.18849334238615256254      2     0        5        Inf      2
    ## 2    nurse 104.55680749508934468395      1     0        5        Inf      1
    ## 3   doctor 104.55680749508934468395      3     1        3        Inf      4
    ## 4   doctor 128.57357971186451095491      3     2        3        Inf      5
    ##   limit replication      name period  time_type
    ## 1   Inf           1 patient22     dc start_time
    ## 2   Inf           1 patient22     dc   end_time
    ## 3   Inf           1 patient22     dc start_time
    ## 4   Inf           1 patient22     dc   end_time

Filtering for NA’s though, we don’t see anything.

Instead, lets look for times around the expect time of the appointment.
As a reminder:

    patient22   doctor  104.556807495089344683947   105.448863449860368746158   128.573579711864510954911   1   dc

We see a match, for patient17’s end time.

``` r
matched_data2 %>%
  filter(time > 104 & time < 106)
```

    ##   resource                    time server queue capacity queue_size system
    ## 1    nurse 104.1100505969713196919      2     0        5        Inf      2
    ## 2    nurse 104.1100505969713196919      2     0        5        Inf      2
    ## 3    nurse 104.5568074950893446839      1     0        5        Inf      1
    ## 4   doctor 104.5568074950893446839      3     1        3        Inf      4
    ## 5   doctor 105.4488634498603545353      3     0        3        Inf      3
    ##   limit replication      name period  time_type
    ## 1   Inf           1 patient23     dc start_time
    ## 2   Inf           1 patient23     dc start_time
    ## 3   Inf           1 patient22     dc   end_time
    ## 4   Inf           1 patient22     dc start_time
    ## 5   Inf           1 patient17     dc   end_time

``` r
get_mon_resources(env) %>%
  filter(time > 104 & time < 107)
```

    ##   resource                    time server queue capacity queue_size system
    ## 1    nurse 104.1100505969713196919      2     0        5        Inf      2
    ## 2    nurse 104.5568074950893446839      1     0        5        Inf      1
    ## 3   doctor 104.5568074950893446839      3     1        3        Inf      4
    ## 4   doctor 105.4488634498603545353      3     0        3        Inf      3
    ##   limit replication
    ## 1   Inf           1
    ## 2   Inf           1
    ## 3   Inf           1
    ## 4   Inf           1

### Matching without end_time

``` r
# Remove end times
arrivals_start_times_clean <- arrivals_times_clean %>%
  filter(time_type != "end_time")

# Merge the dataframes
matched_data3 <- left_join(
  resources, arrivals_start_times_clean,
  by = c("time" = "time_value",
         "resource" = "resource",
         "replication" = "replication")
)
matched_data3
```

    ##     resource                      time server queue capacity queue_size system
    ## 1      nurse   3.020727332513380769541      1     0        5        Inf      1
    ## 2      nurse   4.477794599551309318031      0     0        5        Inf      0
    ## 3     doctor   4.477794599551309318031      1     0        3        Inf      1
    ## 4     doctor   5.875747218236287316984      0     0        3        Inf      0
    ## 5      nurse   7.747298448941805304457      1     0        5        Inf      1
    ## 6      nurse   9.491572952058504597517      2     0        5        Inf      2
    ## 7      nurse  14.409821165718078361806      3     0        5        Inf      3
    ## 8      nurse  14.888401352029632107588      2     0        5        Inf      2
    ## 9     doctor  14.888401352029632107588      1     0        3        Inf      1
    ## 10     nurse  15.880281070757604311439      1     0        5        Inf      1
    ## 11    doctor  15.880281070757604311439      2     0        3        Inf      2
    ## 12     nurse  18.236091140511895503096      2     0        5        Inf      2
    ## 13     nurse  23.186505343451216276662      3     0        5        Inf      3
    ## 14    doctor  23.500579625458339450006      1     0        3        Inf      1
    ## 15     nurse  27.404678012693885591489      4     0        5        Inf      4
    ## 16    doctor  28.795752640133933653033      0     0        3        Inf      0
    ## 17     nurse  33.538944803758624857437      3     0        5        Inf      3
    ## 18    doctor  33.538944803758624857437      1     0        3        Inf      1
    ## 19     nurse  33.952144384833637502652      2     0        5        Inf      2
    ## 20    doctor  33.952144384833637502652      2     0        3        Inf      2
    ## 21     nurse  34.908818702326875893505      3     0        5        Inf      3
    ## 22     nurse  36.696983823582542072472      2     0        5        Inf      2
    ## 23    doctor  36.696983823582542072472      3     0        3        Inf      3
    ## 24    doctor  36.908279567605916327011      2     0        3        Inf      2
    ## 25    doctor  39.638187699981045852837      1     0        3        Inf      1
    ## 26    doctor  39.836941599364045885068      0     0        3        Inf      0
    ## 27     nurse  41.327744584644001690776      1     0        5        Inf      1
    ## 28    doctor  41.327744584644001690776      1     0        3        Inf      1
    ## 29     nurse  44.366879714421457947537      2     0        5        Inf      2
    ## 30     nurse  44.791170207552141846463      3     0        5        Inf      3
    ## 31     nurse  44.961271318375594319150      2     0        5        Inf      2
    ## 32    doctor  44.961271318375594319150      2     0        3        Inf      2
    ## 33    doctor  46.986399830432397095592      1     0        3        Inf      1
    ## 34     nurse  47.106020061067766846463      3     0        5        Inf      3
    ## 35     nurse  51.093271882043140408314      4     0        5        Inf      4
    ## 36     nurse  51.242345987589018818653      5     0        5        Inf      5
    ## 37     nurse  53.277449487904675606842      4     0        5        Inf      4
    ## 38    doctor  53.277449487904675606842      2     0        3        Inf      2
    ## 39     nurse  54.333373410397129532612      3     0        5        Inf      3
    ## 40    doctor  54.333373410397129532612      3     0        3        Inf      3
    ## 41     nurse  56.524217704844183174373      4     0        5        Inf      4
    ## 42    doctor  56.694392376583301995652      2     0        3        Inf      2
    ## 43    doctor  57.350782751806931969440      1     0        3        Inf      1
    ## 44     nurse  59.425074918560738979068      5     0        5        Inf      5
    ## 45     nurse  60.365184722044617160464      5     1        5        Inf      6
    ## 46     nurse  61.458873494798524461658      5     0        5        Inf      5
    ## 47    doctor  61.458873494798524461658      2     0        3        Inf      2
    ## 48     nurse  62.475433317340247185712      4     0        5        Inf      4
    ## 49    doctor  62.475433317340247185712      3     0        3        Inf      3
    ## 50    doctor  63.504708261005177405423      2     0        3        Inf      2
    ## 51     nurse  64.039644622095025283670      3     0        5        Inf      3
    ## 52    doctor  64.039644622095025283670      3     0        3        Inf      3
    ## 53     nurse  64.478172337044668438466      4     0        5        Inf      4
    ## 54    doctor  67.052474585841522980445      2     0        3        Inf      2
    ## 55    doctor  68.021847294039361031537      1     0        3        Inf      1
    ## 56     nurse  69.650670961648472712113      5     0        5        Inf      5
    ## 57     nurse  70.223886290510179719604      4     0        5        Inf      4
    ## 58    doctor  70.223886290510179719604      2     0        3        Inf      2
    ## 59     nurse  71.707368145868429110124      5     0        5        Inf      5
    ## 60    doctor  73.989927039331902847152      1     0        3        Inf      1
    ## 61     nurse  74.381489971540119654492      4     0        5        Inf      4
    ## 62    doctor  74.381489971540119654492      2     0        3        Inf      2
    ## 63     nurse  74.423730217771250750047      3     0        5        Inf      3
    ## 64    doctor  74.423730217771250750047      3     0        3        Inf      3
    ## 65    doctor  74.446310739909293374694      2     0        3        Inf      2
    ## 66    doctor  79.959783520437028414563      1     0        3        Inf      1
    ## 67    doctor  80.369906735526043917162      0     0        3        Inf      0
    ## 68     nurse  80.422458418826550996528      4     0        5        Inf      4
    ## 69     nurse  82.521124224360079324470      3     0        5        Inf      3
    ## 70    doctor  82.521124224360079324470      1     0        3        Inf      1
    ## 71     nurse  84.332041642118582558396      4     0        5        Inf      4
    ## 72     nurse  84.380498729176963479404      3     0        5        Inf      3
    ## 73    doctor  84.380498729176963479404      2     0        3        Inf      2
    ## 74    doctor  85.277239512301008517170      1     0        3        Inf      1
    ## 75    doctor  85.615602785903007543311      0     0        3        Inf      0
    ## 76     nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 77     nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 78     nurse  89.728994984442493887400      3     0        5        Inf      3
    ## 79    doctor  89.728994984442493887400      1     0        3        Inf      1
    ## 80     nurse  91.228429248731231382408      2     0        5        Inf      2
    ## 81    doctor  91.228429248731231382408      2     0        3        Inf      2
    ## 82     nurse  92.073919283227340315534      1     0        5        Inf      1
    ## 83    doctor  92.073919283227340315534      3     0        3        Inf      3
    ## 84     nurse  93.188493342386152562540      2     0        5        Inf      2
    ## 85    doctor  96.385240605102197264387      2     0        3        Inf      2
    ## 86     nurse 103.885258323348807607545      1     0        5        Inf      1
    ## 87    doctor 103.885258323348807607545      3     0        3        Inf      3
    ## 88     nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 89     nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 90     nurse 104.556807495089344683947      1     0        5        Inf      1
    ## 91    doctor 104.556807495089344683947      3     1        3        Inf      4
    ## 92    doctor 105.448863449860354535303      3     0        3        Inf      3
    ## 93     nurse 107.458076559658692872290      2     0        5        Inf      2
    ## 94     nurse 110.313986403587804829840      1     0        5        Inf      1
    ## 95    doctor 110.313986403587804829840      3     1        3        Inf      4
    ## 96    doctor 112.018940782983236204018      3     0        3        Inf      3
    ## 97    doctor 115.906808503546301380993      2     0        3        Inf      2
    ## 98     nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 99     nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 100    nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 101    nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 102    nurse 121.957704642383561122188      2     0        5        Inf      2
    ## 103   doctor 121.957704642383561122188      3     0        3        Inf      3
    ## 104    nurse 122.616330614384665409489      1     0        5        Inf      1
    ## 105   doctor 122.616330614384665409489      3     1        3        Inf      4
    ## 106    nurse 125.566812808094169895412      2     0        5        Inf      2
    ## 107    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 108    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 109    nurse 127.451205490135080822256      2     0        5        Inf      2
    ## 110   doctor 127.451205490135080822256      3     2        3        Inf      5
    ## 111    nurse 127.704199118049814387632      1     0        5        Inf      1
    ## 112   doctor 127.704199118049814387632      3     3        3        Inf      6
    ## 113   doctor 128.573579711864510954911      3     2        3        Inf      5
    ##     limit replication      name period           time_type
    ## 1     Inf           1  patient0     wu          start_time
    ## 2     Inf           1      <NA>   <NA>                <NA>
    ## 3     Inf           1  patient0     wu          start_time
    ## 4     Inf           1      <NA>   <NA>                <NA>
    ## 5     Inf           1  patient1     wu          start_time
    ## 6     Inf           1  patient2     wu          start_time
    ## 7     Inf           1  patient3     wu          start_time
    ## 8     Inf           1      <NA>   <NA>                <NA>
    ## 9     Inf           1  patient2     wu          start_time
    ## 10    Inf           1      <NA>   <NA>                <NA>
    ## 11    Inf           1  patient3     wu          start_time
    ## 12    Inf           1  patient4     wu          start_time
    ## 13    Inf           1  patient5     wu          start_time
    ## 14    Inf           1      <NA>   <NA>                <NA>
    ## 15    Inf           1  patient6     wu          start_time
    ## 16    Inf           1      <NA>   <NA>                <NA>
    ## 17    Inf           1      <NA>   <NA>                <NA>
    ## 18    Inf           1  patient5     wu          start_time
    ## 19    Inf           1      <NA>   <NA>                <NA>
    ## 20    Inf           1  patient6     wu          start_time
    ## 21    Inf           1  patient7     wu          start_time
    ## 22    Inf           1      <NA>   <NA>                <NA>
    ## 23    Inf           1  patient1     wu          start_time
    ## 24    Inf           1      <NA>   <NA>                <NA>
    ## 25    Inf           1      <NA>   <NA>                <NA>
    ## 26    Inf           1      <NA>   <NA>                <NA>
    ## 27    Inf           1      <NA>   <NA>                <NA>
    ## 28    Inf           1  patient7     wu          start_time
    ## 29    Inf           1  patient8     wu          start_time
    ## 30    Inf           1  patient9     wu          start_time
    ## 31    Inf           1      <NA>   <NA>                <NA>
    ## 32    Inf           1  patient8     wu          start_time
    ## 33    Inf           1      <NA>   <NA>                <NA>
    ## 34    Inf           1 patient10     wu          start_time
    ## 35    Inf           1 patient11     dc          start_time
    ## 36    Inf           1 patient12     dc          start_time
    ## 37    Inf           1      <NA>   <NA>                <NA>
    ## 38    Inf           1 patient12     dc          start_time
    ## 39    Inf           1      <NA>   <NA>                <NA>
    ## 40    Inf           1 patient11     dc          start_time
    ## 41    Inf           1 patient13     dc          start_time
    ## 42    Inf           1      <NA>   <NA>                <NA>
    ## 43    Inf           1      <NA>   <NA>                <NA>
    ## 44    Inf           1 patient14     dc          start_time
    ## 45    Inf           1 patient15     dc          start_time
    ## 46    Inf           1 patient15     dc resource_start_time
    ## 47    Inf           1 patient10     wu          start_time
    ## 48    Inf           1      <NA>   <NA>                <NA>
    ## 49    Inf           1  patient4     wu          start_time
    ## 50    Inf           1      <NA>   <NA>                <NA>
    ## 51    Inf           1      <NA>   <NA>                <NA>
    ## 52    Inf           1 patient13     dc          start_time
    ## 53    Inf           1 patient16     dc          start_time
    ## 54    Inf           1      <NA>   <NA>                <NA>
    ## 55    Inf           1      <NA>   <NA>                <NA>
    ## 56    Inf           1 patient17     dc          start_time
    ## 57    Inf           1      <NA>   <NA>                <NA>
    ## 58    Inf           1 patient14     dc          start_time
    ## 59    Inf           1 patient18     dc          start_time
    ## 60    Inf           1      <NA>   <NA>                <NA>
    ## 61    Inf           1      <NA>   <NA>                <NA>
    ## 62    Inf           1 patient15     dc          start_time
    ## 63    Inf           1      <NA>   <NA>                <NA>
    ## 64    Inf           1 patient16     dc          start_time
    ## 65    Inf           1      <NA>   <NA>                <NA>
    ## 66    Inf           1      <NA>   <NA>                <NA>
    ## 67    Inf           1      <NA>   <NA>                <NA>
    ## 68    Inf           1 patient19     dc          start_time
    ## 69    Inf           1      <NA>   <NA>                <NA>
    ## 70    Inf           1 patient19     dc          start_time
    ## 71    Inf           1 patient20     dc          start_time
    ## 72    Inf           1      <NA>   <NA>                <NA>
    ## 73    Inf           1  patient9     wu          start_time
    ## 74    Inf           1      <NA>   <NA>                <NA>
    ## 75    Inf           1      <NA>   <NA>                <NA>
    ## 76    Inf           1 patient21     dc          start_time
    ## 77    Inf           1 patient21     dc          start_time
    ## 78    Inf           1      <NA>   <NA>                <NA>
    ## 79    Inf           1 patient17     dc          start_time
    ## 80    Inf           1      <NA>   <NA>                <NA>
    ## 81    Inf           1 patient21     dc          start_time
    ## 82    Inf           1      <NA>   <NA>                <NA>
    ## 83    Inf           1 patient20     dc          start_time
    ## 84    Inf           1 patient22     dc          start_time
    ## 85    Inf           1      <NA>   <NA>                <NA>
    ## 86    Inf           1      <NA>   <NA>                <NA>
    ## 87    Inf           1 patient18     dc          start_time
    ## 88    Inf           1 patient23     dc          start_time
    ## 89    Inf           1 patient23     dc          start_time
    ## 90    Inf           1      <NA>   <NA>                <NA>
    ## 91    Inf           1 patient22     dc          start_time
    ## 92    Inf           1      <NA>   <NA>                <NA>
    ## 93    Inf           1 patient24     dc          start_time
    ## 94    Inf           1      <NA>   <NA>                <NA>
    ## 95    Inf           1 patient24     dc          start_time
    ## 96    Inf           1 patient24     dc resource_start_time
    ## 97    Inf           1      <NA>   <NA>                <NA>
    ## 98    Inf           1 patient25     dc          start_time
    ## 99    Inf           1 patient25     dc          start_time
    ## 100   Inf           1 patient26     dc          start_time
    ## 101   Inf           1 patient26     dc          start_time
    ## 102   Inf           1      <NA>   <NA>                <NA>
    ## 103   Inf           1 patient23     dc          start_time
    ## 104   Inf           1      <NA>   <NA>                <NA>
    ## 105   Inf           1 patient25     dc          start_time
    ## 106   Inf           1 patient27     dc          start_time
    ## 107   Inf           1 patient28     dc          start_time
    ## 108   Inf           1 patient28     dc          start_time
    ## 109   Inf           1      <NA>   <NA>                <NA>
    ## 110   Inf           1 patient26     dc          start_time
    ## 111   Inf           1      <NA>   <NA>                <NA>
    ## 112   Inf           1 patient28     dc          start_time
    ## 113   Inf           1      <NA>   <NA>                <NA>

Now we see it has matched to patient22.

``` r
matched_data3 %>%
  filter(time > 104 & time < 106)
```

    ##   resource                    time server queue capacity queue_size system
    ## 1    nurse 104.1100505969713196919      2     0        5        Inf      2
    ## 2    nurse 104.1100505969713196919      2     0        5        Inf      2
    ## 3    nurse 104.5568074950893446839      1     0        5        Inf      1
    ## 4   doctor 104.5568074950893446839      3     1        3        Inf      4
    ## 5   doctor 105.4488634498603545353      3     0        3        Inf      3
    ##   limit replication      name period  time_type
    ## 1   Inf           1 patient23     dc start_time
    ## 2   Inf           1 patient23     dc start_time
    ## 3   Inf           1      <NA>   <NA>       <NA>
    ## 4   Inf           1 patient22     dc start_time
    ## 5   Inf           1      <NA>   <NA>       <NA>

However, there are some duplicate rows (e.g. patient21 matched on start
time twice).

``` r
# Viewing duplicates
matched_data3 %>%
  drop_na(name) %>%
  group_by(name) %>%
  filter(n() > 2) %>%
  ungroup()
```

    ## # A tibble: 21 × 12
    ##    resource  time server queue capacity queue_size system limit replication
    ##    <chr>    <dbl>  <int> <int>    <dbl>      <dbl>  <int> <dbl>       <int>
    ##  1 nurse     60.4      5     1        5        Inf      6   Inf           1
    ##  2 nurse     61.5      5     0        5        Inf      5   Inf           1
    ##  3 doctor    74.4      2     0        3        Inf      2   Inf           1
    ##  4 nurse     88.8      4     0        5        Inf      4   Inf           1
    ##  5 nurse     88.8      4     0        5        Inf      4   Inf           1
    ##  6 doctor    91.2      2     0        3        Inf      2   Inf           1
    ##  7 nurse    104.       2     0        5        Inf      2   Inf           1
    ##  8 nurse    104.       2     0        5        Inf      2   Inf           1
    ##  9 nurse    107.       2     0        5        Inf      2   Inf           1
    ## 10 doctor   110.       3     1        3        Inf      4   Inf           1
    ## # ℹ 11 more rows
    ## # ℹ 3 more variables: name <chr>, period <chr>, time_type <chr>

``` r
# Viewing original resources for patient21
get_mon_resources(env) %>%
  filter(time > 88 & time < 89)
```

    ##   resource                    time server queue capacity queue_size system
    ## 1    nurse 88.75578671532863950233      4     0        5        Inf      4
    ##   limit replication
    ## 1   Inf           1

``` r
# Viewing original arrivals for patient21
arrivals %>%
  filter(name == "patient21")
```

    ## # A tibble: 3 × 8
    ##   name      start_time end_time activity_time resource replication period
    ##   <chr>          <dbl>    <dbl>         <dbl> <chr>          <int> <chr> 
    ## 1 patient21       88.8     91.2          2.47 nurse              1 dc    
    ## 2 patient21       91.2     NA           NA    doctor             1 dc    
    ## 3 patient21       88.8     NA           NA    nurse              1 dc    
    ## # ℹ 1 more variable: resource_start_time <dbl>

``` r
get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE) %>%
  filter(name == "patient21")
```

    ##        name              start_time                end_time
    ## 1 patient21 88.75578671532863950233 91.22842924873123138241
    ## 2 patient21 91.22842924873123138241                      NA
    ## 3 patient21 88.75578671532863950233                      NA
    ##             activity_time resource replication
    ## 1 2.472642533402591880076    nurse           1
    ## 2                      NA   doctor           1
    ## 3                      NA    nurse           1

### Why does arrivals have duplicate rows?

Lets see if this is a wider issue.

``` r
run_number <- 1
param <- parameters()
set_seed <- TRUE
number_of_doctors <- 3

# Check all inputs are valid
valid_inputs(run_number, param)

# Set random seed based on run number
if (set_seed) {
  set.seed(run_number)
}

# Define the patient trajectory
patient <- trajectory("appointment") %>%
  seize("nurse", 1L) %>%
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("nurse", 1L) %>%
  seize("doctor", 1L) %>%
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("doctor", 1L)

# Determine whether to get verbose activity logs
verbose <- any(c(param[["log_to_console"]], param[["log_to_file"]]))

# Create simmer environment, add nurse resource and patient generator, and
# run the simulation. Capture output, which will save a log if verbose=TRUE
sim_log <- capture.output(
  env <- simmer("simulation", verbose = verbose) %>% # nolint
    add_resource("nurse", param[["number_of_nurses"]]) %>%
    add_resource("doctor", number_of_doctors) %>%
    add_generator("patient", patient, function() {
      rexp(n = 1L, rate = 1L / param[["patient_inter"]])
    }) %>%
    simmer::run(param[["warm_up_period"]] +
                param[["data_collection_period"]]) %>%
    wrap()
)

arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE)
resources <- get_mon_resources(env)
```

The max time is 130. All these patients were ones who were seen by a
nurse, but still waiting for or in consultation with a doctor at the end
of the time period.

``` r
arrivals %>%
  group_by(name) %>%
  filter(n() > 2) %>%
  arrange(name)
```

    ## # A tibble: 15 × 6
    ## # Groups:   name [5]
    ##    name      start_time end_time activity_time resource replication
    ##    <chr>          <dbl>    <dbl>         <dbl> <chr>          <int>
    ##  1 patient21       88.8     91.2         2.47  nurse              1
    ##  2 patient21       91.2     NA          NA     doctor             1
    ##  3 patient21       88.8     NA          NA     nurse              1
    ##  4 patient23      104.     122.         17.8   nurse              1
    ##  5 patient23      122.      NA          NA     doctor             1
    ##  6 patient23      104.      NA          NA     nurse              1
    ##  7 patient25      119.     123.          3.52  nurse              1
    ##  8 patient25      123.      NA          NA     doctor             1
    ##  9 patient25      119.      NA          NA     nurse              1
    ## 10 patient26      119.     127.          8.15  nurse              1
    ## 11 patient26      127.      NA          NA     doctor             1
    ## 12 patient26      119.      NA          NA     nurse              1
    ## 13 patient28      127.     128.          0.593 nurse              1
    ## 14 patient28      128.      NA          NA     doctor             1
    ## 15 patient28      127.      NA          NA     nurse              1

These are lost if ongoing = FALSE.

``` r
get_mon_arrivals(env, per_resource = TRUE, ongoing = FALSE) %>%
  group_by(name)%>%
  filter(n() > 2)
```

    ## # A tibble: 0 × 6
    ## # Groups:   name [0]
    ## # ℹ 6 variables: name <chr>, start_time <dbl>, end_time <dbl>,
    ## #   activity_time <dbl>, resource <chr>, replication <int>

``` r
get_mon_arrivals(env, per_resource = TRUE, ongoing = FALSE) %>%
  filter(name %in% c("patient21", "patient23", "patient25", "patient26"))
```

    ##        name               start_time                 end_time
    ## 1 patient21  88.75578671532863950233  91.22842924873123138241
    ## 2 patient23 104.11005059697131969187 121.95770464238356112219
    ## 3 patient25 119.09762563554370728980 122.61633061438466540949
    ## 4 patient26 119.30584742685580579291 127.45120549013508082226
    ##              activity_time resource replication
    ## 1  2.472642533402591880076    nurse           1
    ## 2 17.847654045412248535740    nurse           1
    ## 3  3.518704978840963448761    nurse           1
    ## 4  8.145358063279271476631    nurse           1

Hence, I think it is reasonable to drop these rows for these patients.

### Returning to the warm-up calculations

To summarise, our aim now is:

- Add column marking warm-up and data collection patients.
- Drop rows for patients with blank next to resource, if they already
  have times by the resource (BUT: could this be an issue if they
  revisit a resource in a simulation?)
- Calculate resource start time.
- Pivot the dataframe.
- Match on start time and resource start time in the first instance.
- Then, fill remaining blanks by matching on end time.
- Then check for NA.

Lets do it from scratch from `env` step.

``` r
arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE)
arrivals
```

    ##         name                start_time                  end_time
    ## 1   patient0   3.020727332513380769541   4.477794599551309318031
    ## 2   patient0   4.477794599551309318031   5.875747218236287316984
    ## 3   patient2   9.491572952058504597517  14.888401352029632107588
    ## 4   patient3  14.409821165718078361806  15.880281070757604311439
    ## 5   patient3  15.880281070757604311439  23.500579625458339450006
    ## 6   patient2  14.888401352029632107588  28.795752640133933653033
    ## 7   patient5  23.186505343451216276662  33.538944803758624857437
    ## 8   patient6  27.404678012693885591489  33.952144384833637502652
    ## 9   patient1   7.747298448941805304457  36.696983823582542072472
    ## 10  patient5  33.538944803758624857437  36.908279567605916327011
    ## 11  patient1  36.696983823582542072472  39.638187699981045852837
    ## 12  patient6  33.952144384833637502652  39.836941599364045885068
    ## 13  patient7  34.908818702326875893505  41.327744584644001690776
    ## 14  patient8  44.366879714421457947537  44.961271318375594319150
    ## 15  patient7  41.327744584644001690776  46.986399830432397095592
    ## 16 patient12  51.242345987589018818653  53.277449487904675606842
    ## 17 patient11  51.093271882043140408314  54.333373410397129532612
    ## 18  patient8  44.961271318375594319150  56.694392376583301995652
    ## 19 patient11  54.333373410397129532612  57.350782751806931969440
    ## 20 patient10  47.106020061067766846463  61.458873494798524461658
    ## 21  patient4  18.236091140511895503096  62.475433317340247185712
    ## 22 patient12  53.277449487904675606842  63.504708261005177405423
    ## 23 patient13  56.524217704844183174373  64.039644622095025283670
    ## 24 patient13  64.039644622095025283670  67.052474585841522980445
    ## 25  patient4  62.475433317340247185712  68.021847294039361031537
    ## 26 patient14  59.425074918560738979068  70.223886290510179719604
    ## 27 patient10  61.458873494798524461658  73.989927039331902847152
    ## 28 patient15  60.365184722044617160464  74.381489971540119654492
    ## 29 patient16  64.478172337044668438466  74.423730217771250750047
    ## 30 patient14  70.223886290510179719604  74.446310739909293374694
    ## 31 patient15  74.381489971540119654492  79.959783520437028414563
    ## 32 patient16  74.423730217771250750047  80.369906735526043917162
    ## 33 patient19  80.422458418826550996528  82.521124224360079324470
    ## 34  patient9  44.791170207552141846463  84.380498729176963479404
    ## 35  patient9  84.380498729176963479404  85.277239512301008517170
    ## 36 patient19  82.521124224360079324470  85.615602785903007543311
    ## 37 patient17  69.650670961648472712113  89.728994984442493887400
    ## 38 patient21  88.755786715328639502331  91.228429248731231382408
    ## 39 patient20  84.332041642118582558396  92.073919283227340315534
    ## 40 patient20  92.073919283227340315534  96.385240605102197264387
    ## 41 patient18  71.707368145868429110124 103.885258323348807607545
    ## 42 patient22  93.188493342386152562540 104.556807495089344683947
    ## 43 patient17  89.728994984442493887400 105.448863449860354535303
    ## 44 patient24 107.458076559658692872290 110.313986403587804829840
    ## 45 patient18 103.885258323348807607545 112.018940782983236204018
    ## 46 patient24 110.313986403587804829840 115.906808503546301380993
    ## 47 patient23 104.110050596971319691875 121.957704642383561122188
    ## 48 patient25 119.097625635543707289798 122.616330614384665409489
    ## 49 patient26 119.305847426855805792911 127.451205490135080822256
    ## 50 patient28 127.111587061988188906980 127.704199118049814387632
    ## 51 patient22 104.556807495089344683947 128.573579711864510954911
    ## 52 patient26 127.451205490135080822256                        NA
    ## 53 patient26 119.305847426855805792911                        NA
    ## 54 patient25 122.616330614384665409489                        NA
    ## 55 patient25 119.097625635543707289798                        NA
    ## 56 patient23 121.957704642383561122188                        NA
    ## 57 patient23 104.110050596971319691875                        NA
    ## 58 patient28 127.704199118049814387632                        NA
    ## 59 patient28 127.111587061988188906980                        NA
    ## 60 patient27 125.566812808094169895412                        NA
    ## 61 patient21  91.228429248731231382408                        NA
    ## 62 patient21  88.755786715328639502331                        NA
    ##                activity_time resource replication
    ## 1   1.4570672670379281044006    nurse           1
    ## 2   1.3979526186849779989529   doctor           1
    ## 3   5.3968283999711275100708    nurse           1
    ## 4   1.4704599050395255055435    nurse           1
    ## 5   7.6202985547007342503889   doctor           1
    ## 6  13.9073512881042997690884   doctor           1
    ## 7  10.3524394603074121334885    nurse           1
    ## 8   6.5474663721397519111633    nurse           1
    ## 9  28.9496853746407403207286    nurse           1
    ## 10  3.3693347638472914695740   doctor           1
    ## 11  2.9412038763985037803650   doctor           1
    ## 12  5.8847972145304083824158   doctor           1
    ## 13  6.4189258823171257972717    nurse           1
    ## 14  0.5943916039541363716125    nurse           1
    ## 15  5.6586552457883954048157   doctor           1
    ## 16  2.0351035003156576763672    nurse           1
    ## 17  3.2401015283539891242981    nurse           1
    ## 18 11.7331210582077094528586   doctor           1
    ## 19  3.0174093414098024368286   doctor           1
    ## 20 14.3528534337307576151943    nurse           1
    ## 21 44.2393421768283516826159    nurse           1
    ## 22 10.2272587731004982458671   doctor           1
    ## 23  7.5154269172508483265460    nurse           1
    ## 24  3.0128299637464945881504   doctor           1
    ## 25  5.5464139766991138458252   doctor           1
    ## 26 10.7988113719494371878227    nurse           1
    ## 27 12.5310535445333748327812   doctor           1
    ## 28 12.9226164767415987455479    nurse           1
    ## 29  9.9455578807265769825108    nurse           1
    ## 30  4.2224244493991136550903   doctor           1
    ## 31  5.5782935488969087600708   doctor           1
    ## 32  5.9461765177547931671143   doctor           1
    ## 33  2.0986658055335283279419    nurse           1
    ## 34 39.5893285216248145275131    nurse           1
    ## 35  0.8967407831240499227476   doctor           1
    ## 36  3.0944785615429282188416   doctor           1
    ## 37 20.0783240227940140698593    nurse           1
    ## 38  2.4726425334025918800762    nurse           1
    ## 39  7.7418776411087533162458    nurse           1
    ## 40  4.3113213218748569488525   doctor           1
    ## 41 32.1778901774803784974210    nurse           1
    ## 42 11.3683141527031921214075    nurse           1
    ## 43 15.7198684654178659769741   doctor           1
    ## 44  2.8559098439291119575500    nurse           1
    ## 45  8.1336824596344303728301   doctor           1
    ## 46  3.8878677205630713942242   doctor           1
    ## 47 17.8476540454122485357402    nurse           1
    ## 48  3.5187049788409634487607    nurse           1
    ## 49  8.1453580632792714766310    nurse           1
    ## 50  0.5926120560616254806519    nurse           1
    ## 51 23.1247162620041422087525   doctor           1
    ## 52                        NA   doctor           1
    ## 53                        NA    nurse           1
    ## 54                        NA   doctor           1
    ## 55                        NA    nurse           1
    ## 56                        NA   doctor           1
    ## 57                        NA    nurse           1
    ## 58                        NA   doctor           1
    ## 59                        NA    nurse           1
    ## 60                        NA    nurse           1
    ## 61                        NA   doctor           1
    ## 62                        NA    nurse           1

``` r
# Add column marking warm-up (wu) and data-collection (dc) patients
arrivals <- arrivals %>%
  group_by(name) %>%
  mutate(period = if_else(
    any(start_time < param[["warm_up_period"]]), "wu", "dc"
  )) %>%
  ungroup()

# Remove the blank entries for patients with  more rows than number of
# resources (2), who have a complete version and blank version of same row
arrivals <- arrivals %>%
  group_by(name)%>%
  mutate(group_size = n()) %>%
  group_by(name, resource) %>%
  filter(!(
    any(!is.na(start_time) & !is.na(end_time) &
          !is.na(activity_time)) & is.na(end_time)
    ) | group_size <= 2) %>%
  select(-group_size)

arrivals
```

    ## # A tibble: 57 × 7
    ## # Groups:   name, resource [57]
    ##    name     start_time end_time activity_time resource replication period
    ##    <chr>         <dbl>    <dbl>         <dbl> <chr>          <int> <chr> 
    ##  1 patient0       3.02     4.48          1.46 nurse              1 wu    
    ##  2 patient0       4.48     5.88          1.40 doctor             1 wu    
    ##  3 patient2       9.49    14.9           5.40 nurse              1 wu    
    ##  4 patient3      14.4     15.9           1.47 nurse              1 wu    
    ##  5 patient3      15.9     23.5           7.62 doctor             1 wu    
    ##  6 patient2      14.9     28.8          13.9  doctor             1 wu    
    ##  7 patient5      23.2     33.5          10.4  nurse              1 wu    
    ##  8 patient6      27.4     34.0           6.55 nurse              1 wu    
    ##  9 patient1       7.75    36.7          28.9  nurse              1 wu    
    ## 10 patient5      33.5     36.9           3.37 doctor             1 wu    
    ## # ℹ 47 more rows

``` r
# Add column recording the resource start time (excluding wait time for resource)
arrivals[["resource_start_time"]] <- (
  arrivals[["end_time"]] - arrivals[["activity_time"]]
)

# Pivot dataframe so rows for each patient's resource start and end time
arrivals_times <- arrivals %>%
  select(name, resource, start_time, resource_start_time, end_time, replication, period) %>%
  pivot_longer(cols = c(start_time, resource_start_time, end_time),
               names_to = "time_type",
               values_to = "time_value")

arrivals_times
```

    ## # A tibble: 171 × 6
    ## # Groups:   name, resource [57]
    ##    name     resource replication period time_type           time_value
    ##    <chr>    <chr>          <int> <chr>  <chr>                    <dbl>
    ##  1 patient0 nurse              1 wu     start_time                3.02
    ##  2 patient0 nurse              1 wu     resource_start_time       3.02
    ##  3 patient0 nurse              1 wu     end_time                  4.48
    ##  4 patient0 doctor             1 wu     start_time                4.48
    ##  5 patient0 doctor             1 wu     resource_start_time       4.48
    ##  6 patient0 doctor             1 wu     end_time                  5.88
    ##  7 patient2 nurse              1 wu     start_time                9.49
    ##  8 patient2 nurse              1 wu     resource_start_time       9.49
    ##  9 patient2 nurse              1 wu     end_time                 14.9 
    ## 10 patient3 nurse              1 wu     start_time               14.4 
    ## # ℹ 161 more rows

``` r
matched_data4 <- resources %>%
    left_join(arrivals, by = c("resource", "replication", "time" = "start_time")) %>%
    left_join(arrivals, by = c("resource", "replication", "time" = "resource_start_time"), suffix = c("", "_rs")) %>%
    left_join(arrivals, by = c("resource", "replication", "time" = "end_time"), suffix = c("", "_et")) %>%
    mutate(
      name = coalesce(name, name_rs, name_et),
      match_type = case_when(
        !is.na(name) ~ "start_time",
        !is.na(name_rs) ~ "resource_start_time",
        !is.na(name_et) ~ "end_time",
        TRUE ~ NA_character_
      ),
      period = coalesce(period, period_rs, period_et)
    ) %>%
    select(resource, time, server, queue, capacity, queue_size, system, limit, replication,
           name, match_type, period)
matched_data4
```

    ##     resource                      time server queue capacity queue_size system
    ## 1      nurse   3.020727332513380769541      1     0        5        Inf      1
    ## 2      nurse   4.477794599551309318031      0     0        5        Inf      0
    ## 3     doctor   4.477794599551309318031      1     0        3        Inf      1
    ## 4     doctor   5.875747218236287316984      0     0        3        Inf      0
    ## 5      nurse   7.747298448941805304457      1     0        5        Inf      1
    ## 6      nurse   9.491572952058504597517      2     0        5        Inf      2
    ## 7      nurse  14.409821165718078361806      3     0        5        Inf      3
    ## 8      nurse  14.888401352029632107588      2     0        5        Inf      2
    ## 9     doctor  14.888401352029632107588      1     0        3        Inf      1
    ## 10     nurse  15.880281070757604311439      1     0        5        Inf      1
    ## 11    doctor  15.880281070757604311439      2     0        3        Inf      2
    ## 12     nurse  18.236091140511895503096      2     0        5        Inf      2
    ## 13     nurse  23.186505343451216276662      3     0        5        Inf      3
    ## 14    doctor  23.500579625458339450006      1     0        3        Inf      1
    ## 15     nurse  27.404678012693885591489      4     0        5        Inf      4
    ## 16    doctor  28.795752640133933653033      0     0        3        Inf      0
    ## 17     nurse  33.538944803758624857437      3     0        5        Inf      3
    ## 18    doctor  33.538944803758624857437      1     0        3        Inf      1
    ## 19     nurse  33.952144384833637502652      2     0        5        Inf      2
    ## 20    doctor  33.952144384833637502652      2     0        3        Inf      2
    ## 21     nurse  34.908818702326875893505      3     0        5        Inf      3
    ## 22     nurse  36.696983823582542072472      2     0        5        Inf      2
    ## 23    doctor  36.696983823582542072472      3     0        3        Inf      3
    ## 24    doctor  36.908279567605916327011      2     0        3        Inf      2
    ## 25    doctor  39.638187699981045852837      1     0        3        Inf      1
    ## 26    doctor  39.836941599364045885068      0     0        3        Inf      0
    ## 27     nurse  41.327744584644001690776      1     0        5        Inf      1
    ## 28    doctor  41.327744584644001690776      1     0        3        Inf      1
    ## 29     nurse  44.366879714421457947537      2     0        5        Inf      2
    ## 30     nurse  44.791170207552141846463      3     0        5        Inf      3
    ## 31     nurse  44.961271318375594319150      2     0        5        Inf      2
    ## 32    doctor  44.961271318375594319150      2     0        3        Inf      2
    ## 33    doctor  46.986399830432397095592      1     0        3        Inf      1
    ## 34     nurse  47.106020061067766846463      3     0        5        Inf      3
    ## 35     nurse  51.093271882043140408314      4     0        5        Inf      4
    ## 36     nurse  51.242345987589018818653      5     0        5        Inf      5
    ## 37     nurse  53.277449487904675606842      4     0        5        Inf      4
    ## 38    doctor  53.277449487904675606842      2     0        3        Inf      2
    ## 39     nurse  54.333373410397129532612      3     0        5        Inf      3
    ## 40    doctor  54.333373410397129532612      3     0        3        Inf      3
    ## 41     nurse  56.524217704844183174373      4     0        5        Inf      4
    ## 42    doctor  56.694392376583301995652      2     0        3        Inf      2
    ## 43    doctor  57.350782751806931969440      1     0        3        Inf      1
    ## 44     nurse  59.425074918560738979068      5     0        5        Inf      5
    ## 45     nurse  60.365184722044617160464      5     1        5        Inf      6
    ## 46     nurse  61.458873494798524461658      5     0        5        Inf      5
    ## 47    doctor  61.458873494798524461658      2     0        3        Inf      2
    ## 48     nurse  62.475433317340247185712      4     0        5        Inf      4
    ## 49    doctor  62.475433317340247185712      3     0        3        Inf      3
    ## 50    doctor  63.504708261005177405423      2     0        3        Inf      2
    ## 51     nurse  64.039644622095025283670      3     0        5        Inf      3
    ## 52    doctor  64.039644622095025283670      3     0        3        Inf      3
    ## 53     nurse  64.478172337044668438466      4     0        5        Inf      4
    ## 54    doctor  67.052474585841522980445      2     0        3        Inf      2
    ## 55    doctor  68.021847294039361031537      1     0        3        Inf      1
    ## 56     nurse  69.650670961648472712113      5     0        5        Inf      5
    ## 57     nurse  70.223886290510179719604      4     0        5        Inf      4
    ## 58    doctor  70.223886290510179719604      2     0        3        Inf      2
    ## 59     nurse  71.707368145868429110124      5     0        5        Inf      5
    ## 60    doctor  73.989927039331902847152      1     0        3        Inf      1
    ## 61     nurse  74.381489971540119654492      4     0        5        Inf      4
    ## 62    doctor  74.381489971540119654492      2     0        3        Inf      2
    ## 63     nurse  74.423730217771250750047      3     0        5        Inf      3
    ## 64    doctor  74.423730217771250750047      3     0        3        Inf      3
    ## 65    doctor  74.446310739909293374694      2     0        3        Inf      2
    ## 66    doctor  79.959783520437028414563      1     0        3        Inf      1
    ## 67    doctor  80.369906735526043917162      0     0        3        Inf      0
    ## 68     nurse  80.422458418826550996528      4     0        5        Inf      4
    ## 69     nurse  82.521124224360079324470      3     0        5        Inf      3
    ## 70    doctor  82.521124224360079324470      1     0        3        Inf      1
    ## 71     nurse  84.332041642118582558396      4     0        5        Inf      4
    ## 72     nurse  84.380498729176963479404      3     0        5        Inf      3
    ## 73    doctor  84.380498729176963479404      2     0        3        Inf      2
    ## 74    doctor  85.277239512301008517170      1     0        3        Inf      1
    ## 75    doctor  85.615602785903007543311      0     0        3        Inf      0
    ## 76     nurse  88.755786715328639502331      4     0        5        Inf      4
    ## 77     nurse  89.728994984442493887400      3     0        5        Inf      3
    ## 78    doctor  89.728994984442493887400      1     0        3        Inf      1
    ## 79     nurse  91.228429248731231382408      2     0        5        Inf      2
    ## 80    doctor  91.228429248731231382408      2     0        3        Inf      2
    ## 81     nurse  92.073919283227340315534      1     0        5        Inf      1
    ## 82    doctor  92.073919283227340315534      3     0        3        Inf      3
    ## 83     nurse  93.188493342386152562540      2     0        5        Inf      2
    ## 84    doctor  96.385240605102197264387      2     0        3        Inf      2
    ## 85     nurse 103.885258323348807607545      1     0        5        Inf      1
    ## 86    doctor 103.885258323348807607545      3     0        3        Inf      3
    ## 87     nurse 104.110050596971319691875      2     0        5        Inf      2
    ## 88     nurse 104.556807495089344683947      1     0        5        Inf      1
    ## 89    doctor 104.556807495089344683947      3     1        3        Inf      4
    ## 90    doctor 105.448863449860354535303      3     0        3        Inf      3
    ## 91     nurse 107.458076559658692872290      2     0        5        Inf      2
    ## 92     nurse 110.313986403587804829840      1     0        5        Inf      1
    ## 93    doctor 110.313986403587804829840      3     1        3        Inf      4
    ## 94    doctor 112.018940782983236204018      3     0        3        Inf      3
    ## 95    doctor 115.906808503546301380993      2     0        3        Inf      2
    ## 96     nurse 119.097625635543707289798      2     0        5        Inf      2
    ## 97     nurse 119.305847426855805792911      3     0        5        Inf      3
    ## 98     nurse 121.957704642383561122188      2     0        5        Inf      2
    ## 99    doctor 121.957704642383561122188      3     0        3        Inf      3
    ## 100    nurse 122.616330614384665409489      1     0        5        Inf      1
    ## 101   doctor 122.616330614384665409489      3     1        3        Inf      4
    ## 102    nurse 125.566812808094169895412      2     0        5        Inf      2
    ## 103    nurse 127.111587061988188906980      3     0        5        Inf      3
    ## 104    nurse 127.451205490135080822256      2     0        5        Inf      2
    ## 105   doctor 127.451205490135080822256      3     2        3        Inf      5
    ## 106    nurse 127.704199118049814387632      1     0        5        Inf      1
    ## 107   doctor 127.704199118049814387632      3     3        3        Inf      6
    ## 108   doctor 128.573579711864510954911      3     2        3        Inf      5
    ##     limit replication      name match_type period
    ## 1     Inf           1  patient0 start_time     wu
    ## 2     Inf           1  patient0 start_time     wu
    ## 3     Inf           1  patient0 start_time     wu
    ## 4     Inf           1  patient0 start_time     wu
    ## 5     Inf           1  patient1 start_time     wu
    ## 6     Inf           1  patient2 start_time     wu
    ## 7     Inf           1  patient3 start_time     wu
    ## 8     Inf           1  patient2 start_time     wu
    ## 9     Inf           1  patient2 start_time     wu
    ## 10    Inf           1  patient3 start_time     wu
    ## 11    Inf           1  patient3 start_time     wu
    ## 12    Inf           1  patient4 start_time     wu
    ## 13    Inf           1  patient5 start_time     wu
    ## 14    Inf           1  patient3 start_time     wu
    ## 15    Inf           1  patient6 start_time     wu
    ## 16    Inf           1  patient2 start_time     wu
    ## 17    Inf           1  patient5 start_time     wu
    ## 18    Inf           1  patient5 start_time     wu
    ## 19    Inf           1  patient6 start_time     wu
    ## 20    Inf           1  patient6 start_time     wu
    ## 21    Inf           1  patient7 start_time     wu
    ## 22    Inf           1  patient1 start_time     wu
    ## 23    Inf           1  patient1 start_time     wu
    ## 24    Inf           1  patient5 start_time     wu
    ## 25    Inf           1  patient1 start_time     wu
    ## 26    Inf           1  patient6 start_time     wu
    ## 27    Inf           1  patient7 start_time     wu
    ## 28    Inf           1  patient7 start_time     wu
    ## 29    Inf           1  patient8 start_time     wu
    ## 30    Inf           1  patient9 start_time     wu
    ## 31    Inf           1  patient8 start_time     wu
    ## 32    Inf           1  patient8 start_time     wu
    ## 33    Inf           1  patient7 start_time     wu
    ## 34    Inf           1 patient10 start_time     wu
    ## 35    Inf           1 patient11 start_time     dc
    ## 36    Inf           1 patient12 start_time     dc
    ## 37    Inf           1 patient12 start_time     dc
    ## 38    Inf           1 patient12 start_time     dc
    ## 39    Inf           1 patient11 start_time     dc
    ## 40    Inf           1 patient11 start_time     dc
    ## 41    Inf           1 patient13 start_time     dc
    ## 42    Inf           1  patient8 start_time     wu
    ## 43    Inf           1 patient11 start_time     dc
    ## 44    Inf           1 patient14 start_time     dc
    ## 45    Inf           1 patient15 start_time     dc
    ## 46    Inf           1 patient15 start_time     dc
    ## 47    Inf           1 patient10 start_time     wu
    ## 48    Inf           1  patient4 start_time     wu
    ## 49    Inf           1  patient4 start_time     wu
    ## 50    Inf           1 patient12 start_time     dc
    ## 51    Inf           1 patient13 start_time     dc
    ## 52    Inf           1 patient13 start_time     dc
    ## 53    Inf           1 patient16 start_time     dc
    ## 54    Inf           1 patient13 start_time     dc
    ## 55    Inf           1  patient4 start_time     wu
    ## 56    Inf           1 patient17 start_time     dc
    ## 57    Inf           1 patient14 start_time     dc
    ## 58    Inf           1 patient14 start_time     dc
    ## 59    Inf           1 patient18 start_time     dc
    ## 60    Inf           1 patient10 start_time     wu
    ## 61    Inf           1 patient15 start_time     dc
    ## 62    Inf           1 patient15 start_time     dc
    ## 63    Inf           1 patient16 start_time     dc
    ## 64    Inf           1 patient16 start_time     dc
    ## 65    Inf           1 patient14 start_time     dc
    ## 66    Inf           1 patient15 start_time     dc
    ## 67    Inf           1 patient16 start_time     dc
    ## 68    Inf           1 patient19 start_time     dc
    ## 69    Inf           1 patient19 start_time     dc
    ## 70    Inf           1 patient19 start_time     dc
    ## 71    Inf           1 patient20 start_time     dc
    ## 72    Inf           1  patient9 start_time     wu
    ## 73    Inf           1  patient9 start_time     wu
    ## 74    Inf           1  patient9 start_time     wu
    ## 75    Inf           1 patient19 start_time     dc
    ## 76    Inf           1 patient21 start_time     dc
    ## 77    Inf           1 patient17 start_time     dc
    ## 78    Inf           1 patient17 start_time     dc
    ## 79    Inf           1 patient21 start_time     dc
    ## 80    Inf           1 patient21 start_time     dc
    ## 81    Inf           1 patient20 start_time     dc
    ## 82    Inf           1 patient20 start_time     dc
    ## 83    Inf           1 patient22 start_time     dc
    ## 84    Inf           1 patient20 start_time     dc
    ## 85    Inf           1 patient18 start_time     dc
    ## 86    Inf           1 patient18 start_time     dc
    ## 87    Inf           1 patient23 start_time     dc
    ## 88    Inf           1 patient22 start_time     dc
    ## 89    Inf           1 patient22 start_time     dc
    ## 90    Inf           1 patient17 start_time     dc
    ## 91    Inf           1 patient24 start_time     dc
    ## 92    Inf           1 patient24 start_time     dc
    ## 93    Inf           1 patient24 start_time     dc
    ## 94    Inf           1 patient24 start_time     dc
    ## 95    Inf           1 patient24 start_time     dc
    ## 96    Inf           1 patient25 start_time     dc
    ## 97    Inf           1 patient26 start_time     dc
    ## 98    Inf           1 patient23 start_time     dc
    ## 99    Inf           1 patient23 start_time     dc
    ## 100   Inf           1 patient25 start_time     dc
    ## 101   Inf           1 patient25 start_time     dc
    ## 102   Inf           1 patient27 start_time     dc
    ## 103   Inf           1 patient28 start_time     dc
    ## 104   Inf           1 patient26 start_time     dc
    ## 105   Inf           1 patient26 start_time     dc
    ## 106   Inf           1 patient28 start_time     dc
    ## 107   Inf           1 patient28 start_time     dc
    ## 108   Inf           1 patient22 start_time     dc

Checking for NA…

``` r
matched_data4 %>%
  filter(is.na(name))
```

    ##  [1] resource    time        server      queue       capacity    queue_size 
    ##  [7] system      limit       replication name        match_type  period     
    ## <0 rows> (or 0-length row.names)

Checking if it matched patient17 or patient22…

``` r
matched_data4 %>%
  filter(time > 104 & time < 106)
```

    ##   resource                    time server queue capacity queue_size system
    ## 1    nurse 104.1100505969713196919      2     0        5        Inf      2
    ## 2    nurse 104.5568074950893446839      1     0        5        Inf      1
    ## 3   doctor 104.5568074950893446839      3     1        3        Inf      4
    ## 4   doctor 105.4488634498603545353      3     0        3        Inf      3
    ##   limit replication      name match_type period
    ## 1   Inf           1 patient23 start_time     dc
    ## 2   Inf           1 patient22 start_time     dc
    ## 3   Inf           1 patient22 start_time     dc
    ## 4   Inf           1 patient17 start_time     dc

## Attempt using `reset()`

``` r
run_number <- 1
param <- parameters(
  patient_inter = 5,
  mean_n_consult_time = 20,
  number_of_nurses = 1,
  warm_up_period = 80,
  data_collection_period = 80
)
set_seed <- TRUE
number_of_doctors <- 3

# Check all inputs are valid
valid_inputs(run_number, param)

# Set random seed based on run number
if (set_seed) {
  set.seed(run_number)
}

# Define the patient trajectory
patient <- trajectory("appointment") %>%
  seize("nurse", 1L) %>%
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("nurse", 1L)

# Create simmer environment, add nurse resource and patient generator
env <- simmer("simulation", verbose = verbose) %>% # nolint
  add_resource("nurse", param[["number_of_nurses"]]) %>%
  add_generator("patient", patient, function() {
    rexp(n = 1L, rate = 1L / param[["patient_inter"]])
  })

# Run the warm-up period
env %>%
  simmer::run(param[["warm_up_period"]])
```

    ## simmer environment: simulation | now: 80 | next: 80.610811387249
    ## { Monitor: in memory }
    ## { Resource: nurse | monitored: TRUE | server status: 1(1) | queue status: 6(Inf) }
    ## { Source: patient | monitored: 1 | n_generated: 12 }

``` r
# Extract monitoring data *before* the reset
wu_arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE)
wu_resources <- get_mon_resources(env)

# Reset the environment to clear statistics
env %>%
  simmer::reset()
```

    ## simmer environment: simulation | now: 0 | next: 0
    ## { Monitor: in memory }
    ## { Resource: nurse | monitored: TRUE | server status: 0(1) | queue status: 0(Inf) }
    ## { Source: patient | monitored: 1 | n_generated: 0 }

``` r
# Run the data collection period
sim_log <- capture.output(
  env %>%
    simmer::run(param[["data_collection_period"]]) %>%
    wrap()
)

# Extract monitoring data *after* the reset
arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE)
resources <- get_mon_resources(env)

# Display
wu_arrivals %>% arrange(start_time)
```

    ##         name               start_time                 end_time
    ## 1   patient0  3.775909165641726072948  6.690043699717582725839
    ## 2   patient1  9.684123061177256630572 18.405495576760749543155
    ## 3   patient2 10.383099370519746074137 42.996736645058618364601
    ## 4   patient3 24.857942057840116234502 67.748807659755215127007
    ## 5   patient4 27.556356257825679989537                       NA
    ## 6   patient5 32.339193726317951416149                       NA
    ## 7   patient6 33.074423678837710838252                       NA
    ## 8   patient7 40.028099322889858058261                       NA
    ## 9   patient8 43.838248600240227403901                       NA
    ## 10  patient9 65.957919688654399692496                       NA
    ## 11 patient10 71.230635525207731006958                       NA
    ##               activity_time resource replication
    ## 1   2.914134534075856208801    nurse           1
    ## 2   8.721372515583492912583    nurse           1
    ## 3  24.591241068297868821446    nurse           1
    ## 4  24.752071014696603867833    nurse           1
    ## 5                        NA    nurse           1
    ## 6                        NA    nurse           1
    ## 7                        NA    nurse           1
    ## 8                        NA    nurse           1
    ## 9                        NA    nurse           1
    ## 10                       NA    nurse           1
    ## 11                       NA    nurse           1

``` r
wu_resources
```

    ##    resource                     time server queue capacity queue_size system
    ## 1     nurse  3.775909165641726072948      1     0        1        Inf      1
    ## 2     nurse  6.690043699717582725839      0     0        1        Inf      0
    ## 3     nurse  9.684123061177256630572      1     0        1        Inf      1
    ## 4     nurse 10.383099370519746074137      1     1        1        Inf      2
    ## 5     nurse 18.405495576760749543155      1     0        1        Inf      1
    ## 6     nurse 24.857942057840116234502      1     1        1        Inf      2
    ## 7     nurse 27.556356257825679989537      1     2        1        Inf      3
    ## 8     nurse 32.339193726317951416149      1     3        1        Inf      4
    ## 9     nurse 33.074423678837710838252      1     4        1        Inf      5
    ## 10    nurse 40.028099322889858058261      1     5        1        Inf      6
    ## 11    nurse 42.996736645058618364601      1     4        1        Inf      5
    ## 12    nurse 43.838248600240227403901      1     5        1        Inf      6
    ## 13    nurse 65.957919688654399692496      1     6        1        Inf      7
    ## 14    nurse 67.748807659755215127007      1     5        1        Inf      6
    ## 15    nurse 71.230635525207731006958      1     6        1        Inf      7
    ##    limit replication
    ## 1    Inf           1
    ## 2    Inf           1
    ## 3    Inf           1
    ## 4    Inf           1
    ## 5    Inf           1
    ## 6    Inf           1
    ## 7    Inf           1
    ## 8    Inf           1
    ## 9    Inf           1
    ## 10   Inf           1
    ## 11   Inf           1
    ## 12   Inf           1
    ## 13   Inf           1
    ## 14   Inf           1
    ## 15   Inf           1

``` r
arrivals %>% arrange(start_time)
```

    ##         name               start_time                end_time
    ## 1   patient0  3.273733186069875955582 15.04332761513069272041
    ## 2   patient1  4.958400567993521690369 27.88117937976494431496
    ## 3   patient2 16.780976833111751034266 51.34742149618035966796
    ## 4   patient3 18.251578771311002924449 52.09279202390975171966
    ## 5   patient4 21.080906394205200626857 58.57299508061772996825
    ## 6   patient5 21.611269510618555500514 62.64320208124904354463
    ## 7   patient6 21.908465312595623686320                      NA
    ## 8   patient7 24.802027629490154936320                      NA
    ## 9   patient8 44.596691890302565752791                      NA
    ## 10  patient9 49.580756666521786257817                      NA
    ## 11 patient10 56.757183383387165065415                      NA
    ## 12 patient11 63.359523029956122286421                      NA
    ## 13 patient12 64.868227700661023504836                      NA
    ## 14 patient13 68.494299217806712931633                      NA
    ## 15 patient14 72.252012676432130433568                      NA
    ## 16 patient15 73.427149930786967502172                      NA
    ## 17 patient16 78.826555616761680767013                      NA
    ##                activity_time resource replication
    ## 1  11.7695944290608167648315    nurse           1
    ## 2  12.8378517646342515945435    nurse           1
    ## 3  23.4662421164154189057172    nurse           1
    ## 4   0.7453705277293920516968    nurse           1
    ## 5   6.4802030567079782485962    nurse           1
    ## 6   4.0702070006313153527344    nurse           1
    ## 7                         NA    nurse           1
    ## 8                         NA    nurse           1
    ## 9                         NA    nurse           1
    ## 10                        NA    nurse           1
    ## 11                        NA    nurse           1
    ## 12                        NA    nurse           1
    ## 13                        NA    nurse           1
    ## 14                        NA    nurse           1
    ## 15                        NA    nurse           1
    ## 16                        NA    nurse           1
    ## 17                        NA    nurse           1

``` r
resources
```

    ##    resource                     time server queue capacity queue_size system
    ## 1     nurse  3.273733186069875955582      1     0        1        Inf      1
    ## 2     nurse  4.958400567993521690369      1     1        1        Inf      2
    ## 3     nurse 15.043327615130692720413      1     0        1        Inf      1
    ## 4     nurse 16.780976833111751034266      1     1        1        Inf      2
    ## 5     nurse 18.251578771311002924449      1     2        1        Inf      3
    ## 6     nurse 21.080906394205200626857      1     3        1        Inf      4
    ## 7     nurse 21.611269510618555500514      1     4        1        Inf      5
    ## 8     nurse 21.908465312595623686320      1     5        1        Inf      6
    ## 9     nurse 24.802027629490154936320      1     6        1        Inf      7
    ## 10    nurse 27.881179379764944314957      1     5        1        Inf      6
    ## 11    nurse 44.596691890302565752791      1     6        1        Inf      7
    ## 12    nurse 49.580756666521786257817      1     7        1        Inf      8
    ## 13    nurse 51.347421496180359667960      1     6        1        Inf      7
    ## 14    nurse 52.092792023909751719657      1     5        1        Inf      6
    ## 15    nurse 56.757183383387165065415      1     6        1        Inf      7
    ## 16    nurse 58.572995080617729968253      1     5        1        Inf      6
    ## 17    nurse 62.643202081249043544631      1     4        1        Inf      5
    ## 18    nurse 63.359523029956122286421      1     5        1        Inf      6
    ## 19    nurse 64.868227700661023504836      1     6        1        Inf      7
    ## 20    nurse 68.494299217806712931633      1     7        1        Inf      8
    ## 21    nurse 72.252012676432130433568      1     8        1        Inf      9
    ## 22    nurse 73.427149930786967502172      1     9        1        Inf     10
    ## 23    nurse 78.826555616761680767013      1    10        1        Inf     11
    ##    limit replication
    ## 1    Inf           1
    ## 2    Inf           1
    ## 3    Inf           1
    ## 4    Inf           1
    ## 5    Inf           1
    ## 6    Inf           1
    ## 7    Inf           1
    ## 8    Inf           1
    ## 9    Inf           1
    ## 10   Inf           1
    ## 11   Inf           1
    ## 12   Inf           1
    ## 13   Inf           1
    ## 14   Inf           1
    ## 15   Inf           1
    ## 16   Inf           1
    ## 17   Inf           1
    ## 18   Inf           1
    ## 19   Inf           1
    ## 20   Inf           1
    ## 21   Inf           1
    ## 22   Inf           1
    ## 23   Inf           1

It appears that in `wu_arrivals`, patients `end_time` = NA in some cases
as not yet seen but in others as they start being seen but not finished
before end of simulation.

**TODO:** Find a way to distinguish patients still waiting for a
resource v.s. patients in ongoing session with resource (perhaps by
matching with resource times).

When we reset, these are no longer monitored so not included in the new
dataframes. However, I am concerned they simply no longer exist, as the
patients in `arrivals` should all be waiting and not seen immediately,
but `patient0` seems to be seen as soon as they arrive.
