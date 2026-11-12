# ForestGEO-style stem and tree census verbs

Tidyverse-style helpers for ForestGEO / CTFS plot inventories. They
accept data frames with the usual columns (`plot`, `census`, `treeID`,
`stemID`, `gx`, `gy`, `dbh`, `species` / `sp`, `status`, optionally
`date`) and return tibbles. Callers stay inside tidydiversity instead of
using the fgeo or CTFS packages.

Typical workflow: standardise names with `stems_as_trees()` (main stem
per tree) or keep stems; summarise `stems_abundance()` and
`stems_basal_area()`; size classes with `stems_size_class()`; demography
between two censuses with `stems_demography()`; feed species counts to
[`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md)
via `stems_as_community()`.

Spatial stem verbs (quadrats, habitat joins, neighbourhoods, the
torus-translation habitat test) and stem maps over topography are in the
companion package tidymapr
([`tidymapr::stems_quadrat()`](https://tidymapr.in4metrix.dev/reference/stems_spatial.html),
[`tidymapr::stems_habitat_test()`](https://tidymapr.in4metrix.dev/reference/stems_habitat_test.html),
[`tidymapr::plot_topo()`](https://tidymapr.in4metrix.dev/reference/plot_topo.html)).

Basal area for one stem is `\eqn{\pi/4 \times \mathrm{dbh}^2}` (Condit
1998; fgeo.analyze). With `dbh_unit = "cm"` the result is cm\\^2\\; with
`"mm"` it is mm\\^2\\. Convert afterwards if you need m\\^2\\
ha\\^{-1}\\.

## Usage

``` r
stems_as_trees(data, hom = NULL)

stems_abundance(
  data,
  .by = NULL,
  alive_only = TRUE,
  alive = "A",
  level = c("tree", "stem")
)

stems_basal_area(
  data,
  .by = NULL,
  dbh_unit = c("mm", "cm"),
  alive_only = TRUE,
  alive = "A"
)

stems_size_class(
  data,
  breaks = c(10, 20, 50, 100, Inf),
  labels = NULL,
  dbh_unit = c("mm", "cm"),
  .by = NULL,
  alive_only = TRUE,
  alive = "A"
)

stems_demography(
  census1,
  census2,
  mindbh = 0,
  alive = "A",
  time = NULL,
  growth = c("absolute", "relative"),
  dbh_unit = c("mm", "cm"),
  .by = NULL
)

stems_as_community(
  data,
  site = NULL,
  alive_only = TRUE,
  alive = "A",
  level = c("tree", "stem")
)
```

## Arguments

- data:

  A ForestGEO-like data frame.

- hom:

  Optional height-of-measure column; the largest HOM row is kept when
  several measures share a stem.

- .by:

  Optional grouping columns (species, quadrat, habitat).

- alive_only:

  Keep only stems/trees whose `status` is in `alive`?

- alive:

  Character codes of `status` that mean alive (default `"A"`).

- level:

  `"tree"` (collapse to one row per `treeID`) or `"stem"`.

- dbh_unit:

  `"mm"` or `"cm"` for the `dbh` column.

- breaks:

  Breakpoints for DBH size classes (in the same unit as `dbh`).

- labels:

  Optional labels for size classes.

- census1, census2:

  Two census tables for demography (tree-level preferred).

- mindbh:

  Minimum DBH included in demography counts.

- time:

  Mean census interval in years. When `NULL`, estimated from `date`
  columns when present, otherwise required.

- growth:

  `"absolute"` for (dbh2-dbh1)/time or `"relative"` for (log dbh2 - log
  dbh1)/time.

- site:

  Column to use as the site identifier in the community table (default
  `quadrat`, as added by
  [`tidymapr::stems_quadrat()`](https://tidymapr.in4metrix.dev/reference/stems_spatial.html),
  or `plot`).

## References

Condit, R. (1998). *Tropical Forest Census Plots*. Springer.
Anderson-Teixeira, K. J. et al. (2015). CTFS-ForestGEO: a worldwide
network monitoring forests in an era of global change. *Global Change
Biology*, 21, 528-549.
[doi:10.1111/gcb.12712](https://doi.org/10.1111/gcb.12712) . Condit, R.
et al. (2014). Data and database standards for permanent forest plots in
a global network. *Forest Ecology and Management*. ForestGEO
(Smithsonian Tropical Research Institute). Analysis conventions also
follow the fgeo.analyze package (rOpenSci / ForestGEO).

## Examples

``` r
# The column layout of a ForestGEO stem table (illustrative rows; use
# your own census, or tidymapr::geo_example_stems())
stems <- tibble::tibble(
  treeID = 1:6,
  stemID = 1:6,
  gx = c(12.1, 40.5, 77.0, 23.9, 61.2, 88.4),
  gy = c(8.3, 55.0, 31.7, 90.2, 14.6, 66.1),
  dbh = c(105, 342, 58, 220, 77, 410),
  species = c("Pometia_pinnata", "Intsia_bijuga", "Pometia_pinnata",
    "Pterocarpus_indicus", "Intsia_bijuga", "Pometia_pinnata"),
  status = "A"
)
stems_abundance(stems, .by = species)
#> # A tibble: 3 × 2
#>   species                 n
#>   <chr>               <int>
#> 1 Pometia_pinnata         3
#> 2 Intsia_bijuga           2
#> 3 Pterocarpus_indicus     1
stems_basal_area(stems, dbh_unit = "mm", .by = species)
#> # A tibble: 3 × 4
#>   species             basal_area basal_area_unit n_stem
#>   <chr>                    <dbl> <chr>            <int>
#> 1 Pometia_pinnata        143327. mm2                  3
#> 2 Intsia_bijuga           96520. mm2                  2
#> 3 Pterocarpus_indicus     38013. mm2                  1
```
