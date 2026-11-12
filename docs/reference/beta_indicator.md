# Indicator species analysis

Finds species associated with groups of sites (Dufrene and Legendre
1997; De Caceres et al. 2010) using
[`indicspecies::multipatt()`](https://rdrr.io/pkg/indicspecies/man/multipatt.html),
and returns a tidy table.

## Usage

``` r
beta_indicator(
  data,
  site = site,
  species = species,
  abundance = NULL,
  group,
  env = NULL,
  func = c("IndVal.g", "IndVal", "r.g", "r"),
  combinations = FALSE,
  adjust = "holm",
  alpha = 0.05,
  permutations = 999
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

- group:

  Site variable (unquoted) defining the groups.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- func:

  `"IndVal.g"` (group-equalised indicator value, the default),
  `"IndVal"`, `"r.g"` or `"r"` (point-biserial correlation).

- combinations:

  Allow species to indicate combinations of groups?

- adjust:

  Correction for testing many species at once, passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html): `"holm"`
  (the default, controls the family-wise error rate), `"fdr"` (false
  discovery rate) or `"none"`.

- alpha:

  Return only species with adjusted `p.adj <= alpha`; `1` for all.

- permutations:

  Number of permutations for the tests of passive variables.

## Value

A tibble with `species`, `group` (the group or combination the species
indicates), `stat`, `A` (specificity) and `B` (fidelity; for IndVal
only), the permutation `p.value` and the adjusted `p.adj`, sorted by
group and decreasing `stat`.

## Details

Every species is tested, so with many species some reach
`p.value < 0.05` by chance. Following De Caceres et al. (2010) and
Legendre and Legendre (2012), p-values are corrected for multiple
testing before species are selected.

## References

Dufrene, M. and Legendre, P. (1997). Species assemblages and indicator
species: the need for a flexible asymmetrical approach. *Ecological
Monographs*, 67, 345-366.
[doi:10.1890/0012-9615(1997)067\[0345:SAAIST\]2.0.CO;2](https://doi.org/10.1890/0012-9615%281997%29067%5B0345%3ASAAIST%5D2.0.CO%3B2)

De Caceres, M., Legendre, P. and Moretti, M. (2010). Improving indicator
species analysis by combining groups of sites. *Oikos*, 119, 1674-1684.
[doi:10.1111/j.1600-0706.2010.18334.x](https://doi.org/10.1111/j.1600-0706.2010.18334.x)

## Examples

``` r
ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect),
                      zone = ifelse(elevation <= 700, "lowland", "montane"))
set.seed(1)
beta_indicator(ants, site = unit, group = zone, permutations = 199)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: species <chr>, group <chr>, stat <dbl>, A <dbl>, B <dbl>,
#> #   p.value <dbl>, p.adj <dbl>
```
