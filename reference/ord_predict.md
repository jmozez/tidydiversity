# Place new sites in an existing ordination (supplementary sites)

CANOCO's supplementary samples: sites that did not take part in the
analysis are placed in its diagram from their species composition, as
weighted averages of the species scores
([`vegan::predict.cca()`](https://vegandevs.github.io/vegan/reference/predict.cca.html)
with `type = "wa"`). Use it to show where new, disturbed or resurveyed
sites fall relative to the reference sites.

## Usage

``` r
ord_predict(
  x,
  newdata,
  site = site,
  species = species,
  abundance = NULL,
  axes = 2
)
```

## Arguments

- x:

  A `td_ordination` from a PCA, CA, RDA or CCA.

- newdata:

  Long community data for the new sites, with the same species (species
  not in the analysis are ignored).

- site, species, abundance:

  Columns of `newdata`, as in
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md).

- axes:

  Number of axes.

## Value

A tibble with `site` and the axis scores, in the scaling of the sites of
`x`.

## Examples

``` r
d <- community_long(dune_species, cols = -site)
ref <- d[d$site %in% as.character(1:15), ]
new <- d[d$site %in% as.character(16:20), ]
o <- ord_fit(ref, abundance = abundance, method = "ca")
ord_predict(o, new, abundance = abundance)
#> # A tibble: 5 × 3
#>   site   axis1  axis2
#>   <chr>  <dbl>  <dbl>
#> 1 16     2.49  -0.573
#> 2 17    -1.27  -1.87 
#> 3 18    -0.449 -0.711
#> 4 19    -0.436 -0.820
#> 5 20     2.64  -1.06 
```
