# Temporal beta diversity: losses and gains at each site

Compares the composition of each site at two times with the temporal
beta diversity index (TBI) of Legendre (2019). The dissimilarity of each
site between the two surveys is split into species losses (`b`) and
gains (`c`), and a permutation test identifies the sites whose change is
exceptional. With the percentage difference (Bray-Curtis) the losses and
gains are in abundance; with Sorensen and Jaccard they are in species.
The results match `adespatial::TBI()`.

## Usage

``` r
beta_tbi(
  data,
  time,
  site = site,
  species = species,
  abundance = NULL,
  index = c("bray", "sorensen", "jaccard"),
  nperm = 999,
  .by = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- time:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column with the survey time. It must have exactly two values
  within each group; the earlier (in sort order or factor level) is the
  first survey.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- index:

  `"bray"` (percentage difference, default), `"sorensen"` or
  `"jaccard"`.

- nperm:

  Number of permutations for the test of each site. Each species is
  permuted independently among sites at both times. Use `0` to skip the
  test.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_tbi` tibble with the grouping columns, the site column, `losses`
and `gains` (B/den and C/den of Legendre 2019, which sum to `tbi`),
`tbi`, `change` (`"loss"`, `"gain"` or `"none"`, whichever is larger),
`p_value` and `p_adjusted` (Holm).

## References

Legendre, P. (2019). A temporal beta-diversity index to identify sites
that have changed in exceptional ways in space-time surveys. Ecology and
Evolution, 9, 3500-3514.
[doi:10.1002/ece3.4984](https://doi.org/10.1002/ece3.4984)

## Examples

``` r
set.seed(1)
surveys <- subset(portal_rodents, year %in% c(2016, 2019))
beta_tbi(surveys, time = year, site = plot, nperm = 99)
#> # A tibble: 24 × 7
#>     plot losses  gains   tbi change p_value p_adjusted
#>    <int>  <dbl>  <dbl> <dbl> <chr>    <dbl>      <dbl>
#>  1     1 0.622  0.0541 0.676 loss      0.12       1   
#>  2     2 0.113  0.0397 0.152 loss      0.94       1   
#>  3     3 0.442  0.0442 0.487 loss      0.39       1   
#>  4     4 0.258  0.0710 0.329 loss      0.7        1   
#>  5     5 0.395  0      0.395 loss      0.49       1   
#>  6     6 0.225  0.0490 0.275 loss      0.78       1   
#>  7     7 0.228  0.0652 0.293 loss      0.75       1   
#>  8     8 0.0859 0.117  0.203 gain      0.92       1   
#>  9     9 0.190  0.143  0.333 loss      0.61       1   
#> 10    10 0.889  0.111  1     loss      0.01       0.24
#> # ℹ 14 more rows
```
