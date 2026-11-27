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
# S3 method for class 'td_cva'
ord_interpret(x, ...)

# S3 method for class 'td_dcca'
ord_interpret(x, ...)

# S3 method for class 'td_rlq'
ord_interpret(x, ...)

# S3 method for class 'td_coca'
ord_interpret(x, ...)

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
#> • A1 has a significant unique effect (F = 2.09, p = 0.035), after allowing for
#>   the other variables.
#> • Management has a significant unique effect (F = 2.08, p = 0.005), after
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
#> 
#> ── After the overall test ──
#> 
#> • Management (4 levels) has a significant effect (p = 0.005): the groups are
#>   not all alike in composition, but the test does not say which differ. Go on
#>   to pairwise PERMANOVA between the levels, with p-values adjusted for the
#>   number of pairs (Holm):
#> • env <- ord$env; comm <- ord$community pairs <-
#>   combn(levels(factor(env$Management)), 2, simplify = FALSE) p <- sapply(pairs,
#>   function(l) { k <- env$Management %in% l; vegan::adonis2(comm[k, ] ~
#>   Management, data = env[k, , drop = FALSE], method = "bray")$`Pr(>F)`[1] })
#>   stats::setNames(p.adjust(p, "holm"), vapply(pairs, paste, "", collapse = " vs
#>   "))
#> • Check that the levels of Management have similar spread
#>   (beta_dispersion(data, group = Management)); if they do not, a significant
#>   pair may differ in spread rather than in composition.
#> 
#> ── For the paper ──
#> 
#> • Results: 'Community composition was related to A1 and Management (RDA on
#>   Hellinger-transformed abundances; pseudo-F = 2.35, p = 0.005, 199
#>   permutations; adjusted R² = 22.2%).'
#> • Report the test with its statistic, p-value and number of permutations, and
#>   the variation explained as an adjusted R².
#> • Figure: the ordination diagram with the sites as points (coloured or shaped
#>   by group), the variables as arrows or centroids, and only the species that
#>   matter labelled:
#> • ord_plot <- ggplot2::autoplot(ord) ord_plot
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 85, units = "mm") # one
#>   journal column
#> • Figure style for journals: one column (about 85 mm) or the page (about 180
#>   mm); label only the species that matter (the strongest weights or best
#>   fitted); give the variation of each axis in its label; a colour-blind-safe
#>   palette and different symbols for groups; text at least 8 pt; vector PDF or
#>   SVG.
#> • Table: the permutation test for the whole model and for each variable (df,
#>   variance, pseudo-F, p), and the variation explained by the axes.
#> • Methods: the method (RDA), the transformation (Hellinger), the scaling, the
#>   permutation scheme and number of permutations, and the software (R 4.6.2,
#>   vegan 2.7.8; citation("vegan"), citation("tidydiversity")).
```
