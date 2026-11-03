#!/usr/bin/env Rscript

# Reproduce the fixed-x Gaussian calibration tables in docs/inference.md.
# Run from the package root: Rscript docs/inference-simulation.R
pkgload::load_all(".", quiet = TRUE)

breakpoint <- 0.17
error_sd <- 0.6
confidence_level <- 0.95

simulate_response <- function(predictor, slope_change) {
  1 + 0.5 * predictor + slope_change * pmax(0, predictor - breakpoint) +
    rnorm(length(predictor), sd = error_sd)
}

is_covered <- function(fit) {
  intervals <- stats::confint(fit, level = confidence_level)
  any(intervals[, "lower"] <= breakpoint &
        intervals[, "upper"] >= breakpoint)
}

monte_carlo_se <- function(proportion, n_datasets) {
  sqrt(proportion * (1 - proportion) / n_datasets)
}

evaluate_tests <- function(slope_change, seed) {
  set.seed(seed)
  predictor <- seq(-1, 1, length.out = 20)
  n_datasets <- 80L
  n_boot <- 49L
  results <- replicate(n_datasets, {
    response <- simulate_response(predictor, slope_change)
    fit <- regrans(predictor, response, n_min = 4, model = "continuous")
    bootstrap_p <- test_slope_change(fit, n_boot = n_boot)$p.value
    davies_p <- test_slope_change(
      fit, method = "davies", n_grid = 25L
    )$p.value
    coverage <- if (slope_change == 0) NA else is_covered(fit)
    c(bootstrap_reject = bootstrap_p <= 0.05,
      davies_reject = davies_p <= 0.05,
      profile_covers = coverage)
  })
  rates <- rowMeans(results, na.rm = TRUE)
  rates[is.nan(rates)] <- NA_real_
  data.frame(
    slope_change = slope_change,
    seed = seed,
    bootstrap_reject = rates[["bootstrap_reject"]],
    bootstrap_mc_se = monte_carlo_se(rates[["bootstrap_reject"]],
                                    n_datasets),
    davies_reject = rates[["davies_reject"]],
    davies_mc_se = monte_carlo_se(rates[["davies_reject"]], n_datasets),
    profile_coverage = rates[["profile_covers"]],
    profile_mc_se = monte_carlo_se(rates[["profile_covers"]], n_datasets)
  )
}

evaluate_coverage <- function(slope_change, seed) {
  set.seed(seed)
  predictor <- seq(-1, 1, length.out = 80)
  n_datasets <- 60L
  coverage <- replicate(n_datasets, {
    response <- simulate_response(predictor, slope_change)
    fit <- regrans(predictor, response, n_min = 8, model = "continuous")
    is_covered(fit)
  })
  rate <- mean(coverage)
  data.frame(slope_change = slope_change, seed = seed,
             profile_coverage = rate,
             profile_mc_se = monte_carlo_se(rate, n_datasets))
}

small_sample <- rbind(
  evaluate_tests(0, 20261103L),
  evaluate_tests(1.5, 20261104L),
  evaluate_tests(3, 20261105L)
)
larger_sample <- rbind(
  evaluate_coverage(1.5, 20261106L),
  evaluate_coverage(3, 20261107L)
)
cat("Regrans version:", read.dcf("DESCRIPTION", fields = "Version"), "\n")
cat("R version:", as.character(getRversion()), "\n")
cat("n = 20, 80 datasets per scenario, 49 bootstrap samples\n")
print(small_sample, row.names = FALSE, digits = 3)
cat("n = 80, 60 datasets per scenario\n")
print(larger_sample, row.names = FALSE, digits = 3)
