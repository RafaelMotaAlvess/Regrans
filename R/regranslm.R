#' Search admissible divisions between observations
#'
#' Fits two independent `lm` models for each candidate and minimizes their
#' combined RSS. A tie selects the earliest admissible division in sorted
#' predictor order. No continuity constraint or numerical breakpoint is used.
#'
#' @param x,y Validated finite numeric input vectors.
#' @param n.min Validated minimum observations per side.
#' @return Selected `left` and `right` models, split bounds, candidate scores,
#'   and the row permutation used for sorting.
#' @noRd
regranslm <- function(x, y, n.min) {
  sorted_rows <- order(x, seq_along(x))
  ordered <- data.frame(X = x[sorted_rows], Y = y[sorted_rows])
  n <- nrow(ordered)
  split_indices <- admissible_splits(ordered$X, n.min)
  if (!length(split_indices)) {
    stop("No admissible split: each side needs n.min observations and ",
         "at least two distinct x values.", call. = FALSE)
  }

  models <- lapply(split_indices, function(i) {
    list(
      left = stats::lm(Y ~ X, data = ordered[seq_len(i), , drop = FALSE]),
      right = stats::lm(Y ~ X, data = ordered[seq.int(i + 1L, n), ,
                                                 drop = FALSE])
    )
  })
  left_rss <- vapply(models, function(model) model_rss(model$left), numeric(1))
  right_rss <- vapply(models, function(model) model_rss(model$right),
                      numeric(1))
  rss <- left_rss + right_rss
  finite <- is.finite(rss)
  if (!any(finite)) {
    stop("No admissible split has a finite residual sum of squares.",
         call. = FALSE)
  }
  split_indices <- split_indices[finite]
  models <- models[finite]
  left_rss <- left_rss[finite]
  right_rss <- right_rss[finite]
  rss <- rss[finite]

  best <- which.min(rss)
  index <- split_indices[[best]]
  list(
    left = models[[best]]$left,
    right = models[[best]]$right,
    split = list(index = index, left_max_x = ordered$X[[index]],
                 right_min_x = ordered$X[[index + 1L]]),
    candidates = candidate_table(ordered$X, split_indices,
                                 left_rss, right_rss),
    sorted_rows = sorted_rows
  )
}

#' Enumerate divisions that can estimate both slopes
#'
#' @param x Predictor values sorted in ascending order.
#' @param n.min Minimum observations on either side.
#' @return Integer split indices between distinct `x` values, with at least
#'   two distinct values on each side.
#' @noRd
admissible_splits <- function(x, n.min) {
  n <- length(x)
  indices <- seq.int(n.min, n - n.min)
  indices <- indices[x[indices] < x[indices + 1L]]
  indices[vapply(indices, function(i) {
    length(unique(x[seq_len(i)])) >= 2L &&
      length(unique(x[seq.int(i + 1L, n)])) >= 2L
  }, logical(1))]
}

#' Calculate a model's residual sum of squares
#'
#' @param model A fitted `lm` model.
#' @return A single numeric RSS value.
#' @noRd
model_rss <- function(model) {
  sum(stats::residuals(model)^2)
}

#' Record the scores and observed bounds of admissible divisions
#'
#' @param x Predictor values sorted in ascending order.
#' @param split_indices Admissible positions after which to divide `x`.
#' @param left_rss,right_rss Residual sums of squares for each side.
#' @return A data frame with counts, observed bounds, and RSS per candidate.
#' @noRd
candidate_table <- function(x, split_indices, left_rss, right_rss) {
  data.frame(
    split_index = split_indices,
    left_n = split_indices,
    right_n = length(x) - split_indices,
    left_max_x = x[split_indices],
    right_min_x = x[split_indices + 1L],
    left_rss = left_rss,
    right_rss = right_rss,
    rss = left_rss + right_rss
  )
}
