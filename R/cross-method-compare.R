#' Cross-method Rasch difficulty comparison (JML / CML / MML)
#'
#' Fits the same Rasch model three ways -- joint ML (`sirt::rasch.jml`),
#' conditional ML (`eRm::RM`), and marginal ML (already fit via TAM) -- and
#' correlates the resulting item difficulties. Close agreement across all
#' three is reassuring evidence the difficulties aren't an artifact of one
#' particular estimation approach.
#'
#' JML/CML both fail on persons with zero non-missing responses (eRm says
#' so explicitly; JML's "missing value where TRUE/FALSE needed" is almost
#' certainly the same cause, just a less informative error), so those
#' persons are dropped for these two fits only -- TAM handles them fine
#' everywhere else. Each method is wrapped defensively: a failure just
#' drops it from the comparison instead of stopping the report.
#' @keywords internal
.cross_method_compare <- function(resp_all, item_names, n_items, b_rasch) {
  has_any_response <- rowSums(!is.na(resp_all)) > 0
  n_fully_na <- sum(!has_any_response)
  if (n_fully_na > 0) {
    message(sprintf(
      "Dropping %d person(s) with no responses at all (JML/CML comparison fits only).",
      n_fully_na
    ))
  }
  resp_for_comparison <- resp_all[has_any_response, , drop = FALSE]

  diff_jml <- tryCatch({
    m_jml <- sirt::rasch.jml(resp_for_comparison, progress = FALSE)
    stats::setNames(as.numeric(m_jml$item$itemdiff), item_names)
  }, error = function(e) {
    message("JML (sirt::rasch.jml) failed, skipping: ", conditionMessage(e))
    stats::setNames(rep(NA_real_, n_items), item_names)
  })

  diff_cml <- tryCatch({
    m_cml <- eRm::RM(resp_for_comparison)
    # eRm reports "easiness" (beta); difficulty is its negative. Its
    # default sum-zero identification constraint gives one parameter per
    # item, in the same column order as resp_all.
    stats::setNames(as.numeric(m_cml$betapar) * -1, item_names)
  }, error = function(e) {
    message("CML (eRm::RM) failed, skipping: ", conditionMessage(e))
    stats::setNames(rep(NA_real_, n_items), item_names)
  })

  method_compare_df <- data.frame(
    item = item_names,
    JML  = diff_jml,
    CML  = diff_cml,
    MML  = b_rasch,
    row.names = NULL
  )

  method_compare_cor <- round(
    stats::cor(method_compare_df[, c("JML", "CML", "MML")], use = "pairwise.complete.obs"),
    4
  )

  list(df = method_compare_df, cor = method_compare_cor)
}
