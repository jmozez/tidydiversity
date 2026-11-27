# Trait-environment analysis: RLQ

RLQ analysis (Doledec et al. 1996;
[`ade4::rlq()`](https://adeverse.github.io/ade4/reference/rlq.html))
finds the axes of greatest co-variation between site variables (R),
weighted by the community table (L), and species traits (Q). It is
tested with the combined fourth-corner permutation models 2 and 4 (Dray
et al. 2014): permuting sites and permuting species; the larger p-value
is reported.

## Usage

``` r
trait_rlq(
  data,
  site = site,
  species = species,
  abundance = NULL,
  traits,
  env_vars,
  trait_vars,
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

- env_vars, trait_vars:

  Names of the site variables and the traits.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- trait_species:

  Name of the species column of `traits`.

- permutations:

  Number of permutations.

## Value

A list of class `td_rlq`: `axes`, `env_scores` (coefficients of site
variables), `trait_scores` (coefficients of traits), `sites`, `species`,
`test` and `fit`.

## References

Doledec, S., Chessel, D., ter Braak, C. J. F. and Champely, S. (1996).
Matching species traits to environmental variables: a new three-table
ordination method. *Environmental and Ecological Statistics*, 3,
143-166.

Dray, S., Choler, P., Doledec, S. et al. (2014). Combining the
fourth-corner and the RLQ methods for assessing trait responses to
environmental variation. *Ecology*, 95, 14-21.
[doi:10.1890/13-0196.1](https://doi.org/10.1890/13-0196.1)

## Examples

``` r
a <- data_aravo()
trait_rlq(a$community, abundance = cover, traits = a$traits,
  env_vars = c("Snow", "PhysD", "Slope"), trait_vars = c("Height", "SLA"),
  permutations = 99)
#> RLQ analysis
#> # A tibble: 2 × 3
#>   axis  eigenvalue proportion
#>   <chr>      <dbl>      <dbl>
#> 1 RLQ1     0.457      0.996  
#> 2 RLQ2     0.00166    0.00361
#> # A tibble: 3 × 3
#>   model       statistic p.value
#>   <chr>           <dbl>   <dbl>
#> 1 2 (sites)       0.459    0.01
#> 2 4 (species)     0.459    0.01
#> 3 max            NA        0.01
```
