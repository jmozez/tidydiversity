# Tree-nesting ants in rainforest plots at three elevations, Papua New Guinea

Real field data: every ant nest in 1254 trees within continuous plots of
primary rainforest at Wanang (200 m), Numba (900 m) and Yawan (1800 m),
Papua New Guinea (Plowman et al. 2020). Only the 769 trees with at least
one nest appear. Each row is one ant species nesting in one tree.

## Usage

``` r
png_tree_ants
```

## Format

A tibble with one row per tree and ant species, and nine columns:

- site:

  Plot: `"Wanang"`, `"Numba"` or `"Yawan"`.

- elevation:

  Elevation of the plot in metres.

- subplot:

  Subplot within the plot.

- tree:

  Tree identifier.

- tree_family, tree_genus:

  Host tree family and genus.

- dbh:

  Tree diameter at breast height (cm).

- species:

  Ant morphospecies code.

- nests:

  Number of nests of the species in the tree.

## Source

Plowman, N. S., Mottl, O., Novotny, V., Idigel, C., Philip, F. J. and
Klimes, P. (2019). Data from: Nest microhabitats and tree size mediate
shifts in ant community structure across elevation in tropical
rainforest canopies. Dryad.
[doi:10.5061/dryad.2fqz612k6](https://doi.org/10.5061/dryad.2fqz612k6) ,
released under CC0 1.0. Built by `data-raw/png_tree_ants.R`.

## References

Plowman, N. S., Mottl, O., Novotny, V., Idigel, C., Philip, F. J.,
Rimandai, M. and Klimes, P. (2020). Nest microhabitats and tree size
mediate shifts in ant community structure across elevation in tropical
rainforest canopies. *Ecography*, 43, 431-442.
[doi:10.1111/ecog.04730](https://doi.org/10.1111/ecog.04730)

## Examples

``` r
png_tree_ants
#> # A tibble: 1,750 × 9
#>    site   elevation subplot tree     tree_family  tree_genus   dbh species nests
#>    <chr>      <int> <chr>   <chr>    <chr>        <chr>      <dbl> <chr>   <int>
#>  1 Wanang       200 B       WP4A0960 Euphorbiace… Macaranga      9 ANON_0…     2
#>  2 Wanang       200 B       WP4A0960 Euphorbiace… Macaranga      9 CAMP_0…     1
#>  3 Wanang       200 B       WP4A0962 Euphorbiace… Mallotus       5 POLY_0…     1
#>  4 Wanang       200 B       WP4A0963 Rubiaceae    Mastixiod…    84 CAMP_0…     1
#>  5 Wanang       200 B       WP4A0963 Rubiaceae    Mastixiod…    84 CREM_0…     2
#>  6 Wanang       200 B       WP4A0963 Rubiaceae    Mastixiod…    84 CREM_0…     1
#>  7 Wanang       200 B       WP4A0963 Rubiaceae    Mastixiod…    84 DIAC_0…     1
#>  8 Wanang       200 B       WP4A0963 Rubiaceae    Mastixiod…    84 PARA_0…     1
#>  9 Wanang       200 B       WP4A0963 Rubiaceae    Mastixiod…    84 PHEI_0…     1
#> 10 Wanang       200 B       WP4A0963 Rubiaceae    Mastixiod…    84 PHEI_0…     1
#> # ℹ 1,740 more rows
# Nest counts per plot, trees pooled
div_estimate(png_tree_ants, site = site, abundance = nests, nboot = 0)
#> # A tibble: 9 × 7
#>   site       q observed estimate    se lower upper
#>   <chr>  <dbl>    <dbl>    <dbl> <dbl> <dbl> <dbl>
#> 1 Numba      0   103       124.     NA    NA    NA
#> 2 Numba      1    49.5      53.6    NA    NA    NA
#> 3 Numba      2    30.1      31.2    NA    NA    NA
#> 4 Wanang     0    85       101.     NA    NA    NA
#> 5 Wanang     1    33.5      35.7    NA    NA    NA
#> 6 Wanang     2    17.8      18.1    NA    NA    NA
#> 7 Yawan      0    22        37.0    NA    NA    NA
#> 8 Yawan      1    12.0      12.4    NA    NA    NA
#> 9 Yawan      2     9.89     10.1    NA    NA    NA
# Turnover between trees within each plot
beta_multi(png_tree_ants, site = tree, .by = site)
#> # A tibble: 3 × 5
#>   site   n_sites turnover nestedness total
#>   <chr>    <int>    <dbl>      <dbl> <dbl>
#> 1 Numba      224    0.986    0.00573 0.992
#> 2 Wanang     326    0.991    0.00346 0.994
#> 3 Yawan      219    0.984    0.00570 0.990
```
