# Bootstrap replicates of diversity estimates

Returns the individual bootstrap replicates behind the standard errors
of
[`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md)
and
[`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md),
one row per site, order `q` and replicate. Each replicate is a
multinomial sample of the observed size drawn from the estimated
community, including undetected species, as in iNEXT (Chao et al. 2014).
Use the replicates to carry estimation uncertainty into downstream
models, for example by refitting a model to each replicate and pooling
the coefficients (see `vignette("modelling")`).

## Usage

``` r
div_boot(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = c(0, 1, 2),
  type = c("asymptotic", "standardised"),
  coverage = NULL,
  size = NULL,
  nboot = 100,
  .by = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- q:

  Orders of diversity: any of 0, 1 and 2.

- type:

  `"asymptotic"` for the asymptotic estimates of
  [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md),
  or `"standardised"` for diversity at a common coverage or size as in
  [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md).

- coverage:

  Target sample coverage between 0 and 1. If both `coverage` and `size`
  are `NULL`, a default coverage is chosen for each group.

- size:

  Target sample size. Supply either `coverage` or `size`.

- nboot:

  Number of bootstrap replicates.

- .by:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, the site column, `q`, `.draw`
(replicate number) and `diversity`. For `type = "standardised"`, also
`m`, the size each site was standardised to (fixed across replicates).

## Examples

``` r
set.seed(1)
draws <- div_boot(png_ants, q = 0, .by = season, nboot = 20)
draws
#> # A tibble: 200 × 5
#>    season site       q .draw diversity
#>    <chr>  <chr>  <dbl> <int>     <dbl>
#>  1 dry    MW0200     0     1      16.6
#>  2 dry    MW0200     0     2      16.0
#>  3 dry    MW0200     0     3      20.9
#>  4 dry    MW0200     0     4      31.6
#>  5 dry    MW0200     0     5      20.9
#>  6 dry    MW0200     0     6      19.1
#>  7 dry    MW0200     0     7      18.1
#>  8 dry    MW0200     0     8      20.4
#>  9 dry    MW0200     0     9      18.1
#> 10 dry    MW0200     0    10      16.6
#> # ℹ 190 more rows

# The bootstrap standard error of each site
dplyr::summarise(draws, se = sd(diversity), .by = c(season, site, q))
#> # A tibble: 10 × 4
#>    season site       q    se
#>    <chr>  <chr>  <dbl> <dbl>
#>  1 dry    MW0200     0  6.36
#>  2 wet    MW0200     0 11.0 
#>  3 dry    MW0700     0 24.6 
#>  4 wet    MW0700     0 32.1 
#>  5 dry    MW1200     0 12.7 
#>  6 wet    MW1200     0 15.0 
#>  7 dry    MW1700     0  1.81
#>  8 wet    MW1700     0 15.2 
#>  9 dry    MW2200     0  5.23
#> 10 wet    MW2200     0  3.67
```
