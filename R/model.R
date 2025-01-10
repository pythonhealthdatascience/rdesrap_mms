#' Simple Reproducible Simmer Discrete-Event Simulation (DES) Model.
#'
#' Licence:
#'     This project is licensed under the MIT Licence. See the LICENSE file for
#'     more details.

library(simmer)
library(parallel)
#library(parallel, include.only = c("mclapply"))
library(future, include.only = c("plan", "multisession", "sequential"))
library(future.apply, include.only = c("future_lapply"))

# TODO: Read this: https://www.r-bloggers.com/2020/09/future-1-19-1-making-sure-proper-random-numbers-are-produced-in-parallel-processing/

set.seed(42)

# Initialise simulation environment
# If set verbose = true, will print times when patient arrive + use resource
env <- simmer(name = "TemplateSim", verbose = TRUE)
env

# Define patient trajectory
patient <- trajectory("appointment") %>%
  seize("nurse", 1) %>%
  timeout(function() rnorm(1, 15)) %>%
  release("nurse", 1)

###############################################################################
# RUN EXAMPLES (SINGLE + REPLICATION)

# Set resources and define patient arrivals
env %>%
  add_resource("nurse", 1) %>%
  add_generator("patient", patient, function() rnorm(1, 10, 2))

# Run once
env %>%
  run(80)

# Run 100 times
envs <- lapply(1:100, function(i) {
  simmer(name = "TemplateSim", verbose = FALSE) %>%
    add_resource("nurse", 1) %>%
    add_generator("patient", patient, function() rnorm(1, 10, 2)) %>%
    run(80)
})

# Get results
envs[[1]] %>% get_n_generated("patient")

envs %>%
  get_mon_resources() %>%
  head()

envs %>%
  get_mon_arrivals() %>%
  head()

###############################################################################
# PARALLEL PROCESSING

# MCLAPPLY (QUICKEST AND SIMPLEST BUT DOESN'T WORK ON WINDOWS)
# ------------------------------------------------------------
# Note: can't resume execution of these envs (whilst can normally) as the C++
# simulation cores are destroyed
envs <- mclapply(1:100, function(i) {
  simmer(name = "TemplateSim", verbose = FALSE) %>%
    add_resource("nurse", 1) %>%
    add_generator("patient", patient, function() rnorm(1, 10, 2)) %>%
    run(80) %>%
    wrap()
})

# PARLAPPLY
# ---------
# Define the patient trajectory as a function
patient_trajectory <- function() {
  trajectory("appointment") %>%
    seize("nurse", 1) %>%
    timeout(function() rnorm(1, 15)) %>%
    release("nurse", 1)
}

# Create a cluster
cl <- makeCluster(detectCores() - 1)

# Load required libraries in each worker
clusterEvalQ(cl, {
  library(simmer)
})

# Export the patient_trajectory function to the cluster
clusterExport(cl, varlist = c("patient_trajectory"))

# Run simulations in parallel
envs <- parLapply(cl, 1:100, function(i) {
  # Define the trajectory within the worker
  patient <- patient_trajectory()

  # Create and run a simmer environment
  simmer(name = "TemplateSim", verbose = FALSE) %>%
    add_resource("nurse", 1) %>%
    add_generator("patient", patient, function() rnorm(1, 10, 2)) %>%
    run(80) %>%
    wrap()
})

# Stop the cluster
stopCluster(cl)

# FUTURE.APPLY
# ------------
# Define the simulation function
simulate_env <- function(i) {
  # Load simmer inside each worker
  library(simmer)

  # Define patient trajectory
  patient <- trajectory("appointment") %>%
    seize("nurse", 1) %>%
    timeout(function() rnorm(1, 15)) %>%
    release("nurse", 1)

  # Create and run the simulation
  env <- simmer(name = "TemplateSim", verbose = FALSE) %>%
    add_resource("nurse", 1) %>%
    add_generator("patient", patient, function() rnorm(1, 10, 2)) %>%
    run(80) %>%
    wrap()

  # Return the monitored arrivals as a data frame
  env %>%
    get_mon_arrivals() %>%
    as.data.frame()
}

# Plan the future strategy
# plan(multisession)  # ISSUE: Gets stuck running forever
# plan(sequential)
plan(multisession, workers = 2)

# Run the simulations in parallel and collect results
results <- future_lapply(1:20, simulate_env, future.seed = TRUE)

# Combine all results
do.call(rbind, results) %>%
  head()
