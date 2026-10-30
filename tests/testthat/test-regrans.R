reference_search <- function(x, y, n_min) {
  sorted <- order(x, seq_along(x))
  x <- x[sorted]
  y <- y[sorted]
  candidates <- seq.int(n_min, length(x) - n_min)
  candidates <- candidates[x[candidates] < x[candidates + 1L]]
  candidates <- candidates[vapply(candidates, function(i) {
    length(unique(x[seq_len(i)])) >= 2L &&
      length(unique(x[seq.int(i + 1L, length(x))])) >= 2L
  }, logical(1))]
  scores <- vapply(candidates, function(i) {
    left <- lm(y[seq_len(i)] ~ x[seq_len(i)])
    right <- lm(y[seq.int(i + 1L, length(x))] ~
                  x[seq.int(i + 1L, length(x))])
    sum(residuals(left)^2) + sum(residuals(right)^2)
  }, numeric(1))
  list(index = candidates[[which.min(scores)]],
       candidates = candidates, scores = scores)
}

test_that("a known two-line example recovers both fitted segments", {
  x <- 1:10
  y <- c(2 + x[1:5], 100 + 3 * x[6:10])
  fit <- regrans(x, y, n_min = 3)

  expect_identical(fit$model, "discontinuous")
  expect_identical(fit$location$status, "interval")
  expect_identical(fit$location$split_index, 5L)
  expect_true(is.na(fit$location$estimate))
  expect_equal(fit$segments$estimate, c(2, 1, 100, 3))
  expect_equal(glance(fit)$rss, 0, tolerance = 1e-20)
})

test_that("the selected partition minimizes independent two-line RSS", {
  x <- c(12, 3, 7, 1, 10, 4, 9, 2, 11, 8, 6, 5)
  y <- ifelse(x <= 6, 2 + 0.8 * x, -7 + 2.4 * x) +
    c(0.1, -0.2, 0.1, 0, -0.1, 0.2, 0, -0.1, 0.1, 0.2, -0.2, 0)
  reference <- reference_search(x, y, 3)
  fit <- regrans(x, y, n_min = 3)

  expect_s3_class(fit$model_fit, "lm")
  expect_identical(fit$location$split_index, reference$index)
  expect_equal(fit$candidates$split_index, reference$candidates)
  expect_equal(fit$candidates$rss, unname(reference$scores))
  expect_equal(
    sum(residuals(fit$model_fit)^2),
    min(reference$scores)
  )
  expect_s3_class(summary(fit), "summary.regrans")
  expect_s3_class(summary(fit, symbolic_cor = TRUE)$model_summary,
                  "summary.lm")
})

test_that("exactly n_min observations on each side are admissible", {
  fit <- regrans(1:6, c(1, 2, 3, 10, 12, 14), n_min = 3)
  expect_identical(fit$location$split_index, 3L)
  expect_equal(fit$candidates$left_n, 3)
  expect_equal(fit$candidates$right_n, 3)
})

test_that("tied x values stay together and degenerate sides are excluded", {
  x <- c(4, 1, 2, 4, 3, 1, 5, 2, 6, 3)
  y <- c(11, 2, 3, 12, 4, 1, 13, 2, 14, 5)
  fit <- regrans(x, y, n_min = 3)
  expect_true(all(fit$candidates$left_max_x < fit$candidates$right_min_x))
  expect_false(3L %in% fit$candidates$split_index)
  expect_error(regrans(rep(1, 6), 1:6, n_min = 3),
               "No admissible split")
})

test_that("equal RSS selects the earliest admissible split", {
  fit <- regrans(1:8, rep(0, 8), n_min = 3)
  expect_identical(fit$location$split_index, 3L)
})

test_that("the formula and vector interfaces agree", {
  data <- data.frame(time = c(7, 3, 1, 8, 4, 6, 2, 5),
                     response = c(8, 4, 1, 10, 6, 7, 3, 5),
                     group = letters[1:8])
  from_formula <- regrans(response ~ time, data = data, n_min = 3)
  from_vectors <- regrans(data$time, data$response, n_min = 3)
  expect_equal(from_formula$location, from_vectors$location)
  expect_equal(from_formula$candidates$rss, from_vectors$candidates$rss)
  expect_identical(from_formula$data, data)
  expect_identical(from_formula$variables,
                   c(x = "time", y = "response"))
})

