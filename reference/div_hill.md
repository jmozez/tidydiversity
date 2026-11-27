# Observed Hill numbers

Computes Hill numbers of order `q` for each site from the observed
relative abundances. Order 0 is species richness, order 1 is the
exponential of Shannon entropy and order 2 is the inverse Simpson index.

## Usage

``` r
div_hill(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = c(0, 1, 2),
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

  Orders of diversity, non-negative numbers.

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

A tibble with the grouping columns, the site column, `q`, `n` (number of
individuals, or of sampling units for incidence data) and `diversity`.
Phylogenetic and functional results also have `type` and `reftime` or
`tau`.

## References

Hill, M. O. (1973). Diversity and evenness: a unifying notation and its
consequences. Ecology, 54, 427-432.
[doi:10.2307/1934352](https://doi.org/10.2307/1934352)

Chao, A., Chiu, C.-H. and Jost, L. (2014). Unifying species diversity,
phylogenetic diversity, functional diversity, and related similarity and
differentiation measures through Hill numbers. Annual Review of Ecology,
Evolution, and Systematics, 45, 297-324.
[doi:10.1146/annurev-ecolsys-120213-091540](https://doi.org/10.1146/annurev-ecolsys-120213-091540)

Chao, A., Chiu, C.-H., Villeger, S., Sun, I.-F., Thorn, S., Lin, Y.-C.,
Chiang, J.-M. and Sherwin, W. B. (2019). An attribute-diversity approach
to functional diversity, functional beta diversity, and related
(dis)similarity measures. Ecological Monographs, 89, e01343.
[doi:10.1002/ecm.1343](https://doi.org/10.1002/ecm.1343)

## Examples

``` r
div_hill(png_ants, .by = season)
#> # A tibble: 30 × 5
#>    season site       q     n diversity
#>    <chr>  <chr>  <dbl> <dbl>     <dbl>
#>  1 dry    MW0200     0    47     16   
#>  2 dry    MW0200     1    47     12.3 
#>  3 dry    MW0200     2    47      9.91
#>  4 dry    MW0700     0    23     15   
#>  5 dry    MW0700     1    23     11.8 
#>  6 dry    MW0700     2    23      8.67
#>  7 dry    MW1200     0    29     13   
#>  8 dry    MW1200     1    29      9.37
#>  9 dry    MW1200     2    29      6.73
#> 10 dry    MW1700     0    17      5   
#> # ℹ 20 more rows

# Grouped data frames work too
png_ants |>
  dplyr::group_by(season) |>
  div_hill(q = c(0, 0.5, 1, 2))
#> # A tibble: 40 × 5
#>    season site       q     n diversity
#>    <chr>  <chr>  <dbl> <dbl>     <dbl>
#>  1 dry    MW0200   0      47     16   
#>  2 dry    MW0200   0.5    47     14.0 
#>  3 dry    MW0200   1      47     12.3 
#>  4 dry    MW0200   2      47      9.91
#>  5 dry    MW0700   0      23     15   
#>  6 dry    MW0700   0.5    23     13.5 
#>  7 dry    MW0700   1      23     11.8 
#>  8 dry    MW0700   2      23      8.67
#>  9 dry    MW1200   0      29     13   
#> 10 dry    MW1200   0.5    29     11.1 
#> # ℹ 30 more rows

# Incidence data: each bait is a sampling unit, 60 baits per site
div_hill(png_ants, unit = bait, n_units = baits, .by = season)
#> # A tibble: 30 × 5
#>    season site       q     n diversity
#>    <chr>  <chr>  <dbl> <int>     <dbl>
#>  1 dry    MW0200     0    60     16   
#>  2 dry    MW0200     1    60     12.3 
#>  3 dry    MW0200     2    60      9.91
#>  4 dry    MW0700     0    60     15   
#>  5 dry    MW0700     1    60     11.8 
#>  6 dry    MW0700     2    60      8.67
#>  7 dry    MW1200     0    60     13   
#>  8 dry    MW1200     1    60      9.37
#>  9 dry    MW1200     2    60      6.73
#> 10 dry    MW1700     0    60      5   
#> # ℹ 20 more rows

# TD, PD and FD together, here for a functional distance matrix only
d <- as.matrix(stats::dist(c(s1 = 0, s2 = 0.1, s3 = 0.5, s4 = 1)))
toy <- data.frame(
  site = rep(c("a", "b"), each = 4), species = paste0("s", 1:4),
  n = c(10, 5, 2, 1, 3, 3, 1, 1)
)
div_hill(toy, abundance = n, type = c("TD", "FD"), distance = d)
#> # A tibble: 12 × 6
#>    site      q     n diversity type     tau
#>    <chr> <dbl> <dbl>     <dbl> <fct>  <dbl>
#>  1 a         0    18      4    TD    NA    
#>  2 a         1    18      2.97 TD    NA    
#>  3 a         2    18      2.49 TD    NA    
#>  4 b         0     8      4    TD    NA    
#>  5 b         1     8      3.51 TD    NA    
#>  6 b         2     8      3.2  TD    NA    
#>  7 a         0    18      3.23 FD     0.245
#>  8 a         1    18      2.07 FD     0.245
#>  9 a         2    18      1.71 FD     0.245
#> 10 b         0     8      3.26 FD     0.245
#> 11 b         1     8      2.48 FD     0.245
#> 12 b         2     8      2.09 FD     0.245
```
