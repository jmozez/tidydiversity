# Shared species and similarity corrected for unseen species

For every pair of sites:

- `beta_shared()` estimates the total number of species the two sites
  share, including shared species that neither sample detected, with the
  Chao1-shared estimator for abundance data and the Chao2-shared
  estimator for incidence data (Chao et al. 2000; Pan et al. 2009).

- `beta_chao()` gives the abundance-based Jaccard and Sørensen
  similarities of Chao et al. (2005), which correct for shared species
  missed by incomplete samples, next to the classic indices.

Classic indices underestimate similarity when samples are incomplete,
because a species shared by two sites but rare in one of them is often
missed. The Chao versions estimate the probability that an individual of
one site belongs to a species shared with the other (`u`, `v`), adding
the shared species that were seen once in one sample. They are the
estimators of EstimateS and SpadeR; the values equal SpadeR's, and
`chao_jaccard` equals one minus vegan's `vegdist(method = "chao")`. This
is checked in the test suite.

## Usage

``` r
beta_shared(
  data,
  site = site,
  species = species,
  abundance = NULL,
  unit = NULL,
  n_units = NULL,
  .by = NULL
)

beta_chao(
  data,
  site = site,
  species = species,
  abundance = NULL,
  unit = NULL,
  n_units = NULL,
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

- unit:

  For incidence data, the column naming the sampling unit (a trap, bait,
  plot or survey day) in which each species was detected. Each site is
  then described by the number of units in which each species was found
  and the number of units sampled, and every estimate is incidence-based
  (Chao et al. 2014), for TD, PD and FD alike. Leave `NULL` for
  abundance data.

- n_units:

  For incidence data, a column giving the number of units sampled at
  each site, constant within a site. Use it when some units detected no
  species and so do not appear in the data. By default the number of
  distinct units in the data is used.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

`beta_shared()`: a tibble with the grouping columns, `site_1`, `site_2`,
`s_1`, `s_2` (observed richness), `observed` (observed shared species)
and `estimate`. `beta_chao()`: a tibble with `site_1`, `site_2`,
`jaccard`, `sorensen` (classic, on species lists), `u`, `v`,
`chao_jaccard` and `chao_sorensen` (similarities, 0-1).

## References

Chao, A., Hwang, W.-H., Chen, Y.-C. and Kuo, C.-Y. (2000). Estimating
the number of shared species in two communities. Statistica Sinica, 10,
227-246.

Chao, A., Chazdon, R. L., Colwell, R. K. and Shen, T.-J. (2005). A new
statistical approach for assessing similarity of species composition
with incidence and abundance data. Ecology Letters, 8, 148-159.
[doi:10.1111/j.1461-0248.2004.00707.x](https://doi.org/10.1111/j.1461-0248.2004.00707.x)

Pan, H.-Y., Chao, A. and Foissner, W. (2009). A nonparametric lower
bound for the number of species shared by multiple communities. Journal
of Agricultural, Biological and Environmental Statistics, 14, 452-468.

## Examples

``` r
beta_shared(png_ants, .by = season)
#> # A tibble: 20 × 7
#>    season site_1 site_2   s_1   s_2 observed estimate
#>    <chr>  <chr>  <chr>  <int> <int>    <int>    <dbl>
#>  1 dry    MW0200 MW0700    16    15        5    12.7 
#>  2 dry    MW0200 MW1200    16    13        3     4.25
#>  3 dry    MW0200 MW1700    16     5        1     1   
#>  4 dry    MW0200 MW2200    16     6        0     0   
#>  5 dry    MW0700 MW1200    15    13        5    29.2 
#>  6 dry    MW0700 MW1700    15     5        1     1   
#>  7 dry    MW0700 MW2200    15     6        1     1   
#>  8 dry    MW1200 MW1700    13     5        0     0   
#>  9 dry    MW1200 MW2200    13     6        1     1   
#> 10 dry    MW1700 MW2200     5     6        0     0   
#> 11 wet    MW0200 MW0700    21    28        8    28.8 
#> 12 wet    MW0200 MW1200    21    20        4     7   
#> 13 wet    MW0200 MW1700    21    10        1     1.25
#> 14 wet    MW0200 MW2200    21     5        0     0   
#> 15 wet    MW0700 MW1200    28    20        9    19   
#> 16 wet    MW0700 MW1700    28    10        1     1   
#> 17 wet    MW0700 MW2200    28     5        0     0   
#> 18 wet    MW1200 MW1700    20    10        4     9.5 
#> 19 wet    MW1200 MW2200    20     5        0     0   
#> 20 wet    MW1700 MW2200    10     5        1     1   
beta_chao(png_ants, .by = season)
#> # A tibble: 20 × 9
#>    season site_1 site_2 jaccard sorensen      u      v chao_jaccard
#>    <chr>  <chr>  <chr>    <dbl>    <dbl>  <dbl>  <dbl>        <dbl>
#>  1 dry    MW0200 MW0700  0.192    0.323  0.786  0.477        0.423 
#>  2 dry    MW0200 MW1200  0.115    0.207  0.202  0.431        0.159 
#>  3 dry    MW0200 MW1700  0.05     0.0952 0.170  0.118        0.0748
#>  4 dry    MW0200 MW2200  0        0      0      0            0     
#>  5 dry    MW0700 MW1200  0.217    0.357  0.406  1            0.406 
#>  6 dry    MW0700 MW1700  0.0526   0.1    0.0435 0.174        0.0360
#>  7 dry    MW0700 MW2200  0.05     0.0952 0.0435 0.455        0.0413
#>  8 dry    MW1200 MW1700  0        0      0      0            0     
#>  9 dry    MW1200 MW2200  0.0556   0.105  0.0345 0.456        0.0331
#> 10 dry    MW1700 MW2200  0        0      0      0            0     
#> 11 wet    MW0200 MW0700  0.195    0.327  0.660  1            0.660 
#> 12 wet    MW0200 MW1200  0.108    0.195  0.224  0.602        0.195 
#> 13 wet    MW0200 MW1700  0.0333   0.0645 0.0195 0.0439       0.0137
#> 14 wet    MW0200 MW2200  0        0      0      0            0     
#> 15 wet    MW0700 MW1200  0.231    0.375  0.634  0.681        0.489 
#> 16 wet    MW0700 MW1700  0.0270   0.0526 0.0512 0.0294       0.0190
#> 17 wet    MW0700 MW2200  0        0      0      0            0     
#> 18 wet    MW1200 MW1700  0.154    0.267  0.405  0.992        0.404 
#> 19 wet    MW1200 MW2200  0        0      0      0            0     
#> 20 wet    MW1700 MW2200  0.0714   0.133  0.265  0.2          0.129 
#> # ℹ 1 more variable: chao_sorensen <dbl>
```