test_that("invalid inputs fail before fitting", {
  expect_error(regrans(1:6, 1:5, n_min = 3), "equal length")
  expect_error(regrans(c(1:5, NA_real_), 1:6, n_min = 3), "finite")
  expect_error(regrans(1:6, c(1:5, Inf), n_min = 3), "finite")
  expect_error(regrans(1:6, 1:6, n_min = 2), "n_min")
  expect_error(regrans(1:6, 1:6, n_min = 3.5), "n_min")
  expect_error(regrans(1:5, 1:5, n_min = 3), "2 \\* n_min")
  data <- data.frame(x = 1:6, y = 1:6, z = 1:6)
  expect_error(regrans(y ~ log(x), data = data, n_min = 3),
               "bare column names")
  expect_error(regrans(y ~ x + z, data = data, n_min = 3),
               "bare column names")
  expect_error(regrans(1:6, 1:6, n_min = 3, model = "unknown"),
               "'arg' should be one of")
})

test_that("continuous fit recovers a known breakpoint between observations", {
  x <- 1:20
  y <- 2 + x + 3 * pmax(0, x - 5.5)
  fit <- regrans(x, y, n_min = 3, model = "continuous")

  expect_identical(fit$model, "continuous")
  expect_identical(fit$location$status, "identified")
  expect_equal(fit$location$estimate, 5.5, tolerance = 1e-5)
  expect_identical(fit$location$split_index, 5L)
  expect_equal(fit$segments$estimate, c(2, 1, -14.5, 4),
               tolerance = 1e-5)
  expect_equal(fit$fitted_values, y, tolerance = 1e-5)
  expect_lt(glance(fit)$rss, 1e-8)
})

test_that("continuous search refines the breakpoint beyond observed x", {
  x <- 1:20
  y <- 4 + 0.7 * x - 2.5 * pmax(0, x - 8.3) +
    sin(x) / 20
  fit <- regrans(x, y, n_min = 3, model = "continuous")
  grid <- seq(7, 10, by = 0.001)
  reference_rss <- vapply(grid, function(point) {
    hinge <- pmax(0, x - point)
    sum(residuals(lm(y ~ x + hinge))^2)
  }, numeric(1))

  expect_gt(fit$location$estimate, 8)
  expect_lt(fit$location$estimate, 9)
  expect_lte(glance(fit)$rss, min(reference_rss) + 1e-6)
  expect_gt(fit$search$evaluations, nrow(fit$candidates))
})

test_that("a flat continuous profile reports no identified breakpoint", {
  x <- 1:12
  y <- 2 + 3 * x
  fit <- regrans(x, y, n_min = 3, model = "continuous")

  expect_identical(fit$location$status, "unidentified")
  expect_true(is.na(fit$location$estimate))
  expect_true(is.na(fit$location$split_index))
  expect_equal(fit$segments$estimate, c(2, 3), tolerance = 1e-10)
  expect_true(all(fit$segment == "overall"))
  expect_equal(fit$fitted_values, y, tolerance = 1e-10)
})

test_that("both modes keep repeated predictor values in one segment", {
  x <- rep(1:10, each = 2)
  y <- 2 + x + 3 * pmax(0, x - 5.5) +
    rep(c(-0.05, 0.05), 10)
  for (model in c("discontinuous", "continuous")) {
    fit <- regrans(x, y, n_min = 3, model = model)
    expect_true(all(fit$candidates$left_max_x <
                      fit$candidates$right_min_x))
    expect_true(all(vapply(unique(x), function(value) {
      length(unique(fit$segment[x == value])) == 1L
    }, logical(1))))
  }
  expect_error(regrans(rep(1, 8), 1:8, n_min = 3,
                       model = "continuous"), "No admissible split")
})

test_that("discontinuous mode fits a jump that continuous mode cannot", {
  x <- 1:20
  y <- ifelse(x <= 10, 2 + x, 12 + x)
  jump_fit <- regrans(x, y, model = "discontinuous")
  joined_fit <- regrans(x, y, model = "continuous")

  expect_lt(glance(jump_fit)$rss, 1e-8)
  expect_gt(glance(joined_fit)$rss, 1)
  expect_true(is.na(jump_fit$location$estimate))
  expect_true(is.finite(joined_fit$location$estimate))
})
