#' Plot the continuous breakpoint profile and confidence region
#'
#' Shows the Gaussian profile likelihood-ratio statistic, its chi-squared
#' acceptance cutoff, and every component of the approximate confidence
#' region. A shaded component reaching a domain edge remains open to that
#' admissible boundary.
#'
#' @param fit A `regrans` fit with `model = "continuous"`.
#' @param level Confidence level strictly between zero and one.
#' @return An editable `ggplot2` object.
#' @examples
#' x <- 1:20
#' y <- 2 + x + 2 * pmax(0, x - 9) + sin(x) / 3
#' fit <- regrans(x, y, model = "continuous")
#' plot_break_profile(fit)
#' @export
plot_break_profile <- function(fit, level = 0.95) {
  validate_break_fit(fit) # nolint: object_usage_linter.
  region <- compute_profile_region(fit, level) # nolint: object_usage_linter.
  grid <- seq(region$domain[[1L]], region$domain[[2L]], length.out = 401L)
  profile <- data.frame(breakpoint = grid,
                        statistic = vapply(grid, region$statistic, numeric(1)))
  ggplot2::ggplot(profile, ggplot2::aes(
    # nolint next: object_usage_linter.
    x = breakpoint, y = statistic
  )) +
    ggplot2::geom_rect(
      data = region$intervals,
      mapping = ggplot2::aes(
        # nolint next: object_usage_linter.
        xmin = lower, xmax = upper, ymin = -Inf, ymax = Inf
      ),
      inherit.aes = FALSE,
      fill = "steelblue", alpha = 0.16
    ) +
    ggplot2::geom_line(colour = "steelblue4") +
    ggplot2::geom_hline(yintercept = region$cutoff, linetype = "dashed") +
    ggplot2::geom_vline(xintercept = region$estimate,
                        colour = "firebrick", linetype = "dotted") +
    ggplot2::labs(
      x = fit$variables[["x"]],
      y = "Profile likelihood-ratio statistic",
      title = "Continuous breakpoint profile"
    )
}

utils::globalVariables(c("breakpoint", "statistic", "lower", "upper"))
