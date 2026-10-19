lib <- Sys.getenv("R_LIBS_USER")
if (!nzchar(lib)) {
    stop("R_LIBS_USER is not set; configure a personal R library first.",
         call. = FALSE)
}

lib <- path.expand(lib)
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(lib)) stop("Could not create R library: ", lib, call. = FALSE)
.libPaths(c(lib, .libPaths()))

required <- c(
    "rcmdcheck", "goodpractice", "testthat", "broom",
    "generics", "ggplot2", "tibble", "roxygen2", "rmarkdown"
)
missing <- required[!vapply(required, requireNamespace, logical(1),
                            quietly = TRUE)]
if (length(missing)) {
    install.packages(missing, repos = "https://cloud.r-project.org", lib = lib)
}

missing <- required[!vapply(required, requireNamespace, logical(1),
                            quietly = TRUE)]
if (length(missing)) {
    stop("Installation did not complete for: ", paste(missing, collapse = ", "),
         call. = FALSE)
}

if (!nzchar(Sys.which("pandoc"))) {
    message("Pandoc is not on PATH; some goodpractice URL checks may be skipped. ",
            "See https://pandoc.org/installing.html")
}
