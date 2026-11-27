# Lichen pasture vegetation and soil chemistry (a species-environment pair)

Real field data: understorey vegetation and soil of 24 lichen pastures
in dry *Pinus sylvestris* forests of northern Finland grazed by reindeer
(Väre et al. 1995), as two tables in the layout CANOCO uses: a species
table with one row per site and one column per species, and an
environment table of soil variables with one row per site. The two are
linked by `site`. Taken unchanged from the vegan package (`varespec` and
`varechem`).

## Usage

``` r
vare_species

vare_env
```

## Format

`vare_species`: a tibble with 24 rows (sites) and 45 columns: `site` and
44 species of vascular plants, mosses and lichens (abbreviated Latin
names, such as `Cladstel` for *Cladina stellaris*), with estimated cover
values (the source does not state the scale).

`vare_env`: a tibble with 24 rows and 15 columns:

- site:

  Site number, matching `vare_species`.

- N, P, K, Ca, Mg, S, Al, Fe, Mn, Zn, Mo:

  Concentrations of soil nutrients and metals (units not stated; see
  below).

- Baresoil:

  Estimated cover of bare soil.

- Humdepth:

  Thickness of the humus layer.

- pH:

  Soil pH.

**Units.** The source of these data (vegan) does not state the units of
the soil variables, and they could not be confirmed from the original
publication (Väre et al. 1995), so none are given here. The variation
that RDA or CCA attributes to a variable does not depend on its units.
Do not compare the values with other soil data without checking the
original publication.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 24
rows and 15 columns.

## Source

The vegan package (Oksanen et al.), data sets `varespec` and `varechem`.
Built by `data-raw/canoco_pairs.R` in the package source.

## References

Väre, H., Ohtonen, R. and Oksanen, J. (1995). Effects of reindeer
grazing on understorey vegetation in dry *Pinus sylvestris* forests.
*Journal of Vegetation Science*, 6, 523-530.

## Examples

``` r
v <- community_long(vare_species, cols = -site)
ord_advise(v, abundance = abundance, formula = ~ Al + P + K, env = vare_env)
#> 
#> ── tidyvisor: do the site variables explain composition? ───────────────────────
#> Question: explain
#> 
#> ── What the data show ──
#> 
#> • Sites: 24
#> • Species: 44
#> • Data: abundances
#> • Zeros: 42%
#> • Species in one site only: 0%
#> • Gradient length (DCA axis 1, SD units): 2.28 — below 3 SD: short; most
#>   species change monotonically; linear methods (PCA, RDA)
#> • Site variables (model terms): 3
#> • Collinearity (largest VIF): 2.4 (K)
#> 
#> ── Recommended ──
#> 
#> Approach: Constrained (direct, canonical) ordination
#> Branch: ordination and multivariate test (a picture with a permutation test).
#> You have a hypothesis that measured site variables explain composition.
#> Method: RDA on Hellinger-transformed data (or db-RDA)
#> Gradient length 2.3 SD.
#> ord <- ord_fit(data, abundance = abundance, method = "rda", transform = "hellinger", formula = ~Al + P + K)
#> Test: Permutation tests: the whole model, each axis and each term
#> The F-test of a constrained ordination has no parametric distribution;
#> permuting sites gives p-values.
#> ord_test(ord, by = "model"); ord_test(ord, by = "axis"); ord_test(ord, by = "margin")
#> Plots: Triplot; species response curves along the main variable; t-value biplot
#> or Van Dobben circles
#> The triplot shows sites, species and variables together; response curves show
#> each species' optimum and tolerance with confidence bands; Van Dobben circles
#> single out the species that respond significantly.
#> autoplot(ord)
#> autoplot(ord, type = "response", variable = "<numeric>")
#> autoplot(ord, type = "vandobben", variable = "<numeric>")
#> Interpret: Plain-language explanation of the tables and the diagram
#> Variation explained, tests, directions of variables, groups, species at each
#> end of the axes, and how to read the plot.
#> ord_interpret(ord)
```
