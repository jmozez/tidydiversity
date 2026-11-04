# tidydiversity 0.0.0.9000

* Package scaffold.
* tidymodels integration: `td_group_folds()` (site-blocked
  cross-validation), `td_case_weights()` (inverse-variance weights from
  diversity SEs) and the recipe step `step_hill()`. New article
  "Modelling diversity with tidymodels".
* Multi-panel figures: `td_panel()` combines plots with patchwork, adding
  panel tags (a, b, ...), shared legends and white backgrounds;
  `td_save()` saves at journal column widths (85, 120 or 175 mm) and
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
