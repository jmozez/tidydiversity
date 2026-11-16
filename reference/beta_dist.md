# Pairwise dissimilarity as a distance matrix

Returns one component of
[`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md),
or one dissimilarity of
[`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md),
as a [stats::dist](https://rdrr.io/r/stats/dist.html) object, ready for
ordination and testing with vegan, for example
[`vegan::metaMDS()`](https://vegandevs.github.io/vegan/reference/metaMDS.html),
[`vegan::adonis2()`](https://vegandevs.github.io/vegan/reference/adonis.html)
or
[`vegan::betadisper()`](https://vegandevs.github.io/vegan/reference/betadisper.html),
or for clustering with
[`stats::hclust()`](https://rdrr.io/r/stats/hclust.html).

## Usage

``` r
beta_dist(x, component = NULL, q = NULL)
```

## Arguments

- x:

  A `td_beta_pair` tibble from
  [`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
  or a `td_beta_hill_pair` tibble from
  [`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md),
  without groups.

- component:

  For
  [`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
  output: `"total"`, `"turnover"` or `"nestedness"` (default `"total"`).
  For
  [`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md)
  output: one of its `dis_` columns (default `"dis_sorensen"`).

- q:

  For
  [`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md)
  output with several orders, the order to use.

## Value

A `dist` object labelled with the site names, in their order of first
appearance.

## Examples

``` r
d <- beta_dist(beta_pair(png_ants[png_ants$season == "wet", ]))
hclust(d)
#> 
#> Call:
#> hclust(d = d)
#> 
#> Cluster method   : complete 
#> Number of objects: 5 
#> 

wet <- png_ants[png_ants$season == "wet", ]
beta_dist(beta_hill_pair(wet, abundance = workers), q = 2)
#>           MW0200    MW0700    MW1200    MW1700
#> MW0700 0.8931865                              
#> MW1200 0.8934988 0.5378074                    
#> MW1700 0.9999783 0.9999473 0.9493274          
#> MW2200 1.0000000 1.0000000 1.0000000 0.9811531
```
