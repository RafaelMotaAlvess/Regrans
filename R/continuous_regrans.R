#' Profile a continuous one-break regression over admissible gaps
#'
#' At a fixed breakpoint, the hinge model is linear in its coefficients.
#' The search evaluates every admissible gap, splitting a gap at any internal
#' maximum of its profiled RSS before applying bounded Brent optimization.
#' This avoids assuming that the profile is unimodal over the entire range.
#'
#' @param x,y Validated finite numeric input vectors.
#' @param n_min Validated minimum observations per side.
#' @return A fitted hinge `lm`, location, candidate scores, sorted rows, and
#'   numerical search information. A flat profile returns a linear `lm` and
#'   an unidentified location.
#' @noRd
continuous_regrans <- function(x, y, n_min) {
  sorted_rows <- order(x, seq_along(x))
  ordered <- data.frame(X = x[sorted_rows], Y = y[sorted_rows])
  # lintr checks files separately; this helper is defined in regranslm.R.
  # nolint next: object_usage_linter.
  split_indices <- admissible_splits(ordered$X, n_min)
  if (!length(split_indices)) {
    stop("No admissible split: each side needs n_min observations and ",
         "at least two distinct x values.", call. = FALSE)
  }

  scaled <- scaled_continuous_profile(ordered)
  gaps <- lapply(split_indices, function(index) {
    best_continuous_gap(scaled$x, scaled$y, index, scaled$profile)
  })
  candidates <- score_continuous_gaps(ordered$X, split_indices, gaps,
                                      scaled$x_origin, scaled$x_span,
                                      scaled$y_scale)
  search <- list(method = "profile_brent",
                 evaluations = scaled$progress$evaluations,
                 tolerance = 1e-8 * scaled$x_span)
  select_continuous_fit(ordered, sorted_rows, candidates, scaled$progress,
                        search)
}

#' Scale inputs and create a profiled RSS evaluator
#'
#' @param ordered Data frame sorted by predictor with `X` and `Y` columns.
#' @return Scaled inputs, scale factors, evaluator, and progress counters.
#' @noRd
scaled_continuous_profile <- function(ordered) {
  x_origin <- min(ordered$X)
  x_span <- diff(range(ordered$X))
  scaled_x <- (ordered$X - x_origin) / x_span
  y_scale <- stats::sd(ordered$Y)
  if (y_scale == 0) {
    y_scale <- 1
  }
  scaled_y <- (ordered$Y - mean(ordered$Y)) / y_scale
  progress <- new.env(parent = emptyenv())
  progress$evaluations <- 0L
  progress$min_rss <- Inf
  progress$max_rss <- -Inf

  profile <- function(breakpoint) {
    progress$evaluations <- progress$evaluations + 1L
    design <- cbind(1, scaled_x, pmax(0, scaled_x - breakpoint))
    fitted <- stats::lm.fit(design, scaled_y)
    rss <- if (fitted$rank == 3L) {
      sum(fitted$residuals^2)
    } else {
      Inf
    }
    if (is.finite(rss)) {
      progress$min_rss <- min(progress$min_rss, rss)
      progress$max_rss <- max(progress$max_rss, rss)
    }
    list(rss = rss, residuals = fitted$residuals)
  }
  list(x = scaled_x, y = scaled_y, x_origin = x_origin, x_span = x_span,
       y_scale = y_scale, profile = profile, progress = progress)
}

#' Record minimum profiled RSS in each admissible gap
#'
#' @param x Original predictor sorted in ascending order.
#' @param split_indices Admissible positions after which to divide `x`.
#' @param gaps Per-gap minimum scores and residual vectors.
#' @param x_origin,x_span Predictor scale factors.
#' @param y_scale Response scale factor.
#' @return A candidate table with refined breakpoint estimates.
#' @noRd
score_continuous_gaps <- function(x, split_indices, gaps, x_origin,
                                  x_span, y_scale) {
  valid <- vapply(gaps, function(gap) is.finite(gap$rss), logical(1))
  if (!any(valid)) {
    stop("No admissible continuous fit has full rank and finite RSS.",
         call. = FALSE)
  }
  split_indices <- split_indices[valid]
  gaps <- gaps[valid]
  estimates <- vapply(gaps, function(gap) gap$estimate, numeric(1))
  left_rss <- vapply(seq_along(gaps), function(j) {
    sum(gaps[[j]]$residuals[seq_len(split_indices[[j]])]^2)
  }, numeric(1)) * y_scale^2
  right_rss <- vapply(seq_along(gaps), function(j) {
    sum(gaps[[j]]$residuals[seq.int(split_indices[[j]] + 1L, length(x))]^2)
  }, numeric(1)) * y_scale^2
  # lintr checks files separately; this helper is defined in regranslm.R.
  # nolint next: object_usage_linter.
  candidates <- candidate_table(x, split_indices,
                                left_rss, right_rss)
  candidates$estimate <- x_origin + x_span * estimates
  candidates[, c("split_index", "left_n", "right_n", "left_max_x",
                 "right_min_x", "estimate", "left_rss", "right_rss", "rss")]
}

