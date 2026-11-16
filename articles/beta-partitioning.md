# Partitioning beta diversity

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
library(ggplot2)
```

Beta diversity measures how communities differ. Baselga (2010) showed
that dissimilarity has two parts: **turnover**, where species replace
each other, and **nestedness**, where poorer sites hold a subset of the
species at richer sites. The examples use `png_ants`, ants at nutrient
baits along Mt Wilhelm, Papua New Guinea (Moses et al. 2023).

## The concept

Two communities can differ in two ways:

| Pattern | Example | What it suggests |
|----|----|----|
| **Turnover** (replacement) | Lowland species are replaced by different montane species | Environmental filtering, dispersal barriers, history |
| **Nestedness** (loss) | The montane site holds only a subset of the lowland species | Species lost along a gradient of harshness or habitat area |

The Sørensen dissimilarity (0 = same species, 1 = no species shared)
mixes both. Baselga’s partition splits it into turnover (Simpson
dissimilarity) and nestedness, which add up to the total, so you can say
*how* sites differ, not only *how much*. Conservation advice differs:
with turnover every site is needed to protect the species; with
nestedness the richest site protects most of them.

## Pairwise dissimilarity

``` r

pairs <- beta_pair(png_ants, .by = season)
pairs
#> # A tibble: 20 × 6
#>    season site_1 site_2 turnover nestedness total
#>    <chr>  <chr>  <chr>     <dbl>      <dbl> <dbl>
#>  1 dry    MW0200 MW0700    0.667    0.0108  0.677
#>  2 dry    MW0200 MW1200    0.769    0.0239  0.793
#>  3 dry    MW0200 MW1700    0.8      0.105   0.905
#>  4 dry    MW0200 MW2200    1        0       1    
#>  5 dry    MW0700 MW1200    0.615    0.0275  0.643
#>  6 dry    MW0700 MW1700    0.8      0.1     0.9  
#>  7 dry    MW0700 MW2200    0.833    0.0714  0.905
#>  8 dry    MW1200 MW1700    1        0       1    
#>  9 dry    MW1200 MW2200    0.833    0.0614  0.895
#> 10 dry    MW1700 MW2200    1        0       1    
#> 11 wet    MW0200 MW0700    0.619    0.0544  0.673
#> 12 wet    MW0200 MW1200    0.8      0.00488 0.805
#> 13 wet    MW0200 MW1700    0.9      0.0355  0.935
#> 14 wet    MW0200 MW2200    1        0       1    
#> 15 wet    MW0700 MW1200    0.55     0.075   0.625
#> 16 wet    MW0700 MW1700    0.9      0.0474  0.947
#> 17 wet    MW0700 MW2200    1        0       1    
#> 18 wet    MW1200 MW1700    0.6      0.133   0.733
#> 19 wet    MW1200 MW2200    1        0       1    
#> 20 wet    MW1700 MW2200    0.8      0.0667  0.867
```

Turnover and nestedness add up to the total. Use `index = "jaccard"` for
the Jaccard family. The results match the betapart package.

``` r

pairs |>
  group_by(season) |>
  summarise(across(c(turnover, nestedness, total), mean))
#> # A tibble: 2 × 4
#>   season turnover nestedness total
#>   <chr>     <dbl>      <dbl> <dbl>
#> 1 dry       0.832     0.0400 0.872
#> 2 wet       0.817     0.0417 0.859
```

**How to read it.** Sites differ strongly (mean total dissimilarity
0.86-0.87: on average a pair shares only about 13% of its species), and
almost all of the difference is turnover (0.82-0.83) rather than
nestedness (0.04). Ant species are *replaced* along Mt Wilhelm, not
simply lost. Several high-elevation pairs share no species at all (total
= 1).

## Many sites at once

``` r

beta_multi(png_ants, .by = season)
#> # A tibble: 2 × 5
#>   season n_sites turnover nestedness total
#>   <chr>    <int>    <dbl>      <dbl> <dbl>
#> 1 dry          5    0.827     0.0507 0.877
#> 2 wet          5    0.790     0.0737 0.864
```

The multiple-site version measures dissimilarity among all five sites at
once (Baselga 2010) and tells the same story: turnover dominates in both
seasons.

## Distance decay

[`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md)
adds the distance between sites along a gradient. Here turnover rises
with elevational distance while nestedness stays low.

``` r

decay <- beta_decay(png_ants, gradient = elevation, .by = season)
decay
#> # A tibble: 20 × 9
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

``` r

