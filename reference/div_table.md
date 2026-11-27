# Publication-ready tables

Formats a tidydiversity result as a table for a manuscript or report:
rounds numbers, combines estimates and confidence limits into one cell
in APA style, for example `12.34 [10.10, 14.50]`, renames columns to
readable titles, and can spread the orders `q` into columns so each site
takes one row. The result can be returned as a tibble, or rendered with
knitr, gt or flextable for HTML, PDF or Word output.

## Usage

``` r
div_table(
  x,
  digits = 2,
  ci = TRUE,
  ci_style = c("apa", "parentheses", "pm"),
  wide = FALSE,
  output = c("tibble", "kable", "gt", "flextable"),
  caption = NULL
)
```

## Arguments

- x:

  A tibble from
  [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md),
  [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md),
  [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md),
  [`div_coverage()`](https://tidydiversity.in4metrix.dev/reference/div_coverage.md),
  [`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
  or
  [`beta_multi()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md).

- digits:

  Number of decimal places.

- ci:

  Combine the estimate with its confidence limits in one cell.

- ci_style:

  Style of the interval: `"apa"` (`[lower, upper]`), `"parentheses"`
  (`(lower-upper)`) or `"pm"` (`+/- SE`).

- wide:

  Spread the orders `q` into columns, one row per site.

- output:

  `"tibble"`, `"kable"`
  ([`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html)), `"gt"`
  ([`gt::gt()`](https://gt.rstudio.com/reference/gt.html)) or
  `"flextable"`
  ([`flextable::flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html)).

- caption:

  Optional table caption for the rendered formats.

## Value

A tibble of formatted character columns, or a kable, gt or flextable
object.

## Examples

``` r
set.seed(1)
est <- div_estimate(png_ants, .by = season, nboot = 20)
div_table(est)
#> # A tibble: 30 × 5
#>    season site   `Order q` Observed `Estimate [95% CI]`  
#>    <chr>  <chr>  <chr>     <chr>    <chr>                
#>  1 dry    MW0200 0         16.00    18.45 [16.15, 56.45] 
#>  2 dry    MW0200 1         12.28    15.18 [12.55, 17.81] 
#>  3 dry    MW0200 2         9.91     12.28 [9.91, 15.51]  
#>  4 dry    MW0700 0         15.00    83.87 [38.61, 215.89]
#>  5 dry    MW0700 1         11.76    38.45 [11.76, 84.04] 
#>  6 dry    MW0700 2         8.67     13.32 [8.67, 31.90]  
#>  7 dry    MW1200 0         13.00    20.89 [13.51, 134.46]
#>  8 dry    MW1200 1         9.37     13.81 [9.37, 23.27]  
#>  9 dry    MW1200 2         6.73     8.46 [6.73, 13.55]   
#> 10 dry    MW1700 0         5.00     5.24 [5.01, 15.40]   
#> # ℹ 20 more rows
div_table(est, wide = TRUE, digits = 1)
#> # A tibble: 10 × 8
#>    season site   `observed (q = 0)` `estimate (q = 0)` `observed (q = 1)`
#>    <chr>  <chr>  <chr>              <chr>              <chr>             
#>  1 dry    MW0200 16.0               18.4 [16.1, 56.5]  12.3              
#>  2 dry    MW0700 15.0               83.9 [38.6, 215.9] 11.8              
#>  3 dry    MW1200 13.0               20.9 [13.5, 134.5] 9.4               
#>  4 dry    MW1700 5.0                5.2 [5.0, 15.4]    3.9               
#>  5 dry    MW2200 6.0                10.2 [6.9, 24.3]   5.0               
#>  6 wet    MW0200 21.0               32.9 [23.2, 84.7]  10.9              
#>  7 wet    MW0700 28.0               75.3 [43.8, 169.4] 21.6              
#>  8 wet    MW1200 20.0               33.3 [21.9, 113.3] 13.9              
#>  9 wet    MW1700 10.0               18.7 [11.8, 52.9]  5.3               
#> 10 wet    MW2200 5.0                6.9 [5.3, 18.1]    3.6               
#> # ℹ 3 more variables: `estimate (q = 1)` <chr>, `observed (q = 2)` <chr>,
#> #   `estimate (q = 2)` <chr>
div_table(est, output = "kable", caption = "Asymptotic diversity")
#> 
#> 
#> Table: Asymptotic diversity
#> 
#> |season |   site| Order q| Observed|     Estimate [95% CI]|
#> |:------|------:|-------:|--------:|---------------------:|
#> |dry    | MW0200|       0|    16.00|  18.45 [16.15, 56.45]|
#> |dry    | MW0200|       1|    12.28|  15.18 [12.55, 17.81]|
#> |dry    | MW0200|       2|     9.91|   12.28 [9.91, 15.51]|
#> |dry    | MW0700|       0|    15.00| 83.87 [38.61, 215.89]|
#> |dry    | MW0700|       1|    11.76|  38.45 [11.76, 84.04]|
#> |dry    | MW0700|       2|     8.67|   13.32 [8.67, 31.90]|
#> |dry    | MW1200|       0|    13.00| 20.89 [13.51, 134.46]|
#> |dry    | MW1200|       1|     9.37|   13.81 [9.37, 23.27]|
#> |dry    | MW1200|       2|     6.73|    8.46 [6.73, 13.55]|
#> |dry    | MW1700|       0|     5.00|    5.24 [5.01, 15.40]|
#> |dry    | MW1700|       1|     3.92|     4.51 [3.92, 5.98]|
#> |dry    | MW1700|       2|     3.25|     3.78 [3.25, 5.24]|
#> |dry    | MW2200|       0|     6.00|   10.15 [6.94, 24.30]|
#> |dry    | MW2200|       1|     4.98|    7.34 [4.98, 11.44]|
#> |dry    | MW2200|       2|     4.33|     6.00 [4.33, 9.71]|
#> |wet    | MW0200|       0|    21.00|  32.94 [23.24, 84.70]|
#> |wet    | MW0200|       1|    10.88|  13.79 [10.88, 16.83]|
#> |wet    | MW0200|       2|     6.99|     7.60 [6.99, 9.23]|
#> |wet    | MW0700|       0|    28.00| 75.34 [43.84, 169.44]|
#> |wet    | MW0700|       1|    21.58|  38.81 [24.38, 53.25]|
#> |wet    | MW0700|       2|    17.16|  23.96 [17.55, 30.37]|
#> |wet    | MW1200|       0|    20.00| 33.26 [21.88, 113.34]|
#> |wet    | MW1200|       1|    13.88|  18.83 [13.88, 26.61]|
#> |wet    | MW1200|       2|    10.06|  12.00 [10.06, 16.57]|
#> |wet    | MW1700|       0|    10.00|  18.74 [11.78, 52.86]|
#> |wet    | MW1700|       1|     5.30|    7.05 [5.30, 10.18]|
#> |wet    | MW1700|       2|     3.61|     3.92 [3.61, 5.91]|
#> |wet    | MW2200|       0|     5.00|    6.87 [5.27, 18.05]|
#> |wet    | MW2200|       1|     3.62|     4.54 [3.62, 7.23]|
#> |wet    | MW2200|       2|     2.85|     3.28 [2.85, 5.57]|
```
