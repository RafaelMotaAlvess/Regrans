# AGENTS.md — Regrans contributor guide

This guide is for AI coding agents working on Regrans, regardless of the
agent or editor they use. It records project-specific rules that are easy to
miss from individual files. Read the relevant source, tests, and guides before
changing behavior. Keep changes focused and report what you verified.

## Project overview

Regrans is an R package that fits two independent linear regressions to
ordered observations. `regrans()` searches eligible partitions and chooses
the pair of fits with the lowest combined residual sum of squares. The
current result contains `left` and `right` `lm` objects. The lines are not
required to meet, and the selected partition is not a continuous breakpoint
estimate. Preserve this distinction in code, documentation, and examples.

The supported interface is defined by `NAMESPACE`: `regrans()`,
`plot_regrans()`, and the `summary()`, `autoplot()`, `tidy()`, `glance()`,
and `augment()` methods for `regrans` objects.
`regranslm()` and `regrans_ancova()` are internal helpers. Do not present
them as public API without an explicit export and documentation change. Read
[`docs/architecture.md`](docs/architecture.md) and
[`docs/usage.md`](docs/usage.md) before changing fit selection or describing
model behavior.

## Repository map and sources of truth

| Path | Responsibility |
| --- | --- |
| `DESCRIPTION` | Package metadata, R compatibility, dependencies, authors, and version. |
| `R/` | Implementation and roxygen documentation source. |
| `NAMESPACE`, `man/` | Generated exports and installed help; regenerate from `R/`. |
| `data/` | Package datasets used by examples. |
| `README.Rmd` | Editable source for the generated `README.md`. |
| `NEWS.md` | User-visible changes, accumulated during development and finalized for releases. |
| `docs/` | Installation, usage, architecture, and contributor guides. |
| `ci/` | Scripts for running package checks locally. |
| `.github/workflows/` | Hosted checks and GitHub Release automation. |

Use the implementation and generated `NAMESPACE` to verify current behavior;
do not infer public support from an internal function's presence in `R/`.
Keep package metadata in `DESCRIPTION` and documentation in the files that
generate it. Preserve unrelated local files and changes.

## Behavior and compatibility

- Changes to ordering, eligible splits, the minimum observations per side,
  or the residual-sum-of-squares criterion can change statistical results.
  Review them as behavior changes and add a reproducible regression example
  or test. A passing package check alone does not establish statistical
  correctness.
- Keep the structure of returned `regrans` objects and the behavior of
  `summary()` and `plot_regrans()` stable unless the change explicitly calls
  for a public API change. Update documentation and tests together with any
  such change.
- `DESCRIPTION` declares `R (>= 4.1.0)`. Use the native pipe `|>` where it
  improves interface code, and keep the numerical search explicit. Verify
  the minimum-R policy when introducing newer language features.
- Development tools belong in the contributor workflow; do not add a runtime
  dependency solely to run a check or format source.

## R code and documentation style

