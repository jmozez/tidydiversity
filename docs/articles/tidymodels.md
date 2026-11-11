# Modelling diversity with tidymodels

tidydiversity provides four tools for modelling diversity with
[tidymodels](https://www.tidymodels.org):

- [`model_group_folds()`](https://tidydiversity.in4metrix.dev/reference/model_group_folds.md):
  cross-validation folds that keep whole sites together.
- [`model_case_weights()`](https://tidydiversity.in4metrix.dev/reference/model_case_weights.md):
  precision weights from the standard errors of diversity estimates.
- [`step_hill()`](https://tidydiversity.in4metrix.dev/reference/step_hill.md):
  a recipe step that turns species columns into Hill numbers.
- Every `div_*()` result is already a tidy data frame, so it goes
  straight into `parsnip` and `workflows`.

``` r
library(tidydiversity)
library(dplyr)
library(parsnip)
library(recipes)
library(workflows)
library(tune)
library(broom)
library(yardstick)
```

## Does ant diversity decline with elevation?

The response is the Shannon diversity (q = 1) of ants in each transect
on Mt Wilhelm, Papua New Guinea. We have 5 elevations x 2 seasons x 2
transects.

``` r
units <- png_ants |>
  div_hill(q = 1, .by = c(elevation, season, transect))
units
#> # A tibble: 20 x 7
#>    elevation season transect site       q     n diversity
#>        <int> <chr>     <int> <chr>  <dbl> <dbl>     <dbl>
#>  1       200 dry           1 MW0200     1    20      8.85
#>  2       200 dry           2 MW0200     1    27      8.84
#>  3       200 wet           1 MW0200     1    41      8.35
#>  4       200 wet           2 MW0200     1    35      8.89
#>  5       700 dry           1 MW0700     1    10      7.58
#>  6       700 dry           2 MW0700     1    13      7.63
#>  7       700 wet           1 MW0700     1    30     14.0 
#>  8       700 wet           2 MW0700     1    28     15.5 
#>  9      1200 dry           1 MW1200     1    18      6.70
#> 10      1200 dry           2 MW1200     1    11      7.19
#> 11      1200 wet           1 MW1200     1    27     10.2 
#> 12      1200 wet           2 MW1200     1    30     11.1 
#> 13      1700 dry           1 MW1700     1    12      2.28
#> 14      1700 dry           2 MW1700     1     5      3.79
#> 15      1700 wet           1 MW1700     1    20      3.41
#> 16      1700 wet           2 MW1700     1    14      6.23
#> 17      2200 dry           1 MW2200     1     5      1.96
#> 18      2200 dry           2 MW2200     1     8      5.66
#> 19      2200 wet           1 MW2200     1     7      1.51
#> 20      2200 wet           2 MW2200     1     8      3.75
```

Transects on the same site share a species pool, so random folds would
leak information. Use one fold per site instead (leave-one-site-out):

``` r
folds <- model_group_folds(units, group = site)
folds
#> # Group 5-fold cross-validation 
#> # A tibble: 5 x 2
#>   splits         id       
#>   <list>         <chr>    
#> 1 <split [16/4]> Resample1
#> 2 <split [16/4]> Resample2
#> 3 <split [16/4]> Resample3
#> 4 <split [16/4]> Resample4
#> 5 <split [16/4]> Resample5
```

Then compare a linear model with and without season:

``` r
wf_elev <- workflow(diversity ~ elevation, linear_reg())
wf_both <- workflow(diversity ~ elevation + season, linear_reg())

rmse_only <- metric_set(rmse)
bind_rows(
  elevation = collect_metrics(fit_resamples(wf_elev, folds, metrics = rmse_only)),
  `elevation + season` = collect_metrics(
    fit_resamples(wf_both, folds, metrics = rmse_only)
  ),
  .id = "model"
)
#> # A tibble: 2 x 7
#>   model              .metric .estimator  mean     n std_err .config        
#>   <chr>              <chr>   <chr>      <dbl> <int>   <dbl> <chr>          
#> 1 elevation          rmse    standard    3.41     5   0.669 pre0_mod0_post0
#> 2 elevation + season rmse    standard    3.43     5   0.633 pre0_mod0_post0
```

Each held-out fold is one whole site, so the error measures how well the
model predicts a site it has never seen. Adding season barely changes
it, so elevation carries the signal. (R² is not reported, because a
single held-out site has only one elevation.)

The fitted coefficients come out tidy:

``` r
fit(wf_both, units) |> tidy()
#> # A tibble: 3 x 5
#>   term        estimate std.error statistic     p.value
#>   <chr>          <dbl>     <dbl>     <dbl>       <dbl>
#> 1 (Intercept) 10.4      1.29          8.10 0.000000307
#> 2 elevation   -0.00365  0.000824     -4.43 0.000365   
#> 3 seasonwet    2.24     1.17          1.92 0.0714
```

## Weighting by precision

Asymptotic estimates are less certain at poorly sampled sites. Inverse-
variance weights give those sites less influence:

``` r
est <- div_estimate(png_ants, q = 1, .by = c(elevation, season)) |>
  mutate(w = model_case_weights(se))

workflow(estimate ~ elevation + season, linear_reg()) |>
  add_case_weights(w) |>
  fit(est) |>
  tidy()
#> # A tibble: 3 x 5
#>   term        estimate std.error statistic  p.value
#>   <chr>          <dbl>     <dbl>     <dbl>    <dbl>
#> 1 (Intercept) 16.4       2.96        5.55  0.000859
#> 2 elevation   -0.00533   0.00179    -2.97  0.0207  
#> 3 seasonwet    0.668     2.84        0.235 0.821
```

## Hill numbers as predictors

When diversity is a predictor rather than the response,
[`step_hill()`](https://tidydiversity.in4metrix.dev/reference/step_hill.md)
computes it inside the recipe. It is then recomputed for every resample
and for new data. Here the species are in wide format:

``` r
wide <- png_ants |>
  count(elevation, season, transect, species, wt = workers) |>
  tidyr::pivot_wider(names_from = species, values_from = n, values_fill = 0)

recipe(elevation ~ ., data = select(wide, -season, -transect)) |>
  step_hill(all_predictors(), q = c(0, 1, 2)) |>
  prep() |>
  bake(new_data = NULL)
#> # A tibble: 20 x 4
#>    elevation hill_q0 hill_q1 hill_q2
#>        <int>   <dbl>   <dbl>   <dbl>
#>  1       200      11    3.16    2.10
#>  2       200      10    5.19    3.61
#>  3       200      14    7.25    5.84
#>  4       200      14    5.21    4.06
#>  5       700       8    4.60    3.76
#>  6       700       9    5.01    3.37
#>  7       700      16    8.12    5.98
#>  8       700      18    8.14    5.95
#>  9      1200       9    3.93    2.58
#> 10      1200       8    3.95    3.44
#> 11      1200      13    2.72    1.72
#> 12      1200      14    3.27    2.46
#> 13      1700       3    1.49    1.26
#> 14      1700       4    2.52    2.04
#> 15      1700       6    1.45    1.17
#> 16      1700       8    4.91    3.96
#> 17      2200       2    1.89    1.8 
#> 18      2200       6    3.13    2.31
#> 19      2200       2    1.72    1.55
#> 20      2200       4    3.91    3.81
```

## Reference

Roberts, D. R. et al. (2017). Cross-validation strategies for data with
temporal, spatial, hierarchical, or phylogenetic structure. *Ecography*,
40, 913-929. <https://doi.org/10.1111/ecog.02881>
