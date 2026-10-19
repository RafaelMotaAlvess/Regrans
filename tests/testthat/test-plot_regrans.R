test_that("plot helpers return editable plots with observed line ranges", {
  x <- c(8, 1, 7, 2, 6, 3, 5, 4)
  fit <- regrans(x, c(17, 2, 15, 4, 13, 6, 11, 8), n.min = 3)
  plot <- plot_regrans(fit, pch = 16, xlab = "Time", ylab = "Value",
                       col.lines = c("red", "blue"))
  expect_s3_class(plot, "ggplot")
  expect_s3_class(ggplot2::autoplot(fit), "ggplot")
  expect_equal(plot$labels$x, "Time")
  expect_equal(plot$labels$y, "Value")

  built <- ggplot2::ggplot_build(plot)
  expect_length(built$data, 3L)
  expect_equal(built$data[[2L]]$x, min(fit$left$model$X))
  expect_equal(built$data[[2L]]$xend, max(fit$left$model$X))
  expect_equal(built$data[[3L]]$x, min(fit$right$model$X))
  expect_equal(built$data[[3L]]$xend, max(fit$right$model$X))
  expect_error(plot_regrans(fit, las = 2), "Supported plot arguments")
})
