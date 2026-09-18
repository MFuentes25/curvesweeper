#' Prepare item-response data for IRT model fitting
#'
#' Splits a data frame into person IDs and an item-response matrix, coerces
#' items to numeric 0/1, and drops items with fewer than two observed
#' response categories (TAM cannot estimate parameters for those).
#'
#' @param data A data frame already imported by the caller (e.g. via
#'   `rio::import()`).
#' @param id_cols Character vector of column name(s) identifying each
#'   person, or `NULL` if `data` has no id column.
#' @param item_cols Character vector of item column names to analyze, or
#'   `NULL` to use every column not in `id_cols`.
#'
#' @return A list with `resp_all` (data frame of numeric 0/1 items, after
#'   exclusions), `item_names`, `n_items`, `item_n_responded`,
#'   `item_n_correct`, `item_pct_correct`, `item_summary`, and
#'   `items_excluded`.
#' @keywords internal
.prepare_data <- function(data, id_cols = NULL, item_cols = NULL) {
  if (is.null(item_cols)) {
    item_cols <- setdiff(names(data), id_cols)
  }

  resp_all <- data[, item_cols, drop = FALSE]
  resp_all <- as.data.frame(lapply(resp_all, function(x) as.numeric(as.character(x))))

  item_n_responded <- sapply(resp_all, function(x) sum(!is.na(x)))
  item_n_correct   <- sapply(resp_all, function(x) sum(x == 1, na.rm = TRUE))
  item_pct_correct <- round(100 * item_n_correct / item_n_responded, 1)

  item_summary <- data.frame(
    item        = names(resp_all),
    n_responded = item_n_responded,
    n_correct   = item_n_correct,
    pct_correct = item_pct_correct,
    row.names   = NULL
  )

  # TAM cannot estimate items with only one observed response category
  # (e.g. everyone got it right, or almost no one answered it).
  n_unique_responses <- sapply(resp_all, function(x) length(unique(stats::na.omit(x))))
  items_excluded <- names(resp_all)[n_unique_responses < 2]

  if (length(items_excluded) > 0) {
    message(sprintf(
      "Excluding %d item(s) with fewer than 2 response categories (no variance): %s",
      length(items_excluded), paste(items_excluded, collapse = ", ")
    ))
  }

  resp_all   <- resp_all[, !(names(resp_all) %in% items_excluded), drop = FALSE]
  item_names <- colnames(resp_all)
  n_items    <- length(item_names)

  # Re-key summary stats to the (possibly narrowed) item set, in
  # item_names order, so downstream code can always index by item_names.
  item_n_responded <- item_n_responded[item_names]
  item_n_correct   <- item_n_correct[item_names]
  item_pct_correct <- item_pct_correct[item_names]

  list(
    resp_all         = resp_all,
    item_names       = item_names,
    n_items          = n_items,
    item_n_responded = item_n_responded,
    item_n_correct   = item_n_correct,
    item_pct_correct = item_pct_correct,
    item_summary     = item_summary,
    items_excluded   = items_excluded
  )
}
