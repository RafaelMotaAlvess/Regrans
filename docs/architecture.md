# Current implementation

This page describes the package **as implemented now**.

## Fit selection

`regrans()` accepts numeric `x` and `y` vectors or a bare two-variable formula
and data frame. It sorts paired observations by `x`, keeping their original row
positions, and considers divisions with at least `n_min` observations on each
side. A candidate must fall between **distinct** observed `x` values, and
each side needs at least two distinct `x` values to estimate a slope.

For `model = "discontinuous"`, the internal `regranslm()` routine fits two
ordinary `lm(Y ~ X)` models independently at every candidate division. It
selects the pair with the smallest combined residual sum of squares (RSS).
Ties select the first admissible division in sorted `x` order. The selected
partition is then expressed as one equivalent `lm(Y ~ X * segment)` model.
Its two lines can jump, and the selected gap is an interval rather than a
numeric breakpoint estimate.

For `model = "continuous"`, `continuous_regrans()` fits the hinge equation
`Y = beta0 + beta1 * X + delta * max(0, X - psi)` at a candidate breakpoint
`psi`. It profiles the coefficients with `lm.fit()` and numerically minimizes
RSS within every admissible observed-`x` gap. A gap is split at an internal
RSS maximum before bounded Brent searches, so the whole range is not
assumed unimodal. The best `psi` is refitted in original units as an `lm`.
The recorded search tolerance scales with the observed `x` range. A
numerically flat profile returns an ordinary linear fit and marks the
breakpoint as unidentified.

Neither model tests for the presence of a break. The observed gap bounds are
not a confidence interval. Coefficient standard errors and p-values are
conditional on the selected location and omit search uncertainty.

## Result and interfaces

The result stores the training data, segment membership, fitted values, and
residuals in the **original observation order**. `model_fit` holds the selected
`lm`; `segments` holds line intercepts and slopes. `location` records its
status, interval bounds, and a numeric estimate only for an identified
continuous break. `summary()` describes this common result. `tidy()`,
`glance()`, and `augment()` provide tibble
outputs through S3 methods implemented in Regrans. `augment()` currently
supports training data only: assigning an unseen `x` to a side inside the gap
requires a prediction policy that has not been chosen.

`plot_regrans()` and `ggplot2::autoplot()` return editable ggplot2 objects.
Discontinuous lines are drawn over their respective observed ranges;
continuous lines meet at the estimated breakpoint. ggplot2 is a presentation
dependency. The discontinuous search refits two `lm` models per candidate;
the continuous search uses base R's `lm.fit()` and `optimize()`. Neither
implementation has a demonstrated speedup over the earlier package.

| Location | Responsibility |
| --- | --- |
| `R/regrans.R` | Public input validation, data retention, and result assembly. |
| `R/regranslm.R` | Candidate enumeration, fitting, and RSS selection. |
| `R/continuous_regrans.R` | Continuous hinge profile and numerical search. |
| `R/tidiers.R` | `tidy()`, `glance()`, and `augment()` methods. |
| `R/plot_regrans.R` | Plotting and `autoplot()` method. |
| `tests/testthat/` | Numerical, input, interface, and plot regression tests. |

The authoritative list of exports is [`NAMESPACE`](../NAMESPACE).
`regranslm()` and `continuous_regrans()` remain internal. See the
[development guide](development.md) for checks and release practices.
