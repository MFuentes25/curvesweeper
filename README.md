# curvesweeper

This tool is heavily based on an item diagnostic R script created by [David Torres-Irribarra](https://github.com/david-ti). The main focus of it is to create Rasch and 2PL item response theory diagnostics, as ready-to-read PDF
reports, for any binary item-response dataset.

`curvesweeper` fits Rasch and 2PL models with [TAM](https://cran.r-project.org/package=TAM)
and builds three PDF reports per dataset: item characteristic curves,
Wright maps, item fit tables, and a cross-method (JML/CML/MML) difficulty
comparison. It calls TAM's and WrightMap's own plotting and fitting
functions.

## Installation

```r
# install.packages("devtools")
devtools::install_github("MFuentes25/curvesweeper")
```

## Usage

Import your data yourself first, then hand it to `irt_curve_report()`:

```r
library(curvesweeper)

data <- rio::import("my_data.dta")

irt_curve_report(
  data,
  id_cols      = "person_id",
  item_cols    = paste0("item", 1:30),
  output_dir   = "reports",
  dataset_name = "my_data"
)
```

This writes three PDFs into `reports/` and returns their paths invisibly.
Request a subset with `pdfs = c("rasch", "2pl", "comparison")` (any
combination); by default all three are produced.

Try it on the bundled simulated dataset first to confirm everything is
working:

```r
irt_curve_report(
  sim_test_data,
  id_cols      = "id",
  item_cols    = paste0("l", 1:25),
  output_dir   = "test_output",
  dataset_name = "sim_test"
)
```

## What each report contains

- **Rasch / 2PL reports** — a title page, item characteristic curves,
  three Wright maps (plain, colored by item fit, and with person density
  shown), person-ability and item-difficulty histograms, a
  measurement-error-vs-ability scatterplot, a model summary with EAP
  reliability, and a full item fit table.
- **Comparison report** — Rasch item difficulty estimated three
  independent ways (joint ML via `sirt::rasch.jml`, conditional ML via
  `eRm::RM`, and marginal ML via TAM), with a correlation table, a
  scatterplot matrix, and a combined Wright map overlaying Rasch and 2PL
  difficulty.

## Function reference

| Function | Description |
|---|---|
| `irt_curve_report()` | The package's only exported function. Fits both models and writes the requested PDF report(s). |
| `sim_test_data` | A bundled simulated dataset (400 persons x 25 items) with structural missingness, for quick trial runs. |

## Package layout

| File | Contents |
|---|---|
| `R/data-prep.R` | Id/item column splitting, numeric coercion, dropping no-variance items. |
| `R/model-fitting.R` | Rasch + 2PL model fits, theta-scale item difficulty. |
| `R/cross-method-compare.R` | JML/CML/MML Rasch difficulty comparison. |
| `R/fit-table.R` | `tam.fit()` table assembly and misfit flagging. |
| `R/pdf-helpers.R` | Generic PDF page builders: tables, text pages, histograms, the SE-vs-ability scatter. |
| `R/pdf-assembly.R` | The three PDF documents, assembled from the pieces above. |
| `R/irt-curve-report.R` | The public `irt_curve_report()` entry point. |
| `R/data.R` | Documentation for the bundled `sim_test_data` dataset. |

## Roadmap

PCM support, faster procesing times, and additional missing data robustness checks and diagnostics are planned
for a future version. 


## License

MIT © Martín Fuentes-Santelices
