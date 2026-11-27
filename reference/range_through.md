# Range-through interpolation along a gradient

`range_through()` assumes that a species recorded at two positions on a
gradient (elevation, latitude, depth) is also present at every sampled
position between them, and adds those records. This is the standard
first step for elevational and latitudinal richness patterns (Grytnes
and Vetaas 2002; Colwell 2008), because a species missed at an
intermediate site is far more likely an undetected than an absent one.

Interpolation fills gaps only *inside* each species' observed range, so
it raises richness most at mid-gradient sites. It therefore creates part
of a mid-domain peak by itself; compare the result with
[`range_mde()`](https://tidydiversity.in4metrix.dev/reference/range_mde.md),
which applies the same interpolation to its null model.

## Usage

``` r
range_through(data, gradient, site = site, species = species, .by = NULL)
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

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A tibble with the grouping columns, the site and gradient columns,
`species` and `interpolated` (`TRUE` for added records), one row per
species and site where it is present or interpolated.

## References

Colwell, R. K. (2008). RangeModel: tools for exploring and assessing
geometric constraints on species richness (the mid-domain effect) along
transects. Ecography, 31, 4-7.
[doi:10.1111/j.2008.0906-7590.05347.x](https://doi.org/10.1111/j.2008.0906-7590.05347.x)

Grytnes, J.-A. and Vetaas, O. R. (2002). Species richness and altitude:
a comparison between null models and interpolated plant species richness
along the Himalayan altitudinal gradient, Nepal. American Naturalist,
159, 294-304. [doi:10.1086/338542](https://doi.org/10.1086/338542)

## Examples

``` r
rt <- range_through(png_frogs, gradient = elevation)
dplyr::count(rt, site, elevation, interpolated)
#> # A tibble: 10 × 4
#>    site   elevation interpolated     n
#>    <chr>      <int> <lgl>        <int>
#>  1 MW0200       200 FALSE           13
#>  2 MW0700       700 FALSE           13
#>  3 MW1200      1200 FALSE           16
#>  4 MW1200      1200 TRUE             1
#>  5 MW1700      1700 FALSE           18
#>  6 MW2200      2200 FALSE           14
#>  7 MW2700      2700 FALSE           12
#>  8 MW3200      3200 FALSE            4
#>  9 MW3200      3200 TRUE             1
#> 10 MW3700      3700 FALSE            2
```
