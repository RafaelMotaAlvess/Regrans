#' Fit an exploratory ANCOVA model for the two selected segments
#'
#' This internal helper compares coefficients after the split has already
#' been selected. It is not part of the supported inferential interface.
#'
#' @param obj A fitted `regrans` object.
#' @return An `lm` model for the interaction of `X` with segment identity.
#' @noRd
regrans_ancova <- function(obj) {
    nleft <- nrow(obj$left$model)
    nright <- nrow(obj$right$model)
    da <- data.frame(model = c(rep("left", nleft),
                               rep("right", nright)),
                     rbind(obj$left$model, obj$right$model))
    m1 <- stats::lm(Y ~ X*model, data = da)
}
