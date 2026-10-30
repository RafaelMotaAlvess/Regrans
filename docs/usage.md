# Fit and inspect a segmented regression

Regrans is useful when a scatterplot suggests that the relationship between
two numeric variables changes across the range of `x`. It searches for one
transition, using either two independent lines that can jump or a continuous
hinge model whose lines meet at an estimated breakpoint.

## Fit a model

```r
library(Regrans)

observations <- data.frame(x = 1:20)
observations$y <- ifelse(observations$x <= 10,
                         2 + observations$x,
                         -15 + 3 * observations$x) +
  sin(observations$x) / 5

fit <- regrans(y ~ x, data = observations, n_min = 5)
fit$location
fit$segments
summary(fit)
plot_regrans(fit, pch = 16, xlab = "x", ylab = "y")

continuous_fit <- regrans(y ~ x, data = observations, n_min = 5,
                          model = "continuous")
continuous_fit$location
plot_regrans(continuous_fit)
```

The vector interface remains available:

```r
same_fit <- regrans(observations$x, observations$y, n_min = 5)
```

The formula must contain one bare numeric response and one bare numeric
predictor, both columns in `data`. Inputs must be finite. `n_min` is an integer
of at least 3, and each side must contain at least `n_min` observations and
two distinct predictor values. Observations with the same `x` always stay on
the same side. An error is returned when no admissible division exists.

## Inspect results

The default `model = "discontinuous"` fits two independent lines. The
`location` contains the observed `left_max_x` and `right_min_x` around the
selected division. `estimate` is `NA` because a numeric breakpoint is not
identified by this model. `model = "continuous"` fits a hinge regression;
`location$estimate` is the RSS-minimizing breakpoint and the fitted lines meet
there. The observed bounds show which gap contains that estimate. They are
not a confidence interval.

`fit$model_fit` is an ordinary `lm` object for the selected model;
`fit$segments` gives each line's intercept and slope. `fit$candidates` lists
the RSS for each admissible division and, for a continuous fit, its refined
breakpoint estimate. `fit$search` records the search method and evaluation
count. `fit$n_min` records the minimum segment size.

If you used the development interface with `fit$left`, `fit$right`, or
`fit$split`, read `fit$segments` for line coefficients and `fit$location` for
the transition. Use `fit$model_fit` for the selected `lm`.

```r
coef(fit$model_fit)
fit$segments
tidy(fit)       # coefficient table, identified by segment
glance(fit)     # one-row model, location, and RSS summary
head(augment(fit)) # original rows with .segment, .fitted, .resid
```

The tidiers also work through `broom::tidy()`, `broom::glance()`, and
`broom::augment()` if broom is installed. The coefficient standard errors and
p-values describe the selected `lm` fit conditionally; they are not a formal
test for a break or an uncertainty estimate for its location. When the
continuous RSS profile is numerically flat, `location$status` is
`"unidentified"`, `estimate` is `NA`, and `model_fit` is a single linear fit.
This avoids reporting an arbitrary breakpoint for a straight line.

## Edit the plot

`plot_regrans(fit)` and `ggplot2::autoplot(fit)` return ggplot2 objects. The
default lines stop at their respective observed `x` ranges and need not
touch. Continuous lines meet at the estimated breakpoint. You can add
ggplot2 layers or themes to the result:

```r
plot_regrans(fit, col_lines = c("red", "blue")) +
  ggplot2::theme_minimal()
```

`plot_regrans()` accepts `col_lines`, `lty_lines`, `lwd_lines`, and common base-plot
arguments `pch`, `col`, `cex`, `xlab`, `ylab`, `main`, `xlim`, and `ylim`.
Other base graphics arguments produce an explicit error.

The package includes `simdata` as a general example dataset. It is not a
benchmark with a known breakpoint. `regranslm()` and `continuous_regrans()`
remain internal and are not part of the supported public interface.
