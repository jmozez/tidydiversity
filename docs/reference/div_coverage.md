# Sample coverage

Estimates the sample coverage of each site, the proportion of the
individuals in the community that belong to species already recorded
(Chao and Jost 2012).

## Usage

``` r
div_coverage(
  data,
  site = site,
  species = species,
  abundance = NULL,
  unit = NULL,
  n_units = NULL,
  .by = NULL
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

- unit:

  For incidence data, the column naming the sampling unit (a trap, bait,
  plot or survey day) in which each species was detected. Each site is
  then described by the number of units in which each species was found
  and the number of units sampled, and every estimate is incidence-based
  (Chao et al. 2014), for TD, PD and FD alike. Leave `NULL` for
  abundance data.

- n_units:

  For incidence data, a column giving the number of units sampled at
  each site, constant within a site. Use it when some units detected no
  species and so do not appear in the data. By default the number of
  distinct units in the data is used.

- .by:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, the site column, `n`, `s_obs`, `f1`,
`f2` (singletons and doubletons) and `coverage`.

## References

Chao, A. and Jost, L. (2012). Coverage-based rarefaction and
extrapolation: standardizing samples by completeness rather than size.
Ecology, 93, 2533-2547.
[doi:10.1890/11-1952.1](https://doi.org/10.1890/11-1952.1)

## Examples

``` r
div_coverage(png_ants, .by = season)
#> # A tibble: 10 x 7
#>    season site       n s_obs    f1    f2 coverage
#>    <chr>  <chr>  <dbl> <int> <int> <int>    <dbl>
#>  1 dry    MW0200    47    16     5     5    0.898
#>  2 wet    MW0200    76    21    11     5    0.857
#>  3 dry    MW0700    23    15    12     1    0.482
#>  4 wet    MW0700    58    28    17     3    0.709
#>  5 dry    MW1200    29    13     7     3    0.766
#>  6 wet    MW1200    57    20     9     3    0.844
#>  7 dry    MW1700    17     5     1     2    0.953
#>  8 wet    MW1700    34    10     6     2    0.827
#>  9 dry    MW2200    13     6     3     1    0.781
#> 10 wet    MW2200    15     5     2     1    0.876
```
