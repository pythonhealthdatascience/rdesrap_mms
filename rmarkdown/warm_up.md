Warm up period
================
Amy Heather
2025-03-06

- [Set up](#set-up)
- [Attempt at incorporating a warm-up period into
  `model.py`](#attempt-at-incorporating-a-warm-up-period-into-modelpy)
  - [Run the model](#run-the-model)
  - [Trim the `arrivals` and `resources` dataframes
    produced](#trim-the-arrivals-and-resources-dataframes-produced)
- [Understanding the times in
  arrivals](#understanding-the-times-in-arrivals)
- [Inspired by `treat-sim-simmer`](#inspired-by-treat-sim-simmer)
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

## Understanding the times in arrivals

``` r
arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE)
arrivals %>%
  mutate(total_time = end_time - start_time) %>%
  filter(total_time > activity_time)
```

    ##         name start_time   end_time activity_time resource replication
    ## 1   patient0   3.020727   4.477795      1.457067    nurse           1
    ## 2   patient3  14.409821  15.880281      1.470460    nurse           1
    ## 3   patient3  15.880281  23.500580      7.620299   doctor           1
    ## 4   patient2  14.888401  28.795753     13.907351   doctor           1
    ## 5  patient12  53.277449  63.504708     10.227259   doctor           1
    ## 6  patient13  64.039645  67.052475      3.012830   doctor           1
    ## 7  patient14  59.425075  70.223886     10.798811    nurse           1
    ## 8  patient10  61.458873  73.989927     12.531054   doctor           1
    ## 9  patient15  60.365185  74.381490     12.922616    nurse           1
    ## 10 patient16  64.478172  74.423730      9.945558    nurse           1
    ## 11  patient9  44.791170  84.380499     39.589329    nurse           1
    ## 12 patient17  69.650671  89.728995     20.078324    nurse           1
    ## 13 patient20  84.332042  92.073919      7.741878    nurse           1
    ## 14 patient24 110.313986 115.906809      3.887868   doctor           1
    ## 15 patient26 119.305847 127.451205      8.145358    nurse           1
    ## 16 patient22 104.556807 128.573580     23.124716   doctor           1
    ##    total_time
    ## 1    1.457067
    ## 2    1.470460
    ## 3    7.620299
    ## 4   13.907351
    ## 5   10.227259
    ## 6    3.012830
    ## 7   10.798811
    ## 8   12.531054
    ## 9   14.016305
    ## 10   9.945558
    ## 11  39.589329
    ## 12  20.078324
    ## 13   7.741878
    ## 14   5.592822
    ## 15   8.145358
    ## 16  24.016772

## Inspired by `treat-sim-simmer`

Calculate utilisation from `get_mon_arrivals()` (and do not use
`get_mon_resources()`).

``` r
# Filter to patients who arrived after the warm-up period
arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE) %>%
  group_by(name) %>%
  filter(all(start_time >= param[["warm_up_period"]])) %>%
  ungroup()

resource_counts <- tibble(
  resource = c("doctor", "nurse"),
  count = c(number_of_doctors, param[["number_of_nurses"]])
)

# Calculate utilisation
arrivals %>%
  mutate(waiting_time = end_time - start_time - activity_time) %>%
  group_by(resource) %>%
  summarise(in_use = sum(activity_time, na.rm=TRUE)) %>%
  merge(resource_counts, by = "resource", all=TRUE) %>%
  mutate(utilisation = in_use / (param[["data_collection_period"]] * count))
```

    ##   resource    in_use count utilisation
    ## 1   doctor  90.27633     3   0.3761514
    ## 2    nurse 155.35557     5   0.3883889

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

    ##         name start_time  end_time activity_time resource replication
    ## 1   patient0   3.775909  6.690044      2.914135    nurse           1
    ## 2   patient1   9.684123 18.405496      8.721373    nurse           1
    ## 3   patient2  10.383099 42.996737     24.591241    nurse           1
    ## 4   patient3  24.857942 67.748808     24.752071    nurse           1
    ## 5   patient4  27.556356        NA            NA    nurse           1
    ## 6   patient5  32.339194        NA            NA    nurse           1
    ## 7   patient6  33.074424        NA            NA    nurse           1
    ## 8   patient7  40.028099        NA            NA    nurse           1
    ## 9   patient8  43.838249        NA            NA    nurse           1
    ## 10  patient9  65.957920        NA            NA    nurse           1
    ## 11 patient10  71.230636        NA            NA    nurse           1

``` r
wu_resources
```

    ##    resource      time server queue capacity queue_size system limit replication
    ## 1     nurse  3.775909      1     0        1        Inf      1   Inf           1
    ## 2     nurse  6.690044      0     0        1        Inf      0   Inf           1
    ## 3     nurse  9.684123      1     0        1        Inf      1   Inf           1
    ## 4     nurse 10.383099      1     1        1        Inf      2   Inf           1
    ## 5     nurse 18.405496      1     0        1        Inf      1   Inf           1
    ## 6     nurse 24.857942      1     1        1        Inf      2   Inf           1
    ## 7     nurse 27.556356      1     2        1        Inf      3   Inf           1
    ## 8     nurse 32.339194      1     3        1        Inf      4   Inf           1
    ## 9     nurse 33.074424      1     4        1        Inf      5   Inf           1
    ## 10    nurse 40.028099      1     5        1        Inf      6   Inf           1
    ## 11    nurse 42.996737      1     4        1        Inf      5   Inf           1
    ## 12    nurse 43.838249      1     5        1        Inf      6   Inf           1
    ## 13    nurse 65.957920      1     6        1        Inf      7   Inf           1
    ## 14    nurse 67.748808      1     5        1        Inf      6   Inf           1
    ## 15    nurse 71.230636      1     6        1        Inf      7   Inf           1

``` r
arrivals %>% arrange(start_time)
```

    ##         name start_time end_time activity_time resource replication
    ## 1   patient0   3.273733 15.04333    11.7695944    nurse           1
    ## 2   patient1   4.958401 27.88118    12.8378518    nurse           1
    ## 3   patient2  16.780977 51.34742    23.4662421    nurse           1
    ## 4   patient3  18.251579 52.09279     0.7453705    nurse           1
    ## 5   patient4  21.080906 58.57300     6.4802031    nurse           1
    ## 6   patient5  21.611270 62.64320     4.0702070    nurse           1
    ## 7   patient6  21.908465       NA            NA    nurse           1
    ## 8   patient7  24.802028       NA            NA    nurse           1
    ## 9   patient8  44.596692       NA            NA    nurse           1
    ## 10  patient9  49.580757       NA            NA    nurse           1
    ## 11 patient10  56.757183       NA            NA    nurse           1
    ## 12 patient11  63.359523       NA            NA    nurse           1
    ## 13 patient12  64.868228       NA            NA    nurse           1
    ## 14 patient13  68.494299       NA            NA    nurse           1
    ## 15 patient14  72.252013       NA            NA    nurse           1
    ## 16 patient15  73.427150       NA            NA    nurse           1
    ## 17 patient16  78.826556       NA            NA    nurse           1

``` r
resources
```

    ##    resource      time server queue capacity queue_size system limit replication
    ## 1     nurse  3.273733      1     0        1        Inf      1   Inf           1
    ## 2     nurse  4.958401      1     1        1        Inf      2   Inf           1
    ## 3     nurse 15.043328      1     0        1        Inf      1   Inf           1
    ## 4     nurse 16.780977      1     1        1        Inf      2   Inf           1
    ## 5     nurse 18.251579      1     2        1        Inf      3   Inf           1
    ## 6     nurse 21.080906      1     3        1        Inf      4   Inf           1
    ## 7     nurse 21.611270      1     4        1        Inf      5   Inf           1
    ## 8     nurse 21.908465      1     5        1        Inf      6   Inf           1
    ## 9     nurse 24.802028      1     6        1        Inf      7   Inf           1
    ## 10    nurse 27.881179      1     5        1        Inf      6   Inf           1
    ## 11    nurse 44.596692      1     6        1        Inf      7   Inf           1
    ## 12    nurse 49.580757      1     7        1        Inf      8   Inf           1
    ## 13    nurse 51.347421      1     6        1        Inf      7   Inf           1
    ## 14    nurse 52.092792      1     5        1        Inf      6   Inf           1
    ## 15    nurse 56.757183      1     6        1        Inf      7   Inf           1
    ## 16    nurse 58.572995      1     5        1        Inf      6   Inf           1
    ## 17    nurse 62.643202      1     4        1        Inf      5   Inf           1
    ## 18    nurse 63.359523      1     5        1        Inf      6   Inf           1
    ## 19    nurse 64.868228      1     6        1        Inf      7   Inf           1
    ## 20    nurse 68.494299      1     7        1        Inf      8   Inf           1
    ## 21    nurse 72.252013      1     8        1        Inf      9   Inf           1
    ## 22    nurse 73.427150      1     9        1        Inf     10   Inf           1
    ## 23    nurse 78.826556      1    10        1        Inf     11   Inf           1

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
