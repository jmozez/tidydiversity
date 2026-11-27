# How well the ordination axes fit each species and site

CANOCO's species and sample fit: the percentage of the variation of each
species (or site) that the first `axes` ordination axes explain
([`vegan::goodness()`](https://vegandevs.github.io/vegan/reference/goodness.cca.html)).
Species with a low fit are poorly represented in the diagram and are
usually left out of it;
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
takes `species_fit` for that.

## Usage

``` r
ord_species_fit(x, axes = 2, display = c("species", "sites"))
```

## Arguments

- x:

  A `td_ordination` from a PCA, CA, RDA, CCA or db-RDA.

- axes:

  Number of axes.

- display:

  `"species"` or `"sites"`.

## Value

A tibble with `species` (or `site`) and `fit_pct`.

## Examples

``` r
d <- community_long(dune_species, cols = -site)
o <- ord_fit(d, abundance = abundance, method = "ca")
ord_species_fit(o)
#> # A tibble: 30 × 2
#>    species  fit_pct
#>    <chr>      <dbl>
#>  1 Achimill   38.4 
#>  2 Agrostol   78.1 
#>  3 Airaprae   73.1 
#>  4 Alopgeni   30.0 
#>  5 Anthodor   68.9 
#>  6 Bellpere   18.9 
#>  7 Bracruta   16.5 
#>  8 Bromhord   24.0 
#>  9 Callcusp   55.7 
#> 10 Chenalbu    4.52
#> # ℹ 20 more rows
```