autoplot(decay)
```

![Dissimilarity against elevational
distance](beta-partitioning_files/figure-html/unnamed-chunk-6-1.png)

[`beta_decay_model()`](https://tidydiversity.in4metrix.dev/reference/beta_decay_model.md)
fits a distance-decay curve to the similarities (one minus
dissimilarity) and tests it. The exponential model S = a exp(-b d) gives
the similarity `a` between sites at the same elevation and the rate `b`;
`half_distance` is the elevational distance over which similarity
halves. Pairs of sites share sites, so they are not independent: the
p-value comes from permuting site labels, as in a Mantel test, and
refitting the model each time.

``` r

set.seed(1)
beta_decay_model(decay, permutations = 999)
#> # A tibble: 2 × 10
#>   season model    component n_pairs     a       b half_distance pseudo_r2    aic
#>   <chr>  <chr>    <chr>       <int> <dbl>   <dbl>         <dbl>     <dbl>  <dbl>
#> 1 dry    exponen… total          10 0.257 7.50e-4          924.     0.143  -9.21
#> 2 wet    exponen… total          10 0.897 2.36e-3          293.     0.694 -17.6 
#> # ℹ 1 more variable: p.value <dbl>
```

**How to read it.** In the wet season similarity decays steeply with
elevational distance: it halves every 293 m, the curve explains 69% of
the variation among pairs (`pseudo_r2`), and the permutation test is
significant (*P* = 0.017). In the dry season the curve is flat and not
significant (*P* = 0.35): sites near each other are already very
dissimilar (`a` = 0.26, the similarity at zero distance), because sparse
dry-season samples share few species by chance.

With only five sites per season there are 120 distinct permutations, so
the smallest attainable p-value is near 0.01 however strong the pattern.

## Shared species and similarity corrected for unseen species

Classic Jaccard and Sørensen indices count only the species seen in both
samples. A species shared by two sites but rare in one is easily missed,
so incomplete samples look less similar than they are. Chao et
al. (2000, 2005) estimate what was missed:

``` r

shared <- beta_shared(png_ants, unit = bait, n_units = baits, .by = season)
filter(shared, season == "wet")
#> # A tibble: 10 × 7
#>    season site_1 site_2   s_1   s_2 observed estimate
#>    <chr>  <chr>  <chr>  <int> <int>    <int>    <dbl>
#>  1 wet    MW0200 MW0700    21    28        8    28.3 
#>  2 wet    MW0200 MW1200    21    20        4     6.95
#>  3 wet    MW0200 MW1700    21    10        1     1.24
#>  4 wet    MW0200 MW2200    21     5        0     0   
#>  5 wet    MW0700 MW1200    28    20        9    18.8 
#>  6 wet    MW0700 MW1700    28    10        1     1   
#>  7 wet    MW0700 MW2200    28     5        0     0   
#>  8 wet    MW1200 MW1700    20    10        4     9.38
#>  9 wet    MW1200 MW2200    20     5        0     0   
#> 10 wet    MW1700 MW2200    10     5        1     1
```

**How to read it.** `observed` is the number of species seen at both
sites, `estimate` the estimated number truly shared. 200 m and 700 m
share 8 observed species but an estimated 28: most shared species were
found at only one bait in one of the two sites. Pairs with no observed
shared species (all pairs with 2200 m) get no correction, because the
estimator extrapolates only from shared species that were seen.

``` r

chao <- beta_chao(png_ants, .by = season)
filter(chao, season == "wet") |>
  select(site_1, site_2, jaccard, chao_jaccard, sorensen, chao_sorensen)
#> # A tibble: 10 × 6
#>    site_1 site_2 jaccard chao_jaccard sorensen chao_sorensen
#>    <chr>  <chr>    <dbl>        <dbl>    <dbl>         <dbl>
#>  1 MW0200 MW0700  0.195        0.660    0.327         0.795 
#>  2 MW0200 MW1200  0.108        0.195    0.195         0.326 
#>  3 MW0200 MW1700  0.0333       0.0137   0.0645        0.0271
#>  4 MW0200 MW2200  0            0        0             0     
#>  5 MW0700 MW1200  0.231        0.489    0.375         0.657 
#>  6 MW0700 MW1700  0.0270       0.0190   0.0526        0.0374
#>  7 MW0700 MW2200  0            0        0             0     
#>  8 MW1200 MW1700  0.154        0.404    0.267         0.575 
#>  9 MW1200 MW2200  0            0        0             0     
#> 10 MW1700 MW2200  0.0714       0.129    0.133         0.228
```

**How to read it.** The Chao indices weight species by their abundance
(or incidence), so they measure the share of *individuals* belonging to
shared species, corrected for shared species that were missed. Where the
shared species are common, they are larger than the classic indices,
which count species only. Between 200 m and 700 m, Sørensen similarity
rises from 0.33 to 0.8: the two lowland sites are much more alike than
their species lists suggest. Where the few shared species are rare at
both sites (200 m and 1700 m), the Chao index is smaller than the
classic one. Elevations far apart remain dissimilar under both indices,
so the turnover along the mountain is real, not an artefact of sampling.

## Hill-number dissimilarity between pairs of sites

Presence-absence indices treat a species with one worker like one with a
thousand.
[`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md)
computes the Hill-number framework of Chao, Chiu and Jost (2014) for
every pair of sites, so the order q sets how much weight common species
get. At q = 0 `dis_sorensen` and `dis_jaccard` are the classic Sorensen
and Jaccard indices; at q = 2 `dis_sorensen` is the Morisita-Horn index,
driven by the dominant species.

