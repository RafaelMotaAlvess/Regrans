<!-- README.md is generated from README.Rmd. Please edit that file. -->

# Regrans

<!-- badges: start -->

[![R-CMD-check](https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml) [![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

<!-- badges: end -->

## Overview

Regrans helps you explore data whose relationship changes across the range of an explanatory variable. It fits two linear segments and selects the split with the smallest combined residual sum of squares. You can inspect each fitted line and plot the result.

## Installation

Regrans is not on CRAN yet. Install the latest tagged version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("RafaelMotaAlvess/Regrans@v0.1.0")
```

For the development version, omit `@v0.1.0`. The [GitHub Releases](https://github.com/RafaelMotaAlvess/Regrans/releases) page also provides a source package and Windows and macOS binaries. The [installation guide](docs/installation.md) explains how to choose and install one.

## Usage

``` r
library(Regrans)

x <- 1:20
y <- ifelse(x <= 10, 2 + x, -15 + 3 * x) + sin(x) / 5

fit <- regrans(x, y)
range(fit$left$model$X)   # observations assigned to the first line
#> [1]  1 10
range(fit$right$model$X)  # observations assigned to the second line
#> [1] 11 20
summary(fit)              # summaries of both linear models
plot_regrans(fit, pch = 16)
```

`fit` contains the `left` and `right` linear models. The lines are fitted independently, so they need not meet at the split. See the [usage guide](docs/usage.md) for data requirements and interpretation.

## Documentation

- [Usage and current scope](docs/usage.md)
- [Installation on Linux, Windows, and macOS](docs/installation.md)
- [Documentation for contributors](docs/README.md)
- [Changes in development and released versions](NEWS.md)

In R, use `help(package = "Regrans")` for the installed reference pages.

## Getting help

If you find a bug, open a [GitHub issue](https://github.com/RafaelMotaAlvess/Regrans/issues) with a minimal reproducible example.

## Authors

- Rodrigo Sant’Ana
- Fernando Mayer
- Paulo Ricardo Pezzuto
- Rafael Mota Alves

Regrans is released under [GPL-3](https://www.gnu.org/licenses/gpl-3.0.html).
