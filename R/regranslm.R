#' Search admissible divisions between observations
#'
#' Fits two independent `lm` models for each candidate and minimizes their
#' combined RSS. A tie selects the earliest admissible division in sorted
#' predictor order. The selected partition is refitted as an equivalent
#' interaction model for the common result interface. No numeric breakpoint
#' is estimated.
#'
#' @param x,y Validated finite numeric input vectors.
#' @param n_min Validated minimum observations per side.
#' @return An interaction `lm`, interval location, candidate scores, and the
#'   row permutation used for sorting.
#' @noRd
regranslm <- function(x, y, n_min) {
  sorted_rows <- order(x, seq_along(x))
  ordered <- data.frame(X = x[sorted_rows], Y = y[sorted_rows])
  n <- nrow(ordered)
  split_indices <- admissible_splits(ordered$X, n_min)
  if (!length(split_indices)) {
    stop("No admissible split: each side needs n_min observations and ",
         "at least two distinct x values.", call. = FALSE)
  }

  scores <- score_independent_splits(ordered, split_indices)
  split_indices <- scores$split_indices
  rss <- scores$left_rss + scores$right_rss
  best <- which.min(rss)
  index <- split_indices[[best]]
  ordered$segment <- factor(
    rep(c("left", "right"), c(index, n - index)),
    levels = c("left", "right")
  )
  model_fit <- stats::lm(Y ~ X * segment, data = ordered)
  list(
    model = "discontinuous",
    model_fit = model_fit,
    location = list(status = "interval", estimate = NA_real_,
                    split_index = index,
                    left_max_x = ordered$X[[index]],
                    right_min_x = ordered$X[[index + 1L]]),
    candidates = candidate_table(ordered$X, split_indices,
                                 scores$left_rss, scores$right_rss),
    sorted_rows = sorted_rows,
    search = list(method = "exhaustive", evaluations = length(split_indices))
  )
}

#' Score independent line fits at every candidate division
#'
#' @param ordered Data frame sorted by predictor with `X` and `Y` columns.
#' @param split_indices Admissible positions after which to divide `X`.
#' @return Finite candidate indices and separate residual sums of squares.
#' @noRd
score_independent_splits <- function(ordered, split_indices) {
  n <- nrow(ordered)
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
  list(split_indices = split_indices[finite],
       left_rss = left_rss[finite], right_rss = right_rss[finite])
}

#' Enumerate divisions that can estimate both slopes
#'
#' @param x Predictor values sorted in ascending order.
#' @param n_min Minimum observations on either side.
#' @return Integer split indices between distinct `x` values, with at least
#'   two distinct values on each side.
#' @noRd
admissible_splits <- function(x, n_min) {
  n <- length(x)
  indices <- seq.int(n_min, n - n_min)
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
    estimate = rep(NA_real_, length(split_indices)),
    left_rss = left_rss,
    right_rss = right_rss,
    rss = left_rss + right_rss
  )
}
