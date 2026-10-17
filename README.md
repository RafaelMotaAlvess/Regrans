# Regrans

<p align="center">
  <strong>Segmented Linear Regression Models in R</strong><br/>
  Detect transition points by fitting two linear segments and selecting the best split.
</p>

<p align="center">
  <a href="https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml">
    <img src="https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml/badge.svg" alt="CI status"/>
  </a>
  <a href="https://www.r-project.org/">
    <img src="https://img.shields.io/badge/R-%3E%3D%203.2.2-276DC3" alt="R >= 3.2.2"/>
  </a>
  <a href="http://www.gnu.org/licenses/gpl-3.0.html">
    <img src="https://img.shields.io/badge/License-GPL--3-blue.svg" alt="License: GPL-3"/>
  </a>
</p>

---

## Table of contents

- [What is Regrans?](#what-is-regrans)
- [Main features](#main-features)
- [Installation](#installation)
  - [Install from GitHub](#install-from-github)
  - [Install from package files](#install-from-package-files)
- [Local checks](#local-checks)
- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [Functions overview](#functions-overview)
- [Data included](#data-included)
- [Documentation](#documentation)
- [Authors](#authors)
- [License](#license)

---

## What is Regrans?

**Regrans** is an R package for fitting **segmented linear regressions** (piecewise linear models with two segments).

It evaluates candidate split points along the explanatory variable, fits one linear model to the left side and another to the right side, and returns the split that minimizes the total residual sum of squares.

This is especially useful when your data suggests a **transition point**, **breakpoint**, or **allometric inflection**.

---

## Main features

- ✅ Fit two-segment linear regressions from numeric vectors (`x`, `y`)
- ✅ Automatic search for the best split point
- ✅ Summary methods for left/right fitted models
- ✅ Built-in plotting helper for segmented fits
- ✅ ANCOVA helper to compare segment parameters
- ✅ Example dataset (`simdata`) included

---

## Installation

### Install from GitHub

```r
# install.packages("devtools")
library(devtools)
install_github("rodrigosantana/Regrans")
```

### Install from package files

#### Linux / macOS (`.tar.gz`)

Download:
- [`Regrans_0.0.1.tar.gz`](https://github.com/rodrigosantana/Regrans/blob/master/downloads/Regrans_0.0.1.tar.gz?raw=true)

Install from terminal:

```bash
R CMD INSTALL -l /path/to/your/R/library Regrans_0.0.1.tar.gz
```

Or from R:

```r
install.packages("Regrans_0.0.1.tar.gz", repos = NULL,
                 lib.loc = "/path/to/your/R/library",
                 dependencies = TRUE)
```

> `-l` and `lib.loc` are optional and only needed when installing into a custom user library.

#### Windows (`.zip`)

Download:
- [`Regrans_0.0.1.zip`](https://github.com/rodrigosantana/Regrans/blob/master/downloads/Regrans_0.0.1.zip?raw=true)

Install from R:

```r
install.packages("Regrans_0.0.1.zip", repos = NULL,
                 dependencies = TRUE)
```

---

## Local checks

From the package root, install the check tools once in your personal R library,
then run both checks:

```bash
Rscript ci/install-local.R
Rscript ci/check-local.R
```

This runs `R CMD check --no-manual --as-cran` and then the default
`goodpractice` checks, excluding its `rcmdcheck` group. Errors and warnings
from `R CMD check` fail the command. `goodpractice` findings are reported but
do not fail it. [Pandoc](https://pandoc.org/installing.html) must be on your
`PATH` for all URL checks to run.

---

## Quick start

```r
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

---

## How it works

Regrans follows a simple and robust strategy:

1. Sort data by `x` (and `y` for ties).
2. Generate candidate split positions respecting `n.min` points per side.
3. For each split:
   - fit `lm(Y ~ X)` on the left subset,
   - fit `lm(Y ~ X)` on the right subset.
4. Compute residual sum of squares for both models.
5. Select the split with the **smallest total residual sum of squares**.

The returned object stores the two selected linear models (`left` and `right`), enabling plotting, summaries, and downstream inference.

---

## Functions overview

| Function | Purpose |
|---|---|
| `regrans(x, y, n.min = 5)` | Fits segmented linear regression and returns the best two-model split. |
| `regranslm(x, y, n.min = 5)` | Evaluates all candidate splits and returns complete fitting details. |
| `summary.regrans(object, ...)` | Summarizes left/right fitted linear models. |
| `plot_regrans(obj, ...)` | Plots observed data and both fitted segment lines. |
| `regrans_ancova(obj)` | Fits an ANCOVA model (`Y ~ X * model`) for segment comparison. |

---

## Data included

The package provides `simdata`, a simulated dataset with:

- 50 observations
- `x`: explanatory variable
- `y`: response variable

Use it to quickly test package workflows and examples.

---

## Documentation

- PDF reference manual: [Regrans-manual.pdf](https://github.com/rodrigosantana/Regrans/raw/master/downloads/Regrans-manual.pdf)

---

## Authors

- [Rodrigo Sant'Ana](http://rodrigosantana.github.io)
- [Fernando Mayer](http://www.leg.ufpr.br/~fernandomayer)
- Paulo Ricardo Pezzuto

---

## License

Released under the [GNU General Public License v3.0 (GPL-3)](http://www.gnu.org/licenses/gpl-3.0.html).
