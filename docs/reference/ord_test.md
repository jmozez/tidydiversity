# Permutation tests for constrained ordinations

Tests the significance of a constrained ordination
([`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
with `"rda"`, `"cca"` or `"dbrda"`) by permutation, with
[`vegan::anova.cca()`](https://rdrr.io/pkg/vegan/man/anova.cca.html),
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
ord <- ord_fit(png_frogs, method = "cca", formula = ~elevation)
ord_test(ord, permutations = 199)
#> # A tibble: 2 x 5
#>   term        df chi_square statistic p.value
#>   <chr>    <dbl>      <dbl>     <dbl>   <dbl>
#> 1 Model        1      0.959      1.44   0.005
#> 2 Residual     6      4.00      NA     NA    
```
