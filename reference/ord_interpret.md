# Explain and interpret an ordination, its tests and its diagram

`ord_interpret()` turns the results of an ordination into plain
sentences for the reader of a report: how much variation the axes hold
(and whether they are worth reading, against the broken-stick
expectation), what the permutation tests say, which way each site
variable runs across the diagram, where the groups lie, which species
define each end of the axes, how faithful an NMDS is (its stress), and
how to read the diagram under the scaling used. It works for
[`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
results, for principal response curves
([`ord_prc()`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md))
and for variation partitioning
([`ord_varpart()`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)).

The sentences describe the results; whether they answer the question is
for the analyst to judge. Fitted variables of an unconstrained
ordination are a post hoc description, not a test of a hypothesis.

## Usage

``` r
ord_interpret(x, ...)

# S3 method for class 'td_ordination'
ord_interpret(x, permutations = 999, n_species = 3, ...)

# S3 method for class 'td_prc'
ord_interpret(x, ...)

# S3 method for class 'td_varpart'
ord_interpret(x, ...)
```

## Arguments

- x:

  An
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md),
  [`ord_prc()`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md)
  or
  [`ord_varpart()`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)
  result.

- ...:

  Not used.

- permutations:

  Number of permutations for the tests of a constrained ordination or of
  fitted variables.

- n_species:

  Number of species named at each end of an axis.

## Value

A list of class `td_ord_interpretation`: `sections` (a named list of
character vectors, one per topic) and `tables` (the tables they are
based on). Printing it shows the sentences.

## References

Clarke, K. R. (1993). Non-parametric multivariate analyses of changes in
community structure. Australian Journal of Ecology, 18, 117-143.

ter Braak, C. J. F. and Smilauer, P. (2012). Canoco Reference Manual and
User's Guide: Software for Ordination (version 5.0). Microcomputer
Power.

## Examples

``` r
data("dune", "dune.env", package = "vegan")
d <- community_long(cbind(site = rownames(dune), dune.env, dune),
  cols = dplyr::all_of(names(dune))
)
o <- ord_fit(d,
  abundance = abundance, method = "rda", transform = "hellinger",
  formula = ~ A1 + Management
)
ord_interpret(o, permutations = 199)
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
#> • A1 has no significant unique effect (F = 2.09, p = 0.065), after allowing for
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
