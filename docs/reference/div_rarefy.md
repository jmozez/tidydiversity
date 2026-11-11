# Rarefaction and extrapolation curves

Computes size-based rarefaction and extrapolation of Hill numbers for
each site, with the matching sample coverage. Rarefaction is exact (Chao
et al. 2014) and extrapolation uses the Chao et al. (2014) estimators,
reproducing iNEXT.

## Usage

``` r
div_rarefy(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = c(0, 1, 2),
  size = NULL,
  endpoint = NULL,
  knots = 40,
  conf = 0.95,
  nboot = 0,
  type = c("TD", "PD", "FD"),
  tree = NULL,
  reftime = NULL,
  pd_unit = c("mean", "total"),
  distance = NULL,
  tau = NULL,
  unit = NULL,
  n_units = NULL,
  .by = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- q:

  Orders of diversity: any of 0, 1 and 2.

- size:

  Sample sizes at which to compute diversity. If `NULL`, a grid of
  `knots` sizes from 1 to `endpoint` is used, always including the
  observed sample size.

- endpoint:

  Largest sample size of the default grid. Defaults to twice the
  observed sample size of each site, the recommended limit for
  extrapolating richness. Larger values give a warning.

- knots:

  Number of sizes in the default grid.

- conf:

  Confidence level of the intervals.

- nboot:

  Number of bootstrap replicates for confidence intervals. The default,
  0, skips them.

- type:

  Diversity dimension: `"TD"` (taxonomic, the default), `"PD"`
  (phylogenetic, needs `tree`) or `"FD"` (functional, needs `distance`).
  Give several, such as `c("TD", "PD")`, or `"all"` for all three, to
  analyse the dimensions together: the results are stacked in one tibble
  with a `type` column, and
  [`autoplot()`](https://rdrr.io/pkg/ggplot2/man/autoplot.html) shows
  them side by side. All three are Hill numbers of the same order `q`,
  in units of effective numbers of species (Chao, Chiu and Jost 2014),
  and reproduce [iNEXT.3D](https://CRAN.R-project.org/package=iNEXT.3D).

- tree:

  For `type = "PD"`, a rooted
  [ape::phylo](https://rdrr.io/pkg/ape/man/read.tree.html) tree with
  branch lengths whose tip labels include every species.

- reftime:

  For `type = "PD"`, the reference time (tree depth) at which diversity
  is measured. Defaults to the age of the root of the tree pruned to the
  species in `data`.

- pd_unit:

  For `type = "PD"`, `"mean"` (the default) divides phylogenetic
  diversity by `reftime`, giving the effective number of lineages on the
  same scale as species; `"total"` gives effective total branch length.

- distance:

  For `type = "FD"`, a species-by-species distance matrix (or
  [stats::dist](https://rdrr.io/r/stats/dist.html) object) with names
  matching the species, scaled to lie between 0 and 1, for example from
  Gower distances of traits.

- tau:

  For `type = "FD"`, the distance threshold below which species are
  treated as functionally identical. Defaults to the mean distance
  between two individuals in the pooled data. Use `"auc"` to integrate
  over all thresholds from 0 to 1 (Chao et al. 2019).

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

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_rarefy` tibble with the grouping columns, the site column, `q`,
`m` (sample size), `method` (`"rarefaction"`, `"observed"` or
`"extrapolation"`), `diversity`, `coverage`, `lower` and `upper`. Use
[`ggplot2::autoplot()`](https://rdrr.io/pkg/ggplot2/man/autoplot.html)
to draw the curves.

## Examples

``` r
curves <- div_rarefy(png_ants, q = 0, .by = season, knots = 20)
curves
#> # A tibble: 200 x 9
#>    season site       q     m method      diversity coverage lower upper
#>    <chr>  <chr>  <dbl> <dbl> <chr>           <dbl>    <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0     1 rarefaction      1      0.0814    NA    NA
#>  2 dry    MW0200     0     6 rarefaction      4.94   0.377     NA    NA
#>  3 dry    MW0200     0    12 rarefaction      8.12   0.573     NA    NA
#>  4 dry    MW0200     0    17 rarefaction     10.0    0.668     NA    NA
#>  5 dry    MW0200     0    23 rarefaction     11.8    0.741     NA    NA
#>  6 dry    MW0200     0    29 rarefaction     13.3    0.794     NA    NA
#>  7 dry    MW0200     0    34 rarefaction     14.2    0.829     NA    NA
#>  8 dry    MW0200     0    40 rarefaction     15.2    0.864     NA    NA
#>  9 dry    MW0200     0    46 rarefaction     15.9    0.894     NA    NA
#> 10 dry    MW0200     0    47 observed        16      0.898     NA    NA
#> # i 190 more rows

div_rarefy(png_ants, size = c(10, 20, 40), .by = season)
#> Warning: Extrapolation beyond twice the observed sample size at 3 sites.
#> i Richness (q = 0) estimates there may be strongly biased (Chao et al. 2014).
#> # A tibble: 90 x 9
#>    season site       q     m method      diversity coverage lower upper
#>    <chr>  <chr>  <dbl> <dbl> <chr>           <dbl>    <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0    10 rarefaction      7.19    0.521    NA    NA
#>  2 dry    MW0200     0    20 rarefaction     11.0     0.708    NA    NA
#>  3 dry    MW0200     0    40 rarefaction     15.2     0.864    NA    NA
#>  4 dry    MW0200     1    10 rarefaction      6.50    0.521    NA    NA
#>  5 dry    MW0200     1    20 rarefaction      9.28    0.708    NA    NA
#>  6 dry    MW0200     1    40 rarefaction     11.8     0.864    NA    NA
#>  7 dry    MW0200     2    10 rarefaction      5.77    0.521    NA    NA
#>  8 dry    MW0200     2    20 rarefaction      7.85    0.708    NA    NA
#>  9 dry    MW0200     2    40 rarefaction      9.58    0.864    NA    NA
#> 10 wet    MW0200     0    10 rarefaction      6.31    0.607    NA    NA
#> # i 80 more rows
```
