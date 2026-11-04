
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

<div class="td-hero">

**Taxonomic, phylogenetic and functional diversity on one scale, in one
tidy workflow.**

Reviewers increasingly expect taxonomic (TD), phylogenetic (PD) and
functional (FD) diversity to be reported together and to be comparable.
tidydiversity expresses all three as Hill numbers of the same order q,
in units of effective numbers of species, and standardises them by
sample size or sample coverage. Data go in as a long data frame and
results come back as tibbles.

</div>

<div class="td-cards">

<div class="td-card">

### Taxonomic (TD)

Species counts only. Observed and asymptotic Hill numbers, sample
coverage, rarefaction and extrapolation, matching iNEXT.

</div>

<div class="td-card">

### Phylogenetic (PD)

Add a phylogeny with `type = "PD", tree = tree`. Effective number of
lineages at a reference time, matching iNEXT.3D.

</div>

<div class="td-card">

### Functional (FD)

Add a trait distance matrix with `type = "FD", distance = d`. Effective
number of functionally distinct species at a threshold tau, or the area
under the tau profile, matching iNEXT.3D.

</div>

</div>

- **Tidy in, tidy out.** One row per site and species goes in, a tibble
  comes out.
- **Data-masking.** Name your columns with `site`, `species` and
  `abundance`, as you would in dplyr.
- **Grouping.** Every verb takes `.by` and respects `group_by()`.
- **Checked.** Estimates match iNEXT, iNEXT.3D and betapart in the test
  suite.

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("jmozez/tidydiversity")
```

## Example

`png_ants` records ground-foraging ants at nutrient baits along the Mt
Wilhelm elevational gradient in Papua New Guinea, in the dry and the wet
season (Moses et al. 2023). Each row is one species at one bait, so
diversity is estimated from the number of baits at which each species
was found.

``` r
library(tidydiversity)
library(dplyr)

div_hill(png_ants, q = c(0, 1, 2), .by = season)
#> # A tibble: 30 x 5
#>    season site       q     n diversity
#>    <chr>  <chr>  <dbl> <dbl>     <dbl>
#>  1 dry    MW0200     0    47     16   
#>  2 dry    MW0200     1    47     12.3 
#>  3 dry    MW0200     2    47      9.91
#>  4 wet    MW0200     0    76     21   
#>  5 wet    MW0200     1    76     10.9 
#>  6 wet    MW0200     2    76      6.99
#>  7 dry    MW0700     0    23     15   
#>  8 dry    MW0700     1    23     11.8 
#>  9 dry    MW0700     2    23      8.67
#> 10 wet    MW0700     0    58     28   
#> # i 20 more rows
```

Compare sites at equal sample completeness. By default each season is
standardised to the lowest coverage that all its sites reach at twice
their sample size, so no site is extrapolated too far:

``` r
set.seed(1)
div_standardise(png_ants, .by = season, nboot = 50) |>
  filter(q == 0)
