# Test CWM-environment relationships with the max test

Relating community-weighted means to site variables with an ordinary
test inflates Type I error, because CWMs of different sites share the
same species traits (Zeleny 2018; Peres-Neto et al. 2017). The *max
test* (ter Braak et al. 2012) combines a row-based permutation (shuffle
sites) with a column-based permutation (shuffle traits among species)
and reports the larger p-value. It controls Type I error whether the
null hypothesis concerns the environment or the traits.

## Usage

``` r
trait_cwm_test(
  data,
  traits,
  env_vars,
  site = site,
  species = species,
  abundance = NULL,
  cols = tidyselect::everything(),
  permutations = 999
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- traits:

  A data frame of traits, one row per species, with a column whose name
  matches the `species` column of `data`.

- env_vars:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Numeric site variables in `data` (constant within sites) to test.

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

- permutations:

  Number of permutations.

## Value

A tibble with one row per numeric trait x variable: `trait`, `variable`,
Pearson `r` between CWM and the variable, `p_row`, `p_col` and `p_max`.

## References

Zeleny, D. (2018). Which results of the standard test for
community-weighted mean approach are too optimistic? *Journal of
Vegetation Science*, 29, 953-966.
[doi:10.1111/jvs.12688](https://doi.org/10.1111/jvs.12688)

ter Braak, C. J. F., Cormont, A. and Dray, S. (2012). Improved testing
of species traits-environment relationships in the fourth-corner
problem. *Ecology*, 93, 1525-1526.
[doi:10.1890/12-0126.1](https://doi.org/10.1890/12-0126.1)

## Examples

``` r
aravo <- data_aravo()
set.seed(1)
trait_cwm_test(aravo$community, aravo$traits, abundance = cover,
            cols = c(Height, SLA), env_vars = Snow, permutations = 199)
#> # A tibble: 2 × 6
#>   trait  variable      r p_row p_col p_max
#>   <chr>  <chr>     <dbl> <dbl> <dbl> <dbl>
#> 1 Height Snow     -0.737 0.005 0.025 0.025
#> 2 SLA    Snow      0.864 0.005 0.005 0.005
```
