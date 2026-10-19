
<!-- README.md is generated from README.Rmd. Please edit that file. -->

# Regrans

<!-- badges: start -->

[![R-CMD-check](https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/RafaelMotaAlvess/Regrans/actions/workflows/R-CMD-check.yaml) [![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

<!-- badges: end -->

## Overview

Regrans helps you explore data whose relationship changes across the range of an explanatory variable. It fits two independent linear segments and selects the division between observed values with the smallest combined residual sum of squares. You can inspect each line and edit the resulting plot.

## Installation

Regrans is not on CRAN yet. Install the latest tagged version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("RafaelMotaAlvess/Regrans@v0.1.0")
```

For the development version, omit `@v0.1.0`; it requires R 4.1 or newer. The [GitHub Releases](https://github.com/RafaelMotaAlvess/Regrans/releases) page also provides a source package and Windows and macOS binaries. The [installation guide](docs/installation.md) explains how to choose and install one.

## Usage

``` r
library(Regrans)

observations <- data.frame(x = 1:20)
observations$y <- ifelse(observations$x <= 10,
                         2 + observations$x,
                         -15 + 3 * observations$x) +
  sin(observations$x) / 5

fit <- regrans(y ~ x, data = observations)
range(fit$left$model$X)   # observations assigned to the first line
#> [1]  1 10
range(fit$right$model$X)  # observations assigned to the second line
#> [1] 11 20
fit$split                 # boundary between observed x values
tidy(fit)                 # coefficients for each segment
glance(fit)               # selected split and fit score
plot_regrans(fit, pch = 16) # editable ggplot2 graphic
```

`fit` contains the `left` and `right` linear models. The lines are fitted independently, so they need not meet at the split. `augment(fit)` adds fitted values, residuals, and segment labels to the original rows. See the [usage guide](docs/usage.md) for data requirements and interpretation.

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
