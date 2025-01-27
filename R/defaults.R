#' @title R6 class returning list of default model parameters
#'
#' @description
#' `Defaults` is an R6 class instead of a function because this allows us to
#' return a list whilst also having functionality which only allows
#' modification of existing attributes, and not the addition of new attributes.
#' This helps avoid an error where a parameter appears to have been changed,
#' but remains the same as the attribute name used was incorrect.
#'
#' The returned list contains the following parameters:
#'
#' \itemize{
#'   \item \code{patient_inter}: Mean inter-arrival time between patients
#'   in minutes.
#'   \item \code{mean_n_consult_time}: Mean nurse consultation time in
#'   minutes.
#'   \item \code{number_of_nurses}: Number of available nurses (integer).
#'   \item \code{data_collection_period}: Duration of data collection
#'   period in minutes.
#'   \item \code{number_of_runs}: Number of simulation runs (integer).
#'   \item \code{scenario_name}: Label for the scenario (int|float|string).
#'   \item \code{cores}: Number of cores to use for parallel execution
#'   (integer).
#'   \item \code{log_to_console}: Whether to print activity log to console.
#'   \item \code{log_to_file}: Whether to save activity log to file.
#'   \item \code{file_path}: Path to save log to file.
#' }
#'
#' @docType class
#' @importFrom R6 R6Class
#' @export
#' @rdname defaults

Defaults <- R6Class( # nolint

  classname = "Defaults",
  private = list(
    defaults = list(
      patient_inter = 4L,
      mean_n_consult_time = 10L,
      number_of_nurses = 5L,
      data_collection_period = 80L,
      number_of_runs = 100L,
      scenario_name = NULL,
      cores = 1L,
      log_to_console = FALSE,
      log_to_file = FALSE,
      file_path = NULL
    ),
    allowed_keys = NULL
  ),

  public = list(

    #' @description
    #' Initialises the R6 object, setting the allowed keys based on the
    #' defaults.
    initialize = function() {
      private[["allowed_keys"]] <- names(private[["defaults"]])
    },

    #' @description
    #' Retrieves the current list of default parameters.
    get = function() {
      private[["defaults"]]
    },

    #' @description
    #' Update the defaults list with new values.
    #' @param new_values A named list containing the parameters to be updated.
    update = function(new_values) {
      new_keys <- names(new_values)
      invalid_keys <- new_keys[!new_keys %in% private[["allowed_keys"]]]
      if (length(invalid_keys) > 0L) {
        stop(
          "Error: Attempted to add the following invalid keys: ",
          toString(invalid_keys),
          "\nYou can only have keys in the defaults list:\n",
          paste(private[["allowed_keys"]], collapse = ",\n")
        )
      }
      for (key in new_keys) {
        private[["defaults"]][[key]] <- new_values[[key]]
      }
    }
  )
)


#' Wrapper for Defaults() R6 class, to create a new instance.
#'
#' `defaults()` is a wrapper which enables us to create a new instance of
#' the class without needing to run `Defaults[["new"]]()` every time.
#'
#' @return Instance of the Defaults class.
#' 
#' @export
#' @rdname defaults

defaults <- function() {
  return(Defaults[["new"]]())
}
