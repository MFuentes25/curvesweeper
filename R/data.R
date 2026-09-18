#' Simulated item-response test dataset
#'
#' A small simulated dataset shaped like the real data this package was
#' built for: an id column plus item columns `l1`..`l25`, with structural
#' (non-random) missingness -- harder items are progressively more likely
#' to be missing for lower-ability people -- and two persons with no
#' responses at all, to exercise the JML/CML "fully-NA person" handling.
#' Useful for trying `irt_curve_report()` quickly: fitting on this data
#' takes seconds, versus 1-1.5 minutes per model on a real ~14,000-person
#' dataset.
#'
#' @format A data frame with 400 rows and 26 columns:
#' \describe{
#'   \item{id}{Person identifier, 1:400.}
#'   \item{l1, l2, ..., l25}{Binary (0/1) item responses, `NA` where
#'     missing/unadministered.}
#' }
#' @source Simulated; see `data-raw/simulate-data.R` for the generating code.
"sim_test_data"
