#' Summarize both fitted segments
#'
#' @param object A `regrans` object.
#' @param correlation,symbolic.cor Arguments passed to `summary.lm()`.
#' @param ... Further arguments passed to `summary.lm()`.
#' @return A list with `left` and `right` `summary.lm` objects. Their
#'   coefficient inference is conditional on the selected partition.
#' @examples
#' data(simdata)
#' summary(regrans(simdata$x, simdata$y))
#' @export
summary.regrans <- function(object, correlation = FALSE,
                            symbolic.cor = FALSE, ...) {
  list(
    left = summary(object$left, correlation = correlation,
                   symbolic.cor = symbolic.cor, ...),
    right = summary(object$right, correlation = correlation,
                    symbolic.cor = symbolic.cor, ...)
  )
}
