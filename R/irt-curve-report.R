#' Generate Rasch / 2PL item curve diagnostic PDF report(s)
#'
#' Fits Rasch and 2PL models (via TAM) to a binary item-response data frame
#' and produces up to three PDF diagnostic reports: item characteristic
#' curves, Wright maps, item fit tables, and (optionally) a cross-method
#' Rasch difficulty comparison (JML/CML/MML). This intentionally calls
#' TAM's own plotting/fit functions directly rather than reconstructing
#' curves by hand, so the output matches exactly what TAM itself computes.
#'
#' Import your data yourself first (e.g. with `rio::import()`) and create
#' `output_dir` yourself if you want control over it -- this function only
#' takes the data frame and a directory path, not a file path, keeping its
#' own argument list short.
#'
#' @param data A data frame of person rows and item columns, already
#'   imported.
#' @param id_cols Character vector of column name(s) identifying each
#'   person, or `NULL` if `data` has no id column and every row is a person.
#' @param item_cols Character vector of item column names to analyze, or
#'   `NULL` to use every column in `data` not in `id_cols`.
#' @param output_dir Directory the PDF(s) are written to. Created if it
#'   doesn't already exist.
#' @param pdfs Which report(s) to produce. Any subset of
#'   `c("rasch", "2pl", "comparison")`; defaults to all three. Both models
#'   are always fit regardless of `pdfs` (the comparison needs the Rasch
#'   fit, and fitting is the expensive step either way).
#' @param dataset_name Label used in plot titles and output filenames.
#' @param icc_type,icc_ngroups Passed through to the ICC plot (`type`,
#'   `ngroups`).
#' @param icc_mfrow Optional `c(rows, cols)` to pack multiple item ICCs per
#'   PDF page. `NULL` keeps TAM's default of one item per page.
#' @param fit_rows_per_page Rows per page in the item-fit tables.
#' @param fit_mnsq_low,fit_mnsq_high MNSQ range considered acceptable fit;
#'   items outside this range are flagged red on the fit-colored Wright Map.
#'
#' @return Invisibly, a named list of the file paths written (only the
#'   entries requested via `pdfs`: `rasch`, `two_pl`, and/or `comparison`).
#'
#' @examples
#' \dontrun{
#' data <- rio::import("my_data.dta")
#' irt_curve_report(
#'   data, id_cols = "person_id", item_cols = paste0("item", 1:30),
#'   output_dir = "reports", dataset_name = "my_data"
#' )
#' }
#' @export
irt_curve_report <- function(data,
                              id_cols = NULL,
                              item_cols = NULL,
                              output_dir = ".",
                              pdfs = c("rasch", "2pl", "comparison"),
                              dataset_name = "dataset",
                              icc_type = "expected",
                              icc_ngroups = 10,
                              icc_mfrow = NULL,
                              fit_rows_per_page = 25,
                              fit_mnsq_low = 0.7,
                              fit_mnsq_high = 1.3) {

  pdfs <- match.arg(pdfs, c("rasch", "2pl", "comparison"), several.ok = TRUE)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  prep <- .prepare_data(data, id_cols = id_cols, item_cols = item_cols)
  resp_all   <- prep$resp_all
  item_names <- prep$item_names
  n_items    <- prep$n_items

  models  <- .fit_models(resp_all)
  m_rasch <- models$m_rasch
  m_2pl   <- models$m_2pl

  diffs   <- .item_difficulties(m_rasch, m_2pl, item_names)
  b_rasch <- diffs$b_rasch
  b_2pl   <- diffs$b_2pl

  fit_rasch_df <- .build_fit_table(m_rasch, item_names, n_items,
                                    prep$item_n_responded, prep$item_n_correct, prep$item_pct_correct)
  fit_2pl_df   <- .build_fit_table(m_2pl, item_names, n_items,
                                    prep$item_n_responded, prep$item_n_correct, prep$item_pct_correct)

  misfit_rasch <- .compute_misfit_flag(fit_rasch_df, fit_mnsq_low, fit_mnsq_high)
  misfit_2pl   <- .compute_misfit_flag(fit_2pl_df, fit_mnsq_low, fit_mnsq_high)

  file_label <- gsub("[^a-zA-Z0-9_]", "_", dataset_name)
  paths <- list()

  if ("rasch" %in% pdfs) {
    paths$rasch <- file.path(output_dir, sprintf("curves_%s_Rasch.pdf", file_label))
    .write_model_pdf(paths$rasch, "Rasch", m_rasch, b_rasch, fit_rasch_df, misfit_rasch,
                      n_items, dataset_name, icc_type, icc_ngroups, icc_mfrow,
                      fit_rows_per_page, fit_mnsq_low, fit_mnsq_high,
                      difficulty_label = "Difficulty (xsi.item)")
  }

  if ("2pl" %in% pdfs) {
    paths$two_pl <- file.path(output_dir, sprintf("curves_%s_2PL.pdf", file_label))
    .write_model_pdf(paths$two_pl, "2PL", m_2pl, b_2pl, fit_2pl_df, misfit_2pl,
                      n_items, dataset_name, icc_type, icc_ngroups, icc_mfrow,
                      fit_rows_per_page, fit_mnsq_low, fit_mnsq_high,
                      difficulty_label = "Difficulty (xsi.item / slope)")
  }

  if ("comparison" %in% pdfs) {
    cmp <- .cross_method_compare(resp_all, item_names, n_items, b_rasch)
    paths$comparison <- file.path(output_dir, sprintf("curves_%s_Comparison.pdf", file_label))
    .write_comparison_pdf(paths$comparison, cmp, b_rasch, b_2pl, m_rasch, n_items,
                           dataset_name, fit_rows_per_page)
  }

  invisible(paths)
}
