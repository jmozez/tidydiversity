# Standardised effect sizes from null models

Compares an observed functional diversity index with its distribution
under a null model, to ask whether communities are more (divergence,
e.g. limiting similarity) or less (convergence, e.g. environmental
filtering) functionally diverse than expected by chance (de Bello et al.
2021, ch. 7). SES = (observed - mean null) / sd null.

## Usage

``` r
trait_ses(
  data,
  traits,
  site = site,
  species = species,
  abundance = NULL,
  cols = tidyselect::everything(),
  dist = NULL,
  index = c("RaoQ", "FDis", "MPD"),
  null = c("traits", "richness", "swap"),
  times = 999
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

- dist:

  Optional species dissimilarity (e.g. from
  [`trait_dist()`](https://tidydiversity.in4metrix.dev/reference/trait_dist.md));
  computed with Gower distance from `traits` if `NULL`.

- index:

  Index to test: `"RaoQ"`, `"FDis"` or `"MPD"` (abundance- weighted mean
  pairwise dissimilarity).

- null:

  Null model, see Details.

- times:

  Number of randomisations.

## Value

A tibble with one row per site: `observed`, `null_mean`, `null_sd`,
`ses` and `p.value` (two-sided rank-based).

## Details

Null models:

- `"traits"`: shuffle trait values among species (keeps every site's
  species richness and abundances; tests trait structure).

- `"richness"`: shuffle abundances among species within each site (keeps
  richness and the abundance distribution of each site).

- `"swap"`: independent swap of the site x species matrix, keeping site
  and species totals
  ([`vegan::nullmodel()`](https://vegandevs.github.io/vegan/reference/nullmodel.html),
  `"quasiswap_count"`).

## Examples

``` r
aravo <- data_aravo()
set.seed(1)
trait_ses(aravo$community, aravo$traits, abundance = cover, times = 49)
#> # A tibble: 75 × 8
#>    site  index null   observed null_mean null_sd    ses p.value
#>    <chr> <chr> <chr>     <dbl>     <dbl>   <dbl>  <dbl>   <dbl>
#>  1 AR01  RaoQ  traits    0.185     0.201  0.0147 -1.10     0.24
#>  2 AR02  RaoQ  traits    0.166     0.206  0.0188 -2.13     0.04
#>  3 AR03  RaoQ  traits    0.132     0.187  0.0269 -2.04     0.04
#>  4 AR04  RaoQ  traits    0.201     0.208  0.0166 -0.452    0.68
#>  5 AR05  RaoQ  traits    0.177     0.202  0.0159 -1.55     0.12
#>  6 AR06  RaoQ  traits    0.208     0.205  0.0129  0.254    0.84
#>  7 AR07  RaoQ  traits    0.156     0.197  0.0265 -1.55     0.16
#>  8 AR08  RaoQ  traits    0.192     0.205  0.0129 -1.05     0.32
#>  9 AR09  RaoQ  traits    0.173     0.197  0.0216 -1.12     0.32
#> 10 AR10  RaoQ  traits    0.151     0.201  0.0224 -2.26     0.08
#> # ℹ 65 more rows
```
