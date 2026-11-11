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

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- cols:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
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
#>  1 AR26  Height  8.80      5     0 3        20 no      140
#>  2 AR22  Height  7.77      5    10 3        70 no      160
#>  3 AR28  Height  8.35      1     5 3        60 no      150
#>  4 AR01  Height  8.68      9    30 3        30 no      140
#>  5 AR23  Height 11.5       5    10 3        20 some    140
#>  6 AR08  Height  7.02      8    20 3        60 some    160
#>  7 AR12  Height  6.71      9     5 3        40 no      150
#>  8 AR61  Height  6.38      8    15 4        10 no      150
#>  9 AR49  Height  6.90      5     2 1        65 no      150
#> 10 AR50  Height  6.78      5     0 1        40 no      160
#> # ℹ 590 more rows
```
