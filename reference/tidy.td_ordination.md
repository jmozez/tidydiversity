# Tidy and glance methods for ordinations

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns one
set of ordination scores as a tibble, and
[`glance()`](https://generics.r-lib.org/reference/glance.html) a one-row
summary of the ordination.

## Usage

``` r
# S3 method for class 'td_ordination'
tidy(
  x,
  display = c("sites", "species", "vectors", "centroids", "axes", "envfit"),
  ...
)

# S3 method for class 'td_ordination'
glance(x, ...)
```

## Arguments

- x:

  A `td_ordination` from
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md).

- display:

  Scores to return: `"sites"`, `"species"`, `"vectors"` (environmental
  arrows), `"centroids"` (factor levels), `"axes"` (eigenvalues and
  variation explained) or `"envfit"` (fit of passive variables).

- ...:

  Not used.

## Value

A tibble.

## Examples

``` r
ord <- ord_fit(png_frogs, method = "ca")
tidy(ord, "species")
#> # A tibble: 55 × 4
#>    species   axis1    axis2   axis3
#>    <chr>     <dbl>    <dbl>   <dbl>
#>  1 FR01    -0.983   0.702   -0.467 
#>  2 FR02    -0.619   0.00967  0.321 
#>  3 FR03     0.367  -1.30     0.774 
#>  4 FR04    -0.0481 -0.955    1.07  
#>  5 FR05     0.367  -1.30     0.774 
#>  6 FR06     0.128  -1.10     0.944 
#>  7 FR07     1.22   -0.521   -1.98  
#>  8 FR08    -0.818   0.347    0.0591
#>  9 FR09     1.22   -0.521   -1.98  
#> 10 FR10     1.20   -0.536   -1.93  
#> # ℹ 45 more rows
glance(ord)
#> # A tibble: 1 × 8
#>   method n_sites n_species transform distance scaling stress constrained
#>   <chr>    <int>     <int> <chr>     <lgl>    <chr>    <dbl>       <dbl>
#> 1 ca           8        55 none      NA       species     NA          NA
```
