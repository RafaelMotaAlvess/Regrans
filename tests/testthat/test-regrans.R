reference_search <- function(x, y, n.min) {
  sorted <- order(x, seq_along(x))
  x <- x[sorted]
  y <- y[sorted]
  candidates <- seq.int(n.min, length(x) - n.min)
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
  fit <- regrans(x, y, n.min = 3)

  expect_identical(fit$split$index, 5L)
  expect_equal(unname(coef(fit$left)), c(2, 1))
  expect_equal(unname(coef(fit$right)), c(100, 3))
  expect_equal(glance(fit)$rss, 0, tolerance = 1e-20)
})

test_that("the selected partition minimizes independent two-line RSS", {
  x <- c(12, 3, 7, 1, 10, 4, 9, 2, 11, 8, 6, 5)
  y <- ifelse(x <= 6, 2 + 0.8 * x, -7 + 2.4 * x) +
    c(0.1, -0.2, 0.1, 0, -0.1, 0.2, 0, -0.1, 0.1, 0.2, -0.2, 0)
  reference <- reference_search(x, y, 3)
  fit <- regrans(x, y, n.min = 3)

  expect_s3_class(fit$left, "lm")
  expect_s3_class(fit$right, "lm")
  expect_identical(fit$split$index, reference$index)
  expect_equal(fit$candidates$split_index, reference$candidates)
  expect_equal(fit$candidates$rss, unname(reference$scores))
  expect_equal(
    sum(residuals(fit$left)^2) + sum(residuals(fit$right)^2),
    min(reference$scores)
  )
  expect_named(summary(fit), c("left", "right"))
})

test_that("exactly n.min observations on each side are admissible", {
  fit <- regrans(1:6, c(1, 2, 3, 10, 12, 14), n.min = 3)
  expect_identical(fit$split$index, 3L)
  expect_equal(fit$candidates$left_n, 3)
  expect_equal(fit$candidates$right_n, 3)
})

test_that("tied x values stay together and degenerate sides are excluded", {
  x <- c(4, 1, 2, 4, 3, 1, 5, 2, 6, 3)
  y <- c(11, 2, 3, 12, 4, 1, 13, 2, 14, 5)
  fit <- regrans(x, y, n.min = 3)
  expect_true(all(fit$candidates$left_max_x < fit$candidates$right_min_x))
  expect_false(3L %in% fit$candidates$split_index)
  expect_error(regrans(rep(1, 6), 1:6, n.min = 3),
               "No admissible split")
})

test_that("equal RSS selects the earliest admissible split", {
  fit <- regrans(1:8, rep(0, 8), n.min = 3)
  expect_identical(fit$split$index, 3L)
})

test_that("the formula and vector interfaces agree", {
  data <- data.frame(time = c(7, 3, 1, 8, 4, 6, 2, 5),
                     response = c(8, 4, 1, 10, 6, 7, 3, 5),
                     group = letters[1:8])
  from_formula <- regrans(response ~ time, data = data, n.min = 3)
  from_vectors <- regrans(data$time, data$response, n.min = 3)
  expect_equal(from_formula$split, from_vectors$split)
  expect_equal(from_formula$candidates$rss, from_vectors$candidates$rss)
  expect_identical(from_formula$data, data)
  expect_identical(from_formula$variables,
                   c(x = "time", y = "response"))
})

test_that("invalid inputs fail before fitting", {
  expect_error(regrans(1:6, 1:5, n.min = 3), "equal length")
  expect_error(regrans(c(1:5, NA_real_), 1:6, n.min = 3), "finite")
  expect_error(regrans(1:6, c(1:5, Inf), n.min = 3), "finite")
  expect_error(regrans(1:6, 1:6, n.min = 2), "n.min")
  expect_error(regrans(1:6, 1:6, n.min = 3.5), "n.min")
  expect_error(regrans(1:5, 1:5, n.min = 3), "2 \\* n.min")
  data <- data.frame(x = 1:6, y = 1:6, z = 1:6)
  expect_error(regrans(y ~ log(x), data = data, n.min = 3),
               "bare column names")
  expect_error(regrans(y ~ x + z, data = data, n.min = 3),
               "bare column names")
})
