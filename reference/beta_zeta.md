# Zeta diversity: species shared by several sites at once

Zeta diversity (Hui and McGeoch 2014) is the mean number of species
shared by any `i` sites. Order 1 is mean richness, order 2 the mean
number shared by pairs, and so on, so the decline of zeta with order
shows how rare and common species contribute to turnover. The mean for
each order is computed exactly from the number of sites occupied by each
species, \\\zeta_i = \sum_j \binom{k_j}{i} / \binom{n}{i}\\, so no
sampling of site combinations is needed.

The shape of the decline is summarised by fitting an exponential form
(log zeta against order) and a power law (log zeta against log order);
an exponential decline points to turnover driven by chance (species
occupy sites independently), a power law to turnover structured by niche
or dispersal differences (Hui and McGeoch 2014). The fits are returned
by [`glance()`](https://generics.r-lib.org/reference/glance.html).

## Usage

``` r
beta_zeta(
  data,
  site = site,
  species = species,
  abundance = NULL,
  orders = NULL,
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

- orders:

  Orders of zeta to compute. Defaults to 1 to the number of sites, up to
  a maximum of 10.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_zeta` tibble with the grouping columns, `order`, `zeta` (mean
number of shared species), `ratio` (zeta of this order over the previous
one, the retention rate) and `zeta_simpson` (zeta scaled by the minimum
richness of the sites in each combination, from 0 to 1; found by
enumerating the combinations, so it is `NA` when an order has more than
5000 of them).
[`glance()`](https://generics.r-lib.org/reference/glance.html) gives one
row per group and model with `slope`, `r_squared` and `aic`.

## References

Hui, C. and McGeoch, M. A. (2014). Zeta diversity as a concept and
metric that unifies incidence-based biodiversity patterns. The American
Naturalist, 184, 684-694.
[doi:10.1086/678125](https://doi.org/10.1086/678125)

McGeoch, M. A., Latombe, G., Andrew, N. R., Nakagawa, S., Nipperess, D.
A., Roige, M., Marzinelli, E. M., Campbell, A. H., Verges, A., Thomas,
T., Steinberg, P. D., Selwood, K. E., Henriksen, M. C. and Hui, C.
(2019). Measuring continuous compositional change using decline and
decay in zeta diversity. Ecology, 100, e02832.
[doi:10.1002/ecy.2832](https://doi.org/10.1002/ecy.2832)

## Examples

``` r
z <- beta_zeta(png_ants, .by = season)
z
#> # A tibble: 10 × 5
#>    season order  zeta  ratio zeta_simpson
#>    <chr>  <int> <dbl>  <dbl>        <dbl>
#>  1 dry        1  11   NA           1     
#>  2 dry        2   1.7  0.155       0.168 
#>  3 dry        3   0.4  0.235       0.0521
#>  4 dry        4   0    0           0     
#>  5 dry        5   0   NA           0     
#>  6 wet        1  16.8 NA           1     
#>  7 wet        2   2.8  0.167       0.183 
#>  8 wet        3   0.7  0.25        0.05  
#>  9 wet        4   0.2  0.286       0.02  
#> 10 wet        5   0    0           0     
glance(z)
#> # A tibble: 4 × 5
#>   season model       slope r_squared   aic
#>   <chr>  <chr>       <dbl>     <dbl> <dbl>
#> 1 dry    exponential -1.66     0.995 0.642
#> 2 dry    power_law   -2.98     0.994 0.950
#> 3 wet    exponential -1.47     0.993 1.52 
#> 4 wet    power_law   -3.14     0.987 4.06 
```
