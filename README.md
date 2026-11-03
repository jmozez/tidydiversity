
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

## Gallery

Every plot that `autoplot()` draws, using the simulated `ant_gradient`
data.

### Rarefaction and extrapolation by sample size

Solid lines are rarefied, dashed lines extrapolated to twice the sample
size; points are the observed samples (north transect).

<img src="man/figures/README-size-1.png" alt="Rarefaction and extrapolation by sample size" width="100%" />

### Rarefaction and extrapolation by sample coverage

The same curves plotted against estimated sample coverage, the basis for
coverage-standardised comparison.

<img src="man/figures/README-coverage-curve-1.png" alt="Rarefaction and extrapolation by sample coverage" width="100%" />

### Hill diversity profile

Observed Hill numbers across orders q from 0 (richness) to 3 (dominant
species), one line per site.

<img src="man/figures/README-profile-1.png" alt="Hill diversity profile" width="100%" />

### Alpha diversity along elevation

Observed q = 0, 1 and 2 diversity at each elevation, one line per
transect.

<img src="man/figures/README-elevation-1.png" alt="Alpha diversity along elevation" width="100%" />

### Observed and asymptotic diversity

Open circles are observed values, filled circles the asymptotic
estimates, with 95% bootstrap intervals.

<img src="man/figures/README-estimate-1.png" alt="Observed and asymptotic diversity" width="100%" />

### Sample coverage

Estimated sample coverage of each site against its number of
individuals.

<img src="man/figures/README-sample-coverage-1.png" alt="Sample coverage" width="100%" />

### Pairwise beta diversity heatmap

Total Sorensen dissimilarity between every pair of sites within each
transect.

<img src="man/figures/README-beta-pair-1.png" alt="Pairwise beta diversity heatmap" width="100%" />

### Multi-site beta partition

Multi-site Sorensen dissimilarity of each transect split into turnover
and nestedness.

<img src="man/figures/README-beta-multi-1.png" alt="Multi-site beta partition" width="100%" />

### Distance decay

Pairwise total, turnover and nestedness dissimilarity against elevation
difference, with linear trends.

<img src="man/figures/README-beta-decay-1.png" alt="Distance decay" width="100%" />

## Output tables

Example output of every main function on the simulated data. Long tables
show their first rows.

### `div_hill()`

Observed Hill numbers: `n` individuals, `diversity` of order `q` per
site.

| transect | site   |   q |   n | diversity |
|:---------|:-------|----:|----:|----------:|
| north    | n_0200 |   0 | 137 |    15.000 |
| north    | n_0200 |   1 | 137 |     7.122 |
| north    | n_0200 |   2 | 137 |     4.801 |
| north    | n_0400 |   0 | 116 |    19.000 |
| north    | n_0400 |   1 | 116 |    11.138 |
| north    | n_0400 |   2 | 116 |     7.442 |
| north    | n_0600 |   0 |  77 |    20.000 |
| north    | n_0600 |   1 |  77 |    12.686 |

### `div_estimate()`

Asymptotic estimates: `observed` and `estimate` Hill numbers with
bootstrap `se`, `lower` and `upper` 95% limits.

| transect | site   |   q | observed | estimate |     se |  lower |   upper |
|:---------|:-------|----:|---------:|---------:|-------:|-------:|--------:|
| north    | n_0200 |   0 |   15.000 |   24.927 |  8.706 | 17.259 |  58.625 |
| north    | n_0200 |   1 |    7.122 |    7.781 |  0.690 |  7.122 |   9.132 |
| north    | n_0200 |   2 |    4.801 |    4.940 |  0.466 |  4.801 |   5.853 |
| north    | n_0400 |   0 |   19.000 |   25.196 | 10.103 | 19.665 |  76.750 |
| north    | n_0400 |   1 |   11.138 |   12.470 |  1.372 | 11.138 |  15.159 |
| north    | n_0400 |   2 |    7.442 |    7.884 |  1.146 |  7.442 |  10.130 |
| north    | n_0600 |   0 |   20.000 |   59.974 | 31.751 | 30.150 | 177.429 |
| north    | n_0600 |   1 |   12.686 |   17.134 |  4.002 | 12.686 |  24.977 |

### `div_coverage()`

Sample coverage: `n` individuals, `s_obs` observed species, `f1`
singletons, `f2` doubletons and estimated `coverage`.

| transect | site   |   n | s_obs |  f1 |  f2 | coverage |
|:---------|:-------|----:|------:|----:|----:|---------:|
| north    | n_0200 | 137 |    15 |   5 |   0 |    0.964 |
| north    | n_0400 | 116 |    19 |   5 |   2 |    0.957 |
| north    | n_0600 |  77 |    20 |   9 |   1 |    0.883 |
| north    | n_0800 | 118 |    20 |   8 |   2 |    0.932 |
| north    | n_1000 |  74 |    19 |   9 |   4 |    0.880 |
| north    | n_1200 |  73 |    20 |   7 |   5 |    0.906 |
| north    | n_1400 |  76 |    10 |   3 |   3 |    0.962 |
| north    | n_1600 |  37 |    11 |   5 |   1 |    0.866 |

### `div_rarefy()`

Rarefaction and extrapolation: diversity of order `q` at sample size
`m`, whether `method` is rarefaction, observed or extrapolation, the
expected `coverage`, and `lower` and `upper` limits (`NA` when
`nboot = 0`).

