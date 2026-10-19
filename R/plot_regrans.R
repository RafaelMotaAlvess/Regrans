#' Plot two independently fitted segments
#'
#' The lines are drawn only over the `x` values used to fit each segment.
#' No continuous breakpoint is estimated or displayed.
#'
#' @param obj A `regrans` object.
#' @param col_lines,lty_lines,lwd_lines Length-two vectors controlling the
#'   colour, line type, and line width of the left and right segments.
#' @param ... Optional base-plot arguments `pch`, `col`, `cex`, `xlab`,
#'   `ylab`, `main`, `xlim`, and `ylim`. Other arguments are rejected.
#' @return An editable `ggplot2` object.
#' @examples
#' data(simdata)
#' fit <- regrans(simdata$x, simdata$y)
#' plot_regrans(fit, pch = 16)
#' @export
plot_regrans <- function(obj,
                         col_lines = c("red", "blue"),
                         lty_lines = c("solid", "solid"),
                         lwd_lines = c(1, 1), ...) {
  if (!inherits(obj, "regrans")) {
    stop("obj must be a regrans object.", call. = FALSE)
  }
  validate_line_styles(col_lines, lty_lines, lwd_lines)
  dots <- validate_plot_options(list(...))

  plot_data <- data.frame(
    X = obj$data[[obj$variables[["x"]]]],
    Y = obj$data[[obj$variables[["y"]]]]
  )
  plot <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = X, y = Y) # nolint: object_usage_linter.
  ) +
    ggplot2::geom_point(
      shape = plot_option(dots, "pch", 1),
      colour = plot_option(dots, "col", "black"),
      size = 1.5 * plot_option(dots, "cex", 1)
    ) +
    ggplot2::labs(
      x = plot_option(dots, "xlab", obj$variables[["x"]]),
      y = plot_option(dots, "ylab", obj$variables[["y"]]),
      title = plot_option(dots, "main", NULL)
    )

  for (side in seq_along(c("left", "right"))) {
    name <- c("left", "right")[[side]]
    plot <- plot + segment_layer(obj[[name]], col_lines[[side]],
                                 lty_lines[[side]], lwd_lines[[side]])
  }
  if ("xlim" %in% names(dots) || "ylim" %in% names(dots)) {
    plot <- plot + ggplot2::coord_cartesian(
      xlim = plot_option(dots, "xlim", NULL),
      ylim = plot_option(dots, "ylim", NULL)
    )
  }
  plot
}

#' Reject invalid segment line styles
#'
#' @param colours,types,widths Length-two style vectors for the segments.
#' @return Called for validation; errors for invalid widths or lengths.
#' @noRd
validate_line_styles <- function(colours, types, widths) {
  if (!valid_line_styles(colours, types, widths)) {
    stop(
      "*.lines must have two values; line widths must be positive.",
      call. = FALSE
    )
  }
}

#' Check the segment line style vectors
#'
#' @param colours,types,widths Candidate segment style vectors.
#' @return `TRUE` when all vectors have length two and widths are positive.
#' @noRd
valid_line_styles <- function(colours, types, widths) {
  if (length(colours) != 2L || length(types) != 2L ||
        length(widths) != 2L || !is.numeric(widths)) {
    return(FALSE)
  }
  all(is.finite(widths)) && all(widths > 0)
}

#' Restrict legacy base-plot arguments to supported translations
#'
#' @param dots Named arguments supplied through `...`.
#' @return The arguments unchanged, or an error for unsupported names.
#' @noRd
validate_plot_options <- function(dots) {
  allowed <- c("pch", "col", "cex", "xlab", "ylab", "main", "xlim", "ylim")
  if (length(dots) && (is.null(names(dots)) ||
                         !all(nzchar(names(dots))) ||
                         !all(names(dots) %in% allowed) ||
                         anyDuplicated(names(dots)))) {
    stop("Supported plot arguments are: ", toString(allowed),
         call. = FALSE)
  }
  dots
}

#' Read one translated plot argument
#'
#' @param dots Named plot arguments.
#' @param name Argument name to read.
#' @param default Value used when `name` is absent.
#' @return The supplied argument value or `default`.
#' @noRd
plot_option <- function(dots, name, default) {
  if (name %in% names(dots)) dots[[name]] else default
}

#' Draw one fitted segment over its observed predictor range
#'
#' @param model One selected `lm` model.
#' @param colour,line_type,line_width Segment line styling.
#' @return A ggplot2 segment layer with endpoints at observed `x` bounds.
#' @noRd
segment_layer <- function(model, colour, line_type, line_width) {
  endpoints <- range(model$model$X)
  line_data <- data.frame(
    x_start = endpoints[[1L]],
    x_end = endpoints[[2L]],
    y_start = stats::predict(
      model, newdata = data.frame(X = endpoints[[1L]])
    ),
    y_end = stats::predict(
      model, newdata = data.frame(X = endpoints[[2L]])
    )
  )
  ggplot2::geom_segment(
    data = line_data,
    mapping = ggplot2::aes(
      # nolint next: object_usage_linter.
      x = x_start, xend = x_end, y = y_start, yend = y_end
    ),
    inherit.aes = FALSE,
    colour = colour,
    linetype = line_type,
    linewidth = line_width
  )
}

#' Autoplot a regrans fit
#'
#' @param object A `regrans` object.
#' @param ... Arguments passed to [plot_regrans()].
#' @return An editable `ggplot2` object.
#' @examples
#' data(simdata)
#' ggplot2::autoplot(regrans(simdata$x, simdata$y))
#' @importFrom ggplot2 autoplot
#' @export
autoplot.regrans <- function(object, ...) {
  plot_regrans(object, ...)
}

utils::globalVariables(c("X", "Y", "x_start", "x_end", "y_start", "y_end"))
