# Which multivariate method? Ordination and the rest

``` r

library(tidydiversity)
```

## Multivariate analysis and ordination are not the same thing

**Multivariate analysis** is the whole family of methods for data with
many response variables measured on the same units: in community
ecology, the abundances of all the species at each site. **Ordination**
is one branch of that family. The four branches answer different
questions:

| Branch | The question | Methods | tidydiversity |
|----|----|----|----|
| **Ordination** | What are the main gradients in composition, and where do sites and species lie along them? | PCA, CA, DCA, PCoA, NMDS (unconstrained); RDA, CCA, db-RDA (constrained) | [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md), [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) |
| **Multivariate tests** | Does composition differ between groups, or change with a variable? | PERMANOVA, test of dispersion, Mantel test, permutation tests of constrained ordinations | [`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md), [`beta_dispersion()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md), [`beta_mantel()`](https://tidydiversity.in4metrix.dev/reference/beta_mantel.md), [`ord_test()`](https://tidydiversity.in4metrix.dev/reference/ord_test.md), [`ord_effects()`](https://tidydiversity.in4metrix.dev/reference/ord_effects.md) |
| **Classification** | Which sites form groups, and which species characterise them? | Cluster analysis, indicator species | [`stats::hclust()`](https://rdrr.io/r/stats/hclust.html) on [`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md); [`beta_indicator()`](https://tidydiversity.in4metrix.dev/reference/beta_indicator.md) |
| **Dissimilarity** | How different is each pair of sites? | Bray-Curtis, Jaccard, Sørensen, beta diversity | [`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md), [`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md), [`beta_multi()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md) |

Ordination is a *picture*: it reduces many species to a few axes you can
plot. A multivariate test is a *decision*: it gives a p-value.
**Constrained ordination** (RDA, CCA, db-RDA) belongs to both branches:
it draws the gradients that your explanatory variables explain, and a
permutation test then says whether that explanation is more than chance.
Unconstrained ordination (PCA, CA, DCA, PCoA, NMDS) only draws; it tests
nothing.

## Choosing: question first, then data, then method

**1. What is the question?**

- *Describe* the main patterns, with no explanatory variables in mind:
  unconstrained ordination.
- *Explain* composition with measured variables (soil, elevation,
  treatment): constrained ordination, with
  [`ord_test()`](https://tidydiversity.in4metrix.dev/reference/ord_test.md)
  and
  [`ord_effects()`](https://tidydiversity.in4metrix.dev/reference/ord_effects.md).
- *Compare groups* of sites (treatments, habitats): PERMANOVA
  ([`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md))
  with its test of dispersion
  ([`beta_dispersion()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)),
  or a constrained ordination with the factor.
- *Relate two distance matrices* (composition and geography, say):
  Mantel test
  ([`beta_mantel()`](https://tidydiversity.in4metrix.dev/reference/beta_mantel.md)).
- *Follow treatments over time*: principal response curves
  ([`ord_prc()`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md)).
- *Separate the effects of sets of variables* (environment and space):
  variation partitioning
  ([`ord_varpart()`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)).

**2. What are the data?** For ordination, the length of the main
gradient decides between linear and unimodal methods.
[`ord_advise()`](https://tidydiversity.in4metrix.dev/reference/ord_advise.md)
measures it as CANOCO does (the longest axis of a detrended
correspondence analysis, in standard-deviation units of species
turnover):

| Gradient length | Use |
|----|----|
| below 3 SD | linear methods: PCA, RDA (on Hellinger-transformed abundances) |
| 3 to 4 SD | either; both are appropriate |
| above 4 SD | unimodal methods: CA, CCA |

Distance-based methods (PCoA, NMDS, db-RDA, PERMANOVA) suit any gradient
length, with a dissimilarity chosen for the data (Bray-Curtis for
abundances, Jaccard or Sørensen for presence-absence).

**3. Let the advisor check.**
[`ord_advise()`](https://tidydiversity.in4metrix.dev/reference/ord_advise.md)
(or
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.html))
puts the question and the data together and says which method, which
test and which plots, with its reasons:

``` r

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
```

## The words, briefly

- **Axis (gradient)**: a combination of species abundances along which
  sites differ most (unconstrained), or most in relation to the
  explanatory variables (constrained).
- **Eigenvalue**: the variation an axis represents; divided by the
  total, the share of the variation it shows.
- **Constrained / canonical / direct**: the axes are combinations of the
  explanatory variables. **Unconstrained / indirect**: the axes come
  from the species data alone; variables can be fitted afterwards
  (passively).
- **Partial**: the effect of covariables (`Condition()` in the formula)
  is removed first.
- **Permutation test**: shuffles sites to see how often chance alone
  gives as strong a result; the shuffling can be restricted for blocked,
  split-plot, time-series or spatial designs
  ([`ord_design()`](https://tidydiversity.in4metrix.dev/reference/ord_design.md)).

## Further reading

Legendre, P. and Legendre, L. (2012). *Numerical Ecology*, third
edition. Elsevier.

Leps, J. and Smilauer, P. (2003). *Multivariate Analysis of Ecological
Data using CANOCO*. Cambridge University Press.