#> # A tibble: 10 x 10
#>    season site       q      m method        coverage diversity    se lower upper
#>    <chr>  <chr>  <dbl>  <dbl> <chr>            <dbl>     <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0  11.6  rarefaction      0.565      7.96 0.458  7.07  8.86
#>  2 wet    MW0200     0  45.1  rarefaction      0.796     15.7  1.42  12.9  18.4 
#>  3 dry    MW0700     0  46.0  extrapolation    0.565     26.0  5.31  15.6  36.4 
#>  4 wet    MW0700     0 116    extrapolation    0.796     42.2  6.36  29.8  54.7 
#>  5 dry    MW1200     0  11.0  rarefaction      0.565      7.17 0.669  5.86  8.48
#>  6 wet    MW1200     0  40.6  rarefaction      0.796     17.1  1.82  13.5  20.6 
#>  7 dry    MW1700     0   3.07 rarefaction      0.565      2.32 0.226  1.88  2.77
#>  8 wet    MW1700     0  25.4  rarefaction      0.796      8.36 1.58   5.26 11.5 
#>  9 dry    MW2200     0   4.76 rarefaction      0.565      3.48 0.363  2.77  4.20
#> 10 wet    MW2200     0   8.97 rarefaction      0.796      4.01 0.585  2.86  5.15
```

## Example data from Papua New Guinea

Every example uses published field data, rebuilt from the original
deposits by scripts in `data-raw/`.

| Dataset              | What it holds                                                      | Source                                                                                                            |
|----------------------|--------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `png_ants`           | Ants at nutrient baits, Mt Wilhelm, 200-3700 m, dry and wet season | Moses et al. (2023) *Global Ecology and Biogeography*, [doi:10.1111/geb.13757](https://doi.org/10.1111/geb.13757) |
| `png_tree_ants`      | Every ant nest in 1254 trees at 200, 900 and 1800 m                | Plowman et al. (2020) *Ecography*, [doi:10.1111/ecog.04730](https://doi.org/10.1111/ecog.04730)                   |
| `png_frogs`          | 3390 frogs of 55 species at eight elevations, Mt Wilhelm           | Dahl et al. (2023) *Biotropica*, [doi:10.1111/btp.13283](https://doi.org/10.1111/btp.13283)                       |
| `wanang_butterflies` | Butterflies on 36 days over three years, Wanang forest plot        | Luk et al. (2019) *Biotropica*, [doi:10.1111/btp.12671](https://doi.org/10.1111/btp.12671)                        |

## TD, PD and FD on one scale

The same verbs give all three dimensions. Here are rarefaction and
extrapolation curves for two Brazilian rainforest tree assemblages,
using the abundance data, phylogeny and functional distances shipped
with iNEXT.3D.

``` r
library(ggplot2)
data(list = c(
  "Brazil_rainforest_abun_data", "Brazil_rainforest_phylo_tree",
  "Brazil_rainforest_distance_matrix"
), package = "iNEXT.3D")
wide <- Brazil_rainforest_abun_data
brazil <- tibble(
  site = rep(colnames(wide), each = nrow(wide)),
  species = rep(rownames(wide), ncol(wide)),
  n = unlist(wide, use.names = FALSE)
) |>
  filter(n > 0)

curves <- bind_rows(
  div_rarefy(brazil, abundance = n, type = "TD") |> mutate(type = "TD"),
  div_rarefy(brazil,
    abundance = n, type = "PD",
    tree = Brazil_rainforest_phylo_tree
  ),
  div_rarefy(brazil,
    abundance = n, type = "FD",
    distance = as.matrix(Brazil_rainforest_distance_matrix)
  )
)

curves$type <- factor(curves$type, levels = c("TD", "PD", "FD"))

ggplot(curves, aes(m, diversity, colour = site)) +
  geom_line(aes(linetype = method == "extrapolation")) +
  geom_point(data = filter(curves, method == "observed"), size = 2) +
  facet_wrap(vars(q, type),
    ncol = 3, scales = "free_y",
    labeller = labeller(q = function(x) paste("q =", x), .multi_line = FALSE)
  ) +
  scale_linetype_manual(values = c("solid", "dashed"), guide = "none") +
  labs(
    x = "Number of individuals",
    y = "Effective number of species", colour = NULL
  ) +
  theme_tidydiversity()
