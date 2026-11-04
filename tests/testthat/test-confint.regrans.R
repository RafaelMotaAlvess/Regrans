test_that("profile region contains the estimate and inverts its cutoff", {
  x <- 1:30
  y <- 2 + 0.7 * x + 2 * pmax(0, x - 13.4) + sin(x) / 2
  fit <- regrans(x, y, n_min = 4, model = "continuous")
  interval <- stats::confint(fit)
  region <- Regrans:::compute_profile_region(fit, 0.95)

  expect_true(is.matrix(interval))
  expect_equal(nrow(interval), 1L)
  expect_lt(interval[1, "lower"], fit$location$estimate)
  expect_gt(interval[1, "upper"], fit$location$estimate)
  expect_equal(region$statistic(interval[1, "lower"]), region$cutoff,
               tolerance = 1e-6)
  expect_equal(region$statistic(interval[1, "upper"]), region$cutoff,
               tolerance = 1e-6)
  expect_equal(attr(interval, "domain"), c(4, 27))
})

test_that("profile inversion retains disconnected components and boundaries", {
  statistic <- function(point) (point - 1)^2 * (point - 3)^2
  pieces <- Regrans:::find_accepted_intervals(
    statistic, c(0, 1, 2, 3, 4), cutoff = 0.1
  )
  expect_equal(nrow(pieces), 2L)
  expect_lt(pieces[1, 2], pieces[2, 1])
  expect_lt(pieces[1, 1], 1)
  expect_gt(pieces[1, 2], 1)
  expect_lt(pieces[2, 1], 3)
  expect_gt(pieces[2, 2], 3)

  x <- 1:20
  y <- x + 0.5 * pmax(0, x - 9) + sin(x)
  fit <- regrans(x, y, n_min = 3, model = "continuous")
  wide <- stats::confint(fit, level = 1 - 1e-12)
  expect_true(any(attr(wide, "boundary")$lower_boundary))
  expect_true(any(attr(wide, "boundary")$upper_boundary))
  expect_equal(range(wide), attr(wide, "domain"))

  set.seed(9)
  x <- 1:12
  y <- 1 + 0.5 * x + rnorm(length(x))
  multimodal <- regrans(x, y, n_min = 3, model = "continuous")
  separated <- stats::confint(multimodal, level = 0.5)
  expect_equal(nrow(separated), 2L)
  expect_lt(separated[1L, "upper"], separated[2L, "lower"])
  expect_true(attr(separated, "boundary")$lower_boundary[[1L]])
})

test_that("confidence profile validates model and variance", {
  x <- 1:12
  discontinuous <- regrans(x, x + sin(x), n_min = 3)
  flat <- regrans(x, 2 + 3 * x, n_min = 3, model = "continuous")
  expect_error(stats::confint(discontinuous), "model = 'continuous'")
  expect_error(stats::confint(flat), "numerically unidentified")
  noisy <- regrans(x, x + sin(x), n_min = 3, model = "continuous")
  expect_error(stats::confint(noisy, level = 1), "level")
  expect_error(stats::confint(noisy, method = "wald"), "method")
  expect_error(stats::confint(noisy, parm = "slope"), "parm")
})

test_that("profile plot is editable and uses all confidence components", {
  x <- 1:20
  y <- x + 2 * pmax(0, x - 8.5) + sin(x) / 2
  fit <- regrans(x, y, n_min = 3, model = "continuous")
  plot <- plot_break_profile(fit)
  expect_s3_class(plot, "ggplot")
  expect_equal(nrow(plot$layers[[1]]$data),
               nrow(stats::confint(fit)))
  expect_error(plot_break_profile(regrans(x, y, n_min = 3)),
               "model = 'continuous'")
})
