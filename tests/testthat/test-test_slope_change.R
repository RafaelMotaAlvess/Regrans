test_that("bootstrap repeats the continuous search and counts extremes", {
  x <- c(8, 1, 4, 6, 2, 7, 3, 5, 9, 10, 11, 12)
  y <- 2 + x + 2 * pmax(0, x - 6.5) + sin(x) / 2
  fit <- regrans(x, y, n_min = 3, model = "continuous")
  set.seed(2401)
  result <- test_slope_change(fit, n_boot = 11)
  set.seed(2401)
  null_fitted <- fitted(fit$reference_fit)
  sigma <- summary(fit$reference_fit)$sigma
  reference <- vapply(seq_len(11), function(index) {
    response <- null_fitted + rnorm(length(x), sd = sigma)
    sampled <- regrans(x, response, n_min = 3, model = "continuous")
    length(x) * log(sum(residuals(sampled$reference_fit)^2) /
                      sum(residuals(sampled$model_fit)^2))
  }, numeric(1))
  observed <- length(x) * log(sum(residuals(fit$reference_fit)^2) /
                                sum(residuals(fit$model_fit)^2))

  expect_s3_class(result, "htest")
  expect_equal(result$statistic, c(LR = observed))
  expect_equal(result$bootstrap_statistics, reference)
  expect_equal(result$p.value,
               (1 + sum(reference >= observed)) / 12)
  expect_gte(result$p.value, 1 / 12)
})

test_that("Davies grid uses admissible bounds and stable row alignment", {
  x <- rep(1:12, each = 2)
  y <- 1 + 0.5 * x + 1.5 * pmax(0, x - 6.4) +
    rep(c(-0.2, 0.2), 12)
  shuffled <- c(seq(2, 24, 2), seq(1, 23, 2))
  fit <- regrans(x, y, n_min = 4, model = "continuous")
  reordered <- regrans(x[shuffled], y[shuffled], n_min = 4,
                       model = "continuous")
  result <- test_slope_change(fit, method = "davies", n_grid = 17)
  reordered_result <- test_slope_change(reordered, method = "davies",
                                        n_grid = 17)

  expect_s3_class(result, "htest")
  expect_equal(range(result$grid_statistics$breakpoint),
               c(min(fit$candidates$left_max_x),
                 max(fit$candidates$right_min_x)))
  expect_equal(result$max_statistic_location,
               result$grid_statistics$breakpoint[
                 which.max(abs(result$grid_statistics$t))
               ])
  expect_equal(result$p.value, reordered_result$p.value,
               tolerance = 1e-10)
  expect_equal(result$grid_statistics$t,
               reordered_result$grid_statistics$t,
               tolerance = 1e-10)
})

test_that("Davies linear-model bound matches segmented on the same grid", {
  x <- rep(1:20, each = 2)
  y <- 1 + x + 0.45 * pmax(0, x - 9.4) + sin(seq_along(x))
  fit <- regrans(x, y, n_min = 4, model = "continuous")
  result <- test_slope_change(fit, method = "davies", n_grid = 25)

  # Reference from segmented 2.2-2, davies.test(lm(y ~ x), ~x,
  # values = result$grid_statistics$breakpoint).
  expect_equal(result$p.value, 3.53150125725131e-06,
               tolerance = 1e-12)
  expect_equal(result$max_statistic_location, 9.08333333333333,
               tolerance = 1e-12)
  expect_equal(result$breakpoint_estimate, 9, tolerance = 1e-6)
})

test_that("a noisy straight line gives valid non-significant tests", {
  x <- 1:20
  y <- 2 + x + sin(x)
  fit <- regrans(x, y, n_min = 4, model = "continuous")
  set.seed(8)
  bootstrap <- test_slope_change(fit, n_boot = 19)
  davies <- test_slope_change(fit, method = "davies")
  expect_equal(bootstrap$p.value, 0.3)
  expect_equal(davies$p.value, 0.375417426680201,
               tolerance = 1e-12)
  expect_gt(bootstrap$p.value, 0.05)
  expect_gt(davies$p.value, 0.05)
})

test_that("tests reject unsupported and degenerate reference fits", {
  x <- 1:12
  discontinuous <- regrans(x, x + sin(x), n_min = 3)
  flat <- regrans(x, 2 + 3 * x, n_min = 3, model = "continuous")
  expect_error(test_slope_change(discontinuous), "model = 'continuous'")
  expect_error(test_slope_change(flat), "positive residual variance")
  expect_error(test_slope_change(flat, method = "davies"),
               "positive residual variance")
  expect_error(test_slope_change(discontinuous, method = "invalid"),
               "model = 'continuous'")
  noisy <- regrans(x, x + sin(x), n_min = 3, model = "continuous")
  expect_error(test_slope_change(noisy, n_boot = 0), "n_boot")
  expect_error(test_slope_change(noisy, method = "davies", n_grid = 1),
               "n_grid")
})