``` r

wet <- dplyr::filter(png_ants, season == "wet")
hp <- beta_hill_pair(wet, abundance = workers)
hp
#> # A tibble: 30 × 10
#>    site_1 site_2     q gamma alpha  beta dis_sorensen dis_jaccard
#>    <chr>  <chr>  <dbl> <dbl> <dbl> <dbl>        <dbl>       <dbl>
#>  1 MW0200 MW0700     0    41  24.5  1.67        0.673       0.805
#>  2 MW0200 MW1200     0    37  20.5  1.80        0.805       0.892
#>  3 MW0200 MW1700     0    30  15.5  1.94        0.935       0.967
#>  4 MW0200 MW2200     0    26  13    2           1           1    
#>  5 MW0700 MW1200     0    39  24    1.62        0.625       0.769
#>  6 MW0700 MW1700     0    37  19    1.95        0.947       0.973
#>  7 MW0700 MW2200     0    33  16.5  2           1           1    
#>  8 MW1200 MW1700     0    26  15    1.73        0.733       0.846
#>  9 MW1200 MW2200     0    25  12.5  2           1           1    
#> 10 MW1700 MW2200     0    14   7.5  1.87        0.867       0.929
#> # ℹ 20 more rows
#> # ℹ 2 more variables: dis_turnover_sorensen <dbl>, dis_turnover_jaccard <dbl>
```

**How to read it.** `gamma` is the diversity of the two sites pooled,
`alpha` the mean diversity per site, and `beta` = gamma / alpha the
effective number of distinct communities: 1 if the two sites are
identical, 2 if they share nothing. `dis_sorensen` rescales it to 0-1.

``` r

autoplot(hp)
```

![Heatmaps of Sorensen-type dissimilarity between sites for q = 0, 1 and
2](beta-partitioning_files/figure-html/unnamed-chunk-9-1.png)

[`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md)
turns one order into a distance matrix for ordination, clustering or
PERMANOVA:

``` r

beta_dist(hp, q = 2)
#>           MW0200    MW0700    MW1200    MW1700
#> MW0700 0.8931865                              
#> MW1200 0.8934988 0.5378074                    
#> MW1700 0.9999783 0.9999473 0.9493274          
#> MW2200 1.0000000 1.0000000 1.0000000 0.9811531
```

At q = 2 (Morisita-Horn), 700 m and 1200 m are fairly similar (0.54)
although they share under half their species: their dominant species are
the same. Read the three heatmaps together: dissimilarity that grows
from q = 0 to q = 2 means the sites differ most in their *common*
species.

## Beta diversity at equal sample coverage

Beta diversity estimated from samples depends on sample size and
completeness, so regions sampled with different effort cannot be
compared directly.
[`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md)
follows the iNEXT.beta3D framework of Chao et al. (2023): gamma and
alpha Hill numbers are each standardised to the same sample coverage,
and beta = gamma / alpha is the effective number of completely distinct
sites (1 to the number of sites).

``` r

beta_hill(png_ants, .by = season)
#> # A tibble: 6 × 13
#>   season     q coverage m_gamma m_alpha gamma alpha  beta n_sites dis_sorensen
#>   <chr>  <dbl>    <dbl>   <dbl>   <dbl> <dbl> <dbl> <dbl>   <int>        <dbl>
#> 1 dry        0    0.957    238.    371.  50.3 16.2   3.10       5        0.526
#> 2 dry        1    0.957    238.    371.  34.1 10.9   3.12       5        0.708
#> 3 dry        2    0.957    238.    371.  24.7  7.32  3.37       5        0.879
#> 4 wet        0    0.957    480     807.  78.9 27.9   2.83       5        0.457
#> 5 wet        1    0.957    480     807.  39.4 13.6   2.89       5        0.659
#> 6 wet        2    0.957    480     807.  22.2  7.29  3.04       5        0.839
#> # ℹ 3 more variables: dis_jaccard <dbl>, dis_turnover_sorensen <dbl>,
#> #   dis_turnover_jaccard <dbl>
```

