#' Fit two independent linear segments
#'
#' `regrans()` orders observations by the explanatory variable and chooses
#' the admissible partition with the smallest combined residual sum of
#' squares. The two fitted lines are independent and need not meet. The
#' selected split is an interval between observed values, not an estimated
#' continuous breakpoint.
#'
#' @param x A finite numeric explanatory vector, or a formula of the form
#'   `response ~ predictor` with bare column names.
#' @param y A finite numeric response vector when `x` is a vector.
#' @param n.min Minimum number of observations on each side (at least 3).
#' @param data A data frame containing the columns in `x` when `x` is a
#'   formula.
#' @return An object of class `regrans`. `left` and `right` are ordinary
#'   `lm` objects. `split` gives the last observed `x` on the left and the
#'   first observed `x` on the right; `candidates` records the admissible
#'   partitions and their residual sums of squares. `data`, `segment`,
#'   `fitted_values`, and `residual_values` retain the original row order.
#' @examples
#' data(simdata)
#' fit <- regrans(y ~ x, data = simdata)
#' summary(fit)
#' fit$split
#' @export
regrans <- function(x, y, n.min = 5, data = NULL) {
  if (inherits(x, "formula")) {
    if (!missing(y)) {
      stop("Do not supply y when x is a formula.", call. = FALSE)
    }
    input <- formula_regrans_input(x, data)
  } else {
    if (missing(y)) {
      stop("y is required when x is a numeric vector.", call. = FALSE)
    }
    input <- vector_regrans_input(x, y, data)
  }

  n.min <- validate_regrans_input(input$x, input$y, n.min)
  fit <- regranslm(input$x, input$y, n.min)
  assemble_regrans_fit(fit, input, n.min)
}

#' Read a two-variable formula without evaluating transformations
#'
#' @param formula A formula with bare response and predictor names.
#' @param data A data frame containing both variables.
#' @return A list with numeric inputs, their source data, and column names.
#' @noRd
formula_regrans_input <- function(formula, data) {
  if (!is.data.frame(data)) {
    stop("data must be a data frame for the formula interface.",
         call. = FALSE)
  }
  if (length(formula) != 3L || !is.symbol(formula[[2L]]) ||
      !is.symbol(formula[[3L]])) {
    stop("Use a formula with bare column names: response ~ predictor.",
         call. = FALSE)
  }
  response <- as.character(formula[[2L]])
  predictor <- as.character(formula[[3L]])
  if (!all(c(response, predictor) %in% names(data))) {
    stop("Both formula variables must be columns of data.",
         call. = FALSE)
  }
  source_data <- as.data.frame(data)
  list(x = source_data[[predictor]], y = source_data[[response]],
       data = source_data, predictor = predictor, response = response)
}

#' Prepare the vector interface for validation
#'
#' @param x,y Explanatory and response vectors.
#' @param data Must be `NULL` for the vector interface.
#' @return A list with inputs and their default column names.
#' @noRd
vector_regrans_input <- function(x, y, data) {
  if (!is.null(data)) {
    stop("data is only used with a formula.", call. = FALSE)
  }
  list(x = x, y = y, data = NULL, predictor = "x", response = "y")
}

#' Validate observations and minimum segment size
#'
#' @param x,y Explanatory and response vectors.
#' @param n.min Requested minimum observations per segment.
#' @return The validated minimum as an integer; errors on invalid inputs.
#' @noRd
validate_regrans_input <- function(x, y, n.min) {
  if (!valid_regrans_vectors(x, y)) {
    stop("x and y must be finite numeric vectors of equal length.",
         call. = FALSE)
  }
  if (!valid_n_min(n.min)) {
    stop("n.min must be one integer of at least 3.", call. = FALSE)
  }
  if (length(x) < 2 * n.min) {
    stop("At least 2 * n.min observations are required.",
         call. = FALSE)
  }
  as.integer(n.min)
}

#' Check whether paired vectors can be fitted
#'
#' @param x,y Candidate explanatory and response vectors.
#' @return `TRUE` when both are finite numeric vectors of equal length.
#' @noRd
valid_regrans_vectors <- function(x, y) {
  if (!is.numeric(x) || !is.numeric(y) || length(x) != length(y)) {
    return(FALSE)
  }
  all(is.finite(x)) && all(is.finite(y))
}

#' Check the minimum segment size argument
#'
#' @param n.min Candidate minimum segment size.
#' @return `TRUE` for one integer-valued number of at least three.
#' @noRd
valid_n_min <- function(n.min) {
  if (!is.numeric(n.min) || length(n.min) != 1L) {
    return(FALSE)
  }
  is.finite(n.min) && n.min >= 3 && n.min == floor(n.min)
}

#' Restore original observation order in a selected fit
#'
#' @param fit Output of `regranslm()` with selected models and sorted rows.
#' @param input Validated inputs and original data.
#' @param n.min Validated minimum segment size.
#' @return A `regrans` object with row-aligned segment and fitted values.
#' @noRd
assemble_regrans_fit <- function(fit, input, n.min) {
  if (is.null(input$data)) {
    input$data <- data.frame(x = input$x, y = input$y)
  }
  fit$data <- input$data
  fit$variables <- c(x = input$predictor, y = input$response)
  fit$n.min <- n.min

  sorted_rows <- fit$sorted_rows
  left_rows <- sorted_rows[seq_len(fit$split$index)]
  right_rows <- sorted_rows[seq.int(fit$split$index + 1L,
                                    length(sorted_rows))]
  fit$segment <- character(length(sorted_rows))
  fit$segment[left_rows] <- "left"
  fit$segment[right_rows] <- "right"
  fit$fitted_values <- numeric(length(sorted_rows))
  fit$residual_values <- numeric(length(sorted_rows))
  fit$fitted_values[left_rows] <- stats::fitted(fit$left)
  fit$fitted_values[right_rows] <- stats::fitted(fit$right)
  fit$residual_values[left_rows] <- stats::residuals(fit$left)
  fit$residual_values[right_rows] <- stats::residuals(fit$right)
  class(fit) <- "regrans"
  fit
}
