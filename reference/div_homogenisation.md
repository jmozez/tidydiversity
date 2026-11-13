# Biotic homogenisation between two surveys

`div_homogenisation()` asks whether communities have become more alike
over time, as when widespread alien species spread and local endemics
are lost (biotic homogenisation; McKinney and Lockwood 1999; Olden and
Rooney 2006). It computes the mean pairwise similarity among the same
sites in two surveys (Jaccard or Sorensen, presence-absence) and the
change, \\\Delta = \bar S\_{after} - \bar S\_{before}\\: positive values
mean homogenisation, negative values differentiation.

Site pairs share sites, so they are not independent. The confidence
interval therefore resamples sites (a site bootstrap): sites are drawn
with replacement, and the change is recomputed over the pairs of
distinct drawn sites.

With `status`, the change is also computed with native species only: the
difference between the two (`alien_contribution`) is the part of the
change due to alien species.

## Usage

``` r
div_homogenisation(
  before,
  after,
  site = site,
  species = species,
  status = NULL,
  alien = c("alien", "introduced", "exotic", "non-native", "invasive"),
  index = c("jaccard", "sorensen"),
  nboot = 999,
  conf = 0.95,
  seed = NULL
)
```

## Arguments

- before, after:

  Long-format data of the two surveys.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- status:

  Column giving each record's status. Values in `alien` count as alien;
  all others as native.

- alien:

  Values of `status` that mean alien (default `"alien"`, `"introduced"`,
  `"exotic"`, `"non-native"`, `"invasive"`).

- index:

  `"jaccard"` or `"sorensen"` similarity.

- nboot:

  Number of bootstrap resamples of sites.

- conf:

  Confidence level.

- seed:

  Optional random seed.

## Value

A tibble with one row per species set (`"all"` and, with `status`,
`"native"`): `species_set`, `sites`, `similarity_before`,
`similarity_after`, `change`, `lower`, `upper` (bootstrap interval of
the change); with `status`, an attribute `alien_contribution`.

## References

McKinney, M. L. and Lockwood, J. L. (1999). Biotic homogenization: a few
winners replacing many losers in the next mass extinction. Trends in
Ecology & Evolution, 14, 450-453.

Olden, J. D. and Rooney, T. P. (2006). On defining and quantifying
biotic homogenization. Global Ecology and Biogeography, 15, 113-120.

## Examples

``` r
# A small illustrative example: one alien species spreads to every site
before <- data.frame(
  site = rep(1:4, each = 2),
  species = c("a", "b", "c", "d", "e", "f", "g", "h"),
  status = "native"
)
after <- rbind(before, data.frame(site = 1:4, species = "x", status = "alien"))
div_homogenisation(before, after, status = status, nboot = 99, seed = 1)
#> # A tibble: 2 × 7
#>   species_set sites similarity_before similarity_after change lower upper
#>   <chr>       <int>             <dbl>            <dbl>  <dbl> <dbl> <dbl>
#> 1 all             4                 0              0.2    0.2   0.2   0.2
#> 2 native          4                 0              0      0     0     0  
```
