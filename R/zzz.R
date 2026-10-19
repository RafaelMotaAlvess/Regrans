#' Display the package startup message
#'
#' @param lib Library path used by R's package attach hook.
#' @param pkg Name supplied by R's package attach hook.
#' @return Called for its startup-message side effect.
#' @noRd
.onAttach <- function(lib, pkg) {
  pkg_info <- drop(read.dcf(
    file = system.file("DESCRIPTION", package = "Regrans"),
    fields = c("Package", "Title", "Version", "Date", "URL")
  ))
  dashes <- paste0(rep("----------", times = 7), collapse = "")
  packageStartupMessage(
    paste0(dashes, "\n  ",
           pkg_info["Package"], ": ", pkg_info["Title"], "\n  ",
           pkg_info["Package"], " version ", pkg_info["Version"],
           "\n", dashes)
  )
}
