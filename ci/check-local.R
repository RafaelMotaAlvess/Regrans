if (!file.exists("DESCRIPTION")) {
    stop("Run this script from the package root: Rscript ci/check-local.R",
         call. = FALSE)
}

required <- c("rcmdcheck", "goodpractice")
missing <- required[!vapply(required, requireNamespace, logical(1),
                            quietly = TRUE)]
if (length(missing)) {
    stop("Install the local check tools first: Rscript ci/install-local.R",
         call. = FALSE)
}

if (Sys.getenv("_R_CHECK_FORCE_SUGGESTS_", "") == "") {
    Sys.setenv(`_R_CHECK_FORCE_SUGGESTS_` = "false")
}
if (Sys.getenv("_R_CHECK_CRAN_INCOMING_", "") == "") {
    Sys.setenv(`_R_CHECK_CRAN_INCOMING_` = "false")
}
Sys.setenv(R_KEEP_PKG_SOURCE = "yes")

check_ok <- tryCatch({
    rcmdcheck::rcmdcheck(
        path = ".",
        args = c("--no-manual", "--as-cran"),
        build_args = "--no-manual",
        error_on = "warning"
    )
    TRUE
}, error = function(err) {
    message("R CMD check failed: ", conditionMessage(err))
    FALSE
})

options(goodpractice.exclude_check_groups = "rcmdcheck")
quality_ok <- tryCatch({
    report <- goodpractice::gp(".")
    print(report)
    cat("goodpractice: ", length(goodpractice::failed_checks(report)),
        " failed checks; ", sum(is.na(goodpractice::results(report)$passed)),
        " skipped.\n", sep = "")
    TRUE
}, error = function(err) {
    message("goodpractice failed to run: ", conditionMessage(err))
    FALSE
})

if (!check_ok || !quality_ok) quit(status = 1L)
