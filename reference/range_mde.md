# Mid-domain null model of richness along a gradient

If species' ranges are placed at random within a bounded gradient, they
overlap most in the middle, so richness peaks at mid-gradient even with
no environmental cause: the **mid-domain effect** (Colwell and Hurtt
1994; Colwell and Lees 2000). `range_mde()` builds this null model from
the observed ranges, in the spirit of RangeModel (Colwell 2008), and
compares it with the observed richness at each site.

Each species keeps its observed range size (the number of consecutive
sampled sites it spans, after
[`range_through()`](https://tidydiversity.in4metrix.dev/reference/range_through.md)
interpolation), and its position is randomised:

- `model = "uniform"`: every position where the range fits is equally
  likely (Colwell and Hurtt 1994). The expected richness is computed
  exactly; the interval comes from `nsim` randomisations.

- `model = "spread"`: the range starts at a random site and spreads to
  random neighbouring sites (the "spreading dye" model of Jetz and
  Rahbek 2001, as in the rangemodelR package), which places more ranges
  near the ends than the uniform model.

Sites are treated as positions in order along the gradient, so the model
assumes the sampled sites represent the domain evenly.

## Usage

``` r
range_mde(
  data,
  gradient,
  site = site,
  species = species,
  model = c("uniform", "spread"),
  nsim = 999,
  conf = 0.95,
  interpolate = TRUE,
  .by = NULL
)

# S3 method for class 'td_mde'
glance(x, ...)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- gradient:

  Column with the position of each site on the gradient (one value per
  site).

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- model:

  `"uniform"` or `"spread"`.

- nsim:

  Number of randomisations.

- conf:

  Width of the simulation interval.

- interpolate:

  Apply
  [`range_through()`](https://tidydiversity.in4metrix.dev/reference/range_through.md)
  first (recommended).

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

- x:

  A `range_mde()` result.

- ...:

  Not used.

## Value

A tibble of class `td_mde` with the grouping columns, the site and
gradient columns, `observed` richness, `expected` richness under the
null model, its `sd`, `lower` and `upper` simulation limits, and
`outside` (`"above"`, `"below"` or `"within"`). Attributes `r2` (the
variance in observed richness explained by the null model, one value per
group) and `p_value` (a global test: the proportion of randomisations
that deviate from the expectation at least as much as the observed
richness) summarise the fit; see
[`glance()`](https://generics.r-lib.org/reference/glance.html).

## References

Colwell, R. K. and Hurtt, G. C. (1994). Nonbiological gradients in
species richness and a spurious Rapoport effect. American Naturalist,
144, 570-595. [doi:10.1086/285695](https://doi.org/10.1086/285695)

Colwell, R. K. and Lees, D. C. (2000). The mid-domain effect: geometric
constraints on the geography of species richness. Trends in Ecology &
Evolution, 15, 70-76.
[doi:10.1016/S0169-5347(99)01767-X](https://doi.org/10.1016/S0169-5347%2899%2901767-X)

Colwell, R. K. (2008). RangeModel: tools for exploring and assessing
geometric constraints on species richness (the mid-domain effect) along
transects. Ecography, 31, 4-7.
[doi:10.1111/j.2008.0906-7590.05347.x](https://doi.org/10.1111/j.2008.0906-7590.05347.x)

Jetz, W. and Rahbek, C. (2001). Geometric constraints explain much of
the species richness pattern in African birds. Proceedings of the
National Academy of Sciences, 98, 5661-5666.
[doi:10.1073/pnas.091100998](https://doi.org/10.1073/pnas.091100998)

## Examples

``` r
set.seed(1)
mde <- range_mde(png_frogs, gradient = elevation, nsim = 199)
mde
#> # A tibble: 8 × 8
#>   site   elevation observed expected    sd lower upper outside
#>   <chr>      <int>    <dbl>    <dbl> <dbl> <dbl> <dbl> <chr>  
#> 1 MW0200       200       13     7.65  2.65  4     14   within 
#> 2 MW0700       700       13    11.8   2.73  6.95  17   within 
#> 3 MW1200      1200       17    13.7   3.13  8     21   within 
#> 4 MW1700      1700       18    13.9   3.15  9     21.0 within 
#> 5 MW2200      2200       14    13.9   3.11  8.95  21   within 
#> 6 MW2700      2700       12    13.7   3.03  8     20   within 
#> 7 MW3200      3200        5    11.8   2.76  6.95  17   below  
#> 8 MW3700      3700        2     7.65  2.59  3     13   below  
glance(mde)
#> # A tibble: 1 × 5
#>   model   n_sites n_species    r2 p_value
#>   <chr>     <int>     <int> <dbl>   <dbl>
#> 1 uniform       8        55 0.354   0.055
```
