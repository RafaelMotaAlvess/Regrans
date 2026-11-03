#' Confidence region for a continuous breakpoint
#'
#' Inverts the Gaussian profile likelihood-ratio statistic over every
#' admissible breakpoint. A chi-squared reference with one degree of freedom
#' gives an approximate region under a well-identified continuous hinge model
#' with fixed `x` and independent normal, constant-variance errors. The
#' region may have several disconnected components or reach an admissible
#' boundary. A numerically unidentified breakpoint has no informative
#' confidence region.
#'
#' @param object A `regrans` fit with `model = "continuous"`.
#' @param parm Optional `"breakpoint"`; other parameters are not supported.
#' @param level Confidence level strictly between zero and one.
#' @param method Currently only `"profile"`.
#' @param ... Unused.
#' @return A matrix with one row per connected component and columns `lower`
#'   and `upper`. Attributes `boundary` and `domain` identify components
#'   touching admissible edges and the searched domain.
#' @examples
#' x <- 1:20
#' y <- 2 + x + 2 * pmax(0, x - 9) + sin(x) / 3
#' fit <- regrans(x, y, model = "continuous")
#' stats::confint(fit)
#' @export
confint.regrans <- function(object, parm, level = 0.95,
                            method = "profile", ...) {
  validate_break_fit(object) # nolint: object_usage_linter.
  if (!missing(parm) && !identical(parm, "breakpoint")) {
    stop("Only parm = 'breakpoint' is supported.", call. = FALSE)
  }
  if (!identical(method, "profile")) {
    stop("Only method = 'profile' is supported.", call. = FALSE)
  }
  region <- compute_profile_region(object, level)
  intervals <- region$intervals
  result <- as.matrix(intervals[, c("lower", "upper"), drop = FALSE])
  rownames(result) <- paste0("breakpoint", seq_len(nrow(result)))
  attr(result, "boundary") <- intervals[, c("lower_boundary",
                                            "upper_boundary"), drop = FALSE]
  attr(result, "domain") <- region$domain
  attr(result, "level") <- level
  result
}

#' Build the profile likelihood-ratio confidence region
#'
#' @param fit A continuous fit with an identified breakpoint.
#' @param level Confidence level between zero and one.
#' @return Profile evaluator, cutoff, admissible domain, and all components.
#' @noRd
compute_profile_region <- function(fit, level) {
  if (!is.numeric(level) || length(level) != 1L ||
        !is.finite(level) || level <= 0 || level >= 1) {
    stop("level must be one number strictly between zero and one.",
         call. = FALSE)
  }
  if (fit$location$status == "unidentified") {
    stop("The breakpoint is numerically unidentified; its flat profile ",
         "has no informative confidence region.", call. = FALSE)
  }
  prepared <- prepare_scaled_profile(fit)
  scaled <- prepared$scaled
  scaled_estimate <- prepared$scaled_estimate
  minimum_rss <- prepared$minimum_rss
  lr_cutoff <- stats::qchisq(level, df = 1L)
  profile_lr <- function(point) {
    prepared$n * log(scaled$profile(point)$rss / minimum_rss)
  }
  split_indices <- fit$candidates$split_index
  profile_knots <- unlist(lapply(split_indices, function(index) {
    find_profile_knots(scaled$x, scaled$y, index)
  }), use.names = FALSE)
  profile_knots <- sort(unique(c(profile_knots, scaled_estimate)))
  scaled_domain <- range(profile_knots)
  scaled_intervals <- find_accepted_intervals(
    profile_lr, profile_knots, lr_cutoff
  )
  intervals <- data.frame(
    lower = scaled$x_origin + scaled$x_span * scaled_intervals[, 1L],
    upper = scaled$x_origin + scaled$x_span * scaled_intervals[, 2L]
  )
  intervals$lower_boundary <- scaled_intervals[, 1L] ==
    scaled_domain[[1L]]
  intervals$upper_boundary <- scaled_intervals[, 2L] ==
    scaled_domain[[2L]]
  list(
    intervals = intervals,
    domain = scaled$x_origin + scaled$x_span * scaled_domain,
    cutoff = lr_cutoff,
    statistic = function(point) {
      profile_lr((point - scaled$x_origin) / scaled$x_span)
    },
    estimate = fit$location$estimate
  )
}

#' Prepare a numerically scaled breakpoint profile from a fitted model
#'
#' @param fit An identified continuous `regrans` fit.
#' @return Scaled profile, breakpoint estimate, minimum RSS, and sample size.
#' @noRd
prepare_scaled_profile <- function(fit) {
  observations <- extract_fit_observations(fit) # nolint: object_usage_linter.
  ordered <- data.frame(X = observations$x, Y = observations$y)
  ordered <- ordered[order(ordered$X, seq_len(nrow(ordered))), ]
  scaled <- scaled_continuous_profile(ordered) # nolint: object_usage_linter.
  reference_rss <- sum(stats::residuals(fit$reference_fit)^2)
  if (!is.finite(reference_rss) || reference_rss <= 0) {
    stop("Confidence profiling requires positive residual variance.",
         call. = FALSE)
  }
  scaled_estimate <- (fit$location$estimate - scaled$x_origin) /
    scaled$x_span
  minimum_rss <- scaled$profile(scaled_estimate)$rss
  if (!is.finite(minimum_rss) || minimum_rss <= 0) {
    stop("Confidence profiling requires positive selected-model RSS.",
         call. = FALSE)
  }
  list(scaled = scaled, scaled_estimate = scaled_estimate,
       minimum_rss = minimum_rss, n = nrow(ordered))
}

