# Distance decay of similarity

Pairs the pairwise beta diversity from
[`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
with the distance between sites along a gradient, such as elevation, to
study how dissimilarity and its components change with distance.

## Usage

``` r
beta_decay(
  data,
  gradient,
  site = site,
  species = species,
  abundance = NULL,
  index = c("sorensen", "jaccard", "bray"),
  .by = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- gradient:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  One or more numeric site attributes, constant within each site. With
  one column (such as `elevation`) the distance is the absolute
  difference; with several (such as `c(x, y)` coordinates) it is the
  Euclidean distance.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- index:

  Family of dissimilarity: `"sorensen"` or `"jaccard"` (presence and
  absence) or `"bray"` (abundance-based Bray-Curtis).

- .by:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_beta_decay` tibble like the output of
[`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md),
with `distance` and, for a single gradient column, `gradient_1` and
`gradient_2`. Use
[`ggplot2::autoplot()`](https://rdrr.io/pkg/ggplot2/man/autoplot.html)
to plot it.

## Examples

``` r
decay <- beta_decay(png_ants, gradient = elevation, .by = season)
decay
#> # A tibble: 20 x 9
#>    season site_1 site_2 turnover nestedness total gradient_1 gradient_2 distance
#>    <chr>  <chr>  <chr>     <dbl>      <dbl> <dbl>      <int>      <int>    <dbl>
#>  1 dry    MW0200 MW0700    0.667    0.0108  0.677        200        700      500
#>  2 dry    MW0200 MW1200    0.769    0.0239  0.793        200       1200     1000
#>  3 dry    MW0200 MW1700    0.8      0.105   0.905        200       1700     1500
#>  4 dry    MW0200 MW2200    1        0       1            200       2200     2000
#>  5 dry    MW0700 MW1200    0.615    0.0275  0.643        700       1200      500
#>  6 dry    MW0700 MW1700    0.8      0.1     0.9          700       1700     1000
#>  7 dry    MW0700 MW2200    0.833    0.0714  0.905        700       2200     1500
#>  8 dry    MW1200 MW1700    1        0       1           1200       1700      500
#>  9 dry    MW1200 MW2200    0.833    0.0614  0.895       1200       2200     1000
#> 10 dry    MW1700 MW2200    1        0       1           1700       2200      500
#> 11 wet    MW0200 MW0700    0.619    0.0544  0.673        200        700      500
#> 12 wet    MW0200 MW1200    0.8      0.00488 0.805        200       1200     1000
#> 13 wet    MW0200 MW1700    0.9      0.0355  0.935        200       1700     1500
#> 14 wet    MW0200 MW2200    1        0       1            200       2200     2000
#> 15 wet    MW0700 MW1200    0.55     0.075   0.625        700       1200      500
#> 16 wet    MW0700 MW1700    0.9      0.0474  0.947        700       1700     1000
#> 17 wet    MW0700 MW2200    1        0       1            700       2200     1500
#> 18 wet    MW1200 MW1700    0.6      0.133   0.733       1200       1700      500
#> 19 wet    MW1200 MW2200    1        0       1           1200       2200     1000
#> 20 wet    MW1700 MW2200    0.8      0.0667  0.867       1700       2200      500
```
