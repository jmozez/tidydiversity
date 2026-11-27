# Shared, lost and gained species between pairs of sites

For each pair of sites, `beta_turnover_counts()` counts the species they
share, the species found only in the first site (lost on moving to the
second) and only in the second (gained), and gives the pairwise
dissimilarities with Baselga's partitions:

- `sorensen` = `turnover` (Simpson dissimilarity, beta.sim) +
  `nestedness` (beta.sne) (Baselga 2010);

- `jaccard` = `turnover_j` + `nestedness_j` (Baselga 2012);

- with abundances, `bray` = `balanced` (balanced variation in
  abundance) + `gradient` (abundance gradient) (Baselga 2013).

The values equal those of the betapart package. Along a gradient, use
`pairs = "adjacent"` with `order_by` to compare each site with the next.

A site with no species makes the dissimilarities undefined (0 / 0 when
both sites are empty, or a pure loss): such pairs are returned with a
warning, their counts are kept and undefined indices are `NA`.

## Usage

``` r
beta_turnover_counts(
  data,
  site = site,
  species = species,
  abundance = NULL,
  pairs = "adjacent",
  order_by = NULL,
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

- pairs:

  `"adjacent"` (each site with the next in `order_by` order), `"all"`
  (every pair), or a data frame with two columns of site names.

- order_by:

  Column giving the order of sites for `"adjacent"` pairs, such as
  elevation; by default the natural site order.

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, `site_1`, `site_2`, `s_1`, `s_2`
(richness), `shared`, `lost`, `gained`, `sorensen`, `turnover`,
`nestedness`, `jaccard`, `turnover_j`, `nestedness_j`, and with
abundances `bray`, `balanced` and `gradient`.

## References

Baselga, A. (2010). Partitioning the turnover and nestedness components
of beta diversity. Global Ecology and Biogeography, 19, 134-143.

Baselga, A. (2012). The relationship between species replacement,
dissimilarity derived from nestedness, and nestedness. Global Ecology
and Biogeography, 21, 1223-1232.

Baselga, A. (2013). Separating the two components of abundance-based
dissimilarity: balanced changes in abundance vs. abundance gradients.
Methods in Ecology and Evolution, 4, 552-557.

## Examples

``` r
wet <- dplyr::filter(png_ants, season == "wet")
beta_turnover_counts(wet, abundance = workers, order_by = elevation)
#> # A tibble: 4 × 16
#>   site_1 site_2   s_1   s_2 shared  lost gained sorensen turnover nestedness
#>   <chr>  <chr>  <int> <int>  <int> <int>  <int>    <dbl>    <dbl>      <dbl>
#> 1 MW0200 MW0700    21    28      8    13     20    0.673    0.619     0.0544
#> 2 MW0700 MW1200    28    20      9    19     11    0.625    0.55      0.0750
#> 3 MW1200 MW1700    20    10      4    16      6    0.733    0.6       0.133 
#> 4 MW1700 MW2200    10     5      1     9      4    0.867    0.8       0.0667
#> # ℹ 6 more variables: jaccard <dbl>, turnover_j <dbl>, nestedness_j <dbl>,
#> #   bray <dbl>, balanced <dbl>, gradient <dbl>
```
