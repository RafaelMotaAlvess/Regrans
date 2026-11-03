#' Profile a continuous one-break regression over admissible gaps
#'
#' At a fixed breakpoint, the hinge model is linear in its coefficients.
#' The search evaluates every admissible gap, splitting a gap at any internal
#' maximum of its profiled RSS before bounded golden-section refinement.
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
    before <- scaled$progress$evaluations
    gap <- best_continuous_gap(scaled$x, scaled$y, index,
                               scaled$profile)
    gap$evaluations <- scaled$progress$evaluations - before
    gap
  })
  candidates <- score_continuous_gaps(ordered$X, split_indices, gaps,
                                      scaled$x_origin, scaled$x_span,
                                      scaled$y_scale)
  search <- list(method = "profile_golden_section",
                 termination = "tolerance_reached",
                 convergence = "converged",
                 iterations = sum(vapply(gaps, function(gap) {
                   gap$iterations
                 }, integer(1))),
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
  if (!all(valid)) {
    stop("An admissible continuous fit lacks full rank or finite RSS.",
         call. = FALSE)
  }
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
  candidates$iterations <- vapply(gaps, function(gap) {
    gap$iterations
  }, integer(1))
  candidates$evaluations <- vapply(gaps, function(gap) {
    gap$evaluations
  }, integer(1))
  candidates$convergence <- rep("converged", length(gaps))
  candidates$tolerance <- vapply(gaps, function(gap) {
    gap$tolerance
  }, numeric(1)) * x_span
  candidates[, c("split_index", "left_n", "right_n", "left_max_x",
                 "right_min_x", "estimate", "left_rss", "right_rss", "rss",
                 "iterations", "evaluations", "convergence", "tolerance")]
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
#' within a gap. Splitting at the maximum makes each refinement unimodal.
#'
#' @param x,y Scaled, sorted predictor and response.
#' @param index Index of the last observation to the left of the gap.
#' @param profile Function returning RSS and residuals at a breakpoint.
#' @return Minimum RSS, breakpoint, residuals, iterations, and tolerance.
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
  refinements <- vector("list", length(bounds) - 1L)
  for (j in seq_len(length(bounds) - 1L)) {
    interval <- bounds[c(j, j + 1L)]
    refinements[[j]] <- refine_continuous_interval(
      profile, interval[[1L]], interval[[2L]]
    )
    points <- c(points, refinements[[j]]$estimate)
  }
  scores <- lapply(points, profile)
  rss <- vapply(scores, function(score) score$rss, numeric(1))
  best <- which.min(rss)
  list(estimate = points[[best]], rss = rss[[best]],
       residuals = scores[[best]]$residuals,
       iterations = sum(vapply(refinements, function(result) {
         result$iterations
       }, integer(1))),
       tolerance = max(vapply(refinements, function(result) {
         result$tolerance
       }, numeric(1))))
}

#' Refine a profiled RSS minimum with an explicit stopping rule
#'
#' Golden-section search applies after the profile is split into unimodal
#' intervals. A numerical failure stops the fit rather than silently omitting
#' a candidate that might contain the global minimum.
#'
#' @param profile Function returning RSS at a scaled breakpoint.
#' @param lower,upper Bounds of a unimodal interval on the scaled predictor.
#' @return The best interior point, iteration count, and achieved tolerance.
#' @noRd
refine_continuous_interval <- function(profile, lower, upper) {
  width <- upper - lower
  tolerance <- max(min(1e-8, width / 100),
                   16 * .Machine$double.eps)
  ratio <- (sqrt(5) - 1) / 2
  left <- upper - ratio * width
  right <- lower + ratio * width
  left_rss <- checked_profile_rss(profile, left)
  right_rss <- checked_profile_rss(profile, right)

  iterations <- 0L
  while (upper - lower > tolerance && iterations < 128L) {
    if (left <= lower || right >= upper || left >= right) {
      stop("Continuous search reached numeric precision before tolerance.",
           call. = FALSE)
    }
    if (left_rss <= right_rss) {
      upper <- right
      right <- left
      right_rss <- left_rss
      left <- upper - ratio * (upper - lower)
      left_rss <- checked_profile_rss(profile, left)
    } else {
      lower <- left
      left <- right
      left_rss <- right_rss
      right <- lower + ratio * (upper - lower)
      right_rss <- checked_profile_rss(profile, right)
    }
    iterations <- iterations + 1L
  }
  if (upper - lower > tolerance) {
    stop("Continuous search reached its iteration limit.",
         call. = FALSE)
  }
  estimate <- if (left_rss <= right_rss) left else right
  list(estimate = estimate, iterations = iterations,
       tolerance = upper - lower)
}

#' Evaluate a continuous profile only at numerically valid points
#'
#' @param profile Function returning RSS at a scaled breakpoint.
#' @param point Scaled breakpoint to evaluate.
#' @return One finite RSS value; errors on numerical failure.
#' @noRd
checked_profile_rss <- function(profile, point) {
  rss <- profile(point)$rss
  if (!is.finite(rss)) {
    stop("Continuous search encountered a non-finite RSS.",
         call. = FALSE)
  }
  rss
}
