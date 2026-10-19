# Current implementation

This page describes the package **as implemented now**.

## Fit selection

`regrans()` accepts numeric `x` and `y` vectors or a bare two-variable formula
and data frame. It sorts paired observations by `x`, keeping their original row
positions, and considers divisions with at least `n_min` observations on each
side. A candidate must fall between **distinct** observed `x` values, and
each side needs at least two distinct `x` values to estimate a slope.

At every candidate division, the internal `regranslm()` routine fits two
ordinary `lm(Y ~ X)` models independently. It selects the pair with the
smallest combined residual sum of squares (RSS). If scores tie, the first
admissible division in sorted `x` order wins. The returned `left` and `right`
members remain `lm` objects. `split` contains the index and the two observed
values bracketing the division; `candidates` records the admissible scores.

The lines can jump: the fit has no continuity constraint. The bracketing
values are **not** a continuous breakpoint estimate, confidence interval, or
formal test for a structural change. Coefficient statistics from the two
selected `lm` objects are conditional on the selected division.

## Result and interfaces

The result stores the training data, segment membership, fitted values, and
residuals in the **original observation order**. `summary()` returns the two
`summary.lm` objects. `tidy()`, `glance()`, and `augment()` provide tibble
outputs through S3 methods implemented in Regrans. `augment()` currently
supports training data only: assigning an unseen `x` to a side inside the gap
requires a prediction policy that has not been chosen.

`plot_regrans()` and `ggplot2::autoplot()` return editable ggplot2 objects.
Each fitted line is drawn only over the `x` range used for its model. The
numeric search still uses base R's `lm`; ggplot2 is only a presentation
dependency.

| Location | Responsibility |
| --- | --- |
| `R/regrans.R` | Public input validation, data retention, and result assembly. |
| `R/regranslm.R` | Candidate enumeration, fitting, and RSS selection. |
| `R/tidiers.R` | `tidy()`, `glance()`, and `augment()` methods. |
| `R/plot_regrans.R` | Plotting and `autoplot()` method. |
| `R/regrans_ancova.R` | Internal, non-exported ANCOVA helper. |
| `tests/testthat/` | Numerical, input, interface, and plot regression tests. |

The authoritative list of exports is [`NAMESPACE`](../NAMESPACE).
`regranslm()` and `regrans_ancova()` remain internal. See the
[development guide](development.md) for checks and release practices.