Follow the [tidyverse style guide](https://style.tidyverse.org/) for new or
substantially edited R code, including its [syntax](https://style.tidyverse.org/syntax.html),
[package file](https://style.tidyverse.org/package-files.html),
[documentation](https://style.tidyverse.org/documentation.html), and
[NEWS](https://style.tidyverse.org/news.html) guidance. Its
[source repository](https://github.com/tidyverse/style) is a further
reference. Apply style to the code being changed; avoid unrelated,
whole-package formatting diffs.

- Use descriptive `snake_case` names for functions, arguments, variables,
  and returned fields; reserve dots in function names for S3 methods. This
  package is still in development, so prefer a consistent public interface
  over speculative compatibility. Treat a public rename as
  a behavior change: update calls, roxygen, generated help, tests, usage
  guides, and `NEWS.md` together. The `X`/`Y` columns inside returned `lm`
  models are tied to their formulas; investigate their downstream effects
  before changing them.
- Use two-space indentation, spaces around ordinary infix operators, and
  braces for multiline control flow. Aim for lines of at most 80 characters.
  Comments should explain a decision or constraint.
- Name an `R/*.R` file after its principal function, or use a concise name
  for a closely related group of functions. Keep file names lowercase where
  practical.
- Add focused `testthat` tests for behavior changes and fixes, following its
  `tests/testthat/test-foo.R` convention for `R/foo.R`. Keep independent
  numerical reference cases for changes to split selection.
- Run `Rscript -e 'stopifnot(length(lintr::lint_package()) == 0L)'` after
  editing R source, tests, or data-generation scripts. Fix indentation,
  spacing, and private object names rather than disabling a linter globally.
  `ggplot2::aes()` references data columns through nonstandard evaluation;
  `utils::globalVariables()` satisfies `R CMD check` but not necessarily
  `lintr`. Use a line-specific `# nolint: object_usage_linter.` only for
  that verified case, never to avoid a straightforward name or spacing fix.
  Keep `lintr` as a development tool, not an `Imports` dependency.

### Roxygen documentation gate

Documentation is a hard gate for every change to `R/`. Every top-level
function must have an adjacent roxygen block that explains its purpose,
arguments, return value, and any important statistical or compatibility
constraint. Public functions and S3 methods also need a runnable example and
`@export`; use `@rdname` when methods share a help topic. Document internal
helpers in the source with `@noRd`; do not present them as supported public
API.

Before reporting an `R/` change complete, run `roxygen2::roxygenise()` (or
`devtools::document()`), inspect the generated `man/` and `NAMESPACE` diff,
and run `Rscript ci/check-local.R`. Resolve missing documentation, stale
generated files, and code/documentation mismatches before considering the
change ready.
Do not edit generated help as the sole source of a change. Package and dataset
documentation must likewise be maintained in their roxygen source blocks.

Keep the README focused on what the package does, how to install it, and a
working example; place deeper explanations in `docs/`. Edit `README.Rmd`,
then regenerate and commit the matching `README.md` with
`rmarkdown::render("README.Rmd")`. Check rendered output and relative links.

Add a `NEWS.md` bullet under `# Regrans (development version)` for each
user-visible change, including fixes and performance improvements. Write for
users and name the affected functions. Refine and group bullets when cutting
a release. Ordinary pull requests do not create numbered NEWS headings or
bump `DESCRIPTION` to the next release version.

## Validation and pull requests

From the package root:

```sh
Rscript ci/install-local.R # once, if check tools are missing
Rscript ci/check-local.R
```

The local script runs `R CMD check --no-manual --as-cran` through `rcmdcheck`
and runs `goodpractice` with its `rcmdcheck` check group excluded. Keep this
division in `.github/workflows/R-CMD-check.yaml` so the package check runs
once. An `R CMD check` error or warning fails validation; inspect NOTEs.
Review `goodpractice` findings as quality feedback. Failure to run
`goodpractice` is a validation failure, even though individual findings are
reported rather than used as a gate.
Inspect reported call sites before applying a suggestion mechanically. For
example, the current `paste0()` findings in `R/zzz.R` refer to the package
startup message, not to a `stop()` call or a file path.
Run `Rscript -e 'testthat::test_local()'` for focused package tests while
developing; `R CMD check` runs the same suite via `tests/testthat.R`.

When a change exposes a recurring mistake, hidden constraint, or failure in
code, structure, documentation, CI, or release work, fix the underlying issue
and record a short, actionable lesson in this file. Update the affected
source-of-truth guide in `docs/` or another maintained document at the same
time. Describe what to check or do next time and why; avoid session logs and
duplicating whole guides here. Verify that the new rule matches the code and
the commands contributors actually run.

The hosted `R-CMD-check` workflow runs on pushes and pull requests with R
release and R 4.1 on Ubuntu; `goodpractice` runs on the release lane. For
statistical or other behavior changes, run focused
examples or tests as well. In the pull request, use
`.github/pull_request_template.md` to explain the change, how to verify it,
and any relevant NEWS entry. Report the commands run, their results, and
remaining warnings or NOTEs; do not claim cross-platform validation from
the Ubuntu check alone.

## Releases

Releases are deliberate, separate from ordinary pull requests. Regrans
currently distributes through GitHub Releases, not CRAN. Read
`.github/workflows/release.yml` before changing the process.

1. Release only on an explicit request. Review changes since the previous
   tag and finalize the version in `DESCRIPTION` and a nonempty
   `# Regrans X.Y.Z` section in `NEWS.md`.
2. Put the release commit on `master`, run local checks, and require the
   hosted `R-CMD-check` job to pass on that exact commit.
3. Create and push an annotated `vX.Y.Z` tag pointing to that commit. Never
   move or force-push a published tag.
4. Follow the entire tag workflow. It checks one source package on Linux,
   then builds and installs Windows x64 and macOS Intel and Apple Silicon
   binaries from that source package. Only the publish job creates a GitHub
   Release. A tag visible in GitHub is not itself a published release.
5. Verify the release page, notes, expected assets, and `SHA256SUMS` before
   opening a fresh development NEWS section and setting the next development
   version in `DESCRIPTION` to `X.Y.Z.9000`.

In Windows `pwsh` steps, invoke `R.exe CMD ...` explicitly: PowerShell may
resolve `R` to its `Invoke-History` alias. If a tag workflow fails, inspect
the failed step with `gh run view <run-id> --log-failed`. Fix the workflow on
`master`, keep the existing tag unchanged, and rerun it with
`gh workflow run release.yml --ref master -f ref=vX.Y.Z`; that workflow
checks out the named tag for the package build. Verify every build and the
publish job before reporting success. Treat any future CRAN submission as
a separate release decision with its own current checks.
