test_that("tidy and glance describe both fits and the selected score", {
  fit <- regrans(1:10, c(1, 3, 4, 6, 8, 13, 14, 17, 18, 20), n_min = 3)
  coefficients <- tidy(fit)
  overview <- glance(fit)

  expect_s3_class(coefficients, "tbl_df")
  expect_equal(nrow(coefficients), 4L)
  expect_setequal(coefficients$segment, c("left", "right"))
  expect_setequal(coefficients$term, c("(Intercept)", "X"))
  expect_s3_class(overview, "tbl_df")
  expect_equal(nrow(overview), 1L)
  expect_identical(fit$n_min, 3L)
  expect_identical(overview$n_min, 3L)
  expect_equal(overview$rss,
               sum(residuals(fit$model_fit)^2))
  expect_identical(overview$left_max_x, fit$location$left_max_x)
  expect_identical(overview$right_min_x, fit$location$right_min_x)
  expect_identical(overview$status, "interval")
  expect_identical(overview$convergence, "not_applicable")
  expect_s3_class(fit$reference_fit, "lm")
  reference <- lm(y ~ x, data = fit$data)
  expect_equal(unname(coef(fit$reference_fit)),
               unname(coef(reference)))
  expect_equal(residuals(fit$reference_fit), residuals(reference))
  expect_equal(overview$reference_rss, sum(residuals(reference)^2))
  expect_equal(overview$reference_rmse,
               sqrt(sum(residuals(reference)^2) / nrow(fit$data)))
  expect_equal(overview$reference_r_squared,
               summary(reference)$r.squared)
  expect_equal(overview$rmse, sqrt(overview$rss / nrow(fit$data)))
  expect_equal(overview$r_squared,
               1 - overview$rss / sum((fit$data$y - mean(fit$data$y))^2))
  fit_summary <- summary(fit)
  expect_equal(fit_summary$reference_rss, overview$reference_rss)
  expect_equal(fit_summary$rmse, overview$rmse)
})

test_that("augment returns fitted values in the original order", {
  data <- data.frame(x = c(8, 1, 6, 3, 7, 2, 5, 4),
                     y = c(19, 2, 14, 5, 17, 4, 11, 8),
                     label = letters[1:8])
  fit <- regrans(y ~ x, data = data, n_min = 3)
  augmented <- augment(fit)

  expect_s3_class(augmented, "tbl_df")
  expect_identical(augmented$label, data$label)
  expect_identical(augmented$x, data$x)
  expect_equal(augmented$.fitted + augmented$.resid, data$y)
  expect_identical(augmented$.segment,
                   ifelse(data$x <= fit$location$left_max_x,
                          "left", "right"))
  expect_error(augment(fit, newdata = data), "stored training data")
})

test_that("broom dispatches to Regrans methods", {
  skip_if_not_installed("broom")
  fit <- regrans(1:8, c(1, 2.1, 2.8, 4.2, 7.1, 8, 9.2, 10.1),
                 n_min = 3)
  expect_equal(broom::tidy(fit), tidy(fit))
  expect_equal(broom::glance(fit), glance(fit))
  expect_equal(broom::augment(fit), augment(fit))
})

test_that("continuous tidiers preserve row order and expose the estimate", {
  data <- data.frame(x = c(8, 2, 7, 1, 6, 3, 5, 4, 10, 9),
                     y = c(17, 2, 15, 1, 13, 3, 11, 4, 21, 19))
  fit <- regrans(y ~ x, data = data, n_min = 3, model = "continuous")
  coefficients <- tidy(fit)
  overview <- glance(fit)
  augmented <- augment(fit)

  expect_equal(nrow(coefficients), 4L)
  expect_equal(coefficients$estimate, fit$segments$estimate)
  expect_identical(overview$status, "identified")
  expect_equal(overview$breakpoint, fit$location$estimate)
  expect_identical(overview$convergence, "converged")
  expect_identical(augmented$x, data$x)
  expect_equal(augmented$.fitted + augmented$.resid, data$y)
})

test_that("R-squared is undefined for a constant response", {
  fit <- regrans(1:8, rep(4, 8), n_min = 3)
  overview <- glance(fit)
  expect_true(is.na(overview$r_squared))
  expect_true(is.na(overview$reference_r_squared))
  expect_equal(overview$reference_rss, 0, tolerance = 1e-20)
})
