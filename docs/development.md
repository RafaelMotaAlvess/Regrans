# Development workflow

This guide records the repository's current contribution and release practices. For the implemented model behavior, see the [implementation guide](architecture.md).

## Make and check a change

Work on a branch and keep code, documentation, and relevant examples together. From the package root, install the local check tools in your R user library once and run the same two checks used in CI:

```bash
Rscript ci/install-local.R
Rscript ci/check-local.R
```

The script runs `R CMD check --no-manual --as-cran` via `rcmdcheck`, then `goodpractice` with its `rcmdcheck` group disabled. This avoids running the package check twice. `R CMD check` errors and warnings fail the local script; `goodpractice` findings are printed as suggestions, while failure to run the tool fails the script. Pandoc on `PATH` enables its URL-related checks.

The [`R-CMD-check` workflow](../.github/workflows/R-CMD-check.yaml) runs on pushes to branches and on pull requests. It uses the same division of responsibility: `R CMD check` validates the package; `goodpractice` reports complementary quality findings. A green check does not establish statistical correctness, so behavior changes also need focused examples or tests.

The package repository does not carry its own `renv` lockfile. Contributors can use a normal R user library and the two `ci/` scripts above.

## Keep the README and NEWS current

[`README.Rmd`](../README.Rmd) is the editable source; [`README.md`](../README.md) is generated for GitHub. Edit the Rmd, then regenerate the Markdown before committing:

```r
# install.packages("rmarkdown") # if needed
rmarkdown::render("README.Rmd")
```

Keep the README focused on the problem solved, a working example, installation, and links to deeper guidance. Put implementation detail and contributor instructions in `docs/`. Check that the generated Markdown and its relative links render correctly.

Add user-visible changes to the [`# Regrans (development version)`](../NEWS.md) section as work is merged. That section accumulates changes throughout development. It is not reserved for the day a tag is created.

## Prepare a tagged GitHub release

Regrans currently uses GitHub Releases for distribution and keeps R package metadata compatible with a possible future CRAN submission. Release preparation is a separate change after the intended work is on `master`:

1. Review the accumulated development notes and the changes since the last tag. Choose the next version deliberately; the planned first release is `0.1.0`.
2. Finalize the version in `DESCRIPTION` and move the relevant development notes under a heading such as `# Regrans 0.1.0` in `NEWS.md`. Leave a fresh `# Regrans (development version)` section for subsequent work.
3. Run the local checks and wait for the hosted check to pass on the **exact release commit** on `master`.
4. Create and push an annotated `vX.Y.Z` tag pointing to that commit. Do not repoint a published tag.
5. Watch the [release workflow](../.github/workflows/release.yml) and verify the GitHub Release, source archive, platform binaries, and `SHA256SUMS`.

The tag workflow checks that the tag version matches `DESCRIPTION` and a matching, nonempty `NEWS.md` section. It builds a source archive on Linux, checks it, then builds Windows x64 and macOS Intel/Apple Silicon binaries from **that same source archive**. R binaries are platform and R-version specific; a single compiled binary cannot serve every operating system. The workflow publishes assets only after all required jobs succeed. It does not submit to CRAN.

Tagging and publishing are deliberate release actions. Ordinary pull requests should keep `DESCRIPTION` at its development version and add notes under the development heading rather than prematurely creating a numbered release section.
