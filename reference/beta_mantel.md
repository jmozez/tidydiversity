# Mantel and partial Mantel tests

`beta_mantel()` tests whether two distance matrices are correlated, for
example community dissimilarity and elevational or geographic distance,
with the Mantel test (Mantel 1967). With `z`, it gives the partial
Mantel test of `x` and `y` controlling for `z` (Smouse et al. 1986).
Significance comes from permuting the sites of `x` (vegan's
[`vegan::mantel()`](https://vegandevs.github.io/vegan/reference/mantel.html)
and
[`vegan::mantel.partial()`](https://vegandevs.github.io/vegan/reference/mantel.html)).

Pairs of sites are not independent, so do not test distance-decay
relationships with ordinary regression p-values; use this test instead.
With few sites, use `permutations = "exact"` to enumerate every ordering
of the sites (n!; 5,040 for 7 sites); the p-value is then exact.

`alternative` sets the tail: `"greater"` (the default) tests for a
positive correlation, `"less"` for a negative one (for example
similarity decreasing with distance), `"two.sided"` for either.

## Usage

``` r
beta_mantel(
  x,
  y,
  z = NULL,
  method = c("spearman", "pearson", "kendall"),
  permutations = 9999,
  alternative = c("greater", "less", "two.sided"),
  strata = NULL,
  seed = NULL
)
```

## Arguments

- x, y, z:

  Distance matrices: `dist` objects (such as the result of
  [`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md)),
  square matrices, or, for `y` and `z`, a numeric vector of site values
  (such as elevation), from which Euclidean distances are computed. All
  must describe the same sites in the same order; when they carry
  labels, the labels are matched.

- method:

  Correlation: `"spearman"` (default), `"pearson"` or `"kendall"`.

- permutations:

  Number of permutations, or `"exact"`.

- alternative:

  `"greater"`, `"less"` or `"two.sided"`.

- strata:

  Optional grouping of sites within which permutations are restricted.

- seed:

  Optional random seed.

## Value

A one-row tibble with `statistic` (the Mantel r), `p.value`,
`alternative`, `permutations`, `exact`, `method` and `partial`.

## References

Mantel, N. (1967). The detection of disease clustering and a generalized
regression approach. Cancer Research, 27, 209-220.

Smouse, P. E., Long, J. C. and Sokal, R. R. (1986). Multiple regression
and correlation extensions of the Mantel test of matrix correspondence.
Systematic Zoology, 35, 627-632.

## Examples

``` r
wet <- dplyr::filter(png_ants, season == "wet")
d_beta <- beta_dist(beta_pair(wet), "turnover")
elev <- dplyr::distinct(wet, site, elevation)
beta_mantel(d_beta, stats::setNames(elev$elevation, elev$site),
  permutations = "exact"
)
#> # A tibble: 1 × 7
#>   statistic p.value alternative permutations exact method   partial
#>       <dbl>   <dbl> <chr>              <int> <lgl> <chr>    <lgl>  
#> 1     0.848  0.0167 greater              119 TRUE  spearman FALSE  
```
