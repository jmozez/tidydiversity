# Coverage-standardised beta diversity with Hill numbers

Gamma, alpha and beta diversity of order q, standardised to a common
sample coverage, following Chao et al. (2023) (the iNEXT.beta3D
framework). Each `.by` group is a region whose sites are its
assemblages. Gamma diversity is the diversity of the pooled region;
alpha diversity is computed from the species-by-site data and divided by
the number of sites; each is rarefied or extrapolated to the sample size
at which it reaches the target coverage. Beta = gamma / alpha is the
effective number of completely distinct assemblages (1 to N).

## Usage

``` r
beta_hill(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = c(0, 1, 2),
  coverage = NULL,
  type = c("TD", "PD", "FD"),
  tree = NULL,
  reftime = NULL,
  pd_unit = c("mean", "total"),
  distance = NULL,
  tau = NULL,
  unit = NULL,
  n_units = NULL,
  nboot = 0,
  conf = 0.95,
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

  Orders of diversity.

- coverage:

  Target sample coverage(s) in (0, 1\]. By default, the lowest coverage
  that the pooled data of every region reaches at twice its sample size,
  so no region is extrapolated too far.

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

- nboot:

  Number of bootstrap replicates for confidence intervals; 0 for none.

- conf:

  Confidence level.

- .by:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the `.by` columns, `q`, `coverage`, the sample sizes
`m_gamma` and `m_alpha`, `gamma`, `alpha`, `beta`, `n_sites`, the four
dissimilarities and, with `nboot > 0`, their confidence limits.

## Details

Standardising by coverage removes the dependence of beta diversity on
sample size and completeness, so regions sampled with different effort
can be compared (Chao et al. 2023). Four normalised dissimilarities in
0-1 are derived from beta:

- `dis_sorensen` (1 - C): Sorensen-type non-overlap;

- `dis_jaccard` (1 - U): Jaccard-type non-overlap;

- `dis_turnover_sorensen` (1 - V): Sorensen-type turnover;

- `dis_turnover_jaccard` (1 - S): Jaccard-type turnover.

For q = 0 they reduce to the classic Sorensen and Jaccard family; for q
= 1 and 2 they generalise Horn and Morisita-Horn overlap.

## Dimensions and data types

`type = "PD"` gives phylogenetic beta diversity from `tree`, and
`type = "FD"` functional beta diversity from `distance`, exactly as in
iNEXT.beta3D. Sample sizes are always those at which the taxonomic data
reach the target coverage. For FD, `tau = "auc"` integrates gamma, alpha
and beta over 30 thresholds between 0 and 1, as iNEXT.beta3D does.

With `unit`, the data are incidences: each site was surveyed in the same
`T` sampling units (plots, visits, traps), and a unit's label must
identify the same unit at every site of a region, because gamma
diversity counts a species as present in a unit if it was found there at
any site.

## Confidence intervals

With `nboot > 0`, every region is resampled as a whole (Chao et al.
2023): each site's community, including estimated undetected species, is
redrawn with its sample size (or units) and all quantities are
recomputed at the same coverage. Each estimate gets `_lower` and
`_upper` columns, the estimate -/+ z x bootstrap standard error, kept
within each quantity's range (beta in 1 to N, dissimilarities in 0 to
1).

## References

Chao, A., Thorn, S., Chiu, C.-H. et al. (2023). Rarefaction and
extrapolation with beta diversity under a framework of Hill numbers: the
iNEXT.beta3D standardization. *Ecological Monographs*, 93, e1588.
[doi:10.1002/ecm.1588](https://doi.org/10.1002/ecm.1588)

## Examples

``` r
beta_hill(png_ants, .by = season, coverage = 0.9)
#> # A tibble: 6 x 13
#>   season     q coverage m_gamma m_alpha gamma alpha  beta n_sites dis_sorensen
#>   <chr>  <dbl>    <dbl>   <dbl>   <dbl> <dbl> <dbl> <dbl>   <int>        <dbl>
#> 1 dry        0      0.9    150.    244.  44.4 14.5   3.06       5        0.516
#> 2 dry        1      0.9    150.    244.  31.0  9.93  3.12       5        0.707
#> 3 dry        2      0.9    150.    244.  23.3  6.97  3.35       5        0.877
#> 4 wet        0      0.9    260.    481.  64.1 23.5   2.73       5        0.431
#> 5 wet        1      0.9    260.    481.  35.4 12.3   2.86       5        0.654
#> 6 wet        2      0.9    260.    481.  21.4  7.08  3.02       5        0.836
#> # i 3 more variables: dis_jaccard <dbl>, dis_turnover_sorensen <dbl>,
#> #   dis_turnover_jaccard <dbl>
```
