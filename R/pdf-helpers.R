#' @keywords internal
.round_df <- function(df, digits) {
  nums <- vapply(df, is.numeric, FUN.VALUE = logical(1))
  df[, nums] <- round(df[, nums], digits = digits)
  df
}

#' @keywords internal
.tamICC <- function(tam_object, items, ...) {
  op <- options()
  on.exit(options(op))
  graphics::plot(tam_object, items, ...)
}

#' Paginated table pages (item fit tables, method comparison table)
#'
#' `grid.arrange()` already starts a new page on its own -- an earlier
#' version also called `grid.newpage()` explicitly, which produced a blank
#' page before every table page. Single-page tables (n <= rows_per_page,
#' e.g. the 3-row method comparison) skip the "(x N-M of P)" suffix
#' entirely, since it adds nothing when there's no real pagination.
#' @keywords internal
.add_table_pages <- function(df, title_prefix, rows_per_page = 25, row_label = "items") {
  n <- nrow(df)
  starts <- seq(1, n, by = rows_per_page)
  tt <- gridExtra::ttheme_minimal(
    core    = list(fg_params = list(fontsize = 8)),
    colhead = list(fg_params = list(fontsize = 8, fontface = "bold"))
  )
  for (s in starts) {
    e <- min(s + rows_per_page - 1, n)
    chunk <- df[s:e, , drop = FALSE]
    title <- if (n <= rows_per_page) {
      title_prefix
    } else {
      sprintf("%s (%s %d-%d of %d)", title_prefix, row_label, s, e, n)
    }
    gridExtra::grid.arrange(
      gridExtra::tableGrob(chunk, rows = NULL, theme = tt),
      top = grid::textGrob(title, gp = grid::gpar(fontface = "bold", fontsize = 14))
    )
  }
}

#' @keywords internal
.build_summary_lines <- function(tam_object, model_label) {
  rel <- tryCatch(round(tam_object$EAP.rel[1], 3), error = function(e) NA)
  c(
    sprintf("%s reliability", model_label),
    sprintf("EAP reliability: %s", ifelse(is.na(rel), "not available", rel)),
    "",
    utils::capture.output(summary(tam_object))
  )
}

#' @keywords internal
.add_text_pages <- function(lines, title, lines_per_page = 45) {
  n <- length(lines)
  starts <- seq(1, max(n, 1), by = lines_per_page)
  for (s in starts) {
    e <- min(s + lines_per_page - 1, n)
    grid::grid.newpage()
    grid::grid.text(title, y = grid::unit(1, "npc") - grid::unit(1, "lines"),
                     gp = grid::gpar(fontface = "bold", fontsize = 14))
    grid::grid.text(paste(lines[s:e], collapse = "\n"),
                     x = grid::unit(0.02, "npc"), y = grid::unit(1, "npc") - grid::unit(2.5, "lines"),
                     just = c("left", "top"),
                     gp = grid::gpar(fontfamily = "mono", fontsize = 7.5))
  }
}

#' @keywords internal
.add_histogram_page <- function(values, title, xlab) {
  graphics::hist(values, main = title, xlab = xlab, col = "grey85", border = "white")
}

#' Self-built scatter + marginal histograms (base graphics only)
#'
#' `psych::scatterHist()` persistently threw "object 'Md' not found" here
#' even with documented fixes (`ellipse = FALSE`, `show.d = FALSE`), so
#' this sidesteps it with a fully self-contained equivalent (SE of
#' measurement on x, ability estimate on y). psych is not a dependency of
#' this package.
#' @keywords internal
.add_scatterhist_page <- function(se_vec, theta_vec, title) {
  valid <- !is.na(se_vec) & !is.na(theta_vec)
  x <- se_vec[valid]; y <- theta_vec[valid]

  if (length(x) < 2) {
    graphics::plot.new()
    graphics::text(0.5, 0.5, paste0(title, "\n\n(not enough non-missing data)"), cex = 1)
    return(invisible(NULL))
  }

  op <- graphics::par(no.readonly = TRUE)
  on.exit({ graphics::par(op); graphics::layout(1) })

  graphics::layout(matrix(c(2, 0, 1, 3), ncol = 2, byrow = TRUE),
                    widths = c(4, 1), heights = c(1, 4))

  graphics::par(mar = c(4, 4, 1, 1))
  graphics::plot(x, y, pch = 16, col = grDevices::adjustcolor("steelblue", alpha.f = 0.4),
                 xlab = "Standard error of measurement", ylab = "Ability estimate (EAP)")

  graphics::par(mar = c(0, 4, 2, 1))
  graphics::hist(x, main = title, axes = FALSE, xlab = "", ylab = "",
                 col = "grey85", border = "white")

  graphics::par(mar = c(4, 0, 1, 2))
  hist_y <- graphics::hist(y, plot = FALSE)
  graphics::barplot(hist_y$counts, horiz = TRUE, space = 0, axes = FALSE,
                     col = "grey85", border = "white")
}
