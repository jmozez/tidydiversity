# Standardise diversity by coverage or sample size

Compares sites at equal sample completeness (coverage) or equal sample
size, by rarefying or extrapolating each site to that level (Chao and
Jost 2012).

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
  level = c("max_extrapolation", "min_observed"),
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

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- q:

  Orders of diversity: any of 0, 1 and 2.

- coverage:

  Target sample coverage between 0 and 1. If both `coverage` and `size`
  are `NULL`, the target is chosen by `level`.

- size:

  Target sample size. Supply either `coverage` or `size`.

- level:

  Rule for the default target coverage: `"max_extrapolation"` or
  `"min_observed"`; see Details.

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
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  shows them side by side. All three are Hill numbers of the same order
  `q`, in units of effective numbers of species (Chao, Chiu and Jost
  2014), and reproduce
  [iNEXT.3D](https://CRAN.R-project.org/package=iNEXT.3D).

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

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_standardise` tibble with the grouping columns, the site column,
`q`, `m`, `method`, `target` (the target coverage, or `NA` for a target
size), `coverage` (coverage reached), `diversity`, `se`, `lower` and
`upper`. A warning is given when a site has to be extrapolated beyond
twice its sample size, where richness estimates become unreliable.

## Details

When neither `coverage` nor `size` is given, the target coverage of each
group is set by `level`:

- `"max_extrapolation"` (default, the rule of
  [`iNEXT::estimateD()`](https://rdrr.io/pkg/iNEXT/man/estimateD.html)):
  the lowest coverage that every site reaches at twice its sample size,
  the largest extrapolation that is still reliable for richness.

- `"min_observed"`: the lowest observed coverage of any site, so the
  least complete site is used as observed and the others are rarefied
  (the most conservative choice; Chao and Jost 2012).

The target is reported in the `target` column. A site whose coverage
curve cannot reach the target (for example one with a single singleton
and no doubletons) is returned at its highest attainable coverage with a
warning, so check `coverage` against `target`. iNEXT rounds the target
coverage it prints, so results can differ from iNEXT in the second
decimal when a rounded level is passed back to it.

## Examples

``` r
set.seed(1)
div_standardise(png_ants, coverage = 0.95, .by = season, nboot = 10)
#> Warning: Extrapolation beyond twice the observed sample size at 7 sites.
#> ℹ Richness (q = 0) estimates there may be strongly biased (Chao et al. 2014).
#> Warning: 3 sites cannot reach the target coverage: "MW0200", "MW1200", and "MW2200".
#> ℹ They are returned at their highest attainable coverage; compare coverage with
#>   target, or use `level = "min_observed"`.
#> # A tibble: 30 × 11
#>    season site      q     m method target coverage diversity     se lower  upper
#>    <chr>  <chr> <dbl> <dbl> <chr>   <dbl>    <dbl>     <dbl>  <dbl> <dbl>  <dbl>
#>  1 dry    MW02…     0  63.7 extra…   0.95    0.950     17.2   0.755 15.8   18.7 
#>  2 dry    MW02…     1  63.7 extra…   0.95    0.950     13.1   0.757 11.7   14.6 
#>  3 dry    MW02…     2  63.7 extra…   0.95    0.950     10.4   0.918  8.64  12.2 
#>  4 dry    MW07…     0 333.  extra…   0.95    0.950     77.2  36.9    4.91 150.  
#>  5 dry    MW07…     1 333.  extra…   0.95    0.950     37.6  31.0    0     98.5 
#>  6 dry    MW07…     2 333.  extra…   0.95    0.950     12.8   9.64   0     31.7 
#>  7 dry    MW12…     0  80.2 extra…   0.95    0.950     19.2   3.54  12.3   26.1 
#>  8 dry    MW12…     1  80.2 extra…   0.95    0.950     12.6   2.19   8.31  16.9 
#>  9 dry    MW12…     2  80.2 extra…   0.95    0.950      7.74  2.11   3.60  11.9 
#> 10 dry    MW17…     0  16.7 raref…   0.95    0.950      4.99  1.15   2.74   7.23
#> # ℹ 20 more rows

div_standardise(png_ants, size = 20, .by = season, nboot = 0)
#> # A tibble: 30 × 11
#>    season site       q     m method  target coverage diversity    se lower upper
#>    <chr>  <chr>  <dbl> <dbl> <chr>    <dbl>    <dbl>     <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0    20 rarefa…     NA    0.708     11.0     NA    NA    NA
#>  2 dry    MW0200     1    20 rarefa…     NA    0.708      9.28    NA    NA    NA
#>  3 dry    MW0200     2    20 rarefa…     NA    0.708      7.85    NA    NA    NA
#>  4 dry    MW0700     0    20 rarefa…     NA    0.470     13.4     NA    NA    NA
#>  5 dry    MW0700     1    20 rarefa…     NA    0.470     10.8     NA    NA    NA
#>  6 dry    MW0700     2    20 rarefa…     NA    0.470      8.24    NA    NA    NA
#>  7 dry    MW1200     0    20 rarefa…     NA    0.689     10.5     NA    NA    NA
#>  8 dry    MW1200     1    20 rarefa…     NA    0.689      8.12    NA    NA    NA
#>  9 dry    MW1200     2    20 rarefa…     NA    0.689      6.16    NA    NA    NA
#> 10 dry    MW1700     0    20 extrap…     NA    0.976      5.11    NA    NA    NA
#> # ℹ 20 more rows
```
