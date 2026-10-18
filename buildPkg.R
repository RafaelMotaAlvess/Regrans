##======================================================================
## Script to check and build the `Regrans` package
##======================================================================

##----------------------------------------------------------------------
## Set working directory
if (!basename(getwd()) == "Regrans") {
    stop("The working directory isn't /Regrans")
}

##----------------------------------------------------------------------
## Packages
library(devtools)

##----------------------------------------------------------------------
## Run checks

## Load the package (to make functiona available)
load_all()

## Create/update NAMESPACE, *.Rd files.
document()

## Check documentation.
check_man()

## Check functions, datasets, run examples, etc. Using cleanup = FALSE
## and check_dir = "../" will create a directory named Regrans.Rcheck
## with all the logs, manuals, figures from examples, etc.
check(cleanup = FALSE, manual = TRUE, vignettes = FALSE,
      check_dir = "../")

## Examples
# Run examples from all functions of the package
# run_examples()
# Run examples from a specific function
# dev_example("yscale.components.right")

## Show all exported objects.
ls("package:Regrans")
version <- read.dcf("DESCRIPTION")[1L, "Version"]
cat("Package version:", version, "\n")

## Build the package (it will be one directory up)
build(manual = TRUE, vignettes = FALSE)

##----------------------------------------------------------------------
## Test installation.

## Test install with install.packages()
pkg <- paste0("../Regrans_", version, ".tar.gz")
install.packages(pkg, repos = NULL, type = "source")
