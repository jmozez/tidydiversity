# Partition beta diversity into turnover and nestedness

`beta_pair()` computes pairwise dissimilarity between sites and splits
it into turnover (species replacement) and nestedness (species loss)
components following Baselga (2010, 2012). `beta_multi()` computes the
multiple-site version for all sites in each group. Both use presence and
absence, so any positive abundance counts as presence.

With `index = "sorensen"` the components are Simpson turnover, the
nestedness-resultant component and Sorensen dissimilarity. With
`index = "jaccard"` they are the Jaccard equivalents. With
`index = "bray"` abundances are used: `turnover` is the balanced
variation in abundance and `nestedness` the abundance gradient component
of Bray-Curtis dissimilarity (Baselga 2013), matching
[`betapart::beta.pair.abund()`](https://rdrr.io/pkg/betapart/man/beta.pair.abund.html)
and
[`betapart::beta.multi.abund()`](https://rdrr.io/pkg/betapart/man/beta.multi.abund.html).

## Usage

``` r
beta_pair(
  data,
  site = site,
  species = species,
  abundance = NULL,
  index = c("sorensen", "jaccard", "bray"),
  .by = NULL
)

beta_multi(
  data,
  site = site,
  species = species,
  abundance = NULL,
  index = c("sorensen", "jaccard", "bray"),
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

- index:

  Family of dissimilarity: `"sorensen"` or `"jaccard"` (presence and
  absence) or `"bray"` (abundance-based Bray-Curtis).

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

`beta_pair()` returns a tibble with the grouping columns, `site_1`,
`site_2`, `turnover`, `nestedness` and `total`. `beta_multi()` returns
one row per group with `n_sites`, `turnover`, `nestedness` and `total`.

## References

Baselga, A. (2010). Partitioning the turnover and nestedness components
of beta diversity. Global Ecology and Biogeography, 19, 134-143.
[doi:10.1111/j.1466-8238.2009.00490.x](https://doi.org/10.1111/j.1466-8238.2009.00490.x)

Baselga, A. (2012). The relationship between species replacement,
dissimilarity derived from nestedness, and nestedness. Global Ecology
and Biogeography, 21, 1223-1232.
[doi:10.1111/j.1466-8238.2011.00756.x](https://doi.org/10.1111/j.1466-8238.2011.00756.x)

Baselga, A. (2013). Separating the two components of abundance-based
dissimilarity: balanced changes in abundance vs. abundance gradients.
Methods in Ecology and Evolution, 4, 552-557.
[doi:10.1111/2041-210X.12029](https://doi.org/10.1111/2041-210X.12029)

## Examples

``` r
beta_pair(png_ants, .by = season)
#> # A tibble: 20 × 6
#>    season site_1 site_2 turnover nestedness total
#>    <chr>  <chr>  <chr>     <dbl>      <dbl> <dbl>
#>  1 dry    MW0200 MW0700    0.667    0.0108  0.677
#>  2 dry    MW0200 MW1200    0.769    0.0239  0.793
#>  3 dry    MW0200 MW1700    0.8      0.105   0.905
#>  4 dry    MW0200 MW2200    1        0       1    
#>  5 dry    MW0700 MW1200    0.615    0.0275  0.643
#>  6 dry    MW0700 MW1700    0.8      0.1     0.9  
#>  7 dry    MW0700 MW2200    0.833    0.0714  0.905
#>  8 dry    MW1200 MW1700    1        0       1    
#>  9 dry    MW1200 MW2200    0.833    0.0614  0.895
#> 10 dry    MW1700 MW2200    1        0       1    
#> 11 wet    MW0200 MW0700    0.619    0.0544  0.673
#> 12 wet    MW0200 MW1200    0.8      0.00488 0.805
#> 13 wet    MW0200 MW1700    0.9      0.0355  0.935
#> 14 wet    MW0200 MW2200    1        0       1    
#> 15 wet    MW0700 MW1200    0.55     0.075   0.625
#> 16 wet    MW0700 MW1700    0.9      0.0474  0.947
#> 17 wet    MW0700 MW2200    1        0       1    
#> 18 wet    MW1200 MW1700    0.6      0.133   0.733
#> 19 wet    MW1200 MW2200    1        0       1    
#> 20 wet    MW1700 MW2200    0.8      0.0667  0.867

beta_multi(png_ants, .by = season, index = "jaccard")
#> # A tibble: 2 × 5
#>   season n_sites turnover nestedness total
#>   <chr>    <int>    <dbl>      <dbl> <dbl>
#> 1 dry          5    0.905     0.0296 0.935
#> 2 wet          5    0.883     0.0442 0.927
```
