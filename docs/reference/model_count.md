# Overdispersed count and proportion models (aods3-free)

Fits Poisson, quasi-Poisson, negative binomial, binomial or
quasi-binomial GLMs with a tidy interface so callers never need
**aods3**, and need **MASS** only when `family = "negbin"` (Suggests).
Designed for the abundance / richness models in Moses et al. (2021),
which switched to negative binomial after detecting overdispersion.

## Usage

``` r
model_count(
  data,
  formula,
  family = c("poisson", "quasipoisson", "negbin", "binomial", "quasibinomial"),
  weights = NULL,
  offset = NULL,
  ...
)

# S3 method for class 'td_count_model'
tidy(x, ...)

# S3 method for class 'td_count_model'
glance(x, ...)
```

## Arguments

- data:

  A data frame (for example a site table of abundance or Hill richness).

- formula:

  A model formula, such as `abundance ~ poly(elevation, 2) * litter`.

- family:

  One of `"poisson"`, `"quasipoisson"`, `"negbin"`, `"binomial"`,
  `"quasibinomial"`.

- weights, offset:

  Optional columns (bare names or expressions) passed to
  [`stats::glm()`](https://rdrr.io/r/stats/glm.html) /
  [`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html).

- ...:

  Additional arguments forwarded to the fitter.

- x:

  A `td_count_model` from `model_count()`.

## Value

A `td_count_model` list with `fit`, `family`, `formula`, `data`, and
dispersion diagnostics.
[`generics::tidy()`](https://rdrr.io/pkg/generics/man/tidy.html) /
[`generics::glance()`](https://rdrr.io/pkg/generics/man/glance.html)
methods are provided as `tidy.td_count_model()` and
`glance.td_count_model()`.

## References

Moses, J., Fayle, T. M., Novotny, V. and Klimes, P. (2021). Elevation
and leaf litter interact in determining the structure of ant communities
on a tropical mountain. *Biotropica*, 53, 906-919.
[doi:10.1111/btp.12914](https://doi.org/10.1111/btp.12914)

## Examples

``` r
ants <- png_ants |>
  dplyr::group_by(site, elevation) |>
  dplyr::summarise(richness = dplyr::n_distinct(species), .groups = "drop")
fit <- model_count(ants, richness ~ poly(elevation, 2), family = "poisson")
tidy(fit)
#> # A tibble: 3 x 5
#>   term                estimate std.error statistic   p.value
#>   <chr>                  <dbl>     <dbl>     <dbl>     <dbl>
#> 1 (Intercept)            2.95      0.112     26.3  2.32e-152
#> 2 poly(elevation, 2)1   -1.22      0.277     -4.39 1.13e-  5
#> 3 poly(elevation, 2)2   -0.486     0.241     -2.02 4.38e-  2
glance(fit)
#> # A tibble: 1 x 8
#>   family dispersion overdispersed null.deviance deviance   aic df.residual  nobs
#>   <chr>       <dbl> <lgl>                 <dbl>    <dbl> <dbl>       <int> <int>
#> 1 poiss~       1.35 FALSE                  27.9     2.84  32.8           2     5
```
