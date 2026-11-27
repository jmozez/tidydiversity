# Canonical variate analysis (discriminant analysis)

CANOCO's canonical variate analysis (CVA): the axes that best separate
predefined groups of sites by their species composition (linear
discriminant analysis,
[`MASS::lda()`](https://rdrr.io/pkg/MASS/man/lda.html)). It needs fewer
species than sites minus groups; with more species, analyse the first
axes of a PCA, or species selected beforehand. The separation of the
groups is tested by permuting group labels, with the sum of the squared
canonical correlations (the Pillai trace) as statistic.

## Usage

``` r
ord_cva(
  data,
  site = site,
  species = species,
  abundance = NULL,
  group,
  env = NULL,
  transform = "none",
  permutations = 999
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- group:

  Name of the site variable defining the groups.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- transform:

  Transformation of the community matrix before the analysis:
  `"hellinger"` (the default for PCA and RDA, which otherwise overweight
  abundant species; Legendre and Gallagher 2001), `"chord"`, `"log"`
  (log(x) + 1 for x \> 0), `"sqrt"`, `"pa"` (presence-absence),
  `"logratio"` or `"none"` (the default for the other methods).
  `"logratio"` takes log(y + 1) and centres it by both sites and
  species: PCA of it is CANOCO's log-ratio analysis (LRA), and RDA of it
  is constrained log-ratio analysis.

- permutations:

  Number of permutations.

## Value

A list of class `td_cva`: `sites` (site scores and group), `centroids`
(group means on the axes), `axes` (eigenvalues, canonical correlations
and the share of the separation per axis), `test` (a tibble with the
statistic and p-value) and `fit` (the
[`MASS::lda()`](https://rdrr.io/pkg/MASS/man/lda.html) object).

## References

ter Braak, C. J. F. and Smilauer, P. (2012). *Canoco Reference Manual
and User's Guide: Software for Ordination (version 5.0)*. Microcomputer
Power, Ithaca.

## Examples

``` r
v <- community_long(vare_species, cols = -site)
v <- v[v$species %in% c("Cladstel", "Cladrang", "Pleuschr", "Vaccviti", "Empenigr"), ]
env <- vare_env
env$humus <- ifelse(env$Humdepth > stats::median(env$Humdepth), "deep", "shallow")
ord_cva(v, abundance = abundance, group = "humus", env = env, permutations = 199)
#> Canonical variate analysis of 24 sites in 2 groups
#> # A tibble: 1 × 4
#>   axis  eigenvalue canonical_correlation proportion
#>   <chr>      <dbl>                 <dbl>      <dbl>
#> 1 LD1         35.9                 0.788          1
#> Separation of the groups: Pillai trace 0.62, p = 0.005 (199 permutations)
```
