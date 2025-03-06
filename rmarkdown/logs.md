Logs
================
Amy Heather
2025-03-06

- [Set up](#set-up)
- [Simulation run with logs printed to the
  console](#simulation-run-with-logs-printed-to-the-console)
  - [Interpreting the simmer log
    messages](#interpreting-the-simmer-log-messages)
  - [Compare with recorded results](#compare-with-recorded-results)
- [Customising the log messages](#customising-the-log-messages)
- [Calculate run time](#calculate-run-time)

Logs will describe events during the simulation. Simmer has built-in
functionality to generate logs, which can be activated by setting
`verbose` as TRUE.

Logs will output lots of information, so they are best used when running
the simulation for a short time with few patients. For example, to
illustrate how a simulation work, or to support debugging.

## Set up

Install the latest version of the local simulation package.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Start timer.

``` r
start_time <- Sys.time()
```

## Simulation run with logs printed to the console

We use the built-in simmer logging functionality. Within our `model`
function, we accept the parameters:

- `log_to_console` - whether to print the activity log to the console.
- `log_to_file` - whether to save the activity log to a file.
- `file_path` - path to save log to file.

Here, we will print to console and save to file:

``` r
log_file <- file.path("..", "outputs", "logs", "log_example.log")

param <- parameters(
  patient_inter = 6L,
  mean_n_consult_time = 8L,
  number_of_nurses = 1L,
  data_collection_period = 30L,
  number_of_runs = 1L,
  cores = 1L,
  log_to_console = TRUE,
  log_to_file = TRUE,
  file_path = log_file
)

verbose_run <- model(run_number = 0L, param = param)
```

    ##  [1] "Parameters:"                                                                                                                                                                                                           
    ##  [2] "patient_inter=6; mean_n_consult_time=8; number_of_nurses=1; data_collection_period=30; number_of_runs=1; scenario_name=NULL; cores=1; log_to_console=TRUE; log_to_file=TRUE; file_path=../outputs/logs/log_example.log"
    ##  [3] "Log:"                                                                                                                                                                                                                  
    ##  [4] "         0 |    source: patient          |       new: patient0         | 1.10422"                                                                                                                                      
    ##  [5] "   1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ##  [6] "   1.10422 |  resource: nurse            |   arrival: patient0         | SERVE"                                                                                                                                        
    ##  [7] "   1.10422 |    source: patient          |       new: patient1         | 1.97846"                                                                                                                                      
    ##  [8] "   1.10422 |   arrival: patient0         |  activity: Timeout          | function()"                                                                                                                                   
    ##  [9] "   1.97846 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [10] "   1.97846 |  resource: nurse            |   arrival: patient1         | ENQUEUE"                                                                                                                                      
    ## [11] "   1.97846 |    source: patient          |       new: patient2         | 4.59487"                                                                                                                                      
    ## [12] "   2.22258 |   arrival: patient0         |  activity: Release          | nurse, 1"                                                                                                                                     
    ## [13] "   2.22258 |  resource: nurse            |   arrival: patient0         | DEPART"                                                                                                                                       
    ## [14] "   2.22258 |      task: Post-Release     |          :                  | "                                                                                                                                             
    ## [15] "   2.22258 |  resource: nurse            |   arrival: patient1         | SERVE"                                                                                                                                        
    ## [16] "   2.22258 |   arrival: patient1         |  activity: Timeout          | function()"                                                                                                                                   
    ## [17] "   4.59487 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [18] "   4.59487 |  resource: nurse            |   arrival: patient2         | ENQUEUE"                                                                                                                                      
    ## [19] "   4.59487 |    source: patient          |       new: patient3         | 11.9722"                                                                                                                                      
    ## [20] "   11.9722 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [21] "   11.9722 |  resource: nurse            |   arrival: patient3         | ENQUEUE"                                                                                                                                      
    ## [22] "   11.9722 |    source: patient          |       new: patient4         | 15.2103"                                                                                                                                      
    ## [23] "   15.2103 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [24] "   15.2103 |  resource: nurse            |   arrival: patient4         | ENQUEUE"                                                                                                                                      
    ## [25] "   15.2103 |    source: patient          |       new: patient5         | 20.9497"                                                                                                                                      
    ## [26] "   20.9497 |   arrival: patient5         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [27] "   20.9497 |  resource: nurse            |   arrival: patient5         | ENQUEUE"                                                                                                                                      
    ## [28] "   20.9497 |    source: patient          |       new: patient6         | 21.832"                                                                                                                                       
    ## [29] "    21.832 |   arrival: patient6         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [30] "    21.832 |  resource: nurse            |   arrival: patient6         | ENQUEUE"                                                                                                                                      
    ## [31] "    21.832 |    source: patient          |       new: patient7         | 30.1764"                                                                                                                                      
    ## [32] "   25.3823 |   arrival: patient1         |  activity: Release          | nurse, 1"                                                                                                                                     
    ## [33] "   25.3823 |  resource: nurse            |   arrival: patient1         | DEPART"                                                                                                                                       
    ## [34] "   25.3823 |      task: Post-Release     |          :                  | "                                                                                                                                             
    ## [35] "   25.3823 |  resource: nurse            |   arrival: patient2         | SERVE"                                                                                                                                        
    ## [36] "   25.3823 |   arrival: patient2         |  activity: Timeout          | function()"

If we import the log file, we’ll see it contains the same output:

``` r
log_contents <- readLines(log_file)
print(log_contents, sep = "\n")
```

    ##  [1] "Parameters:"                                                                                                                                                                                                           
    ##  [2] "patient_inter=6; mean_n_consult_time=8; number_of_nurses=1; data_collection_period=30; number_of_runs=1; scenario_name=NULL; cores=1; log_to_console=TRUE; log_to_file=TRUE; file_path=../outputs/logs/log_example.log"
    ##  [3] "Log:"                                                                                                                                                                                                                  
    ##  [4] "         0 |    source: patient          |       new: patient0         | 1.10422"                                                                                                                                      
    ##  [5] "   1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ##  [6] "   1.10422 |  resource: nurse            |   arrival: patient0         | SERVE"                                                                                                                                        
    ##  [7] "   1.10422 |    source: patient          |       new: patient1         | 1.97846"                                                                                                                                      
    ##  [8] "   1.10422 |   arrival: patient0         |  activity: Timeout          | function()"                                                                                                                                   
    ##  [9] "   1.97846 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [10] "   1.97846 |  resource: nurse            |   arrival: patient1         | ENQUEUE"                                                                                                                                      
    ## [11] "   1.97846 |    source: patient          |       new: patient2         | 4.59487"                                                                                                                                      
    ## [12] "   2.22258 |   arrival: patient0         |  activity: Release          | nurse, 1"                                                                                                                                     
    ## [13] "   2.22258 |  resource: nurse            |   arrival: patient0         | DEPART"                                                                                                                                       
    ## [14] "   2.22258 |      task: Post-Release     |          :                  | "                                                                                                                                             
    ## [15] "   2.22258 |  resource: nurse            |   arrival: patient1         | SERVE"                                                                                                                                        
    ## [16] "   2.22258 |   arrival: patient1         |  activity: Timeout          | function()"                                                                                                                                   
    ## [17] "   4.59487 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [18] "   4.59487 |  resource: nurse            |   arrival: patient2         | ENQUEUE"                                                                                                                                      
    ## [19] "   4.59487 |    source: patient          |       new: patient3         | 11.9722"                                                                                                                                      
    ## [20] "   11.9722 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [21] "   11.9722 |  resource: nurse            |   arrival: patient3         | ENQUEUE"                                                                                                                                      
    ## [22] "   11.9722 |    source: patient          |       new: patient4         | 15.2103"                                                                                                                                      
    ## [23] "   15.2103 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [24] "   15.2103 |  resource: nurse            |   arrival: patient4         | ENQUEUE"                                                                                                                                      
    ## [25] "   15.2103 |    source: patient          |       new: patient5         | 20.9497"                                                                                                                                      
    ## [26] "   20.9497 |   arrival: patient5         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [27] "   20.9497 |  resource: nurse            |   arrival: patient5         | ENQUEUE"                                                                                                                                      
    ## [28] "   20.9497 |    source: patient          |       new: patient6         | 21.832"                                                                                                                                       
    ## [29] "    21.832 |   arrival: patient6         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                            
    ## [30] "    21.832 |  resource: nurse            |   arrival: patient6         | ENQUEUE"                                                                                                                                      
    ## [31] "    21.832 |    source: patient          |       new: patient7         | 30.1764"                                                                                                                                      
    ## [32] "   25.3823 |   arrival: patient1         |  activity: Release          | nurse, 1"                                                                                                                                     
    ## [33] "   25.3823 |  resource: nurse            |   arrival: patient1         | DEPART"                                                                                                                                       
    ## [34] "   25.3823 |      task: Post-Release     |          :                  | "                                                                                                                                             
    ## [35] "   25.3823 |  resource: nurse            |   arrival: patient2         | SERVE"                                                                                                                                        
    ## [36] "   25.3823 |   arrival: patient2         |  activity: Timeout          | function()"

### Interpreting the simmer log messages

#### Example A: `patient0`

The patient arrives at 1.10422 and requests a nurse. There is one
available (`SERVE`) so the consultation begins (`Timeout`).

    ##  [5] "  1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths"
    ##  [6] "  1.10422 |  resource: nurse            |   arrival: patient0         | SERVE"
    ...
    ##  [8] "  1.10422 |   arrival: patient0         |  activity: Timeout          | function()"

The consultation finishes at 2.22258, and the patient leaves:

    ## [13] "   2.22258 |   arrival: patient0         |  activity: Release          | nurse, 1"
    ## [14] "   2.22258 |  resource: nurse            |   arrival: patient0         | DEPART"
    ## [15] "   2.22258 |      task: Post-Release     |          :                  | "

#### Example B: `patient2`

The patient arrives at 4.59487, requests a nurse and enters a queue
(`ENQUEUE`).

    [17] "   4.59487 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths"
    [18] "   4.59487 |  resource: nurse            |   arrival: patient2         | ENQUEUE"

A nurse becomes available at 25.3823 (`SERVE`) so consultation begins
(`Timeout`).

    [35] "   25.3823 |  resource: nurse            |   arrival: patient2         | SERVE"
    [36] "   25.3823 |   arrival: patient2         |  activity: Timeout          | function()"

However, there are no further entries as the simulation ends before the
consultation ends.

### Compare with recorded results

The logs will align with the recorded results of each patient.

``` r
verbose_run[["arrivals"]]
```

    ##       name start_time  end_time activity_time resource replication
    ## 1 patient0   1.104219  2.222582      1.118362    nurse           0
    ## 2 patient1   1.978460 25.382330     23.159748    nurse           0
    ## 3 patient6  21.832022        NA            NA    nurse           0
    ## 4 patient5  20.949746        NA            NA    nurse           0
    ## 5 patient4  15.210341        NA            NA    nurse           0
    ## 6 patient3  11.972244        NA            NA    nurse           0
    ## 7 patient2   4.594872        NA            NA    nurse           0
    ##   q_time_unseen
    ## 1            NA
    ## 2            NA
    ## 3      8.167978
    ## 4      9.050254
    ## 5     14.789659
    ## 6     18.027756
    ## 7     25.405128

## Customising the log messages

The `simmer` package allows us to add additional log messages using the
`_log()` function.

Here, we take our simmer code from `model.R` but set `verbose = TRUE`.
We can then add additional `_log()` messages within the patient
trajectory.

You may find this helpful for interpreting the log messages (for
example, with the addition of emojis to make different activities more
distinct).

``` r
# Set the seed
set.seed(0L)

# Define the patient trajectory
patient <- trajectory("appointment") %>%
  simmer::log_("🚶 Arrives.") %>%
  seize("nurse", 1L) %>%
  simmer::log_("🩺 Nurse consultation begins.") %>%
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("nurse", 1L) %>%
  simmer::log_("🚪 Leaves.")

env <- simmer("simulation", verbose = FALSE) %>%
  add_resource("nurse", param[["number_of_nurses"]]) %>%
  add_generator("patient", patient, function() {
    rexp(n = 1L, rate = 1L / param[["patient_inter"]])
  }) %>%
  simmer::run(param[["data_collection_period"]])
```

    ## 1.10422: patient0: 🚶 Arrives.
    ## 1.10422: patient0: 🩺 Nurse consultation begins.
    ## 1.97846: patient1: 🚶 Arrives.
    ## 2.22258: patient0: 🚪 Leaves.
    ## 2.22258: patient1: 🩺 Nurse consultation begins.
    ## 4.59487: patient2: 🚶 Arrives.
    ## 11.9722: patient3: 🚶 Arrives.
    ## 15.2103: patient4: 🚶 Arrives.
    ## 20.9497: patient5: 🚶 Arrives.
    ## 21.832: patient6: 🚶 Arrives.
    ## 25.3823: patient1: 🚪 Leaves.
    ## 25.3823: patient2: 🩺 Nurse consultation begins.

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

    ## Notebook run time: 0m 0s
