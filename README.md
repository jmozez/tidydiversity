
# tidydiversity <a href="https://jmozez.github.io/tidydiversity/"><img src="man/figures/logo.png" align="right" height="139" alt="tidydiversity website" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/jmozez/tidydiversity/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jmozez/tidydiversity/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/jmozez/tidydiversity/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/jmozez/tidydiversity/actions/workflows/test-coverage.yaml)
[![lint](https://github.com/jmozez/tidydiversity/actions/workflows/lint.yaml/badge.svg)](https://github.com/jmozez/tidydiversity/actions/workflows/lint.yaml)
[![pkgdown](https://github.com/jmozez/tidydiversity/actions/workflows/pkgdown.yaml/badge.svg)](https://jmozez.github.io/tidydiversity/)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/jmozez/tidydiversity/blob/main/LICENSE.md)
<!-- badges: end -->

tidydiversity brings biodiversity estimation into the tidyverse. It
computes Hill numbers, asymptotic estimates, sample coverage,
rarefaction and extrapolation, and turnover and nestedness partitions of
beta diversity, all from a long data frame and all returning tibbles.

- **Tidy in, tidy out.** One row per site and species goes in, a tibble
  comes out.
- **Data-masking.** Name your columns with `site`, `species` and
  `abundance`, as you would in dplyr.
- **Grouping.** Every verb takes `.by` and respects `group_by()`.
- **Checked.** Estimates match iNEXT and betapart in the test suite.

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("jmozez/tidydiversity")
```

## Example

`ant_gradient` is a simulated dataset of ants along two elevational
transects, made for examples. It is not field data.

``` r
library(tidydiversity)
library(dplyr)

div_hill(ant_gradient, q = c(0, 1, 2), .by = transect)
#> # A tibble: 48 × 5
#>    transect site       q     n diversity
#>    <chr>    <chr>  <dbl> <int>     <dbl>
#>  1 north    n_0200     0   137     15   
#>  2 north    n_0200     1   137      7.12
#>  3 north    n_0200     2   137      4.80
#>  4 north    n_0400     0   116     19   
#>  5 north    n_0400     1   116     11.1 
#>  6 north    n_0400     2   116      7.44
#>  7 north    n_0600     0    77     20   
#>  8 north    n_0600     1    77     12.7 
#>  9 north    n_0600     2    77      9.11
#> 10 north    n_0800     0   118     20   
#> # ℹ 38 more rows
```

Compare sites at equal sample completeness:

``` r
set.seed(1)
div_standardise(ant_gradient, coverage = 0.9, .by = transect, nboot = 50) |>
  filter(q == 0)
#> # A tibble: 16 × 10
#>    transect site       q     m method       coverage diversity    se lower upper
#>    <chr>    <chr>  <dbl> <dbl> <chr>           <dbl>     <dbl> <dbl> <dbl> <dbl>
#>  1 north    n_0200     0  38.4 rarefaction     0.900      9.89 0.594  8.73 11.1 
#>  2 north    n_0400     0  53.3 rarefaction     0.900     15.0  1.02  13.0  17.0 
#>  3 north    n_0600     0 129.  extrapolati…    0.900     25.7  4.71  16.4  34.9 
#>  4 north    n_0800     0  64.8 rarefaction     0.900     15.7  1.63  12.6  18.9 
#>  5 north    n_1000     0  89.2 extrapolati…    0.900     20.7  2.24  16.3  25.1 
#>  6 north    n_1200     0  69.9 rarefaction     0.900     19.7  1.44  16.9  22.5 
#>  7 north    n_1400     0  28.6 rarefaction     0.900      6.89 0.864  5.19  8.58
#>  8 north    n_1600     0  63.2 extrapolati…    0.900     14.1  2.80   8.58 19.5 
#>  9 south    s_0200     0  50.0 rarefaction     0.900     13.2  0.864 11.5  14.9 
#> 10 south    s_0400     0  55.8 extrapolati…    0.900     17.6  1.47  14.8  20.5 
#> 11 south    s_0600     0  72.5 rarefaction     0.900     14.6  1.46  11.7  17.4 
#> 12 south    s_0800     0 103.  extrapolati…    0.900     23.4  3.57  16.5  30.4 
#> 13 south    s_1000     0  53.9 rarefaction     0.900      9.35 1.12   7.15 11.6 
#> 14 south    s_1200     0  35.2 extrapolati…    0.900     13.1  1.31  10.6  15.7 
#> 15 south    s_1400     0  19.3 rarefaction     0.900      5.71 0.395  4.94  6.49
#> 16 south    s_1600     0  12.1 rarefaction     0.900      3.61 0.260  3.10  4.12
```

Draw rarefaction and extrapolation curves:

``` r
library(ggplot2)
ant_gradient |>
  filter(transect == "north") |>
  div_rarefy(q = c(0, 1)) |>
  autoplot()
```

<img src="man/figures/README-curves-1.png" alt="Rarefaction curves" width="100%" />

Split beta diversity into turnover and nestedness:

``` r
beta_multi(ant_gradient, .by = transect)
#> # A tibble: 2 × 5
#>   transect n_sites turnover nestedness total
#>   <chr>      <int>    <dbl>      <dbl> <dbl>
#> 1 north          8    0.674     0.0596 0.733
#> 2 south          8    0.660     0.0776 0.738
```

## Functions

| Task                             | Function                                                 |
|----------------------------------|----------------------------------------------------------|
| Tidy community data              | `as_community()`, `community_wide()`, `community_long()` |
| Observed Hill numbers            | `div_hill()`                                             |
| Asymptotic estimates             | `div_estimate()`                                         |
| Sample coverage                  | `div_coverage()`                                         |
| Rarefaction and extrapolation    | `div_rarefy()`                                           |
| Coverage or size standardisation | `div_standardise()`                                      |
| Beta partitioning                | `beta_pair()`, `beta_multi()`, `beta_decay()`            |
| Plots                            | `autoplot()`                                             |

## References

- Chao, A. et al. (2014). Rarefaction and extrapolation with Hill
  numbers. *Ecological Monographs*, 84, 45-67.
- Chao, A. and Jost, L. (2012). Coverage-based rarefaction and
  extrapolation. *Ecology*, 93, 2533-2547.
- Baselga, A. (2010). Partitioning the turnover and nestedness
  components of beta diversity. *Global Ecology and Biogeography*, 19,
  134-143.

## Licence

MIT © Jimmy Moses
