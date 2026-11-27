# Trait-environment analysis: double constrained correspondence analysis

Double constrained correspondence analysis of CANOCO 5 (dc-CA; ter Braak
et al. 2018), fitted with
[`douconca::dc_CA()`](https://rdrr.io/pkg/douconca/man/dc_CA.html): the
axes are at the same time combinations of site variables and of species
traits, so they show how traits respond to the environment. The relation
is tested at both levels (sites and species) and the larger p-value is
reported (the max test), which keeps the error rate right.

## Usage

``` r
trait_dcca(
  data,
  site = site,
  species = species,
  abundance = NULL,
  traits,
  trait_formula,
  env_formula,
  env = NULL,
  trait_species = "species",
  permutations = 999
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

- traits:

  A data frame of species traits, one row per species.

- trait_formula, env_formula:

  One-sided formulas of traits and of site variables.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- trait_species:

  Name of the species column of `traits`.

- permutations:

  Number of permutations.

## Value

A list of class `td_dcca`: `axes` (eigenvalues and share of the
trait-environment inertia), `test` (site-level, species-level and max
test) and `fit` (the `dcca` object).

## References

ter Braak, C. J. F., Smilauer, P. and Dray, S. (2018). Algorithms and
biplots for double constrained correspondence analysis. *Environmental
and Ecological Statistics*, 25, 171-197.
[doi:10.1007/s10651-017-0395-x](https://doi.org/10.1007/s10651-017-0395-x)

## Examples

``` r
a <- data_aravo()
trait_dcca(a$community, abundance = cover, traits = a$traits,
  trait_formula = ~ Height + SLA, env_formula = ~ Snow + PhysD,
  permutations = 99)
#> Double constrained correspondence analysis (dc-CA)
#> # A tibble: 2 × 3
#>   axis  eigenvalue  proportion 
#>   <chr> <eigenvls>  <eigenvls> 
#> 1 dcCA1 0.292382146 0.990535904
#> 2 dcCA2 0.002793571 0.009464096
#> # A tibble: 3 × 3
#>   level   statistic p.value
#>   <chr>       <dbl>   <dbl>
#> 1 sites        71.6    0.01
#> 2 species      27.4    0.01
#> 3 max          NA      0.01
```
