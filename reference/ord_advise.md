# Which ordination and which test? Advice from the data and the question

`ord_advise()` helps choose an ordination method and the test that goes
with it. It looks at the community data (number of sites and species,
zeros, abundances or presence-absence, the length of the main gradient)
and at the question asked, and recommends, with its reasons and the code
to run:

- **unconstrained or constrained.** To *describe* the main patterns of
  composition, without a hypothesis about their causes, use an
  unconstrained (indirect) ordination: PCA, CA or NMDS; site variables
  can be fitted afterwards (arrows, contours) but are not part of the
  analysis. To *test* whether, and how much, measured variables explain
  composition, use a constrained (direct, canonical) ordination: RDA,
  CCA or distance-based RDA, with a permutation test.

- **linear or unimodal.** The length of the first axis of a detrended
  correspondence analysis, in standard-deviation units of species
  turnover, measures how heterogeneous the data are: below about 3, most
  species change monotonically and linear methods (PCA, RDA) fit; above
  about 4, species rise and fall along the gradient and unimodal methods
  (CA, CCA) fit; in between, either (ter Braak and Smilauer 2012).
  Hellinger-transformed PCA and RDA (Legendre and Gallagher 2001) work
  well whatever the length, and NMDS or distance-based RDA with
  Bray-Curtis or Jaccard dissimilarity suit any data.

- **the test.** Constrained ordinations are tested by permutation
  (overall, by axis and by term); with many candidate variables, by
  forward selection; differences between groups of sites by PERMANOVA,
  with a test of dispersion alongside; treatments followed over time by
  principal response curves; and the separate and shared effects of sets
  of variables by variation partitioning.

The advice is a starting point, not a rule: the question, which only the
analyst knows, comes first.

## Usage

``` r
ord_advise(
  data,
  site = site,
  species = species,
  abundance = NULL,
  formula = NULL,
  question = c("auto", "explore", "explain", "groups", "time", "partition"),
  treatment = NULL,
  time = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- formula:

  Optional one-sided formula of site variables (columns of `data`, one
  value per site), e.g. `~ elevation + habitat`.

- question:

  What is asked: `"auto"` (from the other arguments), `"explore"`
  (describe the main patterns), `"explain"` (test site variables),
  `"groups"` (compare groups of sites), `"time"` (treatments followed
  over time) or `"partition"` (separate the effects of sets of
  variables).

- treatment, time:

  Optional columns for a treatment followed over time.

## Value

A list of class `td_ord_advice`: `checks` (a tibble of what was measured
in the data, its value and what it means), `advice` (a tibble of steps:
`step`, `recommendation`, `reason` and `code`) and `gradient_length`.
Printing it shows the advice.

## References

ter Braak, C. J. F. and Smilauer, P. (2012). Canoco Reference Manual and
User's Guide: Software for Ordination (version 5.0). Microcomputer
Power.

Legendre, P. and Gallagher, E. D. (2001). Ecologically meaningful
transformations for ordination of species data. Oecologia, 129, 271-280.

Legendre, P. and Legendre, L. (2012). Numerical Ecology, third edition.
Elsevier.

## Examples

``` r
data("dune", "dune.env", package = "vegan")
d <- community_long(cbind(site = rownames(dune), dune.env, dune),
  cols = dplyr::all_of(names(dune))
)
# Describe the meadows
ord_advise(d, abundance = abundance)
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: explore
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
#> • Site variables (model terms): "0"
#> 
#> ── Recommended ──
#> 
#> Approach: Unconstrained (indirect) ordination
#> You want to describe the main patterns of composition, not test their causes.
#> Method: PCA on Hellinger-transformed data, or NMDS
#> Gradient length 3.5 SD; NMDS on bray dissimilarity suits any data.
#> ord_fit(data, abundance = abundance, method = "pca", transform = "hellinger")
#> ord_fit(data, abundance = abundance, method = "nmds", distance = "bray")
#> Interpret: Fit site variables afterwards (arrows, contours, centroids)
#> Fitted variables are a post hoc interpretation of the axes; their permutation
#> p-values are descriptive.
#> autoplot(ord, surface = <numeric variable>)
#> Check: Scree diagram (PCA, CA) or Shepard diagram and stress (NMDS)
#> How many axes are worth reading, and how faithful the diagram is.
#> autoplot(ord, type = "scree")   # or type = "shepard"
#> Plots: Biplot with numeric variables as contours or symbol size, factors as
#> centroids; scree or Shepard inset; stability ellipses
#> Contours show non-linear change that an arrow hides; the inset shows how
#> faithful the diagram is; ellipses show which sites are placed firmly.
#> autoplot(ord, surface = <numeric>, colour = <factor>, inset = "scree")   # "shepard" for NMDS
#> autoplot(ord, type = "gradient", path = <numeric>)
#> autoplot(ord, type = "stability")
#> Interpret: Plain-language explanation of the tables and the diagram
#> Variation explained, tests, directions of variables, groups, species at each
#> end of the axes, and how to read the plot.
#> ord_interpret(ord)
# Test management and soil
ord_advise(d, abundance = abundance, formula = ~ A1 + Moisture + Management)
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
#> • Site variables (model terms): "7" — many terms for the sites: select
#>   variables (forward selection)
#> 
#> ── Recommended ──
#> 
#> Approach: Constrained (direct, canonical) ordination
#> You have a hypothesis that measured site variables explain composition.
#> Method: RDA on Hellinger-transformed data (or db-RDA)
#> Gradient length 3.5 SD.
#> ord <- ord_fit(data, abundance = abundance, method = "rda", transform = "hellinger", formula = ~A1 + Moisture + Management)
#> Select: Forward selection of variables
#> Too many or collinear variables inflate the explained variation and make the
#> test unreliable.
#> ord_select(data, abundance = abundance, formula = ~A1 + Moisture + Management)
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
