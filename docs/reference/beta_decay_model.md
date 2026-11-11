# Fit and test a distance-decay model

Fits a nonlinear distance-decay model to the pairwise similarities from
[`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md)
and tests it by permutation, as in
[`betapart::decay.model()`](https://rdrr.io/pkg/betapart/man/decay.model.html)
(Gómez-Rodríguez and Baselga 2018). Similarity is one minus the chosen
dissimilarity component. The models are

## Usage

``` r
beta_decay_model(
  x,
  model = c("exponential", "power"),
  component = c("total", "turnover", "nestedness"),
  permutations = 999
)
```

## Arguments

- x:

  A `td_beta_decay` tibble from
  [`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md).
  Its groups are kept and fitted separately.

- model:

  `"exponential"` or `"power"`.

- component:

  Dissimilarity component turned into similarity: `"total"`,
  `"turnover"` or `"nestedness"`.

- permutations:

  Number of permutations for the test; `0` skips it.

## Value

A tibble with one row per group: `model`, `component`, `n_pairs`, `a`,
`b`, `half_distance` (the distance over which similarity halves, \\\log
2 / b\\ for the exponential model and the factor \\2^{1/b}\\ for the
power model), `pseudo_r2`, `aic` and `p.value`.

## Details

- `"exponential"`: \\S = a e^{-b d}\\ (Nekola and White 1999), and

- `"power"`: \\S = a d^{-b}\\, which needs positive distances.

Here `a` is the similarity at distance zero (exponential) or one
(power), and `b` is the rate of decay: positive values mean similarity
falls with distance. The fit is by nonlinear least squares, and the fit
statistic is the pseudo-\\R^2\\, one minus the residual deviance over
the deviance of a constant model.

Pairs of sites are not independent, so the test permutes site labels:
rows and columns of the similarity matrix are shuffled together while
the distances stay in place, as in a Mantel test, and the model is
refitted each time. The p-value is \\(1 + \\\\R^2\_{perm} \ge
R^2\_{obs}\\) / (1 + B)\\. betapart instead reports the proportion of
permuted values strictly greater than the observed one, which can be
zero; the version here cannot.

## References

Nekola, J. C. and White, P. S. (1999). The distance decay of similarity
in biogeography and ecology. *Journal of Biogeography*, 26, 867-878.
[doi:10.1046/j.1365-2699.1999.00305.x](https://doi.org/10.1046/j.1365-2699.1999.00305.x)

Gómez-Rodríguez, C. and Baselga, A. (2018). Variation among European
beetle taxa in patterns of distance decay of similarity suggests a major
role of dispersal processes. *Ecography*, 41, 1825-1834.
[doi:10.1111/ecog.03693](https://doi.org/10.1111/ecog.03693)

## Examples

``` r
decay <- beta_decay(png_ants, gradient = elevation, .by = season)
set.seed(1)
beta_decay_model(decay, permutations = 199)
#> # A tibble: 2 x 10
#>   season model    component n_pairs     a       b half_distance pseudo_r2    aic
#>   <chr>  <chr>    <chr>       <int> <dbl>   <dbl>         <dbl>     <dbl>  <dbl>
#> 1 dry    exponen~ total          10 0.257 7.50e-4          924.     0.143  -9.21
#> 2 wet    exponen~ total          10 0.897 2.36e-3          293.     0.694 -17.6 
#> # i 1 more variable: p.value <dbl>
```
