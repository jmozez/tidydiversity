# tidydiversity 0.1.0

* ForestGEO-style census verbs: `stems_as_trees()`, `stems_quadrat()`,
  `stems_abundance()`, `stems_basal_area()`, `stems_size_class()`,
  `stems_demography()`, `stems_habitat()`, `stems_as_community()`,
  `stems_neighbours()`, plus `geo_example_censuses()`.
* `plot_topo()` maps ForestGEO-style stems (`gx`, `gy`, DBH, species)
  over contour and hillshade backdrops; `geo_example_stems()` and
  `geo_example_dem()` supply an illustrative local-metre plot.
* Basemaps for `plot_sites()` and `plot_geo()` via `basemap` / `geo_basemap()`
  (`none`, `coast`, OSM / Carto / ESRI tiles with offline coast fallback, or a
  user raster). Vector verbs: `geo_buffer()`, `geo_crop()`,
  `geo_intersection()`, `geo_difference()`, `geo_union()`, `geo_area()`,
  `geo_centroid()`, `geo_bbox()`, `geo_join()`, `geo_distance_to()`. Raster
  verbs: `geo_raster_read()`, `geo_raster_crop()`, `geo_raster_mask()`,
  `geo_raster_resample()`, `geo_raster_project()`, `geo_raster_terrain()`,
  `geo_raster_focal()`, `geo_raster_zonal()`. Bioclimate: `geo_bioclim_vars()`,
  `geo_bioclim()`, `geo_worldclim()`, `geo_chelsa()` with cache and offline
  `path` (cite Fick and Hijmans 2017; Karger et al. 2017).
* `plot_sites()` draws publication-ready study-site maps (grouping,
  labels, raster or coastline backdrop, facets, scale bar and north arrow
  without map-package dependencies). `geo_example_sites()` supplies
  illustrative Mt Wilhelm and Wanang coordinates for the PNG examples,
  which carry elevation but not GPS. SDM tools such as biomod2 and Maxent
  remain out of scope until rebuilt as tidy verbs.
* Geospatial workflow (native tidyverse-style verbs; **sf** and **terra**
  as Suggests): `geo_as_sf()`, `geo_drop_geometry()`, `geo_extract()`,
  `geo_clean()` (occurrence flags rebuilt so callers never need
  CoordinateCleaner), `geo_gbif()`, `geo_distance()`, `geo_decay()`
  (feeds `beta_decay_model()` with great-circle or elevational distance),
  `plot_geo()` and `geo_moran()` (Moran's I with a permutation p-value,
  rebuilt so callers never need spdep). Compiled haversine kernels speed
  large distance tables. New article "Geospatial diversity workflows".

* Package scaffold.
* Input checks: `beta_hill()`, `beta_hill_pair()` and `div_completeness()`
  now reject infinite `q`, which used to return `NaN`. Bootstrapping a
  sample of more than 2,147,483,647 individuals now gives a clear error
  instead of failing inside `stats::rmultinom()`. `div_evenness()` and the
  other extrapolating verbs no longer fail at high `q`, where the
  asymptotic estimator is undefined; they fall back to the observed value.
* `div_completeness()` warns when a sample has only singletons: estimates
  for q > 0 are then unreliable and can be negative (as in iNEXT.4steps).
* tidydiversity is dedicated to the memory of Filip Damen (about
  1966-2026) of Wanang Village, Papua New Guinea: a new article tells his
  story, linked from the navigation bar and the README.
