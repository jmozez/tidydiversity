# Precision weights from estimated diversity

Asymptotic diversity estimates differ in precision between sites: a
poorly sampled site has a large standard error. `model_case_weights()`
turns standard errors from
[`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md)
or
[`div_boot()`](https://tidydiversity.in4metrix.dev/reference/div_boot.md)
into inverse-variance weights, normalised to mean 1, as
[`hardhat::importance_weights()`](https://hardhat.tidymodels.org/reference/importance_weights.html)
for use with
[`workflows::add_case_weights()`](https://workflows.tidymodels.org/reference/add_case_weights.html).

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
#> # A tibble: 10 × 9
#>    season site       q observed estimate     se lower upper          w
#>    <chr>  <chr>  <dbl>    <dbl>    <dbl>  <dbl> <dbl> <dbl>  <imp_wts>
#>  1 dry    MW0200     1    12.3     15.2   1.90  12.3  18.9  1.32608889
#>  2 dry    MW0700     1    11.8     38.5  30.0   11.8  97.3  0.01326089
#>  3 dry    MW1200     1     9.37    13.8   3.48   9.37 20.6  0.98832406
#>  4 dry    MW1700     1     3.92     4.51  0.975  3.92  6.42 1.32608889
#>  5 dry    MW2200     1     4.98     7.34  2.59   4.98 12.4  1.32608889
#>  6 wet    MW0200     1    10.9     13.8   2.32  10.9  18.3  1.32608889
#>  7 wet    MW0700     1    21.6     38.8   7.64  23.8  53.8  0.20469848
#>  8 wet    MW1200     1    13.9     18.8   3.78  13.9  26.2  0.83718325
#>  9 wet    MW1700     1     5.30     7.05  2.24   5.30 11.4  1.32608889
#> 10 wet    MW2200     1     3.62     4.54  1.13   3.62  6.76 1.32608889
```
