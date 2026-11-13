# Geometry or environment? Partitioning richness along a gradient

`range_partition()` splits the variation in observed richness along a
gradient into the part explained by the mid-domain null model
(geometry), the part explained by environmental variables, the part they
share, and the unexplained rest. It is variation partitioning (Borcard
et al. 1992; Peres-Neto et al. 2006) with adjusted R², applied to the
debate on whether geometric constraints or the environment drive
richness gradients (Colwell et al. 2004; Dunn et al. 2007).

Unique fractions are tested with an F test of the nested linear models.
With few sites (as on most single-mountain transects) tests have little
power and adjusted fractions can be negative (read negative values as
zero); report them as descriptive. Sites along a gradient are also
spatially autocorrelated, which makes the p-values too small.

## Usage

``` r
range_partition(mde, env, data = NULL)
```

## Arguments

- mde:

  A
  [`range_mde()`](https://tidydiversity.in4metrix.dev/reference/range_mde.md)
  result.

- env:

  A formula of environmental predictors, e.g. `~ temperature`, evaluated
  in `mde` joined with `data`.

- data:

  Optional site-level data frame with the environmental variables and
  the site (and grouping) columns of `mde`.

## Value

A tibble with the grouping columns and, for each fraction
(`geometry only`, `environment only`, `shared`, `residual`), `adj_r2`
and, for the unique fractions, `p_value`.

## References

Borcard, D., Legendre, P. and Drapeau, P. (1992). Partialling out the
spatial component of ecological variation. Ecology, 73, 1045-1055.

Colwell, R. K., Rahbek, C. and Gotelli, N. J. (2004). The mid-domain
effect and species richness patterns: what have we learned so far?
American Naturalist, 163, E1-E23.
[doi:10.1086/382056](https://doi.org/10.1086/382056)

Dunn, R. R., McCain, C. M. and Sanders, N. J. (2007). When does
diversity fit null model predictions? Scale and range size mediate the
mid-domain effect. Global Ecology and Biogeography, 16, 305-312.

## Examples

``` r
set.seed(1)
mde <- range_mde(png_frogs, gradient = elevation, nsim = 199)
range_partition(mde, ~elevation)
#> # A tibble: 4 × 3
#>   fraction         adj_r2  p_value
#>   <chr>             <dbl>    <dbl>
#> 1 geometry only     0.404  0.0109 
#> 2 environment only  0.568  0.00567
#> 3 shared           -0.139 NA      
#> 4 residual          0.167 NA      
```
