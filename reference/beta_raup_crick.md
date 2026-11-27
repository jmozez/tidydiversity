# Raup-Crick dissimilarity against a null model

Pairwise dissimilarity that controls for differences in richness, using
the probabilistic null model of Chase et al. (2011). For each pair of
sites, species are drawn at random for both sites, keeping their
observed richness and drawing each species with probability proportional
to the number of sites it occupies in the group. The observed number of
shared species is compared with this null distribution. Values near 1
mean fewer shared species than chance (deterministic divergence), near
-1 more than chance (convergence), and near 0 a composition no different
from random assembly.

## Usage

``` r
beta_raup_crick(
  data,
  site = site,
  species = species,
  abundance = NULL,
  nsim = 999,
  .by = NULL
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

- nsim:

  Number of null communities per pair.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, `site_1`, `site_2`, `shared`
(observed shared species), `null_mean`, `raup_crick` (from -1 to 1,
Chase et al. 2011) and `probability` (the same on a 0 to 1 scale). Ties
between the null and observed counts count half, as in Chase et al.
(2011), so `probability` lies between the two versions of
[`vegan::raupcrick()`](https://vegandevs.github.io/vegan/reference/raupcrick.html)
(`chase = TRUE` counts no ties, `chase = FALSE` all of them).

## References

Chase, J. M., Kraft, N. J. B., Smith, K. G., Vellend, M. and Inouye, B.
D. (2011). Using null models to disentangle variation in community
dissimilarity from variation in alpha-diversity. Ecosphere, 2, art24.
[doi:10.1890/ES10-00117.1](https://doi.org/10.1890/ES10-00117.1)

## Examples

``` r
set.seed(1)
beta_raup_crick(png_ants, .by = season, nsim = 199)
#> # A tibble: 20 × 7
#>    season site_1 site_2 shared null_mean raup_crick probability
#>    <chr>  <chr>  <chr>   <dbl>     <dbl>      <dbl>       <dbl>
#>  1 dry    MW0200 MW0700      5     6.37      0.673        0.837
#>  2 dry    MW0200 MW1200      3     5.40      0.905        0.952
#>  3 dry    MW0200 MW1700      1     2.18      0.678        0.839
#>  4 dry    MW0200 MW2200      0     2.56      0.970        0.985
#>  5 dry    MW0700 MW1200      5     5.14      0.0503       0.525
#>  6 dry    MW0700 MW1700      1     2.02      0.613        0.807
#>  7 dry    MW0700 MW2200      1     2.35      0.688        0.844
#>  8 dry    MW1200 MW1700      0     1.77      0.935        0.967
#>  9 dry    MW1200 MW2200      1     2.11      0.678        0.839
#> 10 dry    MW1700 MW2200      0     0.829     0.658        0.829
#> 11 wet    MW0200 MW0700      8    10.3       0.814        0.907
#> 12 wet    MW0200 MW1200      4     7.24      0.920        0.960
#> 13 wet    MW0200 MW1700      1     3.82      0.960        0.980
#> 14 wet    MW0200 MW2200      0     1.92      0.935        0.967
#> 15 wet    MW0700 MW1200      9     9.90      0.377        0.688
#> 16 wet    MW0700 MW1700      1     5.04      0.985        0.992
#> 17 wet    MW0700 MW2200      0     2.53      0.975        0.987
#> 18 wet    MW1200 MW1700      4     3.73     -0.0603       0.470
#> 19 wet    MW1200 MW2200      0     1.95      0.920        0.960
#> 20 wet    MW1700 MW2200      1     0.990    -0.0553       0.472
```
