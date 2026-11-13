# Community-weighted mean traits

The abundance-weighted mean of each numeric trait in each site, and the
abundance-weighted proportion of each level of categorical traits
(Garnier et al. 2004; de Bello et al. 2021, ch. 5). Species with a
missing trait value are left out of that trait's mean, and the weights
of the remaining species are rescaled.

## Usage

``` r
trait_cwm(
  data,
  traits,
  site = site,
  species = species,
  abundance = NULL,
  cols = tidyselect::everything()
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- traits:

  A data frame of traits, one row per species, with a column whose name
  matches the `species` column of `data`.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- cols:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Trait columns of `traits`.

## Value

A tibble with one row per site and trait: the site column, `trait` and
`cwm`. Site variables (constant within sites) are kept.

## References

Garnier, E. et al. (2004). Plant functional markers capture ecosystem
properties during secondary succession. *Ecology*, 85, 2630-2637.
[doi:10.1890/03-0799](https://doi.org/10.1890/03-0799)

## Examples

``` r
aravo <- data_aravo()
trait_cwm(aravo$community, aravo$traits, abundance = cover)
#> # A tibble: 600 × 9
#>    site  trait    cwm Aspect Slope Form  PhysD ZoogD  Snow
#>    <chr> <chr>  <dbl>  <int> <int> <fct> <int> <fct> <int>
#>  1 AR01  Height  8.68      9    30 3        30 no      140
#>  2 AR02  Height  3.78      9    15 4        15 some    170
#>  3 AR03  Height  3.42      9     5 5        20 no      190
#>  4 AR04  Height  4.82      5     0 1        35 some    180
#>  5 AR05  Height  4.70      9    10 4        20 high    150
#>  6 AR06  Height  6.93      8    20 3        40 high    160
#>  7 AR07  Height  8.75      7     2 1        50 no      140
#>  8 AR08  Height  7.02      8    20 3        60 some    160
#>  9 AR09  Height  3.43      8     2 1        40 some    160
#> 10 AR10  Height  4.01      9     5 1        45 some    160
#> # ℹ 590 more rows
```
