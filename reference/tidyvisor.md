# tidyvisor: advice before the analysis, interpretation after it

`tidyvisor()` is the package's adviser. Give it **data** and a question,
and it recommends the analysis, the test, the plots and the code to run
(see
[`ord_advise()`](https://tidydiversity.in4metrix.dev/reference/ord_advise.md)).
Give it a **result**, and it explains the tables and the diagram in
plain sentences (see
[`ord_interpret()`](https://tidydiversity.in4metrix.dev/reference/ord_interpret.md)).

Its advice follows the standard references of community ecology, and it
always gives its reasons, so it can be checked and overruled: the
question, which only the analyst knows, comes first.

## Usage

``` r
tidyvisor(x, ...)
```

## Arguments

- x:

  Community data in long format (to be advised), or the result of
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md),
  [`ord_prc()`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md)
  or
  [`ord_varpart()`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)
  (to be interpreted).

- ...:

  Passed to
  [`ord_advise()`](https://tidydiversity.in4metrix.dev/reference/ord_advise.md)
  (data) or
  [`ord_interpret()`](https://tidydiversity.in4metrix.dev/reference/ord_interpret.md)
  (results).

## Value

A `td_ord_advice` or a `td_ord_interpretation` object.

## Examples

``` r
data("dune", "dune.env", package = "vegan")
d <- community_long(cbind(site = rownames(dune), dune.env, dune),
  cols = dplyr::all_of(names(dune))
)
# Before: which analysis?
tidyvisor(d, abundance = abundance, formula = ~ A1 + Management)
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: explain
#> 
#> ── What the data show ──
#> 
#> • Sites: "20"
#> • Species: "30"
#> • Data: "abundances"
#> • Zeros: "67%" — many zeros: shared absences must not make sites similar
#>   (Hellinger or Bray-Curtis)
#> • Species in one site only: "10%"
#> • Gradient length (DCA axis 1, SD units): "3.52" — intermediate: linear or
#>   unimodal methods both suit
#> • Site variables (model terms): "4"
#> 
#> ── Recommended ──
#> 
#> Approach: Constrained (direct, canonical) ordination
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
# After: what does it show?
o <- ord_fit(d,
  abundance = abundance, method = "rda", transform = "hellinger",
  formula = ~ A1 + Management
)
tidyvisor(o, permutations = 199)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • A redundancy analysis (RDA) of 20 sites and 30 species
#>   (Hellinger-transformed), constrained by A1, Management.
#> 
#> ── Variation ──
#> 
#> • The site variables explain 38.6% of the variation in composition (adjusted R²
#>   = 22.2%, allowing for the number of variables).
#> • The first two constrained axes hold 17.5% and 13.2% of the total variation
#>   (79.5% of the explained part).
#> 
#> ── Tests ──
#> 
#> • Overall, composition is significantly related to the site variables
#>   (permutation F = 2.35, p = 0.005, 199 permutations).
#> • A1 has a significant unique effect (F = 2.09, p = 0.045), after allowing for
#>   the other variables.
#> • Management has a significant unique effect (F = 2.08, p = 0.015), after
#>   allowing for the other variables.
#> 
#> ── Site variables ──
#> 
#> • A1 increases towards the lower left of the diagram, mostly along the first
#>   axis (biplot scores -0.65, -0.59).
#> • Management: BF lies towards the upper right; HF lies towards the right; NM
#>   lies towards the left; SF lies towards the lower right. The further apart two
#>   centroids, the more the composition of their sites differs.
#> 
#> ── Species ──
#> 
#> • Axis 1 (RDA1) runs from Eleopalu, Ranuflam, Comapalu (negative end) to
#>   Poatriv, Lolipere, Poaprat (positive end).
#> • Axis 2 (RDA2) runs from Agrostol, Alopgeni, Poatriv (negative end) to
#>   Planlanc, Anthodor, Scorautu (positive end).
#> 
#> ── Reading the diagram ──
#> 
#> • Sites (circles) close together have similar species composition.
#> • With species scaling, the angles between species (and between species and
#>   variable arrows) approximate their correlations; distances between sites are
#>   only approximate.
#> • Project a site or species perpendicularly onto an arrow: the further along
#>   the arrow, the higher the variable (or the stronger the species' association
#>   with it).
#> • Triangles are the centroids of the factor levels: the average position of
#>   their sites.
```
