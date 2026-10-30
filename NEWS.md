# Regrans (development version)

* `regrans()` now accepts `model = "continuous"` to estimate one breakpoint
  where the fitted lines meet. The default `"discontinuous"` model still
  permits a jump. Both modes use a common result with `model_fit`, `segments`,
  and `location`, replacing the development fields `left`, `right`, and
  `split`. A numerically flat continuous profile reports the breakpoint as
  unidentified.
* `summary()`, `tidy()`, `glance()`, `augment()`, and `plot_regrans()` now
  describe both model types. Coefficient statistics remain conditional on
  the selected transition and do not test for a break.

* `regrans()` now uses `n_min` instead of `n.min`, including in its result and
  the `glance()` output. `plot_regrans()` uses `col_lines`, `lty_lines`, and
  `lwd_lines`; `summary()` uses `symbolic_cor`.
* `regrans()` now accepts a two-variable formula and data frame, retains the
  selected split and candidate scores, and keeps fitted values and residuals
  in the original observation order.
* `regrans()` now enforces the minimum sample size on both sides, keeps tied
  explanatory values together, and rejects invalid or degenerate inputs.
* `tidy()`, `glance()`, and `augment()` provide tabular results for a
  `regrans` fit. `plot_regrans()` and `ggplot2::autoplot()` now return editable
  ggplot2 graphics, with lines shown only over their observed ranges.

# Regrans 0.1.0

* First tagged release. `regrans()` fits two independent linear segments and
  selects the split with the smallest combined residual sum of squares.
  `summary()` and `plot_regrans()` help inspect the fitted models.
* Added a first-use example and guides for installation, usage, implementation,
  and development.
* GitHub Releases provide a source package and prebuilt Windows and macOS
  binaries, with SHA-256 checksums for downloads.
