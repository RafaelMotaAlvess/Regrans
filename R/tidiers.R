#' Tidy a regrans fit
#'
#' These methods describe the selected model. Coefficient standard errors
#' and p-values are conditional on the selected transition; they do not
#' measure uncertainty about its location or test whether it exists.
#'
#' @param x A `regrans` object.
#' @param ... Reserved for the generic; unused.
#' @return `tidy()` returns intercept and slope rows per segment, or overall
#'   coefficients when a continuous break is numerically unidentified.
#'   `glance()` returns one row with model, location, and fit scores.
#'   `augment()` returns the original observations with `.segment`,
#'   `.fitted`, and `.resid` columns in their original order.
#' @examples
#' data(simdata)
#' fit <- regrans(y ~ x, data = simdata)
#' tidy(fit)
#' glance(fit)
#' head(augment(fit))
#' @name regrans-tidiers
NULL

#' @importFrom generics tidy
#' @export
generics::tidy

#' @importFrom generics glance
#' @export
generics::glance

#' @importFrom generics augment
#' @export
generics::augment

#' @rdname regrans-tidiers
#' @export
tidy.regrans <- function(x, ...) {
  contrasts <- segment_contrasts(x)
  contrast_matrix <- contrasts$matrix
  estimate <- as.vector(contrast_matrix %*% stats::coef(x$model_fit))
  variance <- contrast_matrix %*% stats::vcov(x$model_fit) %*%
    t(contrast_matrix)
  std_error <- sqrt(pmax(0, diag(variance)))
  statistic <- estimate / std_error
  p_value <- 2 * stats::pt(-abs(statistic), df = x$model_fit$df.residual)
  tibble::tibble(
    segment = contrasts$segment,
    term = contrasts$term,
    estimate = estimate,
    std.error = std_error,
    statistic = statistic,
    p.value = p_value
  )
}

#' @rdname regrans-tidiers
#' @export
glance.regrans <- function(x, ...) {
  identified <- x$location$status != "unidentified"
  selected <- if (identified) {
    x$candidates[
      x$candidates$split_index == x$location$split_index, ,
      drop = FALSE
    ]
  } else {
    NULL
  }
  tibble::tibble(
    nobs = nrow(x$data),
    n_min = x$n_min,
    model = x$model,
    status = x$location$status,
    n_candidates = nrow(x$candidates),
    split_index = x$location$split_index,
    breakpoint = x$location$estimate,
    left_max_x = x$location$left_max_x,
    right_min_x = x$location$right_min_x,
    left_rss = if (identified) selected$left_rss else NA_real_,
    right_rss = if (identified) selected$right_rss else NA_real_,
    rss = sum(stats::residuals(x$model_fit)^2)
  )
}

#' Derive segment coefficients from the selected joint model
#'
#' @param fit Selected fit with a joint `lm` and transition location.
#' @return A data frame with intercept and slope estimates per segment.
#' @noRd
segment_estimates <- function(fit) {
  contrasts <- segment_contrasts(fit)
  data.frame(
    segment = contrasts$segment,
    term = contrasts$term,
    estimate = as.vector(contrasts$matrix %*% stats::coef(fit$model_fit))
  )
}

#' Build linear contrasts for the segment coefficients
#'
#' @param fit Selected fit with a joint `lm` and transition location.
#' @return Contrast matrix and corresponding segment and term labels.
#' @noRd
segment_contrasts <- function(fit) {
  coefficients <- names(stats::coef(fit$model_fit))
  if (fit$location$status == "unidentified") {
    segment <- rep("overall", 2L)
    term <- c("(Intercept)", "X")
  } else {
    segment <- rep(c("left", "right"), each = 2L)
    term <- rep(c("(Intercept)", "X"), 2L)
  }
  contrast_matrix <- matrix(0,
    nrow = length(term), ncol = length(coefficients),
    dimnames = list(NULL, coefficients)
  )
  contrast_matrix[term == "(Intercept)", "(Intercept)"] <- 1
  contrast_matrix[term == "X", "X"] <- 1
  if (fit$location$status != "unidentified") {
    right <- segment == "right"
    if (fit$model == "discontinuous") {
      contrast_matrix[right & term == "(Intercept)", "segmentright"] <- 1
      contrast_matrix[right & term == "X", "X:segmentright"] <- 1
    } else {
      contrast_matrix[right & term == "(Intercept)", "hinge"] <-
        -fit$location$estimate
      contrast_matrix[right & term == "X", "hinge"] <- 1
    }
  }
  list(matrix = contrast_matrix, segment = segment, term = term)
}

#' @rdname regrans-tidiers
#' @param data Must be `NULL`; training data are stored in `x`.
#' @param newdata Must be `NULL`. Prediction at unobserved values is not
#'   defined by this interface.
#' @export
augment.regrans <- function(x, data = NULL, newdata = NULL, ...) {
  if (!is.null(data) || !is.null(newdata)) {
    stop("augment.regrans() only supports its stored training data.",
      call. = FALSE
    )
  }
  output <- x$data |> tibble::as_tibble()
  added <- c(".segment", ".fitted", ".resid")
  if (any(added %in% names(output))) {
    stop("Training data already contain an augment column name.",
      call. = FALSE
    )
  }
  output$.segment <- x$segment
  output$.fitted <- x$fitted_values
  output$.resid <- x$residual_values
  output
}
