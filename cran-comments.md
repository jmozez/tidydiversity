## Submission

This is the first submission of tidydiversity (version 0.1.0).

The package computes taxonomic, phylogenetic and functional diversity as
Hill numbers from long-format community data, with rarefaction and
extrapolation and beta-diversity partitioning. Example datasets are
published field records from Papua New Guinea and the Portal Project, each
cited with its DOI and licence in the documentation.

The `png_ants` dataset comes from the Zenodo archive
<https://doi.org/10.5281/zenodo.8191946>, which is open access with no
specific licence stated. I am a co-author of that dataset and of the
associated paper, and it is included with the permission of its authors
(O. Mottl, J. Moses and P. Klimes). The other datasets are released under
CC0 1.0 or CC BY 4.0, as documented in each help page.

A Zenodo archive of this version is at <https://doi.org/10.5281/zenodo.24046912>.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Test environments

* Linux (rocker/geospatial, R 4.5, with TeX Live), R CMD check --as-cran on GitLab CI:
  0 errors, 0 warnings, 2 notes (new submission; compiler flags set by the
  CI image's R build, not by the package)
* win-builder (R-devel and R-release)
* macOS builder (R-release)

## Downstream dependencies

None (new package).
