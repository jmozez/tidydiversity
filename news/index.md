# Changelog

## tidydiversity 0.3.0

- New **tidyvisor**, the package’s adviser:
  [`tidyvisor()`](https://tidydiversity.in4metrix.dev/reference/tidyvisor.md)
  advises on the analysis when given data and interprets the results
  when given a fit.

- New
  [`ord_advise()`](https://tidydiversity.in4metrix.dev/reference/ord_advise.md)
  recommends an ordination and its test from the question and the data:
  unconstrained or constrained, linear or unimodal (from the DCA
  gradient length), with checks for zeros, presence-absence data, rare
  species, too many or collinear site variables, the plots that suit the
  question, and the code to run.

- New
  [`ord_interpret()`](https://tidydiversity.in4metrix.dev/reference/ord_interpret.md)
  explains an ordination, principal response curves or variation
  partitioning in plain sentences: variation explained (against the
  broken stick), permutation tests, the direction of each site variable,
  groups, the species at each end of the axes, NMDS stress, and how to
  read the diagram.

- New article, “A gallery of ordination diagrams”, shows every diagram
  type on the classic vegan data sets (`dune`, `varespec`, `mite`,
  `pyrifos`); the help examples of
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html),
  [`ord_style()`](https://tidydiversity.in4metrix.dev/reference/ord_style.md),
  [`ord_prc()`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md)
  and
  [`ord_test()`](https://tidydiversity.in4metrix.dev/reference/ord_test.md)
  use them too.

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  of an ordination gains `type = "vandobben"` (CANOCO’s t-value biplot
  with Van Dobben circles; species coloured by exact t-tests) and
  `type = "stability"` (95% ellipses of bootstrap ordinations, rotated
  onto the original by Procrustes analysis), and an `inset` option that
  adds a scree or Shepard diagram in a corner of the biplot.

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  for ordinations gains `type =` for the main diagram types of
  multivariate analysis, all styled with
  [`ord_style()`](https://tidydiversity.in4metrix.dev/reference/ord_style.md):
  `"gradient"` (the axis meaning written at its ends, sites joined along
  a gradient, arrow width following r squared, species sorted along the
  first axis in a panel below), `"response"` (species response curves
  from a quadratic Poisson GLM or a GAM, with confidence bands from the
  model on the link scale), `"scree"` (with the broken-stick
  expectation), `"shepard"` (NMDS, with stress and R squared) and
  `"tvalue"` (species that increase or decrease with a site variable,
  from exact t-tests).
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
  keeps the community matrix for these.

- New
  [`ord_prc()`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md):
  principal response curves (van den Brink and ter Braak

  1999. of treatments against a control over time, with a permutation
        test restricted within times, and the classic PRC diagram from
        [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).

- [`ord_varpart()`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)
  results now have an
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  method: a Venn-style diagram of the adjusted R squared of each
  fraction (two or three sets), or a bar chart (four sets).

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  for ordinations no longer colours sites on a continuous colour bar. As
  in CANOCO, sites are drawn as categories: a numeric `colour` variable
  becomes ordered classes, each with its own colour and symbol.

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  for ordinations gains `surface`, which draws a continuous site
  variable as fitted contour lines (a thin-plate GAM as in
  [`vegan::ordisurf()`](https://vegandevs.github.io/vegan/reference/ordisurf.html),
  or a linear trend surface with fewer than 15 sites), and `size`, which
  scales the site symbols to a numeric variable (a CANOCO attribute
  plot). Continuous variables are lines (arrows or contours), factors
  are centroids, sites and species are points.

- Ordination diagrams draw species as points (crosses with italic
  labels) in every method, as `vegan::plot.rda()` does;
  `species_arrows = TRUE` gives a PCA/RDA biplot with species arrows.
  Arrows are otherwise kept for continuous environmental variables.

- New
  [`ord_style()`](https://tidydiversity.in4metrix.dev/reference/ord_style.md)
  and `autoplot(style = )`: every colour, symbol, size, line width and
  font of an ordination diagram can be set. The default look follows
  CANOCO 5, tuned for print: filled site symbols with a thin outline,
  hairlines through the origin, crosses for species, heavier arrows for
  environmental variables.

- Ordination diagrams now have a key for every kind of element: sites,
  species (arrows or crosses), continuous variables (arrows), factor
  centroids and contours, each with its own symbol.

- New
  [`div_invasion()`](https://tidydiversity.in4metrix.dev/reference/div_invasion.md):
  native and alien richness, the alien share of species and of
  individuals per site (levels of invasion).

- New
  [`div_homogenisation()`](https://tidydiversity.in4metrix.dev/reference/div_homogenisation.md):
  biotic homogenisation between two surveys, the change in mean pairwise
  Jaccard or Sorensen similarity among the same sites, with a
  site-bootstrap interval and the part due to alien species.
  Similarities match
  [`vegan::vegdist()`](https://vegandevs.github.io/vegan/reference/vegdist.html).

- New
  [`range_edges()`](https://tidydiversity.in4metrix.dev/reference/range_edges.md):
  the lower and upper edges, midpoint, breadth and abundance-weighted
  optimum of each species along a gradient, with flags for edges
  truncated at the ends of the transect.

- New
  [`range_shift_resurvey()`](https://tidydiversity.in4metrix.dev/reference/range_shift_resurvey.md)
  and
  [`range_shift_test()`](https://tidydiversity.in4metrix.dev/reference/range_shift_resurvey.md):
  shifts of edges, midpoints and optima between a historical survey and
  a resurvey, with bootstrap intervals and an exact sign test across
  species.

- New
  [`range_shift_validate()`](https://tidydiversity.in4metrix.dev/reference/range_shift_validate.md)
  and
  [`range_shift_expected()`](https://tidydiversity.in4metrix.dev/reference/range_shift_validate.md):
  hindcast validation of projected range shifts against resurveys (bias,
  error, correlation, calibration slope, direction and the share of the
  expected shift that species realised, with a bootstrap interval).

## tidydiversity 0.2.0

### Bug fixes

- Site order is now stable and documented: outputs of
  [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md),
  [`div_coverage()`](https://tidydiversity.in4metrix.dev/reference/div_coverage.md),
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
  and every other function follow the factor levels of the site column,
  or else natural order (numbers inside names compared numerically, so
  “200m” comes before “1200m”), whatever the order of the input rows.
  Before, sites came in order of first appearance, and joining site data
  by position gave silently wrong results. Joins inside the package are
  by site name.
- [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
  fitted passive environmental variables on all retained axes (up to
  three) while the biplot showed two, so their p-values did not describe
  the plot. New `choices` (default `1:2`, as in
  [`vegan::envfit()`](https://vegandevs.github.io/vegan/reference/envfit.html))
  sets the axes for both the test and the arrows, and the `envfit` table
  reports the axes, the number of permutations and whether the test was
  exact. New `permutations = "exact"` enumerates every ordering of the
  sites (n!; 5,040 for 7 sites), and `seed` makes random permutation
  tests reproducible.
  [`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)
  also accepts `permutations = "exact"`.
- [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md):
  the default target coverage is now documented and chosen by `level`:
  `"max_extrapolation"` (default, the rule of
  [`iNEXT::estimateD()`](https://rdrr.io/pkg/iNEXT/man/estimateD.html):
  the lowest coverage reached at twice each sample size) or
  `"min_observed"` (the lowest observed coverage). The target is
  returned in a new `target` column, and a site that cannot reach it
  (for example one singleton and no doubletons) now gives a warning
  instead of being returned silently at a lower coverage.
- [`model_count()`](https://tidydiversity.in4metrix.dev/reference/model_count.md)
  printed the whole deparsed [`glm()`](https://rdrr.io/r/stats/glm.html)
  function as the call; it now prints a readable call such as
  `glm(formula = richness ~ poly(elevation, 2), family = poisson, data = data)`.

### New features

- [`beta_mantel()`](https://tidydiversity.in4metrix.dev/reference/beta_mantel.md):
  Mantel and partial Mantel tests (Spearman by default) on
  [`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md)
  results, distance matrices or site values, with exact permutations and
  a choice of tail, returned as a one-row tibble. Equal to
  [`vegan::mantel()`](https://vegandevs.github.io/vegan/reference/mantel.html)
  and
  [`vegan::mantel.partial()`](https://vegandevs.github.io/vegan/reference/mantel.html).
- [`beta_turnover_counts()`](https://tidydiversity.in4metrix.dev/reference/beta_turnover_counts.md):
  species shared, lost and gained between adjacent (or all, or chosen)
  pairs of sites, with Sørensen and Jaccard dissimilarity split into
  turnover and nestedness, and Bray-Curtis into balanced variation and
  abundance gradient; equal to betapart. Sites with no species are kept
  with a warning, and undefined indices are `NA`.
- [`beta_decay_boot()`](https://tidydiversity.in4metrix.dev/reference/beta_decay_boot.md):
  distance-decay slopes with bootstrap confidence intervals that
  resample sites, and the difference between two transects or taxa.
- New vignette “An elevational-gradient workflow”.

## tidydiversity 0.1.0

### Sampling effort and drivers of richness gradients

- New
  [`div_effort()`](https://tidydiversity.in4metrix.dev/reference/div_effort.md):
  the additional individuals or sampling units needed to reach a target
  sample coverage (Chao and Jost 2012) or a target fraction of the
  estimated richness (Chao et al. 2009), solved exactly so the answers
  agree with the extrapolated curves of
  [`div_rarefy()`](https://tidydiversity.in4metrix.dev/reference/div_rarefy.md).
- New
  [`range_partition()`](https://tidydiversity.in4metrix.dev/reference/range_partition.md):
  splits the variation in richness along a gradient into parts explained
  by the mid-domain null model (geometry), by environmental variables,
  by both, and neither (adjusted R², equal to
  [`vegan::varpart()`](https://vegandevs.github.io/vegan/reference/varpart.html)),
  with F tests of the unique fractions.

### Mid-domain effect (RangeModel)

- New
  [`range_through()`](https://tidydiversity.in4metrix.dev/reference/range_through.md):
  range-through interpolation along elevational or latitudinal
  gradients.
- New
  [`range_mde()`](https://tidydiversity.in4metrix.dev/reference/range_mde.md):
  mid-domain null models of richness along a gradient, with uniform
  placement of ranges (Colwell and Hurtt 1994; exact expectation) or the
  spreading-dye model (equal to rangemodelR), a simulation interval per
  site, R² and a global test
  ([`glance()`](https://generics.r-lib.org/reference/glance.html)), and
  an
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  method. New article “Mid-domain effect and range-through
  interpolation”.

### EstimateS and SpadeR estimators

- New
  [`div_richness()`](https://tidydiversity.in4metrix.dev/reference/div_richness.md):
  the classic non-parametric richness estimators of EstimateS and
  SpadeR, with bootstrap standard errors and log-normal intervals.
  Abundance data: Chao1, bias-corrected Chao1, iChao1 (Chiu et
  al. 2014), ACE, ACE-1 and first- and second-order jackknife. Incidence
  data: Chao2, bias-corrected Chao2, iChao2, ICE, ICE-1, jackknives and
  the bootstrap estimator. Point estimates equal SpadeR and vegan.

- New
  [`div_fisher_alpha()`](https://tidydiversity.in4metrix.dev/reference/div_fisher_alpha.md):
  Fisher’s log-series alpha, equal to
  [`vegan::fisher.alpha()`](https://vegandevs.github.io/vegan/reference/diversity.html).

- New
  [`beta_shared()`](https://tidydiversity.in4metrix.dev/reference/beta_shared.md):
  the Chao1- and Chao2-shared estimators of the number of species two
  sites share, including undetected shared species (Chao et al. 2000),
  equal to SpadeR.

- New
  [`beta_chao()`](https://tidydiversity.in4metrix.dev/reference/beta_shared.md):
  Chao et al. (2005) abundance- and incidence-based Jaccard and Sørensen
  similarities corrected for unseen shared species, next to the classic
  indices; equal to SpadeR and to `vegan::vegdist(method = "chao")`.

- A named `palette` in
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods that misses a category is now an error naming the category;
  before, ggplot2 drew that category grey without a warning. Fully named
  palettes always coloured categories by name.

- All geospatial and mapping code has moved to the companion package
  [tidymapr](https://tidymapr.in4metrix.dev/): the `geo_*()` verbs,
  `as_sf()`, `as_spat_raster()`, `plot_sites()`, `plot_geo()`,
  `plot_topo()`, `geo_save()`, the `sdm_*()` functions and `plot_sdm()`,
  the spatial stem verbs `stems_quadrat()`, `stems_habitat()`,
  `stems_neighbours()` and `stems_habitat_test()`, the `geo_example_*()`
  helpers and the `png_ants_sites` coordinates. Load both packages to
  map diversity results; tidymapr returns the same tibbles and ggplots.
  tidydiversity no longer suggests any spatial package, and the map
  figures have left its README and website.

- Maps now use real, published records only. New `png_ants_sites` holds
  the published bait GPS of the 16 Mt Wilhelm ant transects (Mottl,
  Moses and Klimes 2023, <doi:10.5281/zenodo.8191946>), and
  `geo_example_sites()` returns their band centroids instead of invented
  coordinates (the `"wanang"` option, which had no published
  coordinates, is removed). The README and the new “Maps (bonus)”
  section of the website Gallery show a study-site map, a Hill-number
  map, an SRTM elevation map and an SDM of *Oecophylla smaragdina* from
  GBIF records (CC0 / CC BY 4.0, shipped in
  `inst/extdata/gbif_oecophylla_png.csv`) and WorldClim 2.1, rendered by
  `data-raw/gallery_maps.R`. The simulated stem map and demonstration
  SDM figures are gone. `plot_sdm()` no longer adds a default
  “demonstration” subtitle.

- Tile basemaps from maptiles are now projected to the map CRS and drawn
  the right way up, and tile zoom is chosen from the map extent so site
  maps are sharp.

- Map interoperability: `as_sf()` and `as_spat_raster()` return
  CRS-aware **sf** / **terra** objects for optional use with tmap and
  leaflet (Suggests only; not hard Imports).

- Tidy replacements for the Moses et al. (2021) Biotropica plotting
  stack (<doi:10.1111/btp.12914>):
  [`plot_partial()`](https://tidydiversity.in4metrix.dev/reference/plot-partial.md)
  (visreg-like partial effects),
  [`plot_surface()`](https://tidydiversity.in4metrix.dev/reference/plot-partial.md)
  (plotmo / visreg2d-like two-predictor contours), and
  [`model_count()`](https://tidydiversity.in4metrix.dev/reference/model_count.md)
  (Poisson, quasi-Poisson, negative binomial, binomial, quasi-binomial)
  so callers never need visreg, plotmo or aods3.

- Geospatial follow-up: environmental distance in `geo_distance()` /
  `geo_decay()` (Euclidean or Gower on bioclim columns); Hill-number
  site maps via `plot_geo()` with scale bar and north arrow;
  `geo_elevation()` (SRTM-style DEM with cache / offline path);
  `geo_mem()` (dbMEM / PCNM); `geo_rarefy_spatial()`; `geo_grain()`
  (MAUP / multi-grain Hill numbers); `geo_middomain()`; CHELSA-CMIP6 via
  `geo_chelsa(scenario=, year=)`; ForestGEO `stems_habitat_test()`
  (torus); tidy SDM family `sdm_fit()` / `sdm_predict()` /
  `sdm_evaluate()` / `plot_sdm()` (glm, gam, native maxnet-like; no Java
  Maxent, no biomod2); `geo_as_features()` for prioritizr hand-off.
  Spectral / rgee remain deferred. New Rcpp kernels for Euclidean
  distances, neighbour counts, torus shifts, spatial rarefaction and SDM
  link functions.

- ForestGEO-style census verbs:
  [`stems_as_trees()`](https://tidydiversity.in4metrix.dev/reference/stems.md),
  `stems_quadrat()`,
  [`stems_abundance()`](https://tidydiversity.in4metrix.dev/reference/stems.md),
  [`stems_basal_area()`](https://tidydiversity.in4metrix.dev/reference/stems.md),
  [`stems_size_class()`](https://tidydiversity.in4metrix.dev/reference/stems.md),
  [`stems_demography()`](https://tidydiversity.in4metrix.dev/reference/stems.md),
  `stems_habitat()`,
  [`stems_as_community()`](https://tidydiversity.in4metrix.dev/reference/stems.md),
  `stems_neighbours()`, plus `geo_example_censuses()`.

- `plot_topo()` maps ForestGEO-style stems (`gx`, `gy`, DBH, species)
  over contour and hillshade backdrops. `geo_example_stems()`,
  `geo_example_dem()` and `geo_example_censuses()` are simulated test
  data for checking code only; no map in the documentation is drawn from
  them.

- Basemaps for `plot_sites()` and `plot_geo()` via `basemap` /
  `geo_basemap()` (`none`, `coast`, OSM / Carto / ESRI tiles with
  offline coast fallback, or a user raster). Vector verbs:
  `geo_buffer()`, `geo_crop()`, `geo_intersection()`,
  `geo_difference()`, `geo_union()`, `geo_area()`, `geo_centroid()`,
  `geo_bbox()`, `geo_join()`, `geo_distance_to()`. Raster verbs:
  `geo_raster_read()`, `geo_raster_crop()`, `geo_raster_mask()`,
  `geo_raster_resample()`, `geo_raster_project()`,
  `geo_raster_terrain()`, `geo_raster_focal()`, `geo_raster_zonal()`.
  Bioclimate: `geo_bioclim_vars()`, `geo_bioclim()`, `geo_worldclim()`,
  `geo_chelsa()` with cache and offline `path` (cite Fick and Hijmans
  2017; Karger et al. 2017).

- `plot_sites()` draws publication-ready study-site maps (grouping,
  labels, raster or coastline backdrop, facets, scale bar and north
  arrow without map-package dependencies). `geo_example_sites()` returns
  the published bait GPS positions for the Mt Wilhelm elevation bands.
  SDM tools such as biomod2 and Maxent remain out of scope until rebuilt
  as tidy verbs.

- Geospatial workflow (native tidyverse-style verbs; **sf** and
  **terra** as Suggests): `geo_as_sf()`, `geo_drop_geometry()`,
  `geo_extract()`, `geo_clean()` (occurrence flags rebuilt so callers
  never need CoordinateCleaner), `geo_gbif()`, `geo_distance()`,
  `geo_decay()` (feeds
  [`beta_decay_model()`](https://tidydiversity.in4metrix.dev/reference/beta_decay_model.md)
  with great-circle or elevational distance), `plot_geo()` and
  `geo_moran()` (Moran’s I with a permutation p-value, rebuilt so
  callers never need spdep). Compiled haversine kernels speed large
  distance tables. New article “Geospatial diversity workflows”.

- Package scaffold.

- New plots:
  [`plot_venn()`](https://tidydiversity.in4metrix.dev/reference/plot_venn.md)
  draws Venn diagrams of the species shared by two to four groups;
  [`plot_phylo()`](https://tidydiversity.in4metrix.dev/reference/plot_phylo.md)
  draws a phylogeny with a column of relative abundances per site and
  can highlight the branches (Faith’s PD) of one site;
  [`plot_trait_space()`](https://tidydiversity.in4metrix.dev/reference/plot_trait_space.md)
  places species in a PCoA trait space with each group’s convex hull
  (functional richness) and community-weighted mean.

- New dataset `wanang_caterpillars`: 9,363 Lepidoptera larvae of 849
  morphospecies reared from host trees in primary and secondary forest
  at Wanang (Butterill and Redmond 2023, GBIF, CC BY 4.0).

- Citations corrected: Moses et al. (2023) pages 2212-2229, Dahl et al.

  2024. volume 56 pages 90-97, the Portal Project data paper (Ernest et
        al. 2018, bioRxiv) and the authors and years of the Plowman et
        al. and Luk et al. Dryad datasets, all checked against Crossref
        and DataCite.

- Input checks:
  [`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md),
  [`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md)
  and
  [`div_completeness()`](https://tidydiversity.in4metrix.dev/reference/div_completeness.md)
  now reject infinite `q`, which used to return `NaN`. Bootstrapping a
  sample of more than 2,147,483,647 individuals now gives a clear error
  instead of failing inside
  [`stats::rmultinom()`](https://rdrr.io/r/stats/Multinom.html).
  [`div_evenness()`](https://tidydiversity.in4metrix.dev/reference/div_evenness.md)
  and the other extrapolating verbs no longer fail at high `q`, where
  the asymptotic estimator is undefined; they fall back to the observed
  value.

- [`div_completeness()`](https://tidydiversity.in4metrix.dev/reference/div_completeness.md)
  warns when a sample has only singletons: estimates for q \> 0 are then
  unreliable and can be negative (as in iNEXT.4steps).

- tidydiversity is dedicated to the memory of Filip Damen (about
  1966-2026) of Wanang Village, Papua New Guinea: a new article tells
  his story, linked from the navigation bar and the README.

- [`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)
  now defaults to `by = "margin"`: each term is tested after all the
  others, so results no longer depend on the order of terms in the
  formula. The previous default, sequential tests (`by = "terms"`, also
  vegan’s default), is still available.

- [`beta_decay_model()`](https://tidydiversity.in4metrix.dev/reference/beta_decay_model.md):
  fits exponential or power distance-decay models of similarity to
  [`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md)
  output and tests them by permuting sites (Mantel-style). Estimates
  match
  [`betapart::decay.model()`](https://rdrr.io/pkg/betapart/man/decay.model.html);
  the p-value uses (1 + count) / (1 + permutations), so it is never
  zero.

- [`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md):
  pairwise Hill-number gamma, alpha and beta with the four normalised
  dissimilarities (Chao, Chiu and Jost 2014) for every pair of sites. At
  q = 0 it gives Sorensen and Jaccard, at q = 2 Morisita-Horn.
  [`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md)
  and
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  accept its output.

- Ordination plots and the pairwise heatmap keep a fixed aspect ratio;
  they now paint the whole image white, so no transparent margin is left
  on web pages, slides or transparent devices.

- Plots on the website: the site’s dark mode no longer inverts figures
  (it turned white plots black and changed their colours); every figure
  is shown white with its true colours.

- Ordination plots: all labels (species, sites, variables, centroids)
  are placed in one layer that avoids every point and every other label;
  leader lines for moved labels are faint and dotted, and no longer look
  like species vectors. The help page and article explain every line
  type. The text layer no longer adds “a” keys to the legend.

- Coverage plots repel site labels instead of overprinting them and show
  no axis tick above 100%; facet panels have more space between them.

- [`beta_indicator()`](https://tidydiversity.in4metrix.dev/reference/beta_indicator.md)
  now corrects p-values for multiple testing (`adjust = "holm"` by
  default; new column `p.adj`) and selects species on the adjusted
  values. Use `adjust = "none"` for the previous behaviour.

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  for
  [`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md)
  results: gamma, alpha and beta, or the four dissimilarities, against q
  with bootstrap intervals.

- Website: every figure, including reference-page examples, now has an
  opaque white background, so no plot turns dark in the site’s dark
  mode. New gallery entry, README tables and text for
  [`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md)
  and
  [`beta_welch()`](https://tidydiversity.in4metrix.dev/reference/beta_welch.md).

- [`beta_welch()`](https://tidydiversity.in4metrix.dev/reference/beta_welch.md):
  Welch-type PERMANOVA (W\*d; Hamidi et al. 2019), robust to unequal
  dispersion; equals Welch’s F in one Euclidean dimension.

- [`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md):
  coverage-standardised gamma, alpha and beta Hill numbers with four
  normalised dissimilarities (Chao et al. 2023), for taxonomic,
  phylogenetic (`type = "PD"`) and functional (`type = "FD"`, threshold
  or AUC) diversity, abundance or incidence (`unit`) data, and bootstrap
  confidence intervals (`nboot`); point estimates match iNEXT.beta3D
  exactly.

- Trait-based ecology, following the *Handbook of Trait-Based Ecology*
  (de Bello et al. 2021):
  [`trait_dist()`](https://tidydiversity.in4metrix.dev/reference/trait_dist.md)
  (Gower, gawdis),
  [`trait_cwm()`](https://tidydiversity.in4metrix.dev/reference/trait_cwm.md),
  [`trait_cwm_test()`](https://tidydiversity.in4metrix.dev/reference/trait_cwm_test.md)
  (max test),
  [`trait_fd_indices()`](https://tidydiversity.in4metrix.dev/reference/trait_fd_indices.md)
  (FRic, FEve, FDiv, FDis, Rao),
  [`trait_rao()`](https://tidydiversity.in4metrix.dev/reference/trait_rao.md)
  (alpha/beta/gamma with equivalent numbers),
  [`trait_ses()`](https://tidydiversity.in4metrix.dev/reference/trait_ses.md)
  (null models),
  [`trait_itv()`](https://tidydiversity.in4metrix.dev/reference/trait_itv.md)
  (intra- vs interspecific variability) and
  [`trait_fourth_corner()`](https://tidydiversity.in4metrix.dev/reference/trait_fourth_corner.md).
  [`data_aravo()`](https://tidydiversity.in4metrix.dev/reference/data_aravo.md)
  loads the ade4 alpine plant data. Trait probability densities
  ([`trait_tpd()`](https://tidydiversity.in4metrix.dev/reference/trait_tpd.md),
  [`trait_tpd_dissim()`](https://tidydiversity.in4metrix.dev/reference/trait_tpd.md),
  computed natively after
  [`TPD::TPDs()`](https://rdrr.io/pkg/TPD/man/TPDs.html)), and
  phylogenetic signal
  ([`phylo_signal()`](https://tidydiversity.in4metrix.dev/reference/phylo_signal.md),
  with a fast native Blomberg’s K),
  [`phylo_dist()`](https://tidydiversity.in4metrix.dev/reference/phylo_dist.md)
  and
  [`phylo_combine_dist()`](https://tidydiversity.in4metrix.dev/reference/phylo_combine_dist.md).
  New article “Trait-based ecology”.

- Testing community composition:
  [`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)
  (PERMANOVA, with restricted permutations),
  [`beta_dispersion()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)
  (homogeneity of dispersion, with
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)),
  [`ord_select()`](https://tidydiversity.in4metrix.dev/reference/ord_select.md)
  (forward selection with double stopping),
  [`ord_varpart()`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)
  (variation partitioning with tests) and
  [`beta_indicator()`](https://tidydiversity.in4metrix.dev/reference/beta_indicator.md)
  (indicator species). Results match vegan and indicspecies exactly. New
  article “Testing community composition”.

- tidymodels integration:
  [`model_group_folds()`](https://tidydiversity.in4metrix.dev/reference/model_group_folds.md)
  (site-blocked cross-validation),
  [`model_case_weights()`](https://tidydiversity.in4metrix.dev/reference/model_case_weights.md)
  (inverse-variance weights from diversity SEs) and the recipe step
  [`step_hill()`](https://tidydiversity.in4metrix.dev/reference/step_hill.md).
  New article “Modelling diversity with tidymodels”.

- Multi-panel figures:
  [`plot_panel()`](https://tidydiversity.in4metrix.dev/reference/plot_panel.md)
  combines plots with patchwork, adding panel tags (a, b, …), shared
  legends and white backgrounds;
  [`plot_save()`](https://tidydiversity.in4metrix.dev/reference/plot_save.md)
  saves at journal column widths (85, 120 or 175 mm) and 300 dpi.

- Ordination:
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
  fits PCA, CA, DCA, PCoA, NMDS, RDA, CCA and db-RDA (with partial
  versions through `Condition()`) to long community data with vegan,
  returning tidy scores; results match vegan exactly. Variables are
  fitted passively to unconstrained ordinations, as in CANOCO.
  [`ord_test()`](https://tidydiversity.in4metrix.dev/reference/ord_test.md)
  gives tidy permutation tests, and
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  draws CANOCO-style biplots and triplots with ellipses, hulls, spiders
  and non-overlapping labels. New article “Ordination: biplots and
  triplots”.

- `wanang_butterflies` combines three species that the source
  spreadsheet listed in two columns each (189 species, counts
  unchanged).

- `png_ants` leaves out its single dry-season record at 2700 m, so both
  seasons cover the same five elevations (200 to 2200 m) and can be
  compared directly.

- Plots no longer print “Ignoring unknown labels” messages, and long
  site legends wrap instead of running off the figure.

- Incidence data for TD, PD and FD:
  [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md),
  [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md),
  [`div_coverage()`](https://tidydiversity.in4metrix.dev/reference/div_coverage.md),
  [`div_rarefy()`](https://tidydiversity.in4metrix.dev/reference/div_rarefy.md)
  and
  [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md)
  gain `unit` (the sampling-unit column) and `n_units` (units sampled,
  including empty ones). Estimates, rarefaction, extrapolation, coverage
  and bootstrap intervals are incidence-based (Chao et al. 2014); for PD
  a branch is present in a unit when any species below it was detected.
  Results match iNEXT.3D on its fish survey and iNEXT on the `png_ants`
  baits.

- `png_ants` gains `baits`, the number of baits set at each elevation
  and season, for incidence-based estimates with `unit = bait`.

- Example data are now real, published field data from Papua New Guinea,
  replacing the simulated `ant_gradient`: `png_ants` (ants at nutrient
  baits along Mt Wilhelm; Moses et al. 2023), `png_tree_ants`
  (tree-nesting ants in three plots; Plowman et al. 2020), `png_frogs`
  (frogs along Mt Wilhelm; Dahl et al. 2024) and `wanang_butterflies`
  (butterfly monitoring at Wanang; Luk et al. 2019). Each is rebuilt
  from its Zenodo deposit by a script in `data-raw/`.

- New case-study articles for the Papua New Guinea ants, frogs and
  butterflies.

- Rarefaction and extrapolation are about 60 times faster on large
  samples, with identical results.

- Phylogenetic (PD) and functional (FD) diversity:
  [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md),
  [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md),
  [`div_rarefy()`](https://tidydiversity.in4metrix.dev/reference/div_rarefy.md)
  and
  [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md)
  gain `type = c("TD", "PD", "FD")` with `tree`, `reftime`, `pd_unit`,
  `distance` and `tau` (including `tau = "auc"`). Point estimates match
  iNEXT.3D to within 1e-6.

- Bootstrap standard errors and confidence intervals for PD and FD in
  [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md),
  [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md)
  and
  [`div_rarefy()`](https://tidydiversity.in4metrix.dev/reference/div_rarefy.md),
  previously `NA`. The bootstrap community adds undetected species with
  estimated branch lengths (PD) or distances (FD).

- New article “TD, PD and FD on one scale”, and a rewritten home page.

- [`div_completeness()`](https://tidydiversity.in4metrix.dev/reference/div_completeness.md)
  and
  [`div_evenness()`](https://tidydiversity.in4metrix.dev/reference/div_evenness.md)
  give sample completeness and evenness profiles (classes E1 to E5) that
  match iNEXT.4steps.

- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods for every result type:
  [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md)
  profiles and gradients,
  [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md),
  [`div_coverage()`](https://tidydiversity.in4metrix.dev/reference/div_coverage.md),
  [`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
  heatmaps and
  [`beta_multi()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
  stacked bars.
