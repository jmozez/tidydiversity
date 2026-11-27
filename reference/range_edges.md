# Elevational (or other gradient) ranges of species

`range_edges()` summarises where each species occurs along a gradient,
such as elevation: the lower and upper edges (lowest and highest site of
occurrence), the midpoint, the breadth and the abundance-weighted
optimum (mean position of individuals). Species found at the first or
last sampled position have ranges that may extend beyond the transect;
`truncated_lower` and `truncated_upper` flag them (Colwell and Hurtt
1994), as their edges and breadth are underestimated.

## Usage

``` r
range_edges(
  data,
  gradient,
  site = site,
  species = species,
  abundance = NULL,
  .by = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- gradient:

  Column giving the position of each site on the gradient, such as
  elevation in metres.

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

A tibble with one row per species (and group): `species`, `lower`,
`upper`, `midpoint`, `breadth`, `optimum`, `n_sites`, `abundance`,
`truncated_lower`, `truncated_upper`.

## References

Colwell, R. K. and Hurtt, G. C. (1994). Nonbiological gradients in
species richness and a spurious Rapoport effect. American Naturalist,
144, 570-595.

## Examples

``` r
range_edges(png_frogs, abundance = abundance, gradient = elevation)
#> # A tibble: 55 × 10
#>    species lower upper midpoint breadth optimum n_sites abundance
#>    <chr>   <int> <int>    <dbl>   <int>   <dbl>   <int>     <int>
#>  1 FR01      200  1200      700    1000    296.       3       293
#>  2 FR02     1200  1700     1450     500   1330.       2        27
#>  3 FR03     2200  2200     2200       0   2200        1        32
#>  4 FR04     1700  1700     1700       0   1700        1       108
#>  5 FR05     2200  2200     2200       0   2200        1       137
#>  6 FR06     1700  2200     1950     500   1913.       2        47
#>  7 FR07     2700  2700     2700       0   2700        1        40
#>  8 FR08     1200  1200     1200       0   1200        1       133
#>  9 FR09     2700  2700     2700       0   2700        1        13
#> 10 FR10     2200  2700     2450     500   2690.       2       104
#> # ℹ 45 more rows
#> # ℹ 2 more variables: truncated_lower <lgl>, truncated_upper <lgl>
```
