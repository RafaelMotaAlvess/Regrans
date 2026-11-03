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
set.seed(1)
test_slope_change(continuous_fit) # parametric bootstrap, 999 samples
test_slope_change(continuous_fit, method = "davies", n_grid = 25)
stats::confint(continuous_fit)
plot_break_profile(continuous_fit)
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

## Test and profile a continuous break

`test_slope_change(continuous_fit)` tests a single straight line against one change
in slope at an unknown admissible position. Its default parametric bootstrap
simulates responses under the fitted straight line and repeats the full search
for each sample. Set a random seed for a reproducible p-value and increase
`n_boot` from its default of 999 when finer Monte Carlo resolution is needed.
The p-value counts the observed fit plus bootstrap fits at least as extreme as
it. `method = "davies"` uses fixed-breakpoint t statistics on `n_grid`
equally spaced admissible positions. Its p-value is a conservative upper
bound. The reported `max_statistic_location` marks the strongest statistic on
that grid; it is distinct from `continuous_fit$location$estimate`.

`stats::confint(continuous_fit)` returns an approximate profile likelihood
confidence region for the breakpoint. Each matrix row is one connected
component with `lower` and `upper` limits. The `boundary` attribute marks a
component reaching an edge of the admissible domain; the `domain` attribute
gives those edges. `plot_break_profile()` shades all components against the
profile statistic and acceptance cutoff. A weak or multimodal profile may
produce a wide or disconnected region. A numerically unidentified breakpoint
has no informative region and `confint()` explains this with an error.

These methods apply only to `model = "continuous"` with fixed `x` and
independent normal errors of constant variance. The profile region uses a
one-degree-of-freedom chi-squared approximation under regular identification;
its coverage may be poor for weak changes or a breakpoint near the admissible
boundary. The methods have no heteroscedasticity adjustment. The default
discontinuous model selects an observed interval and has no numeric
breakpoint confidence interval. The coefficient p-values shown by `summary()`
remain conditional on the selected location and are not a break test.

See [inference methods and calibration checks](inference.md) for the test
statistics, profile construction, reproducible simulations, and coverage
limits.

`fit$model_fit` is an ordinary `lm` object for the selected model;
`fit$reference_fit` is the single-line `lm` fit on the same observations,
retained in their original order. `fit$segments` gives each line's intercept
and slope. `fit$candidates` lists the RSS for each admissible division and,
for a continuous fit, its refined
breakpoint estimate, iteration count, evaluation count, and achieved bracket
width. `fit$search` records the search method, termination reason, convergence
state, and evaluation count. `fit$n_min` records the minimum segment size.
The continuous search refines each admissible gap until its numerical bracket
meets a scaled tolerance; a numerical failure stops the fit with an error.
The discontinuous search evaluates every admissible split and has no numerical
convergence criterion. Its `search$convergence` is `"not_applicable"`.
Numerical convergence does not mean that a break exists: a straight-line
example may have a converged search and `location$status = "unidentified"`.

If you used the development interface with `fit$left`, `fit$right`, or
`fit$split`, read `fit$segments` for line coefficients and `fit$location` for
the transition. Use `fit$model_fit` for the selected `lm`.

```r
coef(fit$model_fit)
coef(fit$reference_fit)
fit$segments
tidy(fit)       # coefficient table, identified by segment
glance(fit)     # location, convergence, and fit measures
head(augment(fit)) # original rows with .segment, .fitted, .resid
```

`glance()` and `summary()` report RSS, RMSE (`sqrt(RSS / n)`), and R-squared
for the selected and linear reference fits. R-squared is `NA` when the
response is constant. These measures describe training data and do not
provide a formal test for a break. A lower RSS is expected from a more
flexible fitted model and does not establish that the change is real.

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
