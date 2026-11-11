# PERMANOVA and dispersion tests on community composition

`beta_permanova()` tests whether composition differs with site variables
using permutational multivariate analysis of variance
([`vegan::adonis2()`](https://rdrr.io/pkg/vegan/man/adonis.html),
Anderson 2001). `beta_dispersion()` tests whether groups differ in their
spread (multivariate dispersion,
[`vegan::betadisper()`](https://rdrr.io/pkg/vegan/man/betadisper.html),
Anderson 2006). PERMANOVA is sensitive to differences in dispersion, so
report both.

## Usage

``` r
beta_permanova(
  data,
  site = site,
  species = species,
  abundance = NULL,
  formula,
  env = NULL,
  distance = "bray",
  transform = "none",
  by = c("margin", "terms", "model"),
  strata = NULL,
  permutations = 999
)

beta_dispersion(
  data,
  site = site,
  species = species,
  abundance = NULL,
  group,
  env = NULL,
  distance = "bray",
  transform = "none",
  type = c("median", "centroid"),
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

- formula:

  One-sided formula of site variables, such as `~ elevation + season`.

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

- by:

  `"margin"` (the default: each term tested after all the others, so the
  result does not depend on the order of terms), `"terms"` (sequential:
  each term after those listed before it, so order matters when terms
  are correlated) or `"model"` (all terms together). Note that
  [`vegan::adonis2()`](https://rdrr.io/pkg/vegan/man/adonis.html)
  defaults to `"terms"`; set `by = "terms"` to reproduce its default
  output.

- strata:

  Optional site variable (unquoted) within which to restrict
  permutations, for example a block or transect.

- permutations:

  Number of permutations for the tests of passive variables.

- group:

  Site variable (unquoted) defining the groups.

- type:

  Distance to the group spatial `"median"` (the default, as in vegan) or
  `"centroid"`.

## Value

A tibble: one row per term, with `df`, `sum_sq`, `r2`, `statistic`
(pseudo-F) and `p.value`.

For `beta_dispersion()`, a tibble with one row per site (`group`,
`distance` to its group centre) and the permutation test as attribute
`"test"` (also printed). Use
[`autoplot()`](https://rdrr.io/pkg/ggplot2/man/autoplot.html) to draw
it.

## Details

Site variables are taken from the data when they are constant within
sites, as in
[`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md),
or from `env`.

## References

Anderson, M. J. (2001). A new method for non-parametric multivariate
analysis of variance. *Austral Ecology*, 26, 32-46.
[doi:10.1111/j.1442-9993.2001.01070.pp.x](https://doi.org/10.1111/j.1442-9993.2001.01070.pp.x)

Anderson, M. J. (2006). Distance-based tests for homogeneity of
multivariate dispersions. *Biometrics*, 62, 245-253.
[doi:10.1111/j.1541-0420.2005.00440.x](https://doi.org/10.1111/j.1541-0420.2005.00440.x)

## Examples

``` r
ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
set.seed(1)
beta_permanova(ants, site = unit, formula = ~ elevation + season,
               permutations = 199)
#> # A tibble: 4 x 6
#>   term         df sum_sq     r2 statistic p.value
#>   <chr>     <dbl>  <dbl>  <dbl>     <dbl>   <dbl>
#> 1 elevation     1  1.33  0.169       3.75   0.005
#> 2 season        1  0.526 0.0669      1.49   0.105
#> 3 Residual     17  6.01  0.765      NA     NA    
#> 4 Total        19  7.87  1          NA     NA    
beta_dispersion(ants, site = unit, group = season, permutations = 199)
#> Multivariate dispersion by season 
#> # A tibble: 20 x 3
#>    unit         season distance
#>    <chr>        <fct>     <dbl>
#>  1 MW0200 dry 1 dry       0.564
#>  2 MW0200 dry 2 dry       0.607
#>  3 MW0200 wet 1 wet       0.590
#>  4 MW0200 wet 2 wet       0.537
#>  5 MW0700 dry 1 dry       0.574
#>  6 MW0700 dry 2 dry       0.573
#>  7 MW0700 wet 1 wet       0.576
#>  8 MW0700 wet 2 wet       0.533
#>  9 MW1200 dry 1 dry       0.607
#> 10 MW1200 dry 2 dry       0.563
#> 11 MW1200 wet 1 wet       0.508
#> 12 MW1200 wet 2 wet       0.504
#> 13 MW1700 dry 1 dry       0.676
#> 14 MW1700 dry 2 dry       0.668
#> 15 MW1700 wet 1 wet       0.636
#> 16 MW1700 wet 2 wet       0.655
#> 17 MW2200 dry 1 dry       0.647
#> 18 MW2200 dry 2 dry       0.651
#> 19 MW2200 wet 1 wet       0.729
#> 20 MW2200 wet 2 wet       0.671
#> 
#> Permutation test:
#> # A tibble: 2 x 5
#>   term         df  sum_sq statistic p.value
#>   <chr>     <int>   <dbl>     <dbl>   <dbl>
#> 1 Groups        1 0.00182     0.466   0.485
#> 2 Residuals    18 0.0702     NA      NA    
```