#' Refit the best continuous model or report an unidentified location
#'
#' @param ordered Data frame sorted by predictor with `X` and `Y` columns.
#' @param sorted_rows Original row indices in predictor order.
#' @param candidates Per-gap minimum scores.
#' @param progress RSS range observed across numerical evaluations.
#' @param search Search method and evaluation count.
#' @return A fitted `lm`, location, candidates, rows, and search details.
#' @noRd
select_continuous_fit <- function(ordered, sorted_rows, candidates,
                                  progress, search) {
  rss_span <- progress$max_rss - progress$min_rss
  if (rss_span <= 1e-8 * max(1, progress$max_rss)) {
    return(list(
      model = "continuous",
      model_fit = stats::lm(Y ~ X, data = ordered),
      location = list(status = "unidentified", estimate = NA_real_,
                      split_index = NA_integer_, left_max_x = NA_real_,
                      right_min_x = NA_real_),
      candidates = candidates,
      sorted_rows = sorted_rows,
      search = search
    ))
  }

  best <- which.min(candidates$rss)
  index <- candidates$split_index[[best]]
  breakpoint <- candidates$estimate[[best]]
  ordered$hinge <- pmax(0, ordered$X - breakpoint)
  list(
    model = "continuous",
    model_fit = stats::lm(Y ~ X + hinge, data = ordered),
    location = list(status = "identified", estimate = breakpoint,
                    split_index = index,
                    left_max_x = ordered$X[[index]],
                    right_min_x = ordered$X[[index + 1L]]),
    candidates = candidates,
    sorted_rows = sorted_rows,
    search = search
  )
}

#' Minimize profiled RSS within one observed-x gap
#'
#' Residualizing the hinge against the intercept and linear term shows that
#' the profile has at most one internal RSS maximum and one internal minimum
#' within a gap. Splitting at the maximum makes each Brent search unimodal.
#'
#' @param x,y Scaled, sorted predictor and response.
#' @param index Index of the last observation to the left of the gap.
#' @param profile Function returning RSS and residuals at a breakpoint.
#' @return Minimum RSS, breakpoint, and residuals for the gap.
#' @noRd
best_continuous_gap <- function(x, y, index, profile) {
  lower <- x[[index]]
  upper <- x[[index + 1L]]
  base <- cbind(1, x)
  right <- as.numeric(seq_along(x) > index)
  response_resid <- stats::lm.fit(base, y)$residuals
  x_right_resid <- stats::lm.fit(base, x * right)$residuals
  right_resid <- stats::lm.fit(base, right)$residuals
  denominator <- sum(response_resid * right_resid)
  bounds <- c(lower, upper)
  if (abs(denominator) > .Machine$double.eps) {
    maximum <- sum(response_resid * x_right_resid) / denominator
    if (is.finite(maximum) && maximum > lower && maximum < upper) {
      bounds <- c(lower, maximum, upper)
    }
  }

  points <- bounds
  for (j in seq_len(length(bounds) - 1L)) {
    interval <- bounds[c(j, j + 1L)]
    optimum <- stats::optimize(
      function(value) profile(value)$rss,
      interval = interval,
      tol = min(1e-8, diff(interval) / 100)
    )
    points <- c(points, optimum$minimum)
  }
  scores <- lapply(points, profile)
  rss <- vapply(scores, function(score) score$rss, numeric(1))
  best <- which.min(rss)
  list(estimate = points[[best]], rss = rss[[best]],
       residuals = scores[[best]]$residuals)
}
