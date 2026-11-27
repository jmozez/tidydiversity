# Classic species richness estimators

`div_richness()` gives the non-parametric richness estimators of
EstimateS (Colwell 2013) and SpadeR (Chao et al. 2016) for every site,
with bootstrap standard errors and log-normal confidence intervals.

For abundance data (counts of individuals):

- `chao1`: Chao (1984), with the small-sample factor (n - 1)/n.

- `chao1_bc`: the bias-corrected Chao1, finite even without doubletons.

- `ichao1`: the improved Chao1 of Chiu et al. (2014), which also uses
  tripletons and quadrupletons.

- `ace`, `ace1`: the abundance-based coverage estimators of Chao and Lee
  (1992); species seen more than `k` times are "abundant" and counted as
  observed.

- `jack1`, `jack2`: first- and second-order jackknife (Burnham and
  Overton 1978).

For incidence data (detections in sampling units, given with `unit`):

- `chao2`, `chao2_bc`, `ichao2`: the incidence versions of the above.

- `ice`, `ice1`: the incidence-based coverage estimators of Lee and Chao
  (1994), with the improved coverage estimate of Chao et al. (2016).

- `jack1`, `jack2`: jackknife estimators on sampling units.

- `bootstrap`: the bootstrap estimator of Smith and van Belle (1984).

Point estimates equal those of SpadeR (and of vegan's `estimateR()` and
`specpool()` where they compute the same estimator); this is checked in
the test suite. Standard errors come from `nboot` bootstrap samples of
the estimated community, as in
[`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md),
so every estimator has one.

Which to report? Chao1/Chao2 are lower bounds with good statistical
properties and are the usual choice; iChao1/iChao2 are less biased when
many species are rare. ACE/ICE and the jackknives are given for
comparison with older studies. For comparing sites, prefer
coverage-standardised diversity
([`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md)).

## Usage

``` r
div_richness(
  data,
  site = site,
  species = species,
  abundance = NULL,
  unit = NULL,
  n_units = NULL,
  estimator = NULL,
  k = 10,
  conf = 0.95,
  nboot = 100,
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

- estimator:

  Estimators to compute; by default all for the data type.

- k:

  Cut-off for rare (ACE) or infrequent (ICE) species.

- conf:

  Confidence level of the intervals.

- nboot:

  Number of bootstrap samples for the standard errors (0 for none).

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, the site column, `estimator`,
`observed`, `estimate`, `se`, `lower` and `upper`.

## References

Burnham, K. P. and Overton, W. S. (1978). Estimation of the size of a
closed population when capture probabilities vary among animals.
Biometrika, 65, 625-633.

Chao, A. (1984). Nonparametric estimation of the number of classes in a
population. Scandinavian Journal of Statistics, 11, 265-270.

Chao, A. and Lee, S.-M. (1992). Estimating the number of classes via
sample coverage. Journal of the American Statistical Association, 87,
210-217.

Chao, A., Ma, K. H., Hsieh, T. C. and Chiu, C.-H. (2016). SpadeR:
Species-richness prediction and diversity estimation with R. R package.

Chiu, C.-H., Wang, Y.-T., Walther, B. A. and Chao, A. (2014). An
improved nonparametric lower bound of species richness via a modified
Good-Turing frequency formula. Biometrics, 70, 671-682.
[doi:10.1111/biom.12200](https://doi.org/10.1111/biom.12200)

Colwell, R. K. (2013). EstimateS: Statistical estimation of species
richness and shared species from samples. Version 9.

Lee, S.-M. and Chao, A. (1994). Estimating population size via sample
coverage for closed capture-recapture models. Biometrics, 50, 88-97.

Smith, E. P. and van Belle, G. (1984). Nonparametric estimation of
species richness. Biometrics, 40, 119-129.

## Examples

``` r
div_richness(png_ants, .by = season, nboot = 20)
#> # A tibble: 70 × 8
#>    season site   estimator observed estimate    se lower upper
#>    <chr>  <chr>  <chr>        <int>    <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200 chao1           16     18.4  6.16  16.2  54.9
#>  2 dry    MW0200 chao1_bc        16     17.6  3.12  16.1  34.6
#>  3 dry    MW0200 ichao1          16     18.4  6.77  16.1  59.6
#>  4 dry    MW0200 ace             16     20.5  3.16  17.3  31.5
#>  5 dry    MW0200 ace1            16     21.6  4.30  17.5  37.3
#>  6 dry    MW0200 jack1           16     20.9  2.62  17.8  29.1
#>  7 dry    MW0200 jack2           16     21.0  4.21  17.2  37.0
#>  8 dry    MW0700 chao1           15     83.9 21.5   52.9 140. 
#>  9 dry    MW0700 chao1_bc        15     46.6 21.1   24.6 119. 
#> 10 dry    MW0700 ichao1          15     86.7 22.2   54.6 145. 
#> # ℹ 60 more rows
div_richness(png_ants, unit = bait, n_units = baits, .by = season, nboot = 20)
#> # A tibble: 80 × 8
#>    season site   estimator observed estimate    se lower upper
#>    <chr>  <chr>  <chr>        <int>    <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200 chao2           16     18.5  4.95  16.2  45.8
#>  2 dry    MW0200 chao2_bc        16     17.6  3.28  16.1  35.7
#>  3 dry    MW0200 ichao2          16     18.5  5.67  16.2  50.9
#>  4 dry    MW0200 ice             16     20.5  4.51  16.9  39.1
#>  5 dry    MW0200 ice1            16     21.7  7.48  16.8  56.5
#>  6 dry    MW0200 jack1           16     20.9  2.76  17.8  29.7
#>  7 dry    MW0200 jack2           16     21.0  5.46  16.9  44.4
#>  8 dry    MW0200 bootstrap       16     18.6  1.68  16.8  24.3
#>  9 dry    MW0700 chao2           15     85.8 43.2   38.5 228. 
#> 10 dry    MW0700 chao2_bc        15     47.4 40.6   19.8 232. 
#> # ℹ 70 more rows
```
