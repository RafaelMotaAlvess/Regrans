#' Fit a segmented linear regression with one transition
#'
#' `regrans()` orders observations by the explanatory variable. The default
#' `"discontinuous"` model chooses the admissible partition with the smallest
#' combined residual sum of squares (RSS); its two lines need not meet and the
#' location is an interval between observations. The `"continuous"` model
#' minimizes profiled RSS for a hinge regression and estimates a numeric
#' breakpoint. Neither mode tests whether a break exists.
#'
#' @param x A finite numeric explanatory vector, or a formula of the form
#'   `response ~ predictor` with bare column names.
#' @param y A finite numeric response vector when `x` is a vector.
#' @param n_min Minimum number of observations on each side (at least 3).
#' @param data A data frame containing the columns in `x` when `x` is a
#'   formula.
#' @param model Either `"discontinuous"` (the default) or `"continuous"`.
#' @return An object of class `regrans`. `model_fit` is an `lm` object;
#'   `segments` gives its fitted lines. `location` contains an `estimate`
#'   only for an identified continuous break. Its observed bounds identify
#'   the selected gap, not a confidence interval. `candidates` records the
#'   admissible gaps and RSS values. `data`, `segment`, `fitted_values`, and
#'   `residual_values` retain the original row order. A numerically flat
#'   continuous RSS profile returns `location$status = "unidentified"`,
#'   `estimate = NA`, and an ordinary linear `model_fit`.
#' @examples
#' data(simdata)
#' fit <- regrans(y ~ x, data = simdata)
#' summary(fit)
#' fit$location
#' continuous_fit <- regrans(y ~ x, data = simdata, model = "continuous")
#' glance(continuous_fit)
#' @export
regrans <- function(x, y, n_min = 5, data = NULL,
                    model = c("discontinuous", "continuous")) {
  model <- match.arg(model)
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

  n_min <- validate_regrans_input(input$x, input$y, n_min)
  fit <- if (model == "discontinuous") {
    regranslm(input$x, input$y, n_min) # nolint: object_usage_linter.
  } else {
    # Defined in continuous_regrans.R; lintr checks files separately.
    continuous_regrans(input$x, input$y, n_min) # nolint: object_usage_linter.
  }
  assemble_regrans_fit(fit, input, n_min)
}

#' Read a two-variable formula without evaluating transformations
#'
#' @param formula A formula with bare response and predictor names.
#' @param data A data frame containing both variables.
#' @return A list with numeric inputs, their source data, and column names.
#' @noRd
formula_regrans_input <- function(formula, data) {
  if (!is.data.frame(data)) {
    stop(
      "data must be a data frame for the formula interface.",
      call. = FALSE
    )
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
#' @param n_min Requested minimum observations per segment.
#' @return The validated minimum as an integer; errors on invalid inputs.
#' @noRd
validate_regrans_input <- function(x, y, n_min) {
  if (!valid_regrans_vectors(x, y)) {
    stop("x and y must be finite numeric vectors of equal length.",
         call. = FALSE)
  }
  if (!valid_n_min(n_min)) {
    stop("n_min must be one integer of at least 3.", call. = FALSE)
  }
  if (length(x) < 2 * n_min) {
    stop("At least 2 * n_min observations are required.",
         call. = FALSE)
  }
  as.integer(n_min)
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
#' @param n_min Candidate minimum segment size.
#' @return `TRUE` for one integer-valued number of at least three.
#' @noRd
valid_n_min <- function(n_min) {
  if (!is.numeric(n_min) || length(n_min) != 1L) {
    return(FALSE)
  }
  is.finite(n_min) && n_min >= 3 && n_min == floor(n_min)
}

#' Restore original observation order in a selected fit
#'
#' @param fit Selected model, location, and sorted rows.
#' @param input Validated inputs and original data.
#' @param n_min Validated minimum segment size.
#' @return A `regrans` object with row-aligned segment and fitted values.
#' @noRd
assemble_regrans_fit <- function(fit, input, n_min) {
  if (is.null(input$data)) {
    input$data <- data.frame(x = input$x, y = input$y)
  }
  fit$data <- input$data
  fit$variables <- c(x = input$predictor, y = input$response)
  fit$n_min <- n_min

  sorted_rows <- fit$sorted_rows
  fit$segment <- character(length(sorted_rows))
  if (fit$location$status == "unidentified") {
    fit$segment[] <- "overall"
  } else {
    left_rows <- sorted_rows[seq_len(fit$location$split_index)]
    right_rows <- sorted_rows[seq.int(fit$location$split_index + 1L,
                                      length(sorted_rows))]
    fit$segment[left_rows] <- "left"
    fit$segment[right_rows] <- "right"
  }
  fit$fitted_values <- numeric(length(sorted_rows))
  fit$residual_values <- numeric(length(sorted_rows))
  fit$fitted_values[sorted_rows] <- stats::fitted(fit$model_fit)
  fit$residual_values[sorted_rows] <- stats::residuals(fit$model_fit)
  # Defined in tidiers.R; lintr checks files separately.
  fit$segments <- segment_estimates(fit) # nolint: object_usage_linter.
  class(fit) <- "regrans"
  fit
}
