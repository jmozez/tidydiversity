# Dune meadow vegetation and environment (a species-environment pair)

Real field data: the Dutch dune meadow data, a classic teaching example
for ordination (Jongman et al. 1987), as two tables in the layout CANOCO
uses: a species table with one row per site and one column per species,
and an environment table with one row per site. The two are linked by
`site`. Taken unchanged from the vegan package (`dune` and `dune.env`).

## Usage

``` r
dune_species

dune_env
```

## Format

`dune_species`: a tibble with 20 rows (sites) and 31 columns: `site` and
30 plant species (abbreviated Latin names, such as `Achimill` for
*Achillea millefolium*), with cover classes from 1 to 9 (an ordinal
scale, not percent cover; 0 where absent).

`dune_env`: a tibble with 20 rows and six columns:

- site:

  Site number, matching `dune_species`.

- A1:

  Thickness of the soil A1 horizon, in cm; 9 means 9 cm or more. Where
  sand deposition left several A1 horizons, only the top one was
  measured.

- Moisture:

  Moisture class, an ordinal scale from 1 (dry) to 5 (wet); classes 1,
  2, 4 and 5 occur.

- Management:

  `BF` biological farming, `HF` hobby farming, `NM` nature conservation
  management, `SF` standard farming.

- Use:

  Land use, ordered: `Hayfield`, `Haypastu` (hay pasture), `Pasture`.

- Manure:

  Amount of manure applied, an ordinal class from 0 (none) to 4 (the
  most); not a quantity in kg.

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 20
rows and 6 columns.

## Source

The vegan package (Oksanen et al.), data sets `dune` and `dune.env`.
Built by `data-raw/canoco_pairs.R` in the package source.

## Details

To analyse the pair, put the species table in long format with
[`community_long()`](https://tidydiversity.in4metrix.dev/reference/as_community.md)
and give the environment table as `env` to
[`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
or
[`ord_advise()`](https://tidydiversity.in4metrix.dev/reference/ord_advise.md).

## References

Batterink, M. and Wijffels, G. (1983). Report (in Dutch) on the dune
meadows of Terschelling. Agricultural University, Wageningen. (The
original survey.)

Jongman, R. H., ter Braak, C. J. F. and van Tongeren, O. F. R. (1987).
*Data Analysis in Community and Landscape Ecology*. Pudoc, Wageningen.

## Examples

``` r
dune_species
#> # A tibble: 20 × 31
#>    site  Achimill Agrostol Airaprae Alopgeni Anthodor Bellpere Bromhord Chenalbu
#>    <chr>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>    <dbl>
#>  1 1            1        0        0        0        0        0        0        0
#>  2 2            3        0        0        2        0        3        4        0
#>  3 3            0        4        0        7        0        2        0        0
#>  4 4            0        8        0        2        0        2        3        0
#>  5 5            2        0        0        0        4        2        2        0
#>  6 6            2        0        0        0        3        0        0        0
#>  7 7            2        0        0        0        2        0        2        0
#>  8 8            0        4        0        5        0        0        0        0
#>  9 9            0        3        0        3        0        0        0        0
#> 10 10           4        0        0        0        4        2        4        0
#> 11 11           0        0        0        0        0        0        0        0
#> 12 12           0        4        0        8        0        0        0        0
#> 13 13           0        5        0        5        0        0        0        1
#> 14 14           0        4        0        0        0        0        0        0
#> 15 15           0        4        0        0        0        0        0        0
#> 16 16           0        7        0        4        0        0        0        0
#> 17 17           2        0        2        0        4        0        0        0
#> 18 18           0        0        0        0        0        2        0        0
#> 19 19           0        0        3        0        4        0        0        0
#> 20 20           0        5        0        0        0        0        0        0
#> # ℹ 22 more variables: Cirsarve <dbl>, Comapalu <dbl>, Eleopalu <dbl>,
#> #   Elymrepe <dbl>, Empenigr <dbl>, Hyporadi <dbl>, Juncarti <dbl>,
#> #   Juncbufo <dbl>, Lolipere <dbl>, Planlanc <dbl>, Poaprat <dbl>,
#> #   Poatriv <dbl>, Ranuflam <dbl>, Rumeacet <dbl>, Sagiproc <dbl>,
#> #   Salirepe <dbl>, Scorautu <dbl>, Trifprat <dbl>, Trifrepe <dbl>,
#> #   Vicilath <dbl>, Bracruta <dbl>, Callcusp <dbl>
dune_env
#> # A tibble: 20 × 6
#>    site     A1 Moisture Management Use      Manure
#>    <chr> <dbl> <ord>    <fct>      <ord>    <ord> 
#>  1 1       2.8 1        SF         Haypastu 4     
#>  2 2       3.5 1        BF         Haypastu 2     
#>  3 3       4.3 2        SF         Haypastu 4     
#>  4 4       4.2 2        SF         Haypastu 4     
#>  5 5       6.3 1        HF         Hayfield 2     
#>  6 6       4.3 1        HF         Haypastu 2     
#>  7 7       2.8 1        HF         Pasture  3     
#>  8 8       4.2 5        HF         Pasture  3     
#>  9 9       3.7 4        HF         Hayfield 1     
#> 10 10      3.3 2        BF         Hayfield 1     
#> 11 11      3.5 1        BF         Pasture  1     
#> 12 12      5.8 4        SF         Haypastu 2     
#> 13 13      6   5        SF         Haypastu 3     
#> 14 14      9.3 5        NM         Pasture  0     
#> 15 15     11.5 5        NM         Haypastu 0     
#> 16 16      5.7 5        SF         Pasture  3     
#> 17 17      4   2        NM         Hayfield 0     
#> 18 18      4.6 1        NM         Hayfield 0     
#> 19 19      3.7 5        NM         Hayfield 0     
#> 20 20      3.5 5        NM         Hayfield 0     
d <- community_long(dune_species, cols = -site)
ord_advise(d, abundance = abundance, formula = ~ A1 + Management, env = dune_env)
#> 
#> ── tidyvisor: do the site variables explain composition? ───────────────────────
#> Question: explain
#> 
#> ── What the data show ──
#> 
#> • Sites: 20
#> • Species: 30
#> • Data: abundances
#> • Zeros: 67% — many zeros: shared absences must not make sites similar
#>   (Hellinger or Bray-Curtis)
#> • Species in one site only: 10%
#> • Gradient length (DCA axis 1, SD units): 3.52 — 3 to 4 SD: intermediate;
#>   linear and unimodal methods are both appropriate
#> • Site variables (model terms): 4
#> 
#> ── Recommended ──
#> 
#> Approach: Constrained (direct, canonical) ordination
#> Branch: ordination and multivariate test (a picture with a permutation test).
#> You have a hypothesis that measured site variables explain composition.
#> Method: RDA on Hellinger-transformed data (or db-RDA)
#> Gradient length 3.5 SD.
#> ord <- ord_fit(data, abundance = abundance, method = "rda", transform = "hellinger", formula = ~A1 + Management)
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
ord_fit(d,
  abundance = abundance, method = "rda", formula = ~ A1 + Management,
  env = dune_env
)
#> RDA of 20 sites and 30 species
#> Transformation: hellinger
#> Variation explained: RDA1 17.5%, RDA2 13.2%, RDA3 4.8%
#> Constrained: 38.6% of the total
```