```

<img src="man/figures/README-three-d-1.png" alt="Rarefaction and extrapolation curves of taxonomic, phylogenetic and functional diversity for two Brazilian rainforest assemblages, in a grid with one row per order q and one column per dimension, each panel with its own y axis." width="100%" />

### Why one scale?

Hill numbers of order q share one unit, the effective number of equally
abundant (and, for PD and FD, equally distinct) species, so TD, PD and
FD of the same order can be compared directly, and their ratios read as
measures of phylogenetic or functional redundancy (Chao, Chiu and Jost
2014,
[doi:10.1146/annurev-ecolsys-120213-091540](https://doi.org/10.1146/annurev-ecolsys-120213-091540);
Chao et al. 2019,
[doi:10.1002/ecm.1343](https://doi.org/10.1002/ecm.1343)). Standardising
every dimension by the same sample size or coverage removes the effect
of unequal sampling effort before you compare sites.

## Functions

| Task                               | Function                                                     |
|------------------------------------|--------------------------------------------------------------|
| Tidy community data                | `as_community()`, `community_wide()`, `community_long()`     |
| Observed Hill numbers (TD, PD, FD) | `div_hill()`                                                 |
| Asymptotic estimates               | `div_estimate()`                                             |
| Sample coverage                    | `div_coverage()`                                             |
| Rarefaction and extrapolation      | `div_rarefy()`                                               |
| Coverage or size standardisation   | `div_standardise()`                                          |
| Sample completeness and evenness   | `div_completeness()`, `div_evenness()`                       |
| Bootstrap replicates               | `div_boot()`                                                 |
| Beta partitioning                  | `beta_pair()`, `beta_multi()`, `beta_decay()`, `beta_dist()` |
| Plots and tables                   | `autoplot()`, `theme_tidydiversity()`, `div_table()`         |
| Model-ready output                 | `tidy()`, `glance()`, `add_site_data()`                      |

## Gallery

Every plot that `autoplot()` draws, using `png_ants`.

### Rarefaction and extrapolation by sample size

Solid lines are rarefied, dashed lines extrapolated to twice the sample
size; points are the observed samples (wet season).

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
season.

<img src="man/figures/README-elevation-1.png" alt="Alpha diversity along elevation" width="100%" />

### Observed and asymptotic diversity

Open circles are observed values, filled circles the asymptotic
estimates, with 95% bootstrap intervals.

<img src="man/figures/README-estimate-1.png" alt="Observed and asymptotic diversity" width="100%" />

### Sample coverage

Estimated sample coverage of each site against its number of bait
occurrences.

<img src="man/figures/README-sample-coverage-1.png" alt="Sample coverage" width="100%" />

### Pairwise beta diversity heatmap

Total Sorensen dissimilarity between every pair of sites within each
season.

<img src="man/figures/README-beta-pair-1.png" alt="Pairwise beta diversity heatmap" width="100%" />

### Multi-site beta partition

Multi-site Sorensen dissimilarity of each season split into turnover and
nestedness.

<img src="man/figures/README-beta-multi-1.png" alt="Multi-site beta partition" width="100%" />

### Distance decay

Pairwise total, turnover and nestedness dissimilarity against elevation
difference, with quasibinomial (logit) trends that stay within 0-1.

<img src="man/figures/README-beta-decay-1.png" alt="Distance decay" width="100%" />

## Output tables

Example output of every main function on `png_ants`. Long tables show
their first rows.

### `div_hill()`

Observed Hill numbers: `n` occurrences, `diversity` of order `q` per
site.

| season | site   |   q |   n | diversity |
|:-------|:-------|----:|----:|----------:|
| dry    | MW0200 |   0 |  47 |    16.000 |
| dry    | MW0200 |   1 |  47 |    12.278 |
| dry    | MW0200 |   2 |  47 |     9.906 |
| wet    | MW0200 |   0 |  76 |    21.000 |
| wet    | MW0200 |   1 |  76 |    10.876 |
| wet    | MW0200 |   2 |  76 |     6.993 |
| dry    | MW0700 |   0 |  23 |    15.000 |
| dry    | MW0700 |   1 |  23 |    11.758 |

### `div_estimate()`

Asymptotic estimates: `observed` and `estimate` Hill numbers with
bootstrap `se`, `lower` and `upper` 95% limits.

| season | site   |   q | observed | estimate |     se |  lower |   upper |
|:-------|:-------|----:|---------:|---------:|-------:|-------:|--------:|
| dry    | MW0200 |   0 |   16.000 |   18.447 |  5.913 | 16.162 |  53.059 |
| dry    | MW0200 |   1 |   12.278 |   15.183 |  1.700 | 12.278 |  18.515 |
| dry    | MW0200 |   2 |    9.906 |   12.284 |  1.859 |  9.906 |  15.928 |
| wet    | MW0200 |   0 |   21.000 |   32.941 | 11.434 | 23.457 |  79.036 |
| wet    | MW0200 |   1 |   10.876 |   13.793 |  2.024 | 10.876 |  17.761 |
| wet    | MW0200 |   2 |    6.993 |    7.600 |  1.099 |  6.993 |   9.754 |
| dry    | MW0700 |   0 |   15.000 |   83.870 | 39.982 | 38.949 | 213.049 |
| dry    | MW0700 |   1 |   11.758 |   38.453 | 30.595 | 11.758 |  98.417 |

### `div_coverage()`

Sample coverage: `n` occurrences, `s_obs` observed species, `f1`
singletons, `f2` doubletons and estimated `coverage`.

| season | site   |   n | s_obs |  f1 |  f2 | coverage |
|:-------|:-------|----:|------:|----:|----:|---------:|
| dry    | MW0200 |  47 |    16 |   5 |   5 |    0.898 |
| wet    | MW0200 |  76 |    21 |  11 |   5 |    0.857 |
| dry    | MW0700 |  23 |    15 |  12 |   1 |    0.482 |
| wet    | MW0700 |  58 |    28 |  17 |   3 |    0.709 |
| dry    | MW1200 |  29 |    13 |   7 |   3 |    0.766 |
| wet    | MW1200 |  57 |    20 |   9 |   3 |    0.844 |
| dry    | MW1700 |  17 |     5 |   1 |   2 |    0.953 |
| wet    | MW1700 |  34 |    10 |   6 |   2 |    0.827 |

### `div_rarefy()`

Rarefaction and extrapolation: diversity of order `q` at sample size
`m`, whether `method` is rarefaction, observed or extrapolation, the
expected `coverage`, and `lower` and `upper` limits (`NA` when
`nboot = 0`).

| site   |   q |   m | method        | diversity | coverage | lower | upper |
|:-------|----:|----:|:--------------|----------:|---------:|------:|------:|
| MW0200 |   0 |   1 | rarefaction   |     1.000 |    0.132 |    NA |    NA |
| MW0200 |   0 |  38 | rarefaction   |    14.140 |    0.780 |    NA |    NA |
| MW0200 |   0 |  75 | rarefaction   |    20.855 |    0.855 |    NA |    NA |
| MW0200 |   0 |  76 | observed      |    21.000 |    0.857 |    NA |    NA |
| MW0200 |   0 |  77 | extrapolation |    21.143 |    0.859 |    NA |    NA |
| MW0200 |   0 | 102 | extrapolation |    24.211 |    0.895 |    NA |    NA |
| MW0200 |   0 | 127 | extrapolation |    26.482 |    0.923 |    NA |    NA |
| MW0200 |   0 | 152 | extrapolation |    28.162 |    0.943 |    NA |    NA |

### `div_standardise()`

Coverage standardisation: `diversity` of order `q` at a common
`coverage` for every site, with the matching sample size `m`, the
`method` used, and bootstrap `se`, `lower` and `upper` limits.

| season | site   |   q |      m | method        | coverage | diversity |    se |  lower |  upper |
|:-------|:-------|----:|-------:|:--------------|---------:|----------:|------:|-------:|-------:|
| dry    | MW0200 |   0 | 11.646 | rarefaction   |    0.565 |     7.963 | 0.458 |  7.067 |  8.860 |
| dry    | MW0200 |   1 | 11.646 | rarefaction   |    0.565 |     7.099 | 0.513 |  6.093 |  8.105 |
| dry    | MW0200 |   2 | 11.646 | rarefaction   |    0.565 |     6.236 | 0.534 |  5.189 |  7.283 |
| wet    | MW0200 |   0 | 45.094 | rarefaction   |    0.796 |    15.651 | 1.415 | 12.877 | 18.425 |
| wet    | MW0200 |   1 | 45.094 | rarefaction   |    0.796 |     9.570 | 1.071 |  7.471 | 11.668 |
| wet    | MW0200 |   2 | 45.094 | rarefaction   |    0.796 |     6.630 | 0.816 |  5.031 |  8.228 |
| dry    | MW0700 |   0 | 46.000 | extrapolation |    0.565 |    25.975 | 5.306 | 15.575 | 36.374 |
| dry    | MW0700 |   1 | 46.000 | extrapolation |    0.565 |    17.858 | 6.141 |  5.821 | 29.895 |

### `beta_pair()`

Pairwise beta diversity: Sorensen `turnover` (Simpson) and `nestedness`
components, which sum to `total` dissimilarity.

| season | site_1 | site_2 | turnover | nestedness | total |
|:-------|:-------|:-------|---------:|-----------:|------:|
| dry    | MW0200 | MW0700 |    0.667 |      0.011 | 0.677 |
| dry    | MW0200 | MW1200 |    0.769 |      0.024 | 0.793 |
| dry    | MW0200 | MW1700 |    0.800 |      0.105 | 0.905 |
| dry    | MW0200 | MW2200 |    1.000 |      0.000 | 1.000 |
| dry    | MW0700 | MW1200 |    0.615 |      0.027 | 0.643 |
| dry    | MW0700 | MW1700 |    0.800 |      0.100 | 0.900 |
| dry    | MW0700 | MW2200 |    0.833 |      0.071 | 0.905 |
| dry    | MW1200 | MW1700 |    1.000 |      0.000 | 1.000 |

### `beta_multi()`

Multi-site beta diversity: `n_sites` in each group with the multi-site
`turnover`, `nestedness` and `total`.

| season | n_sites | turnover | nestedness | total |
|:-------|--------:|---------:|-----------:|------:|
| dry    |       5 |    0.827 |      0.051 | 0.877 |
| wet    |       5 |    0.790 |      0.074 | 0.864 |

### `beta_decay()`

Distance decay: the pairwise components plus each site’s `gradient_1`
and `gradient_2` values and their `distance`.

| season | site_1 | site_2 | turnover | nestedness | total | gradient_1 | gradient_2 | distance |
|:-------|:-------|:-------|---------:|-----------:|------:|-----------:|-----------:|---------:|
| dry    | MW0200 | MW0700 |    0.667 |      0.011 | 0.677 |        200 |        700 |      500 |
| dry    | MW0200 | MW1200 |    0.769 |      0.024 | 0.793 |        200 |       1200 |     1000 |
| dry    | MW0200 | MW1700 |    0.800 |      0.105 | 0.905 |        200 |       1700 |     1500 |
| dry    | MW0200 | MW2200 |    1.000 |      0.000 | 1.000 |        200 |       2200 |     2000 |
| dry    | MW0700 | MW1200 |    0.615 |      0.027 | 0.643 |        700 |       1200 |      500 |
| dry    | MW0700 | MW1700 |    0.800 |      0.100 | 0.900 |        700 |       1700 |     1000 |
| dry    | MW0700 | MW2200 |    0.833 |      0.071 | 0.905 |        700 |       2200 |     1500 |
| dry    | MW1200 | MW1700 |    1.000 |      0.000 | 1.000 |       1200 |       1700 |      500 |

## References

- Chao, A. et al. (2014). Rarefaction and extrapolation with Hill
  numbers. *Ecological Monographs*, 84, 45-67.
- Chao, A. and Jost, L. (2012). Coverage-based rarefaction and
  extrapolation. *Ecology*, 93, 2533-2547.
- Baselga, A. (2010). Partitioning the turnover and nestedness
  components of beta diversity. *Global Ecology and Biogeography*, 19,
  134-143.
- Moses, J. et al. (2023). Nutrient use by tropical ant communities
  varies among three extensive elevational gradients: a
  cross-continental comparison. *Global Ecology and Biogeography*, 32,
  1958-1973.

## Licence

MIT © Jimmy Moses
