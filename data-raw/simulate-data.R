# ============================================================
# Builds the package's exported example/test dataset, sim_test_data.
# Run this once (from inside the package, e.g. after opening
# curvesweeper.Rproj in RStudio) whenever you want to regenerate it:
#
#   source("data-raw/simulate-data.R")
#
# This writes data/sim_test_data.rda via usethis::use_data() -- you do
# NOT need to run this yourself just to USE the package; sim_test_data
# ships already built once someone has run this at least once and
# committed the resulting data/sim_test_data.rda.
# ============================================================

set.seed(42)

n_persons <- 400
n_items   <- 25

# True person abilities and item difficulties (increasing difficulty,
# like the real "l1..l117" item bank) plus a slope per item for 2PL.
theta_true <- rnorm(n_persons, mean = 0, sd = 1)
b_true     <- seq(-2, 2, length.out = n_items)
a_true     <- runif(n_items, 0.6, 1.8)

# Simulate 2PL responses (Rasch is a special case TAM will still fit fine).
prob <- sapply(seq_len(n_items), function(j) {
  plogis(a_true[j] * (theta_true - b_true[j]))
})
resp <- matrix(rbinom(n_persons * n_items, size = 1, prob = as.vector(prob)),
               nrow = n_persons, ncol = n_items)
colnames(resp) <- paste0("l", seq_len(n_items))

# A little structural missingness, like the branching design in the real
# data: harder items get progressively more missing for lower-ability
# people (NOT random), plus a couple of persons with literally zero
# responses, to specifically exercise the JML/CML "fully NA person" bug.
for (j in seq_len(n_items)) {
  miss_prob <- pmax(0, (b_true[j] - theta_true) / 6)
  miss_prob <- pmin(miss_prob, 0.9)
  resp[runif(n_persons) < miss_prob, j] <- NA
}
resp[c(1, 2), ] <- NA  # two fully-NA persons, on purpose

sim_test_data <- data.frame(id = seq_len(n_persons), resp)

usethis::use_data(sim_test_data, overwrite = TRUE)
