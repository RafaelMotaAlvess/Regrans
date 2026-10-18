# Fit and inspect two linear segments

Regrans is useful when a scatterplot suggests that the relationship between two numeric variables changes across the range of `x`. The current implementation searches for **one split between observed points**, fits a separate line on each side, and chooses the split with the smallest total residual sum of squares.

## A small example

```r
library(Regrans)

x <- 1:20
y <- ifelse(x <= 10, 2 + x, -15 + 3 * x) + sin(x) / 5
fit <- regrans(x, y, n.min = 5)

summary(fit)
plot_regrans(fit, pch = 16, xlab = "x", ylab = "y")
```

`fit$left` and `fit$right` are ordinary `lm` objects. You can use familiar `lm` accessors on either one:

```r
coef(fit$left)
coef(fit$right)
range(fit$left$model$X)
range(fit$right$model$X)
```

The two ranges show which observations went into each fit. They describe a boundary **between** observed `x` values; `regrans()` does not return a separate, continuous breakpoint estimate. `summary(fit)` returns a list with summaries named `left` and `right`.

The package also contains `simdata`, a 50-row example dataset:

```r
data(simdata, package = "Regrans")
fit <- regrans(simdata$x, simdata$y)
plot_regrans(fit)
```

`simdata` is a general regression example, not a benchmark with a known breakpoint. Interpret the fitted split in light of the data and your scientific question.

## Current scope

- Inputs are numeric `x` and `y` vectors of equal length. `n.min` must be at least 3; it controls the minimum observations per side. The current search needs more than `2 * n.min` observations to produce candidates.
- The fit considers one split and two independently fitted straight lines. It does not constrain the lines to meet.
- The selected object holds the two `lm` fits. It does not provide a confidence interval or a dedicated breakpoint estimate.
- Missing values are not given an explicit handling policy. Ties in `x` are ordered by `y`, so candidate splits can separate observations with the same `x` value. Prepare and inspect the data before interpreting a split.
- `regranslm()` and `regrans_ancova()` exist in the source but are not exported as public functions. Public usage examples rely on `regrans()`, `summary()`, and `plot_regrans()`.

For argument details, see `?regrans` and `?plot_regrans` in R. For implementation details, see [Implementation](architecture.md).
