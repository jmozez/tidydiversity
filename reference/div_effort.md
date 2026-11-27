# Additional sampling effort needed

`div_effort()` answers the planning question "how much more do I need to
sample?" for each site. It gives the number of additional individuals
(abundance data) or sampling units (incidence data: traps, plots, days)
needed to reach

- a target **sample coverage** (`coverage`), from the coverage
  extrapolation of Chao and Jost (2012); and/or

- a target **fraction of the estimated richness** (`fraction`), that is
  detecting `fraction` x Chao1 (or Chao2) species, as proposed by Chao
  et al. (2009). The richness extrapolation of Shen et al. (2003) is
  solved exactly, so the answer agrees with the extrapolated curves of
  [`div_rarefy()`](https://tidydiversity.in4metrix.dev/reference/div_rarefy.md).

Targets the sample has already reached give zero. A target fraction of 1
cannot be reached with finite effort and is refused; fractions of 0.8 to
0.95 are typical. Extrapolating far beyond about twice or three times
the current sample is uncertain, so treat large values as indications of
order of magnitude.

## Usage

``` r
div_effort(
  data,
  site = site,
  species = species,
  abundance = NULL,
  unit = NULL,
  n_units = NULL,
  coverage = c(0.9, 0.95),
  fraction = c(0.8, 0.9),
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

- coverage:

  Target coverage levels in (0, 1).

- fraction:

  Target fractions of the estimated richness in (0, 1).

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, the site column, `n` (current sample
size), `s_obs`, `coverage_now`, `s_est` (Chao1 or Chao2), `target`
(`"coverage"` or `"fraction"`), `level`, `additional` (additional
individuals or units, rounded up) and `total`.

## References

Chao, A., Colwell, R. K., Lin, C.-W. and Gotelli, N. J. (2009).
Sufficient sampling for asymptotic minimum species richness estimators.
Ecology, 90, 1125-1133.
[doi:10.1890/07-2147.1](https://doi.org/10.1890/07-2147.1)

Chao, A. and Jost, L. (2012). Coverage-based rarefaction and
extrapolation: standardizing samples by completeness rather than size.
Ecology, 93, 2533-2547.
[doi:10.1890/11-1952.1](https://doi.org/10.1890/11-1952.1)

Shen, T.-J., Chao, A. and Lin, C.-F. (2003). Predicting the number of
new species in further taxonomic sampling. Ecology, 84, 798-804.

## Examples

``` r
div_effort(png_ants, unit = bait, n_units = baits, .by = season)
#> # A tibble: 40 × 10
#>    season site       n s_obs coverage_now s_est target   level additional total
#>    <chr>  <chr>  <int> <int>        <dbl> <dbl> <chr>    <dbl>      <dbl> <dbl>
#>  1 dry    MW0200    60    16        0.897  18.5 coverage  0.9           1    61
#>  2 dry    MW0200    60    16        0.897  18.5 coverage  0.95         22    82
#>  3 dry    MW0200    60    16        0.897  18.5 fraction  0.8           0    60
#>  4 dry    MW0200    60    16        0.897  18.5 fraction  0.9           9    69
#>  5 dry    MW0700    60    15        0.480  85.8 coverage  0.9         585   645
#>  6 dry    MW0700    60    15        0.480  85.8 coverage  0.95        831   891
#>  7 dry    MW0700    60    15        0.480  85.8 fraction  0.8         503   563
#>  8 dry    MW0700    60    15        0.480  85.8 fraction  0.9         749   809
#>  9 dry    MW1200    60    13        0.762  21.0 coverage  0.9          61   121
#> 10 dry    MW1200    60    13        0.762  21.0 coverage  0.95        109   169
#> # ℹ 30 more rows
```