* `beta_permanova()` now defaults to `by = "margin"`: each term is tested
  after all the others, so results no longer depend on the order of terms
  in the formula. The previous default, sequential tests
  (`by = "terms"`, also vegan's default), is still available.
* `beta_decay_model()`: fits exponential or power distance-decay models of
  similarity to `beta_decay()` output and tests them by permuting sites
  (Mantel-style). Estimates match `betapart::decay.model()`; the p-value
  uses (1 + count) / (1 + permutations), so it is never zero.
* `beta_hill_pair()`: pairwise Hill-number gamma, alpha and beta with the
  four normalised dissimilarities (Chao, Chiu and Jost 2014) for every
  pair of sites. At q = 0 it gives Sorensen and Jaccard, at q = 2
  Morisita-Horn. `beta_dist()` and `autoplot()` accept its output.
* Ordination plots and the pairwise heatmap keep a fixed aspect ratio; they
  now paint the whole image white, so no transparent margin is left on
  web pages, slides or transparent devices.
* Plots on the website: the site's dark mode no longer inverts figures
  (it turned white plots black and changed their colours); every figure
  is shown white with its true colours.
* Ordination plots: all labels (species, sites, variables, centroids) are
  placed in one layer that avoids every point and every other label;
  leader lines for moved labels are faint and dotted, and no longer look
  like species vectors. The help page and article explain every line
  type. The text layer no longer adds "a" keys to the legend.
* Coverage plots repel site labels instead of overprinting them and show
  no axis tick above 100%; facet panels have more space between them.
* `beta_indicator()` now corrects p-values for multiple testing
  (`adjust = "holm"` by default; new column `p.adj`) and selects species
  on the adjusted values. Use `adjust = "none"` for the previous
  behaviour.
* `autoplot()` for `beta_hill()` results: gamma, alpha and beta, or the
  four dissimilarities, against q with bootstrap intervals.
* Website: every figure, including reference-page examples, now has an
  opaque white background, so no plot turns dark in the site's dark mode.
  New gallery entry, README tables and text for `beta_hill()` and
  `beta_welch()`.
* `beta_welch()`: Welch-type PERMANOVA (W*d; Hamidi et al. 2019), robust
  to unequal dispersion; equals Welch's F in one Euclidean dimension.
* `beta_hill()`: coverage-standardised gamma, alpha and beta Hill
  numbers with four normalised dissimilarities (Chao et al. 2023), for
  taxonomic, phylogenetic (`type = "PD"`) and functional (`type = "FD"`,
  threshold or AUC) diversity, abundance or incidence (`unit`) data, and
  bootstrap confidence intervals (`nboot`); point estimates match
  iNEXT.beta3D exactly.
* Trait-based ecology, following the *Handbook of Trait-Based Ecology*
  (de Bello et al. 2021): `trait_dist()` (Gower, gawdis),
  `trait_cwm()`, `trait_cwm_test()` (max test), `trait_fd_indices()` (FRic, FEve,
  FDiv, FDis, Rao), `trait_rao()` (alpha/beta/gamma with equivalent numbers),
  `trait_ses()` (null models), `trait_itv()` (intra- vs interspecific
  variability) and `trait_fourth_corner()`. `data_aravo()` loads the ade4
  alpine plant data. Trait probability densities (`trait_tpd()`,
  `trait_tpd_dissim()`, computed natively after `TPD::TPDs()`), and
  phylogenetic signal (`phylo_signal()`, with a fast native Blomberg's
  K), `phylo_dist()` and `phylo_combine_dist()`. New article
  "Trait-based ecology".
* Testing community composition: `beta_permanova()` (PERMANOVA, with
  restricted permutations), `beta_dispersion()` (homogeneity of
  dispersion, with `autoplot()`), `ord_select()` (forward selection with
  double stopping), `ord_varpart()` (variation partitioning with tests)
  and `beta_indicator()` (indicator species). Results match vegan and
  indicspecies exactly. New article "Testing community composition".
* tidymodels integration: `model_group_folds()` (site-blocked
  cross-validation), `model_case_weights()` (inverse-variance weights from
  diversity SEs) and the recipe step `step_hill()`. New article
  "Modelling diversity with tidymodels".
* Multi-panel figures: `plot_panel()` combines plots with patchwork, adding
  panel tags (a, b, ...), shared legends and white backgrounds;
  `plot_save()` saves at journal column widths (85, 120 or 175 mm) and
  300 dpi.
* Ordination: `ord_fit()` fits PCA, CA, DCA, PCoA, NMDS, RDA, CCA and
  db-RDA (with partial versions through `Condition()`) to long community
  data with vegan, returning tidy scores; results match vegan exactly.
  Variables are fitted passively to unconstrained ordinations, as in
  CANOCO. `ord_test()` gives tidy permutation tests, and `autoplot()`
  draws CANOCO-style biplots and triplots with ellipses, hulls, spiders
  and non-overlapping labels. New article "Ordination: biplots and
  triplots".
* `wanang_butterflies` combines three species that the source spreadsheet
  listed in two columns each (189 species, counts unchanged).
* `png_ants` leaves out its single dry-season record at 2700 m, so both
  seasons cover the same five elevations (200 to 2200 m) and can be
  compared directly.
* Plots no longer print "Ignoring unknown labels" messages, and long
  site legends wrap instead of running off the figure.
* Incidence data for TD, PD and FD: `div_hill()`, `div_estimate()`,
  `div_coverage()`, `div_rarefy()` and `div_standardise()` gain `unit`
  (the sampling-unit column) and `n_units` (units sampled, including empty
  ones). Estimates, rarefaction, extrapolation, coverage and bootstrap
  intervals are incidence-based (Chao et al. 2014); for PD a branch is
  present in a unit when any species below it was detected. Results match
  iNEXT.3D on its fish survey and iNEXT on the `png_ants` baits.
* `png_ants` gains `baits`, the number of baits set at each elevation and
  season, for incidence-based estimates with `unit = bait`.
* Example data are now real, published field data from Papua New Guinea,
  replacing the simulated `ant_gradient`: `png_ants` (ants at nutrient
  baits along Mt Wilhelm; Moses et al. 2023), `png_tree_ants` (tree-nesting
  ants in three plots; Plowman et al. 2020), `png_frogs` (frogs along
  Mt Wilhelm; Dahl et al. 2023) and `wanang_butterflies` (butterfly
  monitoring at Wanang; Luk et al. 2019). Each is rebuilt from its Zenodo
  deposit by a script in `data-raw/`.
* New case-study articles for the Papua New Guinea ants, frogs and
  butterflies.
* Rarefaction and extrapolation are about 60 times faster on large samples,
  with identical results.
* Phylogenetic (PD) and functional (FD) diversity: `div_hill()`,
  `div_estimate()`, `div_rarefy()` and `div_standardise()` gain
  `type = c("TD", "PD", "FD")` with `tree`, `reftime`, `pd_unit`,
  `distance` and `tau` (including `tau = "auc"`). Point estimates match
  iNEXT.3D to within 1e-6.
* Bootstrap standard errors and confidence intervals for PD and FD in
  `div_estimate()`, `div_standardise()` and `div_rarefy()`, previously `NA`.
  The bootstrap community adds undetected species with estimated branch
  lengths (PD) or distances (FD).
* New article "TD, PD and FD on one scale", and a rewritten home page.
* `div_completeness()` and `div_evenness()` give sample completeness and
  evenness profiles (classes E1 to E5) that match iNEXT.4steps.
* `autoplot()` methods for every result type: `div_hill()` profiles and
  gradients, `div_estimate()`, `div_coverage()`, `beta_pair()` heatmaps and
  `beta_multi()` stacked bars.
