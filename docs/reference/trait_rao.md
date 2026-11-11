# Rao's quadratic entropy: alpha, beta and gamma functional diversity

Partitions functional diversity across sites with Rao's quadratic
entropy, using the equivalent-numbers correction of de Bello et al.
(2010) so that beta = gamma / alpha and is not underestimated. Sites are
weighted equally. Dissimilarities are scaled to a maximum of 1.

## Usage

``` r
trait_rao(
  data,
  traits = NULL,
  site = site,
  species = species,
  abundance = NULL,
  cols = tidyselect::everything(),
  dist = NULL
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

- dist:

  Species dissimilarity; computed with Gower distance from `traits` if
  `NULL`. Use a dissimilarity of 1 between all species for taxonomic
  (Simpson) diversity.

## Value

A tibble with `component` (`"alpha"`, `"beta"`, `"gamma"`), `rao` (Rao's
Q, for alpha and gamma) and `equivalent` (equivalent numbers, 1 / (1 -
Q)), plus `beta_prop`, the proportional turnover `1 - alpha / gamma` (in
equivalent numbers).

## References

de Bello, F. et al. (2010). The partitioning of diversity: showing
Theseus a way out of the labyrinth. *Journal of Vegetation Science*, 21,
992-1000.
[doi:10.1111/j.1654-1103.2010.01195.x](https://doi.org/10.1111/j.1654-1103.2010.01195.x)

## Examples

``` r
aravo <- data_aravo()
trait_rao(aravo$community, aravo$traits, abundance = cover)
#> # A tibble: 3 × 4
#>   component    rao equivalent beta_prop
#>   <chr>      <dbl>      <dbl>     <dbl>
#> 1 alpha      0.303       1.44   NA     
#> 2 beta      NA           1.08    0.0725
#> 3 gamma      0.354       1.55   NA     
```
