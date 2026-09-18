#' Fit the Rasch (MML) and 2PL models via TAM
#' @keywords internal
.fit_models <- function(resp_all) {
  message("Fitting Rasch model (TAM, marginal maximum likelihood)...")
  m_rasch <- TAM::tam(resp_all)

  message("Fitting 2PL model (TAM)...")
  m_2pl <- TAM::tam.mml.2pl(resp_all, irtmodel = "2PL")

  list(m_rasch = m_rasch, m_2pl = m_2pl)
}

#' @keywords internal
.ordered_col <- function(item_table, col, item_names) {
  vals <- stats::setNames(item_table[[col]], item_table$item)
  as.numeric(vals[item_names])
}

#' Item difficulty on the theta scale, for both models
#'
#' Rasch's `xsi.item` is already on the theta scale (slope fixed at 1).
#' 2PL's `xsi.item` is the raw additive parameter (AXsi) and must be
#' divided by the item's own slope to land on the theta scale -- skipping
#' this division puts 2PL item locations on a different scale than person
#' ability (the Wright Map bug this project hit early on: item locations
#' in the range -20 to +118 instead of a normal -4..4 range).
#' @keywords internal
.item_difficulties <- function(m_rasch, m_2pl, item_names) {
  b_rasch <- stats::setNames(.ordered_col(m_rasch$item, "xsi.item", item_names), item_names)

  slope_col <- grep("^B\\.Cat1", names(m_2pl$item), value = TRUE)[1]
  if (is.na(slope_col)) {
    stop("Could not find the 2PL slope column (B.Cat1...) in m_2pl$item.")
  }

  a_2pl <- stats::setNames(.ordered_col(m_2pl$item, slope_col, item_names), item_names)
  b_2pl <- stats::setNames(.ordered_col(m_2pl$item, "xsi.item", item_names) / a_2pl, item_names)

  list(b_rasch = b_rasch, a_2pl = a_2pl, b_2pl = b_2pl)
}
