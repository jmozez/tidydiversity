# Precision weights from estimated diversity

Asymptotic diversity estimates differ in precision between sites: a
poorly sampled site has a large standard error. `model_case_weights()`
turns standard errors from
[`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md)
or
[`div_boot()`](https://tidydiversity.in4metrix.dev/reference/div_boot.md)
into inverse-variance weights, normalised to mean 1, as
[`hardhat::importance_weights()`](https://rdrr.io/pkg/hardhat/man/importance_weights.html)
for use with
[`workflows::add_case_weights()`](https://rdrr.io/pkg/workflows/man/add_case_weights.html).

## Usage

``` r
model_case_weights(se, cap = 100)
```

## Arguments

- se:

  Numeric vector of standard errors.

- cap:

  Largest allowed ratio between weights, to stop sites with an SE near
  zero from dominating. `Inf` for no cap.

## Value

A `hardhat_importance_weights` vector.

## Examples

``` r
est <- div_estimate(png_ants, q = 1, .by = season)
est$w <- model_case_weights(est$se)
est
#> # A tibble: 10 x 9
#>    season site       q observed estimate     se lower upper          w
#>    <chr>  <chr>  <dbl>    <dbl>    <dbl>  <dbl> <dbl> <dbl>  <imp_wts>
#>  1 dry    MW0200     1    12.3     15.2   2.28  12.3  19.6  1.46863740
#>  2 wet    MW0200     1    10.9     13.8   2.03  10.9  17.8  1.46863740
#>  3 dry    MW0700     1    11.8     38.5  26.6   11.8  90.7  0.01468637
#>  4 wet    MW0700     1    21.6     38.8  10.8   21.6  59.9  0.08980222
#>  5 dry    MW1200     1     9.37    13.8   5.94   9.37 25.5  0.29562867
#>  6 wet    MW1200     1    13.9     18.8   3.20  13.9  25.1  1.02033543
#>  7 dry    MW1700     1     3.92     4.51  1.05   3.92  6.57 1.46863740
#>  8 wet    MW1700     1     5.30     7.05  1.80   5.30 10.6  1.46863740
#>  9 dry    MW2200     1     4.98     7.34  2.90   4.98 13.0  1.23636029
#> 10 wet    MW2200     1     3.62     4.54  0.927  3.62  6.35 1.46863740
```
