# Pairwise Hill-number dissimilarity

For every pair of sites, `beta_hill_pair()` computes gamma, alpha and
beta diversity of order `q` from the observed abundances. It also gives
the four normalised dissimilarities of Chao, Chiu and Jost (2014) for
two assemblages, with the same names as in
[`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md):
`dis_sorensen` (\\1 - C\_{qN}\\), `dis_jaccard` (\\1 - U\_{qN}\\),
`dis_turnover_sorensen` (\\1 - V\_{qN}\\) and `dis_turnover_jaccard`
(\\1 - S\_{qN}\\). Classic indices are special cases:

## Usage

``` r
beta_hill_pair(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = c(0, 1, 2),
  weight = c("equal", "size"),
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

  Orders of diversity, between 0 and 3 (non-negative numbers).

- weight:

  `"equal"` or `"size"`, as described above.

- .by:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_beta_hill_pair` tibble with the grouping columns, `site_1`,
`site_2`, `q`, `gamma`, `alpha`, `beta` and the four `dis_` columns.
[`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md)
turns one order into a distance matrix, and
[`ggplot2::autoplot()`](https://rdrr.io/pkg/ggplot2/man/autoplot.html)
draws it as a heatmap.

## Details

|         |                |                  |
|---------|----------------|------------------|
| Order   | `dis_sorensen` | `dis_jaccard`    |
| `q = 0` | Sorensen       | Jaccard          |
| `q = 1` | Horn           | Horn             |
| `q = 2` | Morisita-Horn  | Regional overlap |

With `weight = "equal"` (the default) each site's abundances are turned
into relative abundances before pooling, so a heavily sampled site does
not dominate the pair, and `q = 2` gives Morisita-Horn exactly. With
`weight = "size"` raw abundances are pooled, as in
[`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md)
and iNEXT.beta3D. At `q = 0` the weighting makes no difference.

These are empirical values. Use
[`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md)
to compare whole sets of sites at a standardised sample coverage.

## References

Chao, A., Chiu, C.-H. and Jost, L. (2014). Unifying species diversity,
phylogenetic diversity, functional diversity, and related similarity and
differentiation measures through Hill numbers. *Annual Review of
Ecology, Evolution, and Systematics*, 45, 297-324.
[doi:10.1146/annurev-ecolsys-120213-091540](https://doi.org/10.1146/annurev-ecolsys-120213-091540)

Jost, L. (2007). Partitioning diversity into independent alpha and beta
components. *Ecology*, 88, 2427-2439.
[doi:10.1890/06-1736.1](https://doi.org/10.1890/06-1736.1)

## Examples

``` r
beta_hill_pair(png_ants, abundance = workers, .by = season)
#> # A tibble: 60 x 11
#>    season site_1 site_2     q gamma alpha  beta dis_sorensen dis_jaccard
#>    <chr>  <chr>  <chr>  <dbl> <dbl> <dbl> <dbl>        <dbl>       <dbl>
#>  1 dry    MW0200 MW0700     0    26  15.5  1.68        0.677       0.808
#>  2 dry    MW0200 MW1200     0    26  14.5  1.79        0.793       0.885
#>  3 dry    MW0200 MW1700     0    20  10.5  1.90        0.905       0.95 
#>  4 dry    MW0200 MW2200     0    22  11    2           1           1    
#>  5 dry    MW0700 MW1200     0    23  14    1.64        0.643       0.783
#>  6 dry    MW0700 MW1700     0    19  10    1.9         0.9         0.947
#>  7 dry    MW0700 MW2200     0    20  10.5  1.90        0.905       0.95 
#>  8 dry    MW1200 MW1700     0    18   9    2           1           1    
#>  9 dry    MW1200 MW2200     0    18   9.5  1.89        0.895       0.944
#> 10 dry    MW1700 MW2200     0    11   5.5  2           1           1    
#> # i 50 more rows
#> # i 2 more variables: dis_turnover_sorensen <dbl>, dis_turnover_jaccard <dbl>
```
