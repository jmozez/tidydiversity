# Classic functional diversity indices

Functional richness (FRic), evenness (FEve), divergence (FDiv),
dispersion (FDis) and Rao's quadratic entropy (RaoQ) for each site
(Villeger et al. 2008; Laliberte and Legendre 2010), computed by
[`FD::dbFD()`](https://rdrr.io/pkg/FD/man/dbFD.html) and returned as a
tidy table. These complement the Hill-number functional diversity of
[`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md).

## Usage

``` r
trait_fd_indices(
  data,
  traits,
  site = site,
  species = species,
  abundance = NULL,
  cols = tidyselect::everything(),
  dist = NULL,
  indices = c("FRic", "FEve", "FDiv", "FDis", "RaoQ"),
  m = "max"
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

  Optional species dissimilarity (e.g. from
  [`trait_dist()`](https://tidydiversity.in4metrix.dev/reference/trait_dist.md));
  computed with Gower distance from `traits` if `NULL`.

- indices:

  Indices to return.

- m:

  Number of PCoA axes for FRic and FDiv: `"max"` or `"min"` (see
  [`FD::dbFD()`](https://rdrr.io/pkg/FD/man/dbFD.html)), or a number.

## Value

A tibble with the site column, `nbsp` (species richness), `index` and
`value`.

## References

Villeger, S., Mason, N. W. H. and Mouillot, D. (2008). New
multidimensional functional diversity indices for a multifaceted
framework in functional ecology. *Ecology*, 89, 2290-2301.
[doi:10.1890/07-1206.1](https://doi.org/10.1890/07-1206.1)

Laliberte, E. and Legendre, P. (2010). A distance-based framework for
measuring functional diversity from multiple traits. *Ecology*, 91,
299-305. [doi:10.1890/08-2244.1](https://doi.org/10.1890/08-2244.1)

## Examples

``` r
aravo <- data_aravo()
trait_fd_indices(aravo$community, aravo$traits, abundance = cover,
              indices = c("FDis", "RaoQ"))
#> # A tibble: 150 × 4
#>    site   nbsp index value
#>    <chr> <int> <chr> <dbl>
#>  1 AR26     26 FDis  0.135
#>  2 AR22     28 FDis  0.136
#>  3 AR28     24 FDis  0.134
#>  4 AR01     23 FDis  0.133
#>  5 AR23     22 FDis  0.134
#>  6 AR08     28 FDis  0.136
#>  7 AR12     24 FDis  0.130
#>  8 AR61     20 FDis  0.138
#>  9 AR49     20 FDis  0.148
#> 10 AR50     21 FDis  0.146
#> # ℹ 140 more rows
```
