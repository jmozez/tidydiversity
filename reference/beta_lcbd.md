# Local and species contributions to beta diversity

`beta_lcbd()` measures how unusual the composition of each site is: its
local contribution to beta diversity (LCBD), with a permutation test.
`beta_scbd()` gives the matching species contributions (SCBD), the
species that vary most among sites. Both follow Legendre and De Caceres
(2013): the community table is transformed, total beta diversity is the
total sum of squares of the transformed table, and each site (row) and
species (column) takes its share of that sum. They reproduce
`adespatial::beta.div()`.

## Usage

``` r
beta_lcbd(
  data,
  site = site,
  species = species,
  abundance = NULL,
  transform = c("hellinger", "chord", "profiles", "presence", "none"),
  nperm = 999,
  .by = NULL
)

beta_scbd(
  data,
  site = site,
  species = species,
  abundance = NULL,
  transform = c("hellinger", "chord", "profiles", "presence", "none"),
  .by = NULL
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

- transform:

  Transformation of the abundances before the sums of squares are taken:
  `"hellinger"` (default), `"chord"`, `"profiles"` (relative
  abundances), `"presence"` (presence and absence) or `"none"`.
  Hellinger and chord give dissimilarities suited to community data
  (Legendre and De Caceres 2013).

- nperm:

  Number of permutations for the test of each LCBD. Each species column
  is permuted independently. Use `0` to skip the test.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

`beta_lcbd()` returns a `td_lcbd` tibble with the grouping columns, the
site column, `lcbd`, `p_value` and `p_adjusted` (Holm), plus `ss_total`
and `bd_total` (total beta diversity) for the group. `beta_scbd()`
returns a tibble with the grouping columns, `species` and `scbd`,
largest first.

## References

Legendre, P. and De Caceres, M. (2013). Beta diversity as the variance
of community data: dissimilarity coefficients and partitioning. Ecology
Letters, 16, 951-963.
[doi:10.1111/ele.12141](https://doi.org/10.1111/ele.12141)

## Examples

``` r
set.seed(1)
beta_lcbd(png_ants, .by = season, nperm = 99)
#> # A tibble: 10 × 7
#>    season site    lcbd p_value p_adjusted ss_total bd_total
#>    <chr>  <chr>  <dbl>   <dbl>      <dbl>    <dbl>    <dbl>
#>  1 dry    MW0200 0.181    0.58          1     3.49    0.873
#>  2 dry    MW0700 0.168    0.7           1     3.49    0.873
#>  3 dry    MW1200 0.184    0.59          1     3.49    0.873
#>  4 dry    MW1700 0.234    0.29          1     3.49    0.873
#>  5 dry    MW2200 0.233    0.3           1     3.49    0.873
#>  6 wet    MW0200 0.197    0.51          1     3.38    0.845
#>  7 wet    MW0700 0.175    0.57          1     3.38    0.845
#>  8 wet    MW1200 0.165    0.64          1     3.38    0.845
#>  9 wet    MW1700 0.217    0.38          1     3.38    0.845
#> 10 wet    MW2200 0.246    0.22          1     3.38    0.845

beta_scbd(png_ants, .by = season)
#> # A tibble: 104 × 3
#>    season species    scbd
#>    <chr>  <chr>     <dbl>
#>  1 dry    phei_057 0.108 
#>  2 dry    prol_004 0.0705
#>  3 dry    phei_019 0.0594
#>  4 dry    phil_001 0.0589
#>  5 dry    rhyt_001 0.0575
#>  6 dry    tetr_026 0.0539
#>  7 dry    rhyt_002 0.0417
#>  8 dry    crem_003 0.0390
#>  9 dry    ancy_001 0.0353
#> 10 dry    mono_002 0.0343
#> # ℹ 94 more rows
```
