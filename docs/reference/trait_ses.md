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
  ([`vegan::nullmodel()`](https://rdrr.io/pkg/vegan/man/nullmodel.html),
  `"quasiswap_count"`).

## Examples

``` r
aravo <- data_aravo()
set.seed(1)
trait_ses(aravo$community, aravo$traits, abundance = cover, times = 49)
#> # A tibble: 75 x 8
#>    site  index null   observed null_mean null_sd    ses p.value
#>    <chr> <chr> <chr>     <dbl>     <dbl>   <dbl>  <dbl>   <dbl>
#>  1 AR26  RaoQ  traits    0.186     0.201  0.0147 -1.00     0.4 
#>  2 AR22  RaoQ  traits    0.192     0.207  0.0134 -1.13     0.36
#>  3 AR28  RaoQ  traits    0.189     0.203  0.0170 -0.827    0.56
#>  4 AR01  RaoQ  traits    0.185     0.201  0.0147 -1.10     0.24
#>  5 AR23  RaoQ  traits    0.184     0.202  0.0189 -0.925    0.44
#>  6 AR08  RaoQ  traits    0.192     0.205  0.0129 -1.05     0.32
#>  7 AR12  RaoQ  traits    0.185     0.200  0.0133 -1.14     0.2 
#>  8 AR61  RaoQ  traits    0.190     0.205  0.0146 -1.02     0.48
#>  9 AR49  RaoQ  traits    0.207     0.202  0.0177  0.250    0.88
#> 10 AR50  RaoQ  traits    0.204     0.203  0.0166  0.111    0.92
#> # i 65 more rows
```
