# Standardise diversity by coverage or sample size

Compares sites at equal sample completeness (coverage) or equal sample
size, by rarefying or extrapolating each site to that level (Chao and
Jost 2012). By default sites are standardised to the lowest coverage
that every site in a group reaches at twice its sample size, as in
[`iNEXT::estimateD()`](https://rdrr.io/pkg/iNEXT/man/estimateD.html).

## Usage

``` r
div_standardise(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = c(0, 1, 2),
  coverage = NULL,
  size = NULL,
  conf = 0.95,
  nboot = 50,
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

- coverage:

  Target sample coverage between 0 and 1. If both `coverage` and `size`
  are `NULL`, a default coverage is chosen for each group.

- size:

  Target sample size. Supply either `coverage` or `size`.

- conf:

  Confidence level of the intervals.

- nboot:

  Number of bootstrap replicates. Use 0 to skip them. For PD and FD the
  bootstrap community adds undetected species with estimated branch
  lengths (PD) or distances (FD); see Details in
  [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md).

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

A `td_standardise` tibble with the grouping columns, the site column,
`q`, `m`, `method`, `coverage`, `diversity`, `se`, `lower` and `upper`.
A warning is given when a site has to be extrapolated beyond twice its
sample size, where richness estimates become unreliable.

## Examples

``` r
set.seed(1)
div_standardise(png_ants, coverage = 0.95, .by = season, nboot = 10)
#> Warning: Extrapolation beyond twice the observed sample size at 7 sites.
#> i Richness (q = 0) estimates there may be strongly biased (Chao et al. 2014).
#> # A tibble: 30 x 10
#>    season site       q     m method        coverage diversity     se lower upper
#>    <chr>  <chr>  <dbl> <dbl> <chr>            <dbl>     <dbl>  <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0  63.7 extrapolation    0.950     17.2   0.755 15.8   18.7
#>  2 dry    MW0200     1  63.7 extrapolation    0.950     13.1   0.757 11.7   14.6
#>  3 dry    MW0200     2  63.7 extrapolation    0.950     10.4   0.918  8.64  12.2
#>  4 wet    MW0200     0 163.  extrapolation    0.950     28.8   5.56  17.9   39.7
#>  5 wet    MW0200     1 163.  extrapolation    0.950     12.6   1.75   9.20  16.1
#>  6 wet    MW0200     2 163.  extrapolation    0.950      7.30  1.67   4.03  10.6
#>  7 dry    MW0700     0 333.  extrapolation    0.950     77.2  21.9   34.3  120. 
#>  8 dry    MW0700     1 333.  extrapolation    0.950     37.6  12.0   14.1   61.2
#>  9 dry    MW0700     2 333.  extrapolation    0.950     12.8   4.20   4.61  21.1
#> 10 wet    MW0700     0 343.  extrapolation    0.950     67.2  15.6   36.7   97.8
#> # i 20 more rows

div_standardise(png_ants, size = 20, .by = season, nboot = 0)
#> # A tibble: 30 x 10
#>    season site       q     m method      coverage diversity    se lower upper
#>    <chr>  <chr>  <dbl> <dbl> <chr>          <dbl>     <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0    20 rarefaction    0.708     11.0     NA    NA    NA
#>  2 dry    MW0200     1    20 rarefaction    0.708      9.28    NA    NA    NA
#>  3 dry    MW0200     2    20 rarefaction    0.708      7.85    NA    NA    NA
#>  4 wet    MW0200     0    20 rarefaction    0.715      9.65    NA    NA    NA
#>  5 wet    MW0200     1    20 rarefaction    0.715      7.35    NA    NA    NA
#>  6 wet    MW0200     2    20 rarefaction    0.715      5.71    NA    NA    NA
#>  7 dry    MW0700     0    20 rarefaction    0.470     13.4     NA    NA    NA
#>  8 dry    MW0700     1    20 rarefaction    0.470     10.8     NA    NA    NA
#>  9 dry    MW0700     2    20 rarefaction    0.470      8.24    NA    NA    NA
#> 10 wet    MW0700     0    20 rarefaction    0.506     14.2     NA    NA    NA
#> # i 20 more rows
```
