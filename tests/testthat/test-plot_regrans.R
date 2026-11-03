test_that("plot helpers return editable plots with observed line ranges", {
  x <- c(8, 1, 7, 2, 6, 3, 5, 4)
  fit <- regrans(x, c(17, 2, 15, 4, 13, 6, 11, 8), n_min = 3)
  plot <- plot_regrans(fit, pch = 16, xlab = "Time", ylab = "Value",
                       col_lines = c("red", "blue"),
                       lty_lines = c("solid", "dashed"),
                       lwd_lines = c(1, 2))
  expect_s3_class(plot, "ggplot")
  expect_s3_class(ggplot2::autoplot(fit), "ggplot")
  expect_equal(plot$labels$x, "Time")
  expect_equal(plot$labels$y, "Value")

  built <- ggplot2::ggplot_build(plot)
  expect_length(built$data, 3L)
  expect_equal(built$data[[2L]]$x, min(x[fit$segment == "left"]))
  expect_equal(built$data[[2L]]$xend, max(x[fit$segment == "left"]))
  expect_equal(built$data[[3L]]$x, min(x[fit$segment == "right"]))
  expect_equal(built$data[[3L]]$xend, max(x[fit$segment == "right"]))
  expect_error(plot_regrans(fit, las = 2), "Supported plot arguments")
})

test_that("continuous plot lines meet at the estimated breakpoint", {
  x <- 1:20
  y <- 2 + x + 3 * pmax(0, x - 5.5)
  fit <- regrans(x, y, model = "continuous")
  built <- ggplot2::ggplot_build(plot_regrans(fit))

  expect_length(built$data, 3L)
  expect_equal(built$data[[2L]]$xend, fit$location$estimate)
  expect_equal(built$data[[3L]]$x, fit$location$estimate)
  expect_equal(built$data[[2L]]$yend, built$data[[3L]]$y,
               tolerance = 1e-7)
})

test_that("unidentified continuous fit draws one line", {
  fit <- regrans(1:12, 2 + 3 * (1:12), model = "continuous")
  built <- ggplot2::ggplot_build(plot_regrans(fit))
  expect_length(built$data, 2L)
})