**How to read it.** At 0.957 coverage, the five dry-season sites hold
the equivalent of 3.1 completely distinct communities out of a possible
5 (`beta`), and the wet-season sites 2.8. `gamma` is the regional
diversity and `alpha` the mean per site. Beta rises from q = 0 to q = 2,
so the sites differ even more in their dominant species than in their
species lists.

The four `dis_` columns rescale beta to 0-1. `dis_sorensen` and
`dis_jaccard` measure non-overlap (for q = 0 they are the classic
Sorensen and Jaccard dissimilarities); the `turnover` versions measure
species turnover. Give `coverage` to compare regions at chosen levels:

``` r

beta_hill(png_ants, q = 0, coverage = c(0.8, 0.9), .by = season)
#> # A tibble: 4 × 13
#>   season     q coverage m_gamma m_alpha gamma alpha  beta n_sites dis_sorensen
#>   <chr>  <dbl>    <dbl>   <dbl>   <dbl> <dbl> <dbl> <dbl>   <int>        <dbl>
#> 1 dry        0      0.8    81.9    140.  34.5  11.5  3.01       5        0.503
#> 2 dry        0      0.9   150.     244.  44.4  14.5  3.06       5        0.516
#> 3 wet        0      0.8   112.     216.  43.3  15.9  2.73       5        0.433
#> 4 wet        0      0.9   260.     481.  64.1  23.5  2.73       5        0.431
#> # ℹ 3 more variables: dis_jaccard <dbl>, dis_turnover_sorensen <dbl>,
#> #   dis_turnover_jaccard <dbl>
```

Add `nboot` for bootstrap confidence intervals. The same function gives
phylogenetic (`type = "PD"`, with `tree`) and functional (`type = "FD"`,
with `distance`) beta diversity, and works on incidence data with `unit`
when the same sampling units (plots, visits) were surveyed at every
site.

``` r

set.seed(1)
b <- beta_hill(png_ants, q = 0, coverage = 0.9, nboot = 20, .by = season)
b[c("season", "beta", "beta_lower", "beta_upper")]
#> # A tibble: 2 × 4
#>   season  beta beta_lower beta_upper
#>   <chr>  <dbl>      <dbl>      <dbl>
#> 1 dry     3.06       2.56       3.57
#> 2 wet     2.73       1.97       3.48
```

**Interpretation.** At 90% coverage, beta diversity is 3.1 in the dry
season and 2.7 in the wet season, but the bootstrap intervals overlap
widely (2.6-3.6 and 2.0-3.5): there is no evidence that turnover along
the mountain differs between seasons.

## How to report it

> Beta diversity among elevations was partitioned into turnover and
> nestedness components of Sørensen dissimilarity (Baselga 2010) with
> tidydiversity. Turnover accounted for 95% of the total dissimilarity
> (mean pairwise turnover 0.82, nestedness 0.04). In the wet season,
> similarity decayed exponentially with elevational distance (half
> distance 293 m, pseudo-R² = 0.69, permutation *P* = 0.017). At equal
> sample coverage (90%; Chao et al. 2023), the five elevations
> represented 3.1 (95% CI 2.6-3.6) effectively distinct communities in
> the dry season and 2.7 (2.0-3.5) in the wet season.

## References

Baselga, A. (2010). Partitioning the turnover and nestedness components
of beta diversity. *Global Ecology and Biogeography*, 19, 134-143.

Chao, A., Chazdon, R. L., Colwell, R. K. and Shen, T.-J. (2005). A new
statistical approach for assessing similarity of species composition
with incidence and abundance data. *Ecology Letters*, 8, 148-159.

Chao, A., Hwang, W.-H., Chen, Y.-C. and Kuo, C.-Y. (2000). Estimating
the number of shared species in two communities. *Statistica Sinica*,
10, 227-246.

Chao, A., Chiu, C.-H. and Jost, L. (2014). Unifying species diversity,
phylogenetic diversity, functional diversity, and related similarity and
differentiation measures through Hill numbers. *Annual Review of
Ecology, Evolution, and Systematics*, 45, 297-324.

Chao, A. et al. (2023). Rarefaction and extrapolation with beta
diversity under a framework of Hill numbers: the iNEXT.beta3D
standardization. *Ecological Monographs*, 93, e1588.
