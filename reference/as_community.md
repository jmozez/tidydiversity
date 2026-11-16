# Tidy community data

`as_community()` tidies long-format records into a community table with
one row per site and species, and standard column names `site`,
`species` and `abundance`. Repeated records are summed and zero counts
are dropped.

`community_wide()` pivots a community into a site by species matrix
stored as a tibble, and `community_long()` turns such a wide table back
into long format.

## Usage

``` r
as_community(
  data,
  site = site,
  species = species,
  abundance = NULL,
  .by = NULL
)

community_wide(
  data,
  site = site,
  species = species,
  abundance = NULL,
  fill = 0,
  .by = NULL
)

community_long(data, cols)
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

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

- fill:

  Value used for species absent from a site.

- cols:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  In `community_long()`, the species columns of a wide table.

## Value

`as_community()` returns a `td_community` tibble with the grouping
columns followed by `site`, `species` and `abundance`.

`community_wide()` returns a tibble with one column per species.
`community_long()` returns a `td_community`.

## Examples

``` r
ants <- as_community(png_ants, .by = season)
ants
#> # A community: 5 sites, 79 species, 369 individuals
#>    season site   species  abundance
#>    <chr>  <chr>  <chr>        <dbl>
#>  1 dry    MW0200 care_007         1
#>  2 dry    MW0200 crem_001         1
#>  3 dry    MW0200 crem_003         8
#>  4 dry    MW0200 lepm_001         3
#>  5 dry    MW0200 lepm_002         1
#>  6 dry    MW0200 mono_002         6
#>  7 dry    MW0200 mono_003         1
#>  8 dry    MW0200 odon_001         2
#>  9 dry    MW0200 para_005         4
#> 10 dry    MW0200 phei_008         3
#> # ℹ 129 more rows

wide <- community_wide(ants, .by = season)
wide
#> # A tibble: 10 × 81
#>    season site   ancy_001 ancy_003 anon_003 anon_008 anon_009 anon_012 anon_013
#>    <chr>  <chr>     <dbl>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>
#>  1 dry    MW0200        0        0        0        0        0        0        0
#>  2 dry    MW0700        0        0        0        0        0        0        0
#>  3 dry    MW1200        0        0        0        0        0        0        0
#>  4 dry    MW1700        0        0        2        0        0        0        0
#>  5 dry    MW2200        2        0        0        1        0        0        0
#>  6 wet    MW0200        0        0        0        0        0        0        0
#>  7 wet    MW0700        0        0        0        0        5        1        0
#>  8 wet    MW1200        0        1        0        0        1        3        1
#>  9 wet    MW1700        0        0        1        0        0        0        1
#> 10 wet    MW2200        8        0        0        0        0        0        0
#> # ℹ 72 more variables: anon_014 <dbl>, anop_001 <dbl>, apha_001 <dbl>,
#> #   camp_001 <dbl>, camp_034 <dbl>, camp_035 <dbl>, care_001 <dbl>,
#> #   care_002 <dbl>, care_003 <dbl>, care_007 <dbl>, crem_001 <dbl>,
#> #   crem_003 <dbl>, crem_010 <dbl>, crem_014 <dbl>, lepm_001 <dbl>,
#> #   lepm_002 <dbl>, mera_001 <dbl>, mera_002 <dbl>, mono_001 <dbl>,
#> #   mono_002 <dbl>, mono_003 <dbl>, mono_004 <dbl>, odon_001 <dbl>,
#> #   oeco_001 <dbl>, para_005 <dbl>, para_007 <dbl>, para_010 <dbl>, …

community_long(wide, -c(season, site))
#> # A community: 5 sites, 79 species, 369 individuals
#>    season site   species  abundance
#>    <chr>  <chr>  <chr>        <dbl>
#>  1 dry    MW0200 care_007         1
#>  2 dry    MW0200 crem_001         1
#>  3 dry    MW0200 crem_003         8
#>  4 dry    MW0200 lepm_001         3
#>  5 dry    MW0200 lepm_002         1
#>  6 dry    MW0200 mono_002         6
#>  7 dry    MW0200 mono_003         1
#>  8 dry    MW0200 odon_001         2
#>  9 dry    MW0200 para_005         4
#> 10 dry    MW0200 phei_008         3
#> # ℹ 129 more rows
```
