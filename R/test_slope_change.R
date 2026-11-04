#' Test for a slope change in a continuous fit
#'
#' Tests a single straight line against a continuous hinge with an unknown
#' breakpoint. The parametric bootstrap repeats the full breakpoint search
#' under the fitted linear model. Davies' test uses a grid of fixed-breakpoint
#' t statistics and reports a conservative upper bound for its p-value.
#' Both methods assume fixed `x` and independent normal errors with constant
#' variance. They do not apply to the discontinuous model.
#'
#' @param fit A `regrans` fit with `model = "continuous"`.
#' @param method Either `"bootstrap"` or `"davies"`.
#' @param n_boot Number of parametric bootstrap samples (at least 1).
#' @param n_grid Number of Davies evaluation points (at least 2).
#' @return An `htest` object. `bootstrap_statistics` contains the simulated
#'   likelihood-ratio statistics when `method = "bootstrap"`. For Davies' test,
#'   `max_statistic_location` is the point with the largest absolute t statistic
#'   on the grid, distinct from the Regrans breakpoint estimate;
#'   `grid_statistics` contains all grid locations and t statistics.
#' @examples
#' x <- 1:20
#' y <- 2 + x + 2 * pmax(0, x - 9) + sin(x) / 3
#' fit <- regrans(x, y, model = "continuous")
#' test_slope_change(fit, n_boot = 19)
#' test_slope_change(fit, method = "davies")
#' @export
test_slope_change <- function(fit, method = c("bootstrap", "davies"),
                              n_boot = 999L, n_grid = 25L) {
  validate_break_fit(fit)
  method <- match.arg(method)
  if (method == "bootstrap") {
    if (!is_positive_integer(n_boot)) {
      stop("n_boot must be one positive integer.", call. = FALSE)
    }
    return(run_bootstrap_break_test(fit, as.integer(n_boot)))
  }
  if (!is_positive_integer(n_grid) || n_grid < 2L) {
    stop("n_grid must be one integer of at least 2.", call. = FALSE)
  }
  run_davies_break_test(fit, as.integer(n_grid))
}

#' Check that an inferential method has a continuous fit
#'
#' @param fit Candidate `regrans` fit.
#' @return `NULL` invisibly, or an error for unsupported fits.
#' @noRd
validate_break_fit <- function(fit) {
  if (!inherits(fit, "regrans") || fit$model != "continuous") {
    stop("Inference requires a regrans fit with model = 'continuous'.",
         call. = FALSE)
  }
  invisible(NULL)
}

#' Check a simulation or grid count
#'
#' @param value Candidate count.
#' @return `TRUE` for a finite positive integer scalar.
#' @noRd
is_positive_integer <- function(value) {
  is.numeric(value) && length(value) == 1L && is.finite(value) &&
    value >= 1 && value == floor(value) && value <= .Machine$integer.max
}

#' Extract training observations from a fit
#'
#' @param fit A continuous `regrans` fit.
#' @return A list containing `x` and `y` in original row order.
#' @noRd
extract_fit_observations <- function(fit) {
  list(x = fit$data[[fit$variables[["x"]]]],
       y = fit$data[[fit$variables[["y"]]]])
}

#' Estimate residual standard deviation under the linear reference
#'
#' @param fit A continuous `regrans` fit.
#' @return Residual standard deviation of the linear reference fit.
#' @noRd
estimate_reference_sd <- function(fit) {
  response <- extract_fit_observations(fit)$y
  rss <- sum(stats::residuals(fit$reference_fit)^2)
  total_ss <- sum((response - mean(response))^2)
  residual_sd <- sqrt(rss / stats::df.residual(fit$reference_fit))
  if (!is.finite(residual_sd) || !is.finite(total_ss) || total_ss <= 0 ||
        rss <= 1e-12 * total_ss) {
    stop("Inference requires positive residual variance in the linear ",
         "reference fit.", call. = FALSE)
  }
  residual_sd
}

#' Repeat the full continuous search under a fitted straight line
#'
#' @param fit A continuous fit with a linear reference.
#' @param n_boot Positive number of bootstrap replicates.
#' @return An `htest` with a finite-simulation p-value and replicates.
#' @noRd
run_bootstrap_break_test <- function(fit, n_boot) {
  residual_sd <- estimate_reference_sd(fit)
  observations <- extract_fit_observations(fit)
  n <- length(observations$y)
  rss_reference <- sum(stats::residuals(fit$reference_fit)^2)
  rss_selected <- sum(stats::residuals(fit$model_fit)^2)
  observed_lr <- n * log(rss_reference / rss_selected)
  if (!is.finite(observed_lr)) {
    stop("The observed likelihood-ratio statistic is not finite.",
         call. = FALSE)
  }
  null_fitted_values <- stats::fitted(fit$reference_fit)
  bootstrap_statistics <- replicate(n_boot, {
    simulated_response <- null_fitted_values +
      stats::rnorm(n, sd = residual_sd)
    # Defined in regrans.R; lintr checks files separately.
    sampled_fit <- regrans( # nolint: object_usage_linter.
      observations$x, simulated_response,
      n_min = fit$n_min, model = "continuous"
    )
    linear_rss <- sum(stats::residuals(sampled_fit$reference_fit)^2)
    hinge_rss <- sum(stats::residuals(sampled_fit$model_fit)^2)
    n * log(linear_rss / hinge_rss)
  })
  p_value <- (1 + sum(bootstrap_statistics >= observed_lr)) / (n_boot + 1)
  result <- list(
    statistic = c(LR = observed_lr),
    parameter = c(n_boot = n_boot),
    p.value = p_value,
    method = "Parametric bootstrap test for one continuous slope change",
    data.name = "continuous regrans fit",
    alternative = "one slope change at an unknown admissible position",
    bootstrap_statistics = bootstrap_statistics
  )
  class(result) <- "htest"
  result
}

