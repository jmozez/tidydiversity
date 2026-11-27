# Restricted permutation designs

Describes how sites may be shuffled in a permutation test when they are
not independent, as the permutation options of CANOCO do. Give the
result as `design` to
[`ord_test()`](https://tidydiversity.in4metrix.dev/reference/ord_test.md),
[`ord_select()`](https://tidydiversity.in4metrix.dev/reference/ord_select.md)
or
[`ord_effects()`](https://tidydiversity.in4metrix.dev/reference/ord_effects.md).

- **Blocks** (`blocks`): sites are shuffled only within blocks, never
  between them. Use for randomised block designs; as in CANOCO, also add
  the blocks as covariables (`+ Condition(block)` in the formula).

- **Split-plot** (`plots`): whole plots (groups of sites) are shuffled
  as units (`plots_type`), and the sites within each plot are shuffled
  (`within`) or kept in place (`within = "none"`). Use when a treatment
  is applied to whole plots.

- **Time series and transects** (`within = "series"`): sites keep their
  order and are shifted cyclically, which keeps temporal or spatial
  autocorrelation intact.

- **Rectangular grids** (`within = "grid"`, with `nrow` and `ncol`):
  toroidal shifts of a grid of sites.

Sites must be in the order the design describes (time, or the grid row
by row), which is the order of the site column after sorting.

## Usage

``` r
ord_design(
  blocks = NULL,
  plots = NULL,
  within = c("free", "series", "grid", "none"),
  plots_type = c("none", "free", "series", "grid"),
  nrow = NULL,
  ncol = NULL,
  mirror = FALSE
)
```

## Arguments

- blocks:

  Name of the site variable defining blocks.

- plots:

  Name of the site variable defining whole plots.

- within:

  How sites are shuffled within plots (or within blocks, or overall):
  `"free"`, `"series"`, `"grid"` or `"none"`.

- plots_type:

  How whole plots are shuffled: `"none"` (kept in place), `"free"`,
  `"series"` or `"grid"`.

- nrow, ncol:

  Grid dimensions for `"grid"`.

- mirror:

  Also use mirror images of series and grids.

## Value

A `td_design` object.

## References

Leps, J. and Smilauer, P. (2003). *Multivariate Analysis of Ecological
Data using CANOCO*. Cambridge University Press. Chapter 5.

Simpson, G. L. (2022). permute: Functions for Generating Restricted
Permutations of Data. R package.

## Examples

``` r
d <- community_long(dune_species, cols = -site)
o <- ord_fit(d, abundance = abundance, method = "rda", formula = ~ A1,
  env = dune_env, permutations = 0)
# shuffle sites only within management types
ord_test(o, permutations = 199, design = ord_design(blocks = "Management"))
#> # A tibble: 2 × 5
#>   term        df variance statistic p.value
#>   <chr>    <dbl>    <dbl>     <dbl>   <dbl>
#> 1 Model        1   0.0722      2.68     0.1
#> 2 Residual    18   0.484      NA       NA  
```
