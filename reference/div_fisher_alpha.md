# Fisher's alpha

Fisher's log-series diversity index alpha (Fisher, Corbet and Williams
1943), the parameter that satisfies S = alpha log(1 + n / alpha). It is
nearly independent of sample size when abundances follow a log-series,
which made it the standard index in tropical ecology, and EstimateS
reports it. The values equal vegan's `fisher.alpha()`.

## Usage

``` r
div_fisher_alpha(
  data,
  site = site,
  species = species,
  abundance = NULL,
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

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, the site column, `n`, `s_obs` and
`alpha`.

## References

Fisher, R. A., Corbet, A. S. and Williams, C. B. (1943). The relation
between the number of species and the number of individuals in a random
sample of an animal population. Journal of Animal Ecology, 12, 42-58.
[doi:10.2307/1411](https://doi.org/10.2307/1411)

## Examples

``` r
div_fisher_alpha(png_ants, .by = season)
#> # A tibble: 10 × 5
#>    season site       n s_obs alpha
#>    <chr>  <chr>  <dbl> <int> <dbl>
#>  1 dry    MW0200    47    16  8.55
#>  2 dry    MW0700    23    15 18.7 
#>  3 dry    MW1200    29    13  9.05
#>  4 dry    MW1700    17     5  2.39
#>  5 dry    MW2200    13     6  4.32
#>  6 wet    MW0200    76    21  9.60
#>  7 wet    MW0700    58    28 21.3 
#>  8 wet    MW1200    57    20 11.0 
#>  9 wet    MW1700    34    10  4.77
#> 10 wet    MW2200    15     5  2.63
```
