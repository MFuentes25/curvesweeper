#' Item fit table (tam.fit), with N responded / N correct / % correct merged in
#'
#' `tam.fit()` rows come back in the same order as the columns of the
#' fitted response data, so N responded/correct are attached POSITIONALLY
#' rather than by matching row names/labels -- matching on labels was the
#' source of an earlier "all NA" bug (`tam.fit()`'s rownames aren't
#' guaranteed to carry usable item labels). A row-count check guards this
#' assumption so it's never silently violated.
#' @keywords internal
.build_fit_table <- function(tam_object, item_names, n_items,
                              item_n_responded, item_n_correct, item_pct_correct) {
  fit <- TAM::tam.fit(tam_object)$itemfit

  if (nrow(fit) != n_items) {
    stop(sprintf(
      "tam.fit() returned %d rows but there are %d items -- cannot align N responded/correct safely.",
      nrow(fit), n_items
    ))
  }

  fit <- data.frame(item = item_names, fit, row.names = NULL)
  fit$parameter <- NULL  # drop if present/duplicated; item names above are authoritative

  fit$n_responded <- item_n_responded[item_names]
  fit$n_correct   <- item_n_correct[item_names]
  fit$pct_correct <- item_pct_correct[item_names]

  .round_df(fit, 2)
}

#' Flag misfitting items (for the fit-colored Wright Map)
#' @keywords internal
.compute_misfit_flag <- function(fit_df, fit_mnsq_low, fit_mnsq_high) {
  cols       <- names(fit_df)
  outfit_col <- intersect(c("Outfit", "outfit"), cols)[1]
  infit_col  <- intersect(c("Infit", "infit"), cols)[1]
  if (is.na(outfit_col) || is.na(infit_col)) {
    message("Could not find Infit/Outfit columns for misfit coloring; defaulting to all black.")
    return(rep(FALSE, nrow(fit_df)))
  }
  (fit_df[[outfit_col]] < fit_mnsq_low | fit_df[[outfit_col]] > fit_mnsq_high |
    fit_df[[infit_col]]  < fit_mnsq_low | fit_df[[infit_col]]  > fit_mnsq_high)
}
