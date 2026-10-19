#' Display the package startup message
#'
#' @param lib Library path used by R's package attach hook.
#' @param pkg Name supplied by R's package attach hook.
#' @return Called for its startup-message side effect.
#' @noRd
.onAttach <- function(lib, pkg) {
    pkg.info <- drop(read.dcf(
        file = system.file("DESCRIPTION", package = "Regrans"),
        fields = c("Package", "Title", "Version", "Date", "URL")
    ))
    dashes <- paste0(rep("----------", times = 7), collapse = "")
    packageStartupMessage(
        paste0(dashes, "\n  ",
               pkg.info["Package"], ": ", pkg.info["Title"], "\n  ",
               pkg.info["Package"], " version ", pkg.info["Version"],
               "\n", dashes)
    )
}
