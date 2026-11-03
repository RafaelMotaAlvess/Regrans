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
RSS maximum before bounded golden-section refinement, so the whole range is
not assumed unimodal. On scaled `x`, the refinement stops when the bracket
width is at most `max(min(1e-8, subinterval_width / 100), 16 * machine_epsilon)`.
It raises an error if the RSS becomes non-finite, machine precision prevents
the required refinement, or 128 iterations do not meet the stopping rule.
The best `psi` is refitted in original units as an `lm`. A numerically flat
profile returns an ordinary linear fit and marks the breakpoint as
unidentified; this is distinct from numerical convergence of the search.

`test_slope_change()` tests the continuous model against its single-line
reference.
The default parametric bootstrap simulates independent Gaussian responses at
the fixed observed `x` under the fitted reference line, then repeats the
entire admissible breakpoint search. Its likelihood-ratio statistic is
`n * log(RSS_reference / RSS_selected)` and its Monte Carlo p-value includes
the observed statistic in both numerator and denominator. The optional Davies
method evaluates signed fixed-breakpoint t statistics on an equally spaced
admissible grid and applies the conservative linear-model upper bound. The
grid point with the largest absolute statistic is not the RSS-minimizing
breakpoint estimate.

`confint()` inverts `n * log(RSS(psi) / RSS_min)` against a one-degree-of-freedom
chi-squared cutoff for an identified continuous breakpoint. The algorithm
splits each admissible observed gap at all internal profile extrema, solves
threshold crossings on monotone pieces, and returns every connected accepted
component. It flags components that reach an admissible boundary.
`plot_break_profile()` shows the same statistic and confidence region. The
region is approximate and relies on regular identification and the Gaussian
model; a numerically flat profile has no informative confidence region.
The inferential methods require positive, numerically meaningful residual
variance, fixed `x`, and independent normal errors with constant variance.
They have no heteroscedasticity adjustment.

The discontinuous observed gap bounds are not a confidence interval.
Coefficient standard errors and p-values in `summary()` are conditional on
the selected location and omit search uncertainty; they do not test for a
break.

## Result and interfaces

The result stores the training data, segment membership, fitted values, and
residuals in the **original observation order**. `model_fit` holds the selected
`lm`; `reference_fit` holds a single-line `lm(Y ~ X)` on the same observations
in their original order. `segments` holds line intercepts and slopes.
`location` records its status, interval bounds, and a numeric estimate for an
identified continuous break. `search` records the termination reason and
numerical
convergence, which is `"not_applicable"` for the exhaustive discontinuous
search and `"converged"` for a completed continuous refinement. Continuous
`candidates` also records iterations, evaluations, and achieved bracket width
per gap. `summary()` describes this common result. `tidy()`,
`glance()`, and `augment()` provide tibble
outputs through S3 methods implemented in Regrans. `augment()` currently
supports training data only: assigning an unseen `x` to a side inside the gap
requires a prediction policy that has not been chosen.

`glance()` and `summary()` report RSS, `sqrt(RSS / n)` as training RMSE, and
`1 - RSS / TSS` as training R-squared for both selected and reference models.
R-squared is `NA` for a constant response. These are descriptive, in-sample
measures; their difference is not a test for a break.

`plot_regrans()` and `ggplot2::autoplot()` return editable ggplot2 objects.
Discontinuous lines are drawn over their respective observed ranges;
continuous lines meet at the estimated breakpoint. ggplot2 is a presentation
dependency. The discontinuous search refits two `lm` models per candidate;
the continuous search uses base R's `lm.fit()` and explicit golden-section
refinement. Neither implementation has a demonstrated speedup over the earlier
package.

| Location | Responsibility |
| --- | --- |
| `R/regrans.R` | Public input validation, data retention, and result assembly. |
| `R/regranslm.R` | Candidate enumeration, fitting, and RSS selection. |
| `R/continuous_regrans.R` | Continuous hinge profile and numerical search. |
| `R/tidiers.R` | `tidy()`, `glance()`, and `augment()` methods. |
| `R/plot_regrans.R` | Plotting and `autoplot()` method. |
| `R/test_slope_change.R` | Bootstrap and Davies tests for a continuous slope change. |
| `R/confint.regrans.R` | Profile likelihood confidence region. |
| `R/plot_break_profile.R` | Editable confidence profile plot. |
| `tests/testthat/` | Numerical, input, interface, and plot regression tests. |

The authoritative list of exports is [`NAMESPACE`](../NAMESPACE).
`regranslm()` and `continuous_regrans()` remain internal. See the
[development guide](development.md) for checks and release practices.
