# Fourth-corner analysis

Tests every trait x environment association with the fourth-corner
method (Legendre et al. 1997; Dray and Legendre 2008) and the max test
(model 6, ter Braak et al. 2012), using
[`ade4::fourthcorner()`](https://rdrr.io/pkg/ade4/man/fourthcorner.html),
and returns a tidy table.

## Usage

``` r
trait_fourth_corner(
  data,
  traits,
  env_vars,
  site = site,
  species = species,
  abundance = NULL,
  cols = tidyselect::everything(),
  permutations = 999,
  adjust = "fdr"
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- traits:

  A data frame of traits, one row per species, with a column whose name
  matches the `species` column of `data`.

- env_vars:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Numeric site variables in `data` (constant within sites) to test.

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

- permutations:

  Number of permutations.

- adjust:

  Method for adjusting p-values across all tests, passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html); `"none"`
  for no adjustment.

## Value

A tibble with `trait`, `variable`, the test `statistic` (Pearson r for
two numeric variables, otherwise as in ade4), `p.value` and `p.adj`.

## References

Dray, S. and Legendre, P. (2008). Testing the species traits-environment
relationships: the fourth-corner problem revisited. *Ecology*, 89,
3400-3412. [doi:10.1890/08-0349.1](https://doi.org/10.1890/08-0349.1)

## Examples

``` r
aravo <- data_aravo()
set.seed(1)
trait_fourth_corner(aravo$community, aravo$traits, abundance = cover,
                 cols = c(Height, SLA), env_vars = c(Snow, PhysD),
                 permutations = 199)
#> # A tibble: 4 × 5
#>   trait  variable statistic p.value  p.adj
#>   <chr>  <chr>        <dbl>   <dbl>  <dbl>
#> 1 Height Snow        -0.272   0.01  0.0133
#> 2 Height PhysD        0.113   0.055 0.055 
#> 3 SLA    Snow         0.481   0.005 0.01  
#> 4 SLA    PhysD       -0.276   0.005 0.01  
```
