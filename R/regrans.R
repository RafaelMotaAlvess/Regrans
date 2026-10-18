##' @title Fit a Two-Segment Linear Regression
##' @name regrans
##'
##' @description Fit two independent linear models after selecting the split
##'     with the smallest combined residual sum of squares.
##' @param x a numeric vector.
##' @param y a numeric vector.
##' @param n.min minimum number of points (x,y) to be considered in a
##'     linear model.
##' @return An object of class \code{regrans}, a list containing the fitted
##'     \code{lm} models named \code{left} and \code{right}.
##' @author Rodrigo Sant'Ana \email{rsantana@@univali.br}, Fernando
##'     Mayer \email{fernando.mayer@@ufpr.br}
##'
##' @importFrom stats lm
##'
##' @examples
##' data(simdata)
##' fit <- regrans(simdata$x, simdata$y)
##' summary(fit)
##'
##' @export
regrans <- function(x, y, n.min = 5) {
    obj <- regranslm(x = x, y = y, n.min = n.min)
    obj$out$id <- as.numeric(gsub("\\D", "", row.names(obj$out)))
    vet <- tapply(obj$out$sq.res, obj$out$id, sum)
    b.fit <- obj$mod[[which.min(vet)[1]]]
    class(b.fit) <- "regrans"
    return(b.fit)
}