| site   |   q |   m | method        | diversity | coverage | lower | upper |
|:-------|----:|----:|:--------------|----------:|---------:|------:|------:|
| n_0200 |   0 |   1 | rarefaction   |     1.000 |    0.202 |    NA |    NA |
| n_0200 |   0 |  68 | rarefaction   |    12.096 |    0.944 |    NA |    NA |
| n_0200 |   0 | 136 | rarefaction   |    14.964 |    0.964 |    NA |    NA |
| n_0200 |   0 | 137 | observed      |    15.000 |    0.964 |    NA |    NA |
| n_0200 |   0 | 138 | extrapolation |    15.036 |    0.964 |    NA |    NA |
| n_0200 |   0 | 183 | extrapolation |    16.542 |    0.969 |    NA |    NA |
| n_0200 |   0 | 228 | extrapolation |    17.818 |    0.974 |    NA |    NA |
| n_0200 |   0 | 274 | extrapolation |    18.923 |    0.978 |    NA |    NA |

### `div_standardise()`

Coverage standardisation: `diversity` of order `q` at a common
`coverage` for every site, with the matching sample size `m`, the
`method` used, and bootstrap `se`, `lower` and `upper` limits.

| transect | site   |   q |       m | method        | coverage | diversity |    se |  lower |  upper |
|:---------|:-------|----:|--------:|:--------------|---------:|----------:|------:|-------:|-------:|
| north    | n_0200 |   0 |  38.396 | rarefaction   |      0.9 |     9.895 | 0.594 |  8.730 | 11.060 |
| north    | n_0200 |   1 |  38.396 | rarefaction   |      0.9 |     6.147 | 0.478 |  5.211 |  7.084 |
| north    | n_0200 |   2 |  38.396 | rarefaction   |      0.9 |     4.480 | 0.377 |  3.740 |  5.220 |
| north    | n_0400 |   0 |  53.281 | rarefaction   |      0.9 |    15.037 | 1.020 | 13.038 | 17.036 |
| north    | n_0400 |   1 |  53.281 | rarefaction   |      0.9 |     9.946 | 0.852 |  8.276 | 11.616 |
| north    | n_0400 |   2 |  53.281 | rarefaction   |      0.9 |     6.982 | 0.881 |  5.256 |  8.708 |
| north    | n_0600 |   0 | 129.431 | extrapolation |      0.9 |    25.674 | 4.709 | 16.445 | 34.903 |
| north    | n_0600 |   1 | 129.431 | extrapolation |      0.9 |    14.059 | 2.196 |  9.755 | 18.363 |

### `beta_pair()`

Pairwise beta diversity: Sorensen `turnover` (Simpson) and `nestedness`
components, which sum to `total` dissimilarity.

| transect | site_1 | site_2 | turnover | nestedness | total |
|:---------|:-------|:-------|---------:|-----------:|------:|
| north    | n_0200 | n_0400 |    0.200 |      0.094 | 0.294 |
| north    | n_0200 | n_0600 |    0.467 |      0.076 | 0.543 |
| north    | n_0200 | n_0800 |    0.600 |      0.057 | 0.657 |
| north    | n_0200 | n_1000 |    0.600 |      0.047 | 0.647 |
| north    | n_0200 | n_1200 |    0.533 |      0.067 | 0.600 |
| north    | n_0200 | n_1400 |    0.800 |      0.040 | 0.840 |
| north    | n_0200 | n_1600 |    0.818 |      0.028 | 0.846 |
| north    | n_0400 | n_0600 |    0.368 |      0.016 | 0.385 |

### `beta_multi()`

Multi-site beta diversity: `n_sites` in each group with the multi-site
`turnover`, `nestedness` and `total`.

| transect | n_sites | turnover | nestedness | total |
|:---------|--------:|---------:|-----------:|------:|
| north    |       8 |    0.674 |      0.060 | 0.733 |
| south    |       8 |    0.660 |      0.078 | 0.738 |

### `beta_decay()`

Distance decay: the pairwise components plus each site’s `gradient_1`
and `gradient_2` values and their `distance`.

| transect | site_1 | site_2 | turnover | nestedness | total | gradient_1 | gradient_2 | distance |
|:---------|:-------|:-------|---------:|-----------:|------:|-----------:|-----------:|---------:|
| north    | n_0200 | n_0400 |    0.200 |      0.094 | 0.294 |        200 |        400 |      200 |
| north    | n_0200 | n_0600 |    0.467 |      0.076 | 0.543 |        200 |        600 |      400 |
| north    | n_0200 | n_0800 |    0.600 |      0.057 | 0.657 |        200 |        800 |      600 |
| north    | n_0200 | n_1000 |    0.600 |      0.047 | 0.647 |        200 |       1000 |      800 |
| north    | n_0200 | n_1200 |    0.533 |      0.067 | 0.600 |        200 |       1200 |     1000 |
| north    | n_0200 | n_1400 |    0.800 |      0.040 | 0.840 |        200 |       1400 |     1200 |
| north    | n_0200 | n_1600 |    0.818 |      0.028 | 0.846 |        200 |       1600 |     1400 |
| north    | n_0400 | n_0600 |    0.368 |      0.016 | 0.385 |        400 |        600 |      200 |

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
