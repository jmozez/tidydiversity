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

0 errors | 0 warnings | 2 notes

* checking CRAN incoming feasibility ... NOTE
  New submission.

* checking compilation flags used ... NOTE
  '-mno-omit-leaf-frame-pointer' comes from the R build of the test
  machine (Ubuntu's r-base), not from the package's Makevars.

## Test environments

* Ubuntu 24.04, R 4.3.3, R CMD check --as-cran (local)
* Ubuntu (GitHub Actions, R release), R CMD check

## Downstream dependencies

None (new package). The companion package tidymapr, by the same author,
will suggest tidydiversity and will be submitted after this one.
