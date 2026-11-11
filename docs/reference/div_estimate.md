# Asymptotic diversity estimates

Estimates the asymptotic Hill numbers of order 0, 1 and 2 for each site
using the Chao1 richness estimator, the Chao et al. (2013) Shannon
estimator and the unbiased Simpson estimator. Standard errors and
confidence intervals come from bootstrap resampling of the estimated
community, as in iNEXT.

## Usage

``` r
div_estimate(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = c(0, 1, 2),
  conf = 0.95,
  nboot = 50,
  ci = c("lognormal", "normal"),
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

- conf:

  Confidence level of the intervals.

- nboot:

  Number of bootstrap replicates. Use 0 to skip them. For PD and FD the
  bootstrap community adds undetected species with estimated branch
  lengths (PD) or distances (FD); see Details in `div_estimate()`.

- ci:

  How to build the confidence intervals from the bootstrap standard
  error. With `"lognormal"` (the default) the richness (q = 0) interval
  uses the log-transformation of Chao (1987), as in SpadeR, so it is
  asymmetric and its lower limit never falls below the observed
  richness; orders 1 and 2 use `estimate +/- z * se`. With `"normal"`
  every order uses `estimate +/- z * se`, as in
  [`iNEXT::iNEXT()`](https://rdrr.io/pkg/iNEXT/man/iNEXT.html). In both
  cases the lower limit is truncated at the observed diversity, which
  the asymptotic diversity cannot fall below.

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

A tibble with the grouping columns, the site column, `q`, `observed`,
`estimate`, `se`, `lower` and `upper`.

## Details

For `type = "PD"` and `type = "FD"` the bootstrap resamples an estimated
community that includes undetected species, as for taxonomic diversity.
Under PD each undetected species is given its own branch, of length
equal to the estimated undetected branch length divided by the estimated
number of undetected species (Chao et al. 2015; Hsieh and Chao 2017).
Under FD undetected species are assumed to resemble the rarest observed
species: their distance to each observed species is the mean distance
from the singletons to that species, and their distance to each other is
the mean distance among the singletons. The reference time (PD) and
threshold `tau` (FD) are held fixed across replicates.

## References

Chao, A., Gotelli, N. J., Hsieh, T. C., Sander, E. L., Ma, K. H.,
Colwell, R. K. and Ellison, A. M. (2014). Rarefaction and extrapolation
with Hill numbers. Ecological Monographs, 84, 45-67.
[doi:10.1890/13-0133.1](https://doi.org/10.1890/13-0133.1)

Chao, A. (1987). Estimating the population size for capture-recapture
data with unequal catchability. Biometrics, 43, 783-791.
[doi:10.2307/2531532](https://doi.org/10.2307/2531532)

## Examples

``` r
set.seed(1)
div_estimate(png_ants, .by = season, nboot = 20)
#> # A tibble: 30 x 8
#>    season site       q observed estimate    se lower upper
#>    <chr>  <chr>  <dbl>    <dbl>    <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0    16        18.4  6.36 16.1   56.5
#>  2 dry    MW0200     1    12.3      15.2  1.34 12.6   17.8
#>  3 dry    MW0200     2     9.91     12.3  1.65  9.91  15.5
#>  4 wet    MW0200     0    21        32.9 11.0  23.6   76.2
#>  5 wet    MW0200     1    10.9      13.8  2.71 10.9   19.1
#>  6 wet    MW0200     2     6.99      7.6  1.32  6.99  10.2
#>  7 dry    MW0700     0    15        83.9 24.6  50.0  151. 
#>  8 dry    MW0700     1    11.8      38.5 11.6  15.7   61.2
#>  9 dry    MW0700     2     8.67     13.3  7.60  8.67  28.2
#> 10 wet    MW0700     0    28        75.3 32.1  42.2  186. 
#> # i 20 more rows

# Incidence-based (Chao2) estimates, baits as sampling units
div_estimate(png_ants, unit = bait, n_units = baits, .by = season, nboot = 20)
#> # A tibble: 30 x 8
#>    season site       q observed estimate     se lower upper
#>    <chr>  <chr>  <dbl>    <dbl>    <dbl>  <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0    16       18.5  10.4   16.1   87.0
#>  2 dry    MW0200     1    12.3     15.2   1.71  12.3   18.6
#>  3 dry    MW0200     2     9.91    12.3   0.947 10.5   14.2
#>  4 wet    MW0200     0    21       32.9  15.4   22.7  104. 
#>  5 wet    MW0200     1    10.9     13.8   2.28  10.9   18.2
#>  6 wet    MW0200     2     6.99     7.57  1.25   6.99  10.0
#>  7 dry    MW0700     0    15       85.8  42.2   39.0  224. 
#>  8 dry    MW0700     1    11.8     39.2  18.5   11.8   75.5
#>  9 dry    MW0700     2     8.67    13.7   5.11   8.67  23.7
#> 10 wet    MW0700     0    28       75.4  26.0   45.3  158. 
#> # i 20 more rows
```