#' Evaluate the Davies upper bound on the admissible breakpoint grid
#'
#' @param fit A continuous fit with a linear reference.
#' @param n_grid Number of equally spaced grid locations.
#' @return An `htest` containing the upper bound and grid statistics.
#' @noRd
run_davies_break_test <- function(fit, n_grid) {
  estimate_reference_sd(fit)
  observations <- extract_fit_observations(fit)
  grid_lower <- min(fit$candidates$left_max_x)
  grid_upper <- max(fit$candidates$right_min_x)
  grid <- seq(grid_lower, grid_upper, length.out = n_grid)
  grid_results <- evaluate_davies_grid(observations$x, observations$y,
                                       grid)
  max_t_index <- which.max(abs(grid_results$t))
  max_abs_t <- abs(grid_results$t[[max_t_index]])
  p_value <- davies_upper_bound(grid_results$t,
                                grid_results$partial_r_squared,
                                length(observations$y) - 3L)
  result <- list(
    statistic = c("max |t|" = max_abs_t),
    parameter = c(n_grid = n_grid),
    p.value = p_value,
    method = paste(
      "Davies test for one continuous slope change",
      "(conservative upper bound)"
    ),
    data.name = "continuous regrans fit",
    alternative = "one slope change at an unknown admissible position",
    max_statistic_location = grid[[max_t_index]],
    grid_statistics = grid_results[, c("breakpoint", "t")],
    breakpoint_estimate = fit$location$estimate
  )
  class(result) <- "htest"
  result
}

#' Evaluate fixed-breakpoint t statistics across the Davies grid
#'
#' @param x,y Training predictor and response in original row order.
#' @param grid Admissible breakpoint locations to evaluate.
#' @return A data frame with grid points, signed t statistics, and partial
#'   R-squared values used by the Davies correction.
#' @noRd
evaluate_davies_grid <- function(x, y, grid) {
  residual_df <- length(y) - 3L
  linear_design <- cbind(1, x)
  linear_residuals <- stats::lm.fit(linear_design, y)$residuals
  linear_rss <- sum(linear_residuals^2)
  scores <- vapply(grid, function(point) {
    hinge <- pmax(0, x - point)
    hinge_residuals <- stats::lm.fit(linear_design, hinge)$residuals
    hinge_residual_ss <- sum(hinge_residuals^2)
    if (!is.finite(hinge_residual_ss) || hinge_residual_ss <= 0) {
      stop("The Davies grid contains a rank-deficient hinge.",
           call. = FALSE)
    }
    cross_product <- sum(linear_residuals * hinge_residuals)
    rss_reduction <- cross_product^2 / hinge_residual_ss
    hinge_rss <- max(0, linear_rss - rss_reduction)
    if (hinge_rss <= 0) {
      stop("The Davies test requires positive fixed-breakpoint ",
           "residual variance.", call. = FALSE)
    }
    slope_change_sign <- sign(cross_product)
    c(
      t = slope_change_sign *
        sqrt(rss_reduction / (hinge_rss / residual_df)),
      partial_r_squared = min(1, rss_reduction / linear_rss)
    )
  }, numeric(2))
  data.frame(breakpoint = grid, t = scores["t", ],
             partial_r_squared = scores["partial_r_squared", ])
}

#' Calculate the conservative Davies linear-model p-value bound
#'
#' @param t_values Signed t statistics across the breakpoint grid.
#' @param partial_r_squared Partial R-squared values at the same points.
#' @param residual_df Residual degrees of freedom for each fixed hinge fit.
#' @return A p-value upper bound between zero and one.
#' @noRd
davies_upper_bound <- function(t_values, partial_r_squared, residual_df) {
  max_abs_t <- max(abs(t_values))
  angular_variation <- sum(abs(diff(asin(sqrt(partial_r_squared)))))
  max_partial_r_squared <- max_abs_t^2 /
    (residual_df + max_abs_t^2)
  # Work on the log scale so the gamma ratio remains finite for large df.
  correction <- angular_variation * exp(
    ((residual_df - 1) / 2) * log1p(-max_partial_r_squared) +
      lgamma(residual_df / 2 + 0.5) - lgamma(residual_df / 2) -
      log(2) - 0.5 * log(pi)
  )
  min(
    1,
    2 * (stats::pt(-max_abs_t, df = residual_df) + correction)
  )
}
