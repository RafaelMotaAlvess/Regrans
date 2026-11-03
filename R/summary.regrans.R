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
#'   location, search status, segment coefficients, descriptive measures for
#'   the selected and reference fits, and the selected `summary.lm`.
#' @examples
#' data(simdata)
#' summary(regrans(simdata$x, simdata$y))
#' @export
summary.regrans <- function(object, correlation = FALSE,
                            symbolic_cor = FALSE, ...) {
  response <- object$data[[object$variables[["y"]]]]
  # Defined in tidiers.R; lintr checks files separately.
  # nolint next: object_usage_linter.
  measures <- fit_measures(object$model_fit, response)
  # Defined in tidiers.R; lintr checks files separately.
  # nolint next: object_usage_linter.
  reference <- fit_measures(object$reference_fit, response)
  result <- list(
    model = object$model,
    location = object$location,
    search = object$search,
    # Defined in tidiers.R; lintr checks files separately.
    coefficients = tidy.regrans(object), # nolint: object_usage_linter.
    rss = measures$rss,
    rmse = measures$rmse,
    r_squared = measures$r_squared,
    reference_rss = reference$rss,
    reference_rmse = reference$rmse,
    reference_r_squared = reference$r_squared,
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
  if (x$search$convergence == "converged") {
    cat("Continuous search converged after ", x$search$iterations,
        " iterations.\n", sep = "")
  } else {
    cat("Exhaustive search completed; numerical convergence does not apply.\n")
  }
  cat("Selected fit: RSS = ", format(x$rss),
      ", RMSE = ", format(x$rmse),
      ", R-squared = ", format(x$r_squared), "\n", sep = "")
  cat("Linear reference: RSS = ", format(x$reference_rss),
      ", RMSE = ", format(x$reference_rmse),
      ", R-squared = ", format(x$reference_r_squared), "\n", sep = "")
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
