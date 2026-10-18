
<!-- README.md is generated from README.Rmd. Please edit that file. -->

# Regrans

**Segmented Linear Regression Models in R**

Detect transition points by fitting two linear segments and selecting the best split.

[![CI status](https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml) [![R \>= 3.2.2](https://img.shields.io/badge/R-%3E%3D%203.2.2-276DC3)](https://www.r-project.org/) [![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0.html)

------------------------------------------------------------------------

## Table of contents

- [What is Regrans?](#what-is-regrans)
- [Main features](#main-features)
- [Installation](#installation)
  - [Install from GitHub](#install-from-github)
  - [Install from a release file](#install-from-a-release-file)
- [Local checks](#local-checks)
- [Release history](#release-history)
- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [Functions overview](#functions-overview)
- [Data included](#data-included)
- [Documentation](#documentation)
- [Authors](#authors)
- [License](#license)

------------------------------------------------------------------------

## What is Regrans?

**Regrans** is an R package for fitting **segmented linear regressions** (piecewise linear models with two segments).

It evaluates candidate split points along the explanatory variable, fits one linear model to the left side and another to the right side, and returns the split that minimizes the total residual sum of squares.

This is especially useful when your data suggests a **transition point**, **breakpoint**, or **allometric inflection**.

------------------------------------------------------------------------

## Main features

- ✅ Fit two-segment linear regressions from numeric vectors (`x`, `y`)
- ✅ Automatic search for the best split point
- ✅ Summary methods for left/right fitted models
- ✅ Built-in plotting helper for segmented fits
- ✅ ANCOVA helper to compare segment parameters
- ✅ Example dataset (`simdata`) included

------------------------------------------------------------------------

## Installation

### Install from GitHub

``` r
# install.packages("remotes")
remotes::install_github("RafaelMotaAlvess/Regrans")
```

### Install from a release file

Once the first release is published, download the appropriate package from the [latest GitHub Release](https://github.com/RafaelMotaAlvess/Regrans/releases/latest):

- **Linux:** `Regrans_<version>.tar.gz` (source package).
- **Windows x64:** the `.zip` file for your R major/minor version.
- **macOS:** the binary file (`.tgz` or `.tar.xz`) for your processor (Intel or Apple Silicon) and R major/minor version.

Check your R version with `getRversion()` and your processor with `R.version$arch`. The source package is also available for installation on Windows and macOS. The prebuilt packages target the current R release used to build them.

Install the downloaded source package from an R session on any system:

``` r
install.packages("path/to/Regrans_<version>.tar.gz", repos = NULL, type = "source")
```

For a matching Windows or macOS binary, use the path to the downloaded file:

``` r
install.packages("path/to/downloaded-file.zip", repos = NULL, type = "binary") # Windows
install.packages("path/to/downloaded-file.tgz", repos = NULL, type = "binary") # macOS; could be .tar.xz
```

Add `lib = "/path/to/your/R/library"` to `install.packages()` if you use a custom library. Local files are installed with `repos = NULL`.

------------------------------------------------------------------------

## Local checks

From the package root, install the check tools once in your personal R library, then run both checks:

``` bash
Rscript ci/install-local.R
Rscript ci/check-local.R
```

This runs `R CMD check --no-manual --as-cran` and then the default `goodpractice` checks, excluding its `rcmdcheck` group. Errors and warnings from `R CMD check` fail the command. `goodpractice` findings are reported but do not fail it. [Pandoc](https://pandoc.org/installing.html) must be on your `PATH` for all URL checks to run.

------------------------------------------------------------------------

## Release history

See [NEWS.md](NEWS.md) for changes in each version. Downloadable files for tagged versions are available under [GitHub Releases](https://github.com/RafaelMotaAlvess/Regrans/releases).

------------------------------------------------------------------------

## Quick start

``` r
library(Regrans)

data(simdata)

# Fit segmented regression (minimum points in each segment = 5)
fit <- regrans(simdata$x, simdata$y, n.min = 5)

# Inspect left and right linear models
summary(fit)

# Plot points and fitted segment lines
plot_regrans(fit,
             col.lines = c("red", "blue"),
             lty.lines = c("solid", "solid"),
             lwd.lines = c(2, 2),
             pch = 16,
             xlab = "X",
             ylab = "Y",
             main = "Segmented linear regression")

# Optional: compare segment parameters via ANCOVA
ancova_fit <- regrans_ancova(fit)
summary(ancova_fit)
```

------------------------------------------------------------------------

## How it works

Regrans follows a simple and robust strategy:

1.  Sort data by `x` (and `y` for ties).
2.  Generate candidate split positions respecting `n.min` points per side.
3.  For each split:
    - fit `lm(Y ~ X)` on the left subset,
    - fit `lm(Y ~ X)` on the right subset.
4.  Compute residual sum of squares for both models.
5.  Select the split with the **smallest total residual sum of squares**.

The returned object stores the two selected linear models (`left` and `right`), enabling plotting, summaries, and downstream inference.

------------------------------------------------------------------------

## Functions overview

| Function | Purpose |
|----|----|
| `regrans(x, y, n.min = 5)` | Fits segmented linear regression and returns the best two-model split. |
| `regranslm(x, y, n.min = 5)` | Evaluates all candidate splits and returns complete fitting details. |
| `summary.regrans(object, ...)` | Summarizes left/right fitted linear models. |
| `plot_regrans(obj, ...)` | Plots observed data and both fitted segment lines. |
| `regrans_ancova(obj)` | Fits an ANCOVA model (`Y ~ X * model`) for segment comparison. |

------------------------------------------------------------------------

## Data included

The package provides `simdata`, a simulated dataset with:

- 50 observations
- `x`: explanatory variable
- `y`: response variable

Use it to quickly test package workflows and examples.

------------------------------------------------------------------------

## Documentation

- In R, run `help(package = "Regrans")` to browse the installed documentation.

------------------------------------------------------------------------

## Authors

- [Rodrigo Sant’Ana](http://rodrigosantana.github.io)
- [Fernando Mayer](http://www.leg.ufpr.br/~fernandomayer)
- Paulo Ricardo Pezzuto
- [Rafael Mota Alves](https://github.com/RafaelMotaAlvess)

------------------------------------------------------------------------

## License

Released under the [GNU General Public License v3.0 (GPL-3)](http://www.gnu.org/licenses/gpl-3.0.html).
