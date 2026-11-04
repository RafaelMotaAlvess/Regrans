# Inference for one continuous slope change

`test_slope_change()`, `stats::confint()`, and `plot_break_profile()` apply only to a
`regrans` fit with `model = "continuous"`. They assume the observed predictor
values are fixed and the errors are independent, normal, and have constant
variance. They do not adjust for heteroscedasticity. The default
`"discontinuous"` fit selects an observed division interval, not a numeric
breakpoint, so these methods do not assign it a point confidence interval.

## Tests against one straight line

The null hypothesis is zero change in slope. The breakpoint is absent under
this null, so a conditional coefficient p-value from `summary()` is not a
valid break test. The default parametric bootstrap fits the straight-line
reference, simulates responses at the same `x` using its fitted mean and
residual standard deviation, and runs the full continuous search on every
sample. It compares `n log(RSS_linear / RSS_hinge)` with the observed value and
reports `(1 + number at least as large) / (n_boot + 1)`.

`method = "davies"` evaluates signed t statistics for the hinge coefficient
at `n_grid` equally spaced points spanning the admissible domain. The
linear-model Davies bound uses their largest absolute value and total
variation. Its p-value is a conservative upper bound.
`max_statistic_location` is the strongest grid point, not the fitted Regrans
breakpoint. This follows the
distinction in the [`segmented` documentation](https://search.r-project.org/CRAN/refmans/segmented/html/davies.test.html).
With `segmented` 2.2-2, the deterministic tied-`x` case in
`tests/testthat/test-test_slope_change.R` gave p-values 3.53150125725191e-06
(Regrans) and 3.53150125725131e-06 (`segmented::davies.test()`), using the
same 25 points. Both reported 9.08333333333333 as the strongest grid point;
the Regrans RSS estimate was 9. The Davies bound follows
[Davies (2002)](https://doi.org/10.1093/biomet/89.2.484) for the linear-model
case. `segmented` switches to a large-sample approximation above 300
observations; Regrans evaluates the gamma ratio on the log scale.

The call style differs intentionally: `segmented::davies.test()` takes an
`lm` and a segmented-variable formula, while `test_slope_change()` takes the
existing Regrans fit because it already stores the predictor, admissible
domain, and linear reference. Regrans uses `n_grid` for the grid size;
`segmented` uses `k` or explicit `values`. Both return `htest`, but the Regrans
`statistic` is the maximum absolute t value and
`max_statistic_location` holds its grid position. In `segmented`, the
`statistic` field itself holds the grid position. Regrans names the extra
results `grid_statistics` and `bootstrap_statistics` to state their contents.

## Profile likelihood region

At each admissible breakpoint `psi`, `confint()` refits the hinge coefficients
and accepts `psi` when `n log(RSS(psi) / RSS_min)` is at most the one-degree-of-
freedom chi-squared quantile for `level`. The inversion searches all
admissible gaps, splits them at internal extrema, and solves crossings on
monotone pieces. Its matrix includes every connected component. The
`boundary` attribute shows when acceptance extends to a searched edge; the
`domain` attribute gives both edges. The construction is an approximate
regular-model profile interval. [Fong et al.](https://pmc.ncbi.nlm.nih.gov/articles/PMC5435560/)
discuss profile test inversion and its sensitivity to model assumptions for
continuous threshold models; their paper studies logistic outcomes, so it
does not establish the finite-sample coverage of this Gaussian implementation.
Both packages use the standard `stats::confint()` generic. Regrans offers a
profile likelihood region; [`segmented::confint()`](https://search.r-project.org/CRAN/refmans/segmented/html/confint.segmented.html)
offers delta, score, and gradient methods. Their reported intervals are not
interchangeable.

## Reproducible calibration check

Run `Rscript docs/inference-simulation.R` from the package root. The script uses
Regrans 0.1.0.9000 and R 4.6.1, with `x` fixed on `[-1, 1]`, a true break at
0.17, intercept 1, initial slope 0.5, and independent `N(0, 0.6^2)` errors.
The first set uses 80 datasets per scenario, `n = 20`, `n_min = 4`,
49 bootstrap samples per dataset, a 25-point Davies grid, and 95% profile
regions. Seeds are shown below. Monte Carlo standard errors use
`sqrt(p(1-p)/number_of_datasets)`; the 49-sample bootstrap has 0.02 p-value
resolution.

| Scenario, seed | Bootstrap rejection at 5% (MC SE) | Davies rejection at 5% (MC SE) | Profile coverage (MC SE) |
| --- | ---: | ---: | ---: |
| No change, 20261103 | 0.050 (0.024) | 0.038 (0.021) | Not defined |
| Slope change 1.5, 20261104 | 0.113 (0.035) | 0.213 (0.046) | 0.888 (0.035) |
| Slope change 3, 20261105 | 0.663 (0.053) | 0.725 (0.050) | 0.888 (0.035) |

The second set checks profile coverage with `n = 80`, `n_min = 8`, and
60 datasets per scenario:

| Slope change, seed | Profile coverage (MC SE) |
| --- | ---: |
| 1.5, 20261106 | 0.800 (0.052) |
| 3, 20261107 | 0.933 (0.032) |

These finite simulations are exploratory, and their Monte Carlo error is
visible in the tables. They show that the nominal 95% profile region can
undercover when the change is weak, even at 80 observations. Interpret the
reported region as an approximate description of location uncertainty when
the break is well identified; do not rely on nominal coverage for weak
changes, near-boundary locations, or model violations. The Davies method was
more powerful than this finite bootstrap in these particular alternatives;
that is not a general ranking. A numerically flat profile has no informative
breakpoint region. An exact or robust interval for weak changes requires a
separately calibrated method and validation.
