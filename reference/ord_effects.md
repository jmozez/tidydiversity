# Simple and conditional effects of explanatory variables

The two tables CANOCO reports for the explanatory variables of a
constrained ordination:

## Usage

``` r
ord_effects(
  x,
  permutations = 999,
  design = NULL,
  adjust = c("holm", "fdr", "bonferroni", "none")
)
```

## Arguments

- x:

  A constrained `td_ordination` from
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md).

- permutations:

  Number of permutations.

- design:

  Optional restricted permutation design from
  [`ord_design()`](https://tidydiversity.in4metrix.dev/reference/ord_design.md).

- adjust:

  Method for adjusting p-values
  ([`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html)):
  `"holm"`, `"fdr"`, `"bonferroni"` or `"none"`.

## Value

A tibble with `effect` (`"simple"` or `"conditional"`), `term`,
`explained` (variance or inertia), `explained_pct` (percent of the
total), `statistic` (pseudo-F), `p.value` and `p.adjusted`.

## Details

- **simple effects**: the variation each variable explains on its own (a
  separate analysis with only that variable), with its own permutation
  test;

- **conditional effects**: the variation each variable adds to those
  before it, in the order of the formula (or the order chosen by
  [`ord_select()`](https://tidydiversity.in4metrix.dev/reference/ord_select.md)),
  with its permutation test.

Testing many variables inflates the chance of false positives, so
adjusted p-values are given as well (Holm by default, or the false
discovery rate, as in CANOCO 5).

## Examples

``` r
v <- community_long(vare_species, cols = -site)
o <- ord_fit(v, abundance = abundance, method = "cca",
  formula = ~ Al + P + K, env = vare_env, permutations = 0)
ord_effects(o, permutations = 199)
#> # A tibble: 6 × 7
#>   effect      term  explained explained_pct statistic p.value p.adjusted
#>   <chr>       <chr>     <dbl>         <dbl>     <dbl>   <dbl>      <dbl>
#> 1 simple      Al        0.298         14.3       3.67   0.005      0.015
#> 2 simple      P         0.189          9.06      2.19   0.025      0.05 
#> 3 simple      K         0.162          7.80      1.86   0.075      0.075
#> 4 conditional Al        0.298         14.3       4.14   0.005      0.015
#> 5 conditional P         0.190          9.12      2.64   0.01       0.02 
#> 6 conditional K         0.156          7.49      2.17   0.025      0.025
```
