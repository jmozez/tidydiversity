# Tidy and model-ready output

Every tidydiversity result is already a tidy tibble with one row per
site and order `q`. The
[`generics::tidy()`](https://rdrr.io/pkg/generics/man/tidy.html) methods
rename the columns to the broom conventions (`estimate`, `std.error`,
`conf.low`, `conf.high`) and add an inverse-variance weight (`weight`,
`1 / se^2`, or `NA` when the standard error is zero, as at a site with a
single species), so results stack with other broom output and can go
straight into weighted models.
[`generics::glance()`](https://rdrr.io/pkg/generics/man/glance.html)
gives one row per site with its sample size, observed richness and
coverage.

`add_site_data()` joins site-level covariates, such as elevation,
habitat or treatment, from the original data or a separate site table,
so diversity can be modelled against them.

## Usage

``` r
# S3 method for class 'td_estimate'
tidy(x, ...)

# S3 method for class 'td_standardise'
tidy(x, ...)

# S3 method for class 'td_rarefy'
tidy(x, ...)

# S3 method for class 'td_boot'
tidy(x, ...)

# S3 method for class 'td_beta_pair'
tidy(x, ...)

# S3 method for class 'td_coverage'
glance(x, ...)

add_site_data(x, data, site = site, cols = NULL)
```

## Arguments

- x:

  A tidydiversity result.

- ...:

  Not used.

- data:

  A data frame holding the site column and the covariates, such as the
  community data the result came from, or a site table.

- site:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The site column of `data`, matched to the site column of `x`.

- cols:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Covariates to join. By default every column that is constant within
  each site and not already in `x`.

## Value

A tibble.

## Examples

``` r
set.seed(1)
est <- div_estimate(png_ants, q = 0, nboot = 20)
generics::tidy(est)
#> # A tibble: 5 x 8
#>   site       q observed estimate std.error conf.low conf.high  weight
#>   <chr>  <dbl>    <dbl>    <dbl>     <dbl>    <dbl>     <dbl>   <dbl>
#> 1 MW0200     0       30     44.0      9.06    34.4       74.6 0.0122 
#> 2 MW0700     0       35     67       30.8     41.5      192.  0.00105
#> 3 MW1200     0       26     36.0     14.2     27.3      104.  0.00497
#> 4 MW1700     0       10     11.5      1.94    10.2       20.5 0.265  
#> 5 MW2200     0        9     11.2      4.34     9.18      35.1 0.0531 

# Join elevation and fit a weighted model
est <- add_site_data(est, png_ants)
fit <- lm(estimate ~ elevation,
  data = generics::tidy(est),
  weights = weight
)
coef(fit)
#> (Intercept)   elevation 
#> 42.26075138 -0.01699226 
```
