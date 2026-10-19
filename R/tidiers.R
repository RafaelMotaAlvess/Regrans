#' Tidy a regrans fit
#'
#' These methods describe the selected pair of models. Coefficient standard
#' errors and p-values are conditional on the selected partition; they do
#' not measure uncertainty about the split.
#'
#' @param x A `regrans` object.
#' @param ... Reserved for the generic; unused.
#' @return `tidy()` returns one coefficient row per term and segment.
#'   `glance()` returns one row with `n_min`, the selected split, and fit
#'   scores.
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
  one_segment <- function(model, segment) {
    coefficients <- summary(model)$coefficients
    tibble::tibble(
      segment = rep(segment, nrow(coefficients)),
      term = rownames(coefficients),
      estimate = coefficients[, 1L],
      std.error = coefficients[, 2L],
      statistic = coefficients[, 3L],
      p.value = coefficients[, 4L]
    )
  }
  rbind(one_segment(x$left, "left"), one_segment(x$right, "right"))
}

#' @rdname regrans-tidiers
#' @export
glance.regrans <- function(x, ...) {
  selected <- x$candidates[
    x$candidates$split_index == x$split$index, , drop = FALSE
  ]
  tibble::tibble(
    nobs = nrow(x$data),
    n_min = x$n_min,
    n_candidates = nrow(x$candidates),
    split_index = x$split$index,
    left_max_x = x$split$left_max_x,
    right_min_x = x$split$right_min_x,
    left_rss = selected$left_rss,
    right_rss = selected$right_rss,
    rss = selected$rss
  )
}

#' @rdname regrans-tidiers
#' @param data Must be `NULL`; training data are stored in `x`.
#' @param newdata Must be `NULL`. Prediction at unobserved values is not
#'   defined by this interface.
#' @export
augment.regrans <- function(x, data = NULL, newdata = NULL, ...) {
  if (!is.null(data) || !is.null(newdata)) {
    stop("augment.regrans() only supports its stored training data.",
         call. = FALSE)
  }
  output <- x$data |> tibble::as_tibble()
  added <- c(".segment", ".fitted", ".resid")
  if (any(added %in% names(output))) {
    stop("Training data already contain an augment column name.",
         call. = FALSE)
  }
  output$.segment <- x$segment
  output$.fitted <- x$fitted_values
  output$.resid <- x$residual_values
  output
}
