# Fit and inspect two linear segments

Regrans is useful when a scatterplot suggests that the relationship between
two numeric variables changes across the range of `x`. It chooses **one
division between observed values**, fits an independent line on each side,
and minimizes their combined residual sum of squares.

## Fit a model

```r
library(Regrans)

observations <- data.frame(x = 1:20)
observations$y <- ifelse(observations$x <= 10,
                         2 + observations$x,
                         -15 + 3 * observations$x) +
  sin(observations$x) / 5

fit <- regrans(y ~ x, data = observations, n.min = 5)
fit$split
summary(fit)
plot_regrans(fit, pch = 16, xlab = "x", ylab = "y")
```

The vector interface remains available:

```r
same_fit <- regrans(observations$x, observations$y, n.min = 5)
```

The formula must contain one bare numeric response and one bare numeric
predictor, both columns in `data`. Inputs must be finite. `n.min` is an integer
of at least 3, and each side must contain at least `n.min` observations and
two distinct predictor values. Observations with the same `x` always stay on
the same side. An error is returned when no admissible division exists.

## Inspect results

`fit$left` and `fit$right` are ordinary `lm` objects. Their `model$X` ranges
show the observations used for each segment. `fit$split$left_max_x` and
`fit$split$right_min_x` bound the selected division; the package does not
estimate a single real-valued breakpoint. `fit$candidates` lists the RSS for
each admissible division.

```r
coef(fit$left)
coef(fit$right)
tidy(fit)       # coefficient table, identified by segment
glance(fit)     # one-row fit and selected-division summary
head(augment(fit)) # original rows with .segment, .fitted, .resid
```

The tidiers also work through `broom::tidy()`, `broom::glance()`, and
`broom::augment()` if broom is installed. The coefficient standard errors and
p-values describe the selected `lm` fits conditionally; they are not a formal
test of the division or its uncertainty.

## Edit the plot

`plot_regrans(fit)` and `ggplot2::autoplot(fit)` return ggplot2 objects. The
two line segments stop at their respective observed `x` ranges and need not
touch. You can add ggplot2 layers or themes to the result:

```r
plot_regrans(fit, col.lines = c("red", "blue")) +
  ggplot2::theme_minimal()
```

`plot_regrans()` accepts the earlier line controls and common base-plot
arguments `pch`, `col`, `cex`, `xlab`, `ylab`, `main`, `xlim`, and `ylim`.
Other base graphics arguments produce an explicit error.

The package includes `simdata` as a general example dataset. It is not a
benchmark with a known breakpoint. `regranslm()` and `regrans_ancova()`
remain internal and are not part of the supported public interface.
