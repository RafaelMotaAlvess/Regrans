#' Fit an exploratory ANCOVA model for the two selected segments
#'
#' This internal helper compares coefficients after the split has already
#' been selected. It is not part of the supported inferential interface.
#'
#' @param obj A fitted `regrans` object.
#' @return An `lm` model for the interaction of `X` with segment identity,
#'   returned invisibly.
#' @noRd
regrans_ancova <- function(obj) {
  n_left <- nrow(obj$left$model)
  n_right <- nrow(obj$right$model)
  model_data <- data.frame(
    model = c(rep("left", n_left), rep("right", n_right)),
    rbind(obj$left$model, obj$right$model)
  )
  fit <- stats::lm(Y ~ X * model, data = model_data)
  invisible(fit)
}
