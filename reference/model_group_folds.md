# Grouped cross-validation folds for community data

Samples from the same site (or transect, plot, ...) are not independent,
so random cross-validation folds leak information and overstate model
skill (Roberts et al. 2017). `model_group_folds()` creates folds that
keep every row of a group together, using
[`rsample::group_vfold_cv()`](https://rsample.tidymodels.org/reference/group_vfold_cv.html).

## Usage

``` r
model_group_folds(data, group, v = NULL, ...)
```

## Arguments

- data:

  A data frame, typically one row per sampling unit.

- group:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The blocking column, such as `site`.

- v:

  Number of folds. Defaults to the number of groups
  (leave-one-group-out).

- ...:

  Passed to
  [`rsample::group_vfold_cv()`](https://rsample.tidymodels.org/reference/group_vfold_cv.html).

## Value

An `rset` object for use with tune.

## References

Roberts, D. R. et al. (2017). Cross-validation strategies for data with
temporal, spatial, hierarchical, or phylogenetic structure. *Ecography*,
40, 913-929.
[doi:10.1111/ecog.02881](https://doi.org/10.1111/ecog.02881)

## Examples

``` r
units <- div_hill(png_ants, q = 0, .by = c(season, transect))
model_group_folds(units, group = site)
#> # Group 5-fold cross-validation 
#> # A tibble: 5 × 2
#>   splits         id       
#>   <list>         <chr>    
#> 1 <split [16/4]> Resample1
#> 2 <split [16/4]> Resample2
#> 3 <split [16/4]> Resample3
#> 4 <split [16/4]> Resample4
#> 5 <split [16/4]> Resample5
```
