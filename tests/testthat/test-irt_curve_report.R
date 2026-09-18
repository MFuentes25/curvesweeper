test_that("irt_curve_report writes all three PDFs on simulated data", {
  skip_if_not_installed("TAM")
  skip_if_not_installed("WrightMap")

  out_dir <- withr::local_tempdir()

  paths <- irt_curve_report(
    sim_test_data,
    id_cols = "id",
    item_cols = paste0("l", 1:25),
    output_dir = out_dir,
    dataset_name = "sim_test"
  )

  expect_true(file.exists(paths$rasch))
  expect_true(file.exists(paths$two_pl))
  expect_true(file.exists(paths$comparison))
})
