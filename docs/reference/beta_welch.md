# Welch-type PERMANOVA robust to unequal dispersion

Tests whether community composition differs among groups with the W\*d
statistic of Hamidi et al. (2019), a distance-based generalisation of
Welch's ANOVA. Unlike classic PERMANOVA
([`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)),
it does not assume that groups have the same multivariate dispersion, so
a significant result reflects a shift in location even when groups
differ in spread or size. For two groups it equals the Tw2 test of
Alekseyenko (2016). With one variable and Euclidean distance it equals
Welch's F statistic
([`stats::oneway.test()`](https://rdrr.io/r/stats/oneway.test.html) with
`var.equal = FALSE`).

## Usage

``` r
beta_welch(
  data,
  site = site,
  species = species,
  abundance = NULL,
  group,
  env = NULL,
  distance = "bray",
  transform = "none",
  permutations = 999
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- group:

  Site variable (unquoted) defining the groups.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- distance:

  Dissimilarity for `"pcoa"`, `"nmds"` and `"dbrda"`, passed to
  [`vegan::vegdist()`](https://rdrr.io/pkg/vegan/man/vegdist.html), such
  as `"bray"` (the default) or `"jaccard"`.

- transform:

  Transformation of the community matrix before the analysis:
  `"hellinger"` (the default for PCA and RDA, which otherwise overweight
  abundant species; Legendre and Gallagher 2001), `"chord"`, `"log"`
  (log(x) + 1 for x \> 0), `"sqrt"`, `"pa"` (presence-absence) or
  `"none"` (the default for the other methods).

- permutations:

  Number of permutations.

## Value

A one-row tibble with `statistic` (W\*d), `n_groups`, `n_sites` and
`p.value`.

## Details

The p-value is obtained by permuting group labels.

## References

Hamidi, B. et al. (2019). W\*d-test: robust distance-based multivariate
analysis of variance. *Microbiome*, 7, 51.
[doi:10.1186/s40168-019-0659-9](https://doi.org/10.1186/s40168-019-0659-9)

Alekseyenko, A. V. (2016). Multivariate Welch t-test on distances.
*Bioinformatics*, 32, 3552-3558.
[doi:10.1093/bioinformatics/btw524](https://doi.org/10.1093/bioinformatics/btw524)

## Examples

``` r
ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
set.seed(1)
beta_welch(ants, site = unit, group = season, permutations = 199)
#> # A tibble: 1 x 4
#>   statistic n_groups n_sites p.value
#>       <dbl>    <int>   <int>   <dbl>
#> 1      1.29        2      20   0.165
```
