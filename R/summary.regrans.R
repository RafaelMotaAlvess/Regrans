#' Summarize a segmented regression fit
#'
#' The displayed coefficient statistics are conditional on the selected
#' transition. They do not account for searching its location and do not
#' constitute a test for a break.
#'
#' @param object A `regrans` object.
#' @param correlation,symbolic_cor Arguments passed to `summary.lm()`.
#' @param ... Further arguments passed to `summary.lm()`.
#' @return `summary()` returns a `summary.regrans` object with model type,
#'   location, segment coefficients, RSS, and the underlying `summary.lm`.
#' @examples
#' data(simdata)
#' summary(regrans(simdata$x, simdata$y))
#' @export
summary.regrans <- function(object, correlation = FALSE,
                            symbolic_cor = FALSE, ...) {
  result <- list(
    model = object$model,
    location = object$location,
    # Defined in tidiers.R; lintr checks files separately.
    coefficients = tidy.regrans(object), # nolint: object_usage_linter.
    rss = sum(stats::residuals(object$model_fit)^2),
    nobs = nrow(object$data),
    model_summary = summary(object$model_fit, correlation = correlation,
                            symbolic.cor = symbolic_cor, ...)
  )
  class(result) <- "summary.regrans"
  result
}

#' Print a segmented regression summary
#'
#' @param x A `summary.regrans` object.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @examples
#' data(simdata)
#' print(summary(regrans(simdata$x, simdata$y)))
#' @export
print.summary.regrans <- function(x, ...) {
  cat("Regrans ", x$model, " fit (", x$nobs, " observations)\n", sep = "")
  if (x$location$status == "interval") {
    cat("Selected interval: (", x$location$left_max_x, ", ",
        x$location$right_min_x, ")\n", sep = "")
  } else if (x$location$status == "identified") {
    cat("Estimated breakpoint: ", x$location$estimate, "\n", sep = "")
  } else {
    cat("Breakpoint numerically unidentified; linear fit shown.\n")
  }
  cat("Residual sum of squares: ", format(x$rss), "\n", sep = "")
  print(as.data.frame(x$coefficients), row.names = FALSE)
  cat("Coefficient statistics are conditional on the selected location.\n")
  invisible(x)
}

#' Print a segmented regression fit
#'
#' @param x A `regrans` object.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @examples
#' data(simdata)
#' regrans(simdata$x, simdata$y)
#' @export
print.regrans <- function(x, ...) {
  print(summary(x))
  invisible(x)
}
