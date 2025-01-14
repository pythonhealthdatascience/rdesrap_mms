#' Generate a list of default parameters
#'
#' This function returns a list containing the default parameters for the model.
#'
#' @return A list containing the default parameters:
#'
#' - `patient_inter`: Average interval (in minutes) between patient arrivals.
#' - `mean_n_consult_time`: Mean consultation time per patient (in minutes).
#' - `number_of_nurses`: Number of available nurses.
#' - `verbose`: Whether to print logs of when patients arrive and use resources.
#' - `data_collection_period`: Total period (in minutes) for data collection.
#' - `number_of_runs`: Number of simulation runs.
#' - `cores`: Number of cores for computation (1 = sequential, -1 = all
#'   available, otherwise specify e.g. 2, 3, 4...).
#'
#' @export

defaults <- function() {
  return(list(
    patient_inter = 4,
    mean_n_consult_time = 10,
    number_of_nurses = 5,
    verbose = FALSE,
    data_collection_period = 80,
    number_of_runs = 100,
    cores = 1
  ))
}
