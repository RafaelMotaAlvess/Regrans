# Installation

Regrans is currently distributed through GitHub. It is not published on CRAN.

## Tagged version

From an R session:

```r
install.packages("remotes") # if needed
remotes::install_github("RafaelMotaAlvess/Regrans@v0.1.0")
```

This installs the tagged release from source. To install the current development version, omit `@v0.1.0`; `remotes` then selects the repository's default branch. You can also use `remotes::install_github("RafaelMotaAlvess/Regrans@<ref>")` for a specific branch or commit.

## Tagged releases

Select an asset from [GitHub Releases](https://github.com/RafaelMotaAlvess/Regrans/releases). The release workflow builds one R source package and uses that source to build platform-specific binaries:

| System | Asset | Install type |
| --- | --- | --- |
| Linux | `Regrans_<version>.tar.gz` | Source |
| Windows x64 | `Regrans_<version>-windows-x86_64-R<major.minor>.zip` | Binary |
| macOS Intel | `Regrans_<version>-macos-x86_64-R<major.minor>.<extension>` | Binary |
| macOS Apple Silicon | `Regrans_<version>-macos-arm64-R<major.minor>.<extension>` | Binary |

The macOS extension depends on the R build tooling and can be `.tgz` or another supported archive format. Match the binary's R major/minor version to `getRversion()` and its architecture to `R.version$arch`. If no binary matches your setup, install the source archive instead; source installs may require platform build tools.

In R, replace the example path with the file you downloaded:

```r
# For development builds with the new plotting and tidier interface:
install.packages(c("generics", "ggplot2", "tibble"))
install.packages("path/to/Regrans_<version>.tar.gz", repos = NULL, type = "source")

# For a matching Windows or macOS binary:
install.packages("path/to/downloaded-binary", repos = NULL, type = "binary")
```

Release assets include `SHA256SUMS` so you can verify a downloaded file before installation. Older files under the repository's `downloads/` directory are historical artifacts; use the release page for future tagged versions.
