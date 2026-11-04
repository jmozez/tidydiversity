# tidydiversity 0.0.0.9000

* Package scaffold.
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