#' Find profile endpoints and stationary points in one observed gap
#'
#' @param x,y Scaled ordered predictor and response.
#' @param index Last observation to the left of the gap.
#' @return Gap endpoints and any internal extrema, in scaled units.
#' @noRd
find_profile_knots <- function(x, y, index) {
  lower <- x[[index]]
  upper <- x[[index + 1L]]
  linear_design <- cbind(1, x)
  right_indicator <- as.numeric(seq_along(x) > index)
  # Inside a gap, the residualized hinge is x_right - psi * right_indicator.
  # Its two stationary RSS points are determined by these cross-products.
  response_residuals <- stats::lm.fit(linear_design, y)$residuals
  x_right_residuals <- stats::lm.fit(
    linear_design, x * right_indicator
  )$residuals
  right_residuals <- stats::lm.fit(
    linear_design, right_indicator
  )$residuals
  response_x_right <- sum(response_residuals * x_right_residuals)
  response_right <- sum(response_residuals * right_residuals)
  x_right_ss <- sum(x_right_residuals^2)
  x_right_right <- sum(x_right_residuals * right_residuals)
  right_ss <- sum(right_residuals^2)
  points <- c(lower, upper)
  if (abs(response_right) > .Machine$double.eps) {
    points <- c(points, response_x_right / response_right)
  }
  denominator <- response_right * x_right_right -
    response_x_right * right_ss
  if (abs(denominator) > .Machine$double.eps) {
    rss_minimum <- (
      response_right * x_right_ss - response_x_right * x_right_right
    ) / denominator
    points <- c(points, rss_minimum)
  }
  sort(unique(points[is.finite(points) & points >= lower &
                       points <= upper]))
}

#' Invert a continuous profile on its monotone intervals
#'
#' @param statistic Function evaluating the likelihood-ratio statistic.
#' @param knots Sorted domain endpoints and stationary points.
#' @param cutoff Acceptance cutoff.
#' @return Two-column matrix of all connected accepted components.
#' @noRd
find_accepted_intervals <- function(statistic, knots, cutoff) {
  distance_from_cutoff <- vapply(
    knots, function(point) statistic(point) - cutoff, numeric(1)
  )
  accepted_pieces <- lapply(seq_len(length(knots) - 1L), function(index) {
    accepted_profile_piece(
      statistic, cutoff, knots[[index]], knots[[index + 1L]],
      distance_from_cutoff[[index]], distance_from_cutoff[[index + 1L]]
    )
  })
  accepted_pieces <- Filter(Negate(is.null), accepted_pieces)
  if (!length(accepted_pieces)) {
    stop("The profile confidence region is empty; check numerical fit.",
         call. = FALSE)
  }
  merge_profile_pieces(accepted_pieces)
}

#' Find the accepted part of one monotone profile segment
#'
#' @param statistic Profile likelihood-ratio evaluator.
#' @param cutoff Acceptance threshold for the statistic.
#' @param lower,upper Segment endpoints.
#' @param lower_difference,upper_difference Endpoint statistics minus cutoff.
#' @return A two-value accepted interval, or `NULL` when rejected throughout.
#' @noRd
accepted_profile_piece <- function(statistic, cutoff, lower, upper,
                                   lower_difference, upper_difference) {
  if (lower_difference <= 0 && upper_difference <= 0) {
    return(c(lower, upper))
  }
  if (lower_difference * upper_difference < 0) {
    root <- stats::uniroot(function(point) statistic(point) - cutoff,
                           c(lower, upper), tol = 1e-12)$root
    if (lower_difference <= 0) {
      return(c(lower, root))
    }
    return(c(root, upper))
  }
  if (lower_difference == 0) {
    return(c(lower, lower))
  }
  if (upper_difference == 0) {
    return(c(upper, upper))
  }
  NULL
}

#' Merge accepted profile pieces that share an endpoint
#'
#' @param accepted_pieces Ordered list of two-value accepted intervals.
#' @return Matrix with one row per connected component.
#' @noRd
merge_profile_pieces <- function(accepted_pieces) {
  components <- list(accepted_pieces[[1L]])
  if (length(accepted_pieces) > 1L) {
    for (index in seq.int(2L, length(accepted_pieces))) {
      last_component <- length(components)
      if (accepted_pieces[[index]][[1L]] <=
            components[[last_component]][[2L]] + 1e-12) {
        components[[last_component]][[2L]] <- max(
          components[[last_component]][[2L]],
          accepted_pieces[[index]][[2L]]
        )
      } else {
        components[[last_component + 1L]] <- accepted_pieces[[index]]
      }
    }
  }
  do.call(rbind, components)
}
