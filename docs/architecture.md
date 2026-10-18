# Current implementation

This page describes the package **as implemented now**.

## Fit selection

`regrans(x, y, n.min = 5)` calls the internal `regranslm()` routine. That routine sorts paired observations by `x` and then `y`, enumerates candidate positions in the ordered data, and fits `lm(Y ~ X)` independently to the observations on either side of each position. For `n` observations, the current loop evaluates `n - 2 * n.min` positions: the left side starts with `n.min` observations, while the right side always has at least `n.min + 1`. `regrans()` chooses the pair whose two residual sums of squares have the smallest total.

The selected result is a list with `left` and `right` `lm` objects and class `regrans`. It does not store a numeric breakpoint or the scores for every candidate. `summary.regrans()` returns summaries of those two `lm` fits. `plot_regrans()` uses base R graphics to display the observations and fitted line segments.

The lines have separate intercepts and slopes. No continuity constraint is imposed, and the current search is over partitions of observations rather than every real-valued breakpoint. This distinction matters when describing statistical results or comparing them with other segmented regression methods.

## Public API and files

| Location | Responsibility |
| --- | --- |
| `R/regrans.R` | Exported entry point and selection of the lowest-scoring split. |
| `R/regranslm.R` | Internal candidate enumeration and two `lm` fits per candidate. |
| `R/summary.regrans.R` | Exported S3 summary method. |
| `R/plot_regrans.R` | Exported base-graphics plot helper. |
| `R/regrans_ancova.R` | Internal ANCOVA helper; not part of the exported API. |
| `data/simdata.rda` | Included example data. |
| `man/` | Installed R help pages. |
| `.github/workflows/` and `ci/` | Hosted and local quality checks; tagged-release automation. |

The authoritative list of exports is [`NAMESPACE`](../NAMESPACE). Avoid presenting internal functions as supported user-facing interfaces until they are deliberately documented and exported.

## Boundaries for changes

Changes to data ordering, eligible splits, the fitting criterion, or the interpretation of a breakpoint can change statistical results. Assess them separately from documentation and interface refactors, and provide reproducible examples or tests when changing behavior. The [development guide](development.md) explains how package checks and release notes fit into that work.
