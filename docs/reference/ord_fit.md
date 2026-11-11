# Ordination of community data

Fits an unconstrained or constrained ordination to long community data
and returns its scores as tidy tibbles. The ordination itself is
computed by the vegan package, so results are identical to vegan's;
tidydiversity adds the data handling, site covariates, tidy output and
publication-quality plots
([autoplot()](https://tidydiversity.in4metrix.dev/reference/autoplot.td_ordination.md)).

## Usage

``` r
ord_fit(
  data,
  site = site,
  species = species,
  abundance = NULL,
  method = c("pca", "ca", "dca", "pcoa", "nmds", "rda", "cca", "dbrda"),
  formula = NULL,
  env = NULL,
  transform = NULL,
  distance = "bray",
  scaling = c("species", "sites", "symmetric"),
  k = 2,
  permutations = 999,
  ...
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- method:

  Ordination method; see Details.

- formula:

  A one-sided formula of site variables, such as `~ elevation + season`.
  Required for constrained methods; for unconstrained methods the
  variables are fitted passively.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- transform:

  Transformation of the community matrix before the analysis:
  `"hellinger"` (the default for PCA and RDA, which otherwise overweight
  abundant species; Legendre and Gallagher 2001), `"chord"`, `"log"`
  (log(x) + 1 for x \> 0), `"sqrt"`, `"pa"` (presence-absence) or
  `"none"` (the default for the other methods).

- distance:

  Dissimilarity for `"pcoa"`, `"nmds"` and `"dbrda"`, passed to
  [`vegan::vegdist()`](https://rdrr.io/pkg/vegan/man/vegdist.html), such
  as `"bray"` (the default) or `"jaccard"`.

- scaling:

  For PCA, CA, PCoA and the constrained methods, which scores to scale
  (ter Braak and Smilauer 2012): `"species"` (the default, vegan
  scaling 2) preserves the correlations between species and variables;
  `"sites"` (scaling 1) preserves the distances between sites;
  `"symmetric"` (scaling 3) is a compromise.

- k:

  For `"nmds"`, the number of dimensions.

- permutations:

  Number of permutations for the tests of passive variables.

- ...:

  Passed to the vegan function that fits the ordination.

## Value

A `td_ordination` object: a list with tibbles `sites` (site scores
joined to the site variables), `species`, `vectors` (environmental
arrows), `centroids` (factor levels) and `axes` (eigenvalues and
proportion of variation explained), plus `stress` for NMDS, `envfit` for
passive variables and `fit`, the vegan object. Use
[tidy()](https://tidydiversity.in4metrix.dev/reference/tidy.td_ordination.md)
and
[glance()](https://tidydiversity.in4metrix.dev/reference/tidy.td_ordination.md)
to extract them and
[`ord_test()`](https://tidydiversity.in4metrix.dev/reference/ord_test.md)
for permutation tests.

## Details

Unconstrained methods summarise the main gradients in species
composition: principal components analysis (`"pca"`), correspondence
analysis (`"ca"`), detrended correspondence analysis (`"dca"`),
principal coordinates analysis (`"pcoa"`) of a dissimilarity, and
non-metric multidimensional scaling (`"nmds"`). Constrained methods find
the gradients explained by environmental variables: redundancy analysis
(`"rda"`), canonical correspondence analysis (`"cca"`) and
distance-based RDA (`"dbrda"`). Add `Condition(x)` to the formula for a
partial analysis that removes the effect of `x` first.

For an unconstrained method, a `formula` fits the variables passively
with [`vegan::envfit()`](https://rdrr.io/pkg/vegan/man/envfit.html), so
they appear as supplementary arrows and centroids (as in CANOCO) without
changing the ordination.

## References

Legendre, P. and Gallagher, E. D. (2001). Ecologically meaningful
transformations for ordination of species data. Oecologia, 129, 271-280.
[doi:10.1007/s004420100716](https://doi.org/10.1007/s004420100716)

ter Braak, C. J. F. and Smilauer, P. (2012). Canoco reference manual and
user's guide: software for ordination (version 5.0). Microcomputer
Power, Ithaca, USA.

Oksanen, J. et al. vegan: Community Ecology Package.
<https://CRAN.R-project.org/package=vegan>

## Examples

``` r
# Tree-nesting ants: one sample per plot and subplot
ants <- png_tree_ants
ants$plot <- paste(ants$site, ants$subplot)

# Constrained: how much of the composition does elevation explain?
ord <- ord_fit(ants,
  site = plot, abundance = nests, method = "rda", formula = ~elevation
)
ord
#> RDA of 5 sites and 169 species
#> Transformation: hellinger
#> Variation explained: RDA1 63.3%, PC1 28.2%, PC2 4.5%
#> Constrained: 63.3% of the total
ord_test(ord)
#> 'nperm' >= set of all permutations: complete enumeration.
#> Set of permutations < 'minperm'. Generating entire set.
#> # A tibble: 2 x 5
#>   term        df variance statistic p.value
#>   <chr>    <dbl>    <dbl>     <dbl>   <dbl>
#> 1 Model        1    0.475      5.17  0.0333
#> 2 Residual     3    0.276     NA    NA     

# Unconstrained NMDS with elevation fitted passively
nmds <- ord_fit(ants,
  site = plot, abundance = nests, method = "nmds", formula = ~elevation
)
#> Warning: stress is (nearly) zero: you may have insufficient data
#> Warning: skipping half-change scaling: too few points below threshold
#> 'nperm' >= set of all permutations: complete enumeration.
#> Set of permutations < 'minperm'. Generating entire set.
#> 'nperm' >= set of all permutations: complete enumeration.
#> Set of permutations < 'minperm'. Generating entire set.
tidy(nmds)
#> # A tibble: 5 x 6
#>   plot      axis1   axis2 site   elevation subplot
#>   <chr>     <dbl>   <dbl> <chr>      <int> <chr>  
#> 1 Wanang B -0.393  0.250  Wanang       200 B      
#> 2 Wanang A -0.429 -0.0484 Wanang       200 A      
#> 3 Numba A  -0.117 -0.336  Numba        900 A      
#> 4 Yawan A   0.398  0.237  Yawan       1800 A      
#> 5 Yawan C   0.542 -0.103  Yawan       1800 C      
```
