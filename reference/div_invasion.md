# Native and alien species in communities

`div_invasion()` summarises, for each site (and group), how much of a
community is made up of alien (introduced, non-native) species: the
number of native and alien species, the alien share of the species and,
with abundances, the alien share of the individuals. These are the
standard measures of the level of invasion of a community (Catford et
al. 2012).

## Usage

``` r
div_invasion(
  data,
  status,
  site = site,
  species = species,
  abundance = NULL,
  alien = c("alien", "introduced", "exotic", "non-native", "invasive"),
  .by = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- status:

  Column giving each record's status. Values in `alien` count as alien;
  all others as native.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- alien:

  Values of `status` that mean alien (default `"alien"`, `"introduced"`,
  `"exotic"`, `"non-native"`, `"invasive"`).

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with one row per site (and group): `site`, `richness`,
`native`, `alien`, `alien_share` (of species) and, with `abundance`,
`alien_abundance_share`.

## References

Catford, J. A., Vesk, P. A., Richardson, D. M. and Pysek, P. (2012).
Quantifying levels of biological invasion: towards the objective
classification of invaded and invasible ecosystems. Global Change
Biology, 18, 44-62.

## Examples

``` r
# A small illustrative table
d <- data.frame(
  site = rep(c("a", "b"), each = 4),
  species = c("s1", "s2", "s3", "s4", "s1", "s5", "s6", "s7"),
  status = c("native", "native", "native", "alien", "native", "alien", "alien", "native"),
  count = c(10, 5, 3, 2, 4, 20, 6, 1)
)
div_invasion(d, status = status, abundance = count)
#> # A tibble: 2 × 6
#>   site  richness native alien alien_share alien_abundance_share
#>   <chr>    <int>  <int> <int>       <dbl>                 <dbl>
#> 1 a            4      3     1        0.25                 0.1  
#> 2 b            4      2     2        0.5                  0.839
```
