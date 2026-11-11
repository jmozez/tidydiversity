# Getting started with tidydiversity

tidydiversity brings biodiversity estimation into the tidyverse. Every
function takes a long data frame, with one row per site and species, and
returns a tibble you can filter, join and plot with the tools you
already use.

``` r
library(tidydiversity)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## The example data

tidydiversity ships with real field data from Papua New Guinea. The main
example, `png_ants`, records ground-foraging ants at nutrient baits
along the Mt Wilhelm elevational gradient, from 200 to 3700 m, in the
dry and the wet season (Moses et al. 2023, *Global Ecology and
Biogeography*). Each row is one ant species at one bait.

``` r
png_ants
#> # A tibble: 369 x 12
#>    site  elevation season transect bait  baits bait_type species genus subfamily
#>    <chr>     <int> <chr>     <int> <chr> <int> <chr>     <chr>   <chr> <chr>    
#>  1 MW02~       200 dry           1 200_~    60 cho       lepm_0~ Lept~ Dolichod~
#>  2 MW02~       200 dry           1 200_~    60 cho       mono_0~ Mono~ Myrmicin~
#>  3 MW02~       200 dry           1 200_~    60 lipid     phei_0~ Phei~ Myrmicin~
#>  4 MW02~       200 dry           1 200_~    60 lipid     tetr_0~ Tetr~ Myrmicin~
#>  5 MW02~       200 dry           1 200_~    60 amino_ac~ crem_0~ Crem~ Myrmicin~
#>  6 MW02~       200 dry           1 200_~    60 cho_amin~ crem_0~ Crem~ Myrmicin~
#>  7 MW02~       200 dry           1 200_~    60 lipid     crem_0~ Crem~ Myrmicin~
#>  8 MW02~       200 dry           1 200_~    60 cho       crem_0~ Crem~ Myrmicin~
#>  9 MW02~       200 dry           1 200_~    60 cho_amin~ rhyt_0~ Rhyt~ Ectatomm~
#> 10 MW02~       200 dry           1 200_~    60 cho       crem_0~ Crem~ Myrmicin~
#> # i 359 more rows
#> # i 2 more variables: guild <chr>, workers <int>
```

Ants recruit to baits, so worker counts measure activity rather than
independent individuals. `png_ants` therefore has no `abundance` column:
tidydiversity counts each row once, and diversity is estimated from the
number of baits at which each species was found.

Three more Papua New Guinea datasets cover other designs and taxa:

- `png_tree_ants`: every ant nest in 1254 trees in plots at 200, 900 and
  1800 m (Plowman et al. 2020).
- `png_frogs`: 3390 frogs of 55 species at eight elevations on Mt
  Wilhelm (Dahl et al. 2024).
- `wanang_butterflies`: butterflies counted on 36 days over three years
  in the Wanang forest dynamics plot (Luk et al. 2019).

## Tidy the community

[`as_community()`](https://tidydiversity.in4metrix.dev/reference/as_community.md)
sums repeated records, drops zeros and gives standard column names. Use
your own column names through the `site`, `species` and `abundance`
arguments.

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
#> # i 129 more rows
```

If your data arrive as a site by species matrix,
[`community_long()`](https://tidydiversity.in4metrix.dev/reference/as_community.md)
turns it into long format, and
[`community_wide()`](https://tidydiversity.in4metrix.dev/reference/as_community.md)
goes the other way.

``` r
wide <- community_wide(ants, .by = season)
wide[, 1:6]
#> # A tibble: 10 x 6
#>    season site   ancy_001 ancy_003 anon_003 anon_008
#>    <chr>  <chr>     <dbl>    <dbl>    <dbl>    <dbl>
#>  1 dry    MW0200        0        0        0        0
#>  2 dry    MW0700        0        0        0        0
#>  3 dry    MW1200        0        0        0        0
#>  4 dry    MW1700        0        0        2        0
#>  5 dry    MW2200        2        0        0        1
#>  6 wet    MW0200        0        0        0        0
#>  7 wet    MW0700        0        0        0        0
#>  8 wet    MW1200        0        1        0        0
#>  9 wet    MW1700        0        0        1        0
#> 10 wet    MW2200        8        0        0        0
```

## Grouping

All verbs accept `.by`, and they respect
[`group_by()`](https://rdrr.io/pkg/dplyr/man/group_by.html):

``` r
png_ants |>
  group_by(season) |>
  div_hill(q = 0) |>
  arrange(desc(diversity))
#> # A tibble: 10 x 5
#>    season site       q     n diversity
#>    <chr>  <chr>  <dbl> <dbl>     <dbl>
#>  1 wet    MW0700     0    58        28
#>  2 wet    MW0200     0    76        21
#>  3 wet    MW1200     0    57        20
#>  4 dry    MW0200     0    47        16
#>  5 dry    MW0700     0    23        15
#>  6 dry    MW1200     0    29        13
#>  7 wet    MW1700     0    34        10
#>  8 dry    MW2200     0    13         6
#>  9 dry    MW1700     0    17         5
#> 10 wet    MW2200     0    15         5
```

## What next

- [`vignette("alpha-rarefaction")`](https://tidydiversity.in4metrix.dev/articles/alpha-rarefaction.md)
  covers Hill numbers, asymptotic estimates and rarefaction.
- [`vignette("beta-partitioning")`](https://tidydiversity.in4metrix.dev/articles/beta-partitioning.md)
  covers turnover, nestedness, distance decay and beta diversity at
  equal sample coverage
  ([`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md)).
