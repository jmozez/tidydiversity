# Permutation tests for constrained ordinations

Tests the significance of a constrained ordination
([`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
with `"rda"`, `"cca"` or `"dbrda"`) by permutation, with
[`vegan::anova.cca()`](https://vegandevs.github.io/vegan/reference/anova.cca.html),
and returns a tidy table.

## Usage

``` r
ord_test(x, by = c("model", "axis", "terms", "margin"), permutations = 999)
```

## Arguments

- x:

  A `td_ordination` from a constrained method.

- by:

  `"model"` (the whole model, the default), `"axis"` (each constrained
  axis), `"terms"` (each term, added sequentially) or `"margin"` (each
  term given the others).

- permutations:

  Number of permutations.

## Value

A tibble with `term`, `df`, `variance` (or `chi_square` for CCA),
`statistic` (pseudo-F) and `p.value`.

## Examples

``` r
data("dune", "dune.env", package = "vegan")
d <- community_long(cbind(site = rownames(dune), dune.env, dune),
  cols = dplyr::all_of(names(dune))
)
ord <- ord_fit(d, abundance = abundance, method = "cca", formula = ~ A1 + Management)
ord_test(ord, permutations = 199)
#> # A tibble: 2 × 5
#>   term        df chi_square statistic p.value
#>   <chr>    <dbl>      <dbl>     <dbl>   <dbl>
#> 1 Model        4      0.780      2.19   0.005
#> 2 Residual    15      1.34      NA     NA    
ord_test(ord, by = "margin", permutations = 199)
#> # A tibble: 3 × 5
#>   term          df chi_square statistic p.value
#>   <chr>      <dbl>      <dbl>     <dbl>   <dbl>
#> 1 A1             1      0.176      1.98   0.05 
#> 2 Management     3      0.555      2.08   0.005
#> 3 Residual      15      1.34      NA     NA    
```
