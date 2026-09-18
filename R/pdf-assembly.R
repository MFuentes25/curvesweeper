#' Write one model's PDF: title page, ICCs, Wright Maps, diagnostics, fit table
#' @keywords internal
.write_model_pdf <- function(path, model_label, tam_object, b_vec, fit_df, misfit_flag,
                              n_items, dataset_name,
                              icc_type, icc_ngroups, icc_mfrow,
                              fit_rows_per_page, fit_mnsq_low, fit_mnsq_high,
                              difficulty_label) {
  grDevices::pdf(path, width = 11, height = 8.5)
  on.exit(grDevices::dev.off())

  graphics::plot.new()
  graphics::text(0.5, 0.6, sprintf("%s Model", model_label), cex = 2.4, font = 2)
  graphics::text(0.5, 0.45, "Item Characteristic Curves, Wright Map, Item Fit", cex = 1.3)

  message(sprintf("  Plotting %s ICCs (tamICC)...", model_label))
  if (!is.null(icc_mfrow)) graphics::par(mfrow = icc_mfrow)
  .tamICC(tam_object, items = 1:n_items, type = icc_type,
          export = FALSE, ask = FALSE, ngroups = icc_ngroups)
  if (!is.null(icc_mfrow)) graphics::par(mfrow = c(1, 1))

  message(sprintf("  Building %s Wright Map...", model_label))
  WrightMap::wrightMap(tam_object$person$EAP, b_vec,
            item.side = "itemClassic", item.prop = .5,
            main.title = sprintf("Wright Map (%s) - %s", model_label, dataset_name))

  message(sprintf("  Building %s Wright Map (colored by fit)...", model_label))
  WrightMap::wrightMap(tam_object$person$EAP, b_vec,
            item.side = WrightMap::itemModern, item.prop = .5,
            thr.sym.col.fg = ifelse(misfit_flag, "red", "black"),
            main.title = sprintf("Wright Map (%s) - colored by fit (red = outside %.1f-%.1f MNSQ) - %s",
                                  model_label, fit_mnsq_low, fit_mnsq_high, dataset_name))

  message(sprintf("  Building %s Wright Map (person density)...", model_label))
  WrightMap::wrightMap(tam_object$person$EAP, b_vec,
            item.side = "itemClassic", item.prop = .5,
            person.side = WrightMap::personDens,
            main.title = sprintf("Wright Map (%s) - person density - %s", model_label, dataset_name))

  message(sprintf("  Building %s histograms...", model_label))
  .add_histogram_page(tam_object$person$EAP,
                       sprintf("%s person ability (EAP) - %s", model_label, dataset_name), "EAP ability")
  .add_histogram_page(b_vec,
                       sprintf("%s item difficulty - %s", model_label, dataset_name), difficulty_label)

  message(sprintf("  Building %s SE-vs-ability scatter...", model_label))
  .add_scatterhist_page(tam_object$person$SD.EAP, tam_object$person$EAP,
                         sprintf("%s: measurement error vs ability - %s", model_label, dataset_name))

  message(sprintf("  Building %s model summary...", model_label))
  .add_text_pages(.build_summary_lines(tam_object, model_label),
                   sprintf("%s model summary - %s", model_label, dataset_name))

  message(sprintf("  Building %s item fit table...", model_label))
  .add_table_pages(fit_df, sprintf("%s item fit - %s", model_label, dataset_name),
                    rows_per_page = fit_rows_per_page)

  message(sprintf("Done. %s PDF saved: %s", model_label, path))
}

#' Write the comparison PDF: cross-method correlation + combined Wright Map
#' @keywords internal
.write_comparison_pdf <- function(path, cmp, b_rasch, b_2pl, m_rasch, n_items,
                                   dataset_name, fit_rows_per_page) {
  grDevices::pdf(path, width = 11, height = 8.5)
  on.exit(grDevices::dev.off())

  graphics::plot.new()
  graphics::text(0.5, 0.6, "Cross-Model / Cross-Method Comparison", cex = 2.0, font = 2)
  graphics::text(0.5, 0.45, "Rasch difficulty by estimation method, and Rasch vs 2PL difficulty", cex = 1.1)

  message("  Building method-comparison correlation table...")
  method_cor_display <- as.data.frame(cmp$cor)
  method_cor_display <- data.frame(method = rownames(method_cor_display), method_cor_display, row.names = NULL)
  .add_table_pages(.round_df(method_cor_display, 3),
                    sprintf("Rasch difficulty correlation: JML vs CML vs MML - %s", dataset_name),
                    rows_per_page = fit_rows_per_page, row_label = "methods")

  message("  Building method-comparison scatterplot matrix...")
  # JML/CML are wrapped in tryCatch upstream and fall back to all-NA
  # columns on failure -- pairs() can't handle an all-NA column (no finite
  # range), so drop any method with no valid values before plotting.
  valid_methods <- names(cmp$df[c("JML", "CML", "MML")])[
    sapply(cmp$df[c("JML", "CML", "MML")], function(x) any(!is.na(x)))
  ]
  dropped_methods <- setdiff(c("JML", "CML", "MML"), valid_methods)
  if (length(dropped_methods) > 0) {
    message(sprintf("  Skipping %s in the scatterplot matrix (no valid values, likely failed to fit).",
                     paste(dropped_methods, collapse = ", ")))
  }

  if (length(valid_methods) >= 2) {
    graphics::pairs(cmp$df[, valid_methods, drop = FALSE],
                     main = sprintf("Rasch item difficulty: %s - %s",
                                     paste(valid_methods, collapse = " vs "), dataset_name))
  } else {
    graphics::plot.new()
    graphics::text(0.5, 0.5, sprintf(
      "Not enough estimation methods succeeded to build a scatterplot matrix.\nValid: %s",
      if (length(valid_methods) == 0) "none" else valid_methods
    ), cex = 1.1)
  }

  message("  Building combined Rasch vs 2PL Wright Map...")
  combined_thresholds <- data.frame(Rasch = b_rasch, TwoPL = b_2pl)
  combined_colors     <- data.frame(Rasch = rep("blue", n_items), TwoPL = rep("red", n_items))

  WrightMap::wrightMap(m_rasch$person$EAP, combined_thresholds,
            item.side = WrightMap::itemModern, item.prop = .5,
            thr.sym.col.fg = combined_colors,
            show.thr.lab = FALSE,
            main.title = sprintf("Wright Map: Rasch (blue) vs 2PL (red) difficulty - %s", dataset_name))

  message(sprintf("Done. Comparison PDF saved: %s", path))
}
