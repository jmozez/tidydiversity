# Sample completeness profiles

Estimates sample completeness of order `q` for each site (Chao et al.
2020). Completeness at q = 0 is the proportion of species richness
detected, at q = 1 it is the sample coverage, and higher orders give
increasing weight to abundant species. Values lie between 0 and 1,
except in samples made up only of singletons, where estimates for q \> 0
are unreliable and can be negative (as in iNEXT.4steps); a warning flags
such sites.

## Usage

``` r
div_completeness(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = seq(0, 2, 0.2),
  conf = 0.95,
  nboot = 50,
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

- q:

  Orders of completeness, non-negative numbers. Defaults to a profile
  from 0 to 2.

- conf:

  Confidence level of the intervals.

- nboot:

  Number of bootstrap replicates. Use 0 to skip them.

- .by:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_completeness` tibble with the grouping columns, the site column,
`q`, `completeness`, `se`, `lower` and `upper`.

## References

Chao, A., Kubota, Y., Zeleny, D., Chiu, C.-H., Li, C.-F., Kusumoto, B.,
Yasuhara, M., Thorn, S., Wei, C.-L., Costello, M. J. and Colwell, R. K.
(2020). Quantifying sample completeness and comparing diversities among
assemblages. Ecological Research, 35, 292-314.
[doi:10.1111/1440-1703.12102](https://doi.org/10.1111/1440-1703.12102)

## Examples

``` r
div_completeness(png_ants, q = c(0, 1, 2), .by = season, nboot = 0)
#> # A tibble: 30 × 7
#>    season site       q completeness    se lower upper
#>    <chr>  <chr>  <dbl>        <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0        0.867    NA    NA    NA
#>  2 dry    MW0200     1        0.898    NA    NA    NA
#>  3 dry    MW0200     2        0.948    NA    NA    NA
#>  4 wet    MW0200     0        0.638    NA    NA    NA
#>  5 wet    MW0200     1        0.857    NA    NA    NA
#>  6 wet    MW0200     2        0.987    NA    NA    NA
#>  7 dry    MW0700     0        0.179    NA    NA    NA
#>  8 dry    MW0700     1        0.482    NA    NA    NA
#>  9 dry    MW0700     2        0.948    NA    NA    NA
#> 10 wet    MW0700     0        0.372    NA    NA    NA
#> # ℹ 20 more rows
```
