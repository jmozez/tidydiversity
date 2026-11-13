# Package index

## Community data

- [`as_community()`](https://tidydiversity.in4metrix.dev/reference/as_community.md)
  [`community_wide()`](https://tidydiversity.in4metrix.dev/reference/as_community.md)
  [`community_long()`](https://tidydiversity.in4metrix.dev/reference/as_community.md)
  : Tidy community data
- [`tidy(`*`<td_estimate>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_standardise>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_rarefy>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_boot>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_beta_pair>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`glance(`*`<td_coverage>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`add_site_data()`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  : Tidy and model-ready output

## Datasets

- [`png_ants`](https://tidydiversity.in4metrix.dev/reference/png_ants.md)
  : Ants at nutrient baits along Mt Wilhelm, Papua New Guinea
- [`png_tree_ants`](https://tidydiversity.in4metrix.dev/reference/png_tree_ants.md)
  : Tree-nesting ants in rainforest plots at three elevations, Papua New
  Guinea
- [`png_frogs`](https://tidydiversity.in4metrix.dev/reference/png_frogs.md)
  : Frogs along the Mt Wilhelm elevational gradient, Papua New Guinea
- [`wanang_butterflies`](https://tidydiversity.in4metrix.dev/reference/wanang_butterflies.md)
  : Butterflies in the Wanang forest dynamics plot, Papua New Guinea
- [`wanang_caterpillars`](https://tidydiversity.in4metrix.dev/reference/wanang_caterpillars.md)
  : Caterpillars reared from trees in primary and secondary forest at
  Wanang
- [`portal_rodents`](https://tidydiversity.in4metrix.dev/reference/portal_rodents.md)
  : Rodent captures at the Portal Project, Arizona

## Alpha diversity

- [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md)
  : Observed Hill numbers
- [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md)
  : Asymptotic diversity estimates
- [`div_richness()`](https://tidydiversity.in4metrix.dev/reference/div_richness.md)
  : Classic species richness estimators
- [`div_fisher_alpha()`](https://tidydiversity.in4metrix.dev/reference/div_fisher_alpha.md)
  : Fisher's alpha
- [`div_effort()`](https://tidydiversity.in4metrix.dev/reference/div_effort.md)
  : Additional sampling effort needed
- [`div_coverage()`](https://tidydiversity.in4metrix.dev/reference/div_coverage.md)
  : Sample coverage

## Completeness and evenness

- [`div_completeness()`](https://tidydiversity.in4metrix.dev/reference/div_completeness.md)
  : Sample completeness profiles
- [`div_evenness()`](https://tidydiversity.in4metrix.dev/reference/div_evenness.md)
  : Evenness profiles

## Rarefaction and standardisation

- [`div_rarefy()`](https://tidydiversity.in4metrix.dev/reference/div_rarefy.md)
  : Rarefaction and extrapolation curves
- [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md)
  : Standardise diversity by coverage or sample size
- [`div_boot()`](https://tidydiversity.in4metrix.dev/reference/div_boot.md)
  : Bootstrap replicates of diversity estimates

## Beta diversity

- [`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
  [`beta_multi()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md)
  : Partition beta diversity into turnover and nestedness
- [`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md)
  : Coverage-standardised beta diversity with Hill numbers
- [`beta_hill_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_hill_pair.md)
  : Pairwise Hill-number dissimilarity
- [`beta_shared()`](https://tidydiversity.in4metrix.dev/reference/beta_shared.md)
  [`beta_chao()`](https://tidydiversity.in4metrix.dev/reference/beta_shared.md)
  : Shared species and similarity corrected for unseen species

## Richness along gradients

- [`range_through()`](https://tidydiversity.in4metrix.dev/reference/range_through.md)
  : Range-through interpolation along a gradient
- [`range_mde()`](https://tidydiversity.in4metrix.dev/reference/range_mde.md)
  [`glance(`*`<td_mde>`*`)`](https://tidydiversity.in4metrix.dev/reference/range_mde.md)
  : Mid-domain null model of richness along a gradient
- [`range_partition()`](https://tidydiversity.in4metrix.dev/reference/range_partition.md)
  : Geometry or environment? Partitioning richness along a gradient
- [`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md)
  : Distance decay of similarity
- [`beta_decay_model()`](https://tidydiversity.in4metrix.dev/reference/beta_decay_model.md)
  : Fit and test a distance-decay model
- [`beta_decay_boot()`](https://tidydiversity.in4metrix.dev/reference/beta_decay_boot.md)
  : Bootstrap confidence interval for a distance-decay slope
- [`beta_mantel()`](https://tidydiversity.in4metrix.dev/reference/beta_mantel.md)
  : Mantel and partial Mantel tests
- [`beta_turnover_counts()`](https://tidydiversity.in4metrix.dev/reference/beta_turnover_counts.md)
  : Shared, lost and gained species between pairs of sites
- [`range_edges()`](https://tidydiversity.in4metrix.dev/reference/range_edges.md)
  : Elevational (or other gradient) ranges of species
- [`range_shift_resurvey()`](https://tidydiversity.in4metrix.dev/reference/range_shift_resurvey.md)
  [`range_shift_test()`](https://tidydiversity.in4metrix.dev/reference/range_shift_resurvey.md)
  : Range shifts between two surveys of the same gradient
- [`range_shift_validate()`](https://tidydiversity.in4metrix.dev/reference/range_shift_validate.md)
  [`range_shift_expected()`](https://tidydiversity.in4metrix.dev/reference/range_shift_validate.md)
  : Validate projected range shifts against resurveys (hindcasting)
- [`div_invasion()`](https://tidydiversity.in4metrix.dev/reference/div_invasion.md)
  : Native and alien species in communities
- [`div_homogenisation()`](https://tidydiversity.in4metrix.dev/reference/div_homogenisation.md)
  : Biotic homogenisation between two surveys
- [`beta_dist()`](https://tidydiversity.in4metrix.dev/reference/beta_dist.md)
  : Pairwise dissimilarity as a distance matrix
- [`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)
  [`beta_dispersion()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md)
  : PERMANOVA and dispersion tests on community composition
- [`beta_welch()`](https://tidydiversity.in4metrix.dev/reference/beta_welch.md)
  : Welch-type PERMANOVA robust to unequal dispersion
- [`beta_indicator()`](https://tidydiversity.in4metrix.dev/reference/beta_indicator.md)
  : Indicator species analysis

## tidyvisor (advice and interpretation)

- [`tidyvisor()`](https://tidydiversity.in4metrix.dev/reference/tidyvisor.md)
  : tidyvisor: advice before the analysis, interpretation after it
- [`ord_advise()`](https://tidydiversity.in4metrix.dev/reference/ord_advise.md)
  : Which ordination and which test? Advice from the data and the
  question
- [`ord_interpret()`](https://tidydiversity.in4metrix.dev/reference/ord_interpret.md)
  : Explain and interpret an ordination, its tests and its diagram

## Ordination

- [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
  : Ordination of community data
- [`ord_style()`](https://tidydiversity.in4metrix.dev/reference/ord_style.md)
  : Style of ordination diagrams
- [`ord_prc()`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md)
  [`autoplot(`*`<td_prc>`*`)`](https://tidydiversity.in4metrix.dev/reference/ord_prc.md)
  : Principal response curves
- [`ord_test()`](https://tidydiversity.in4metrix.dev/reference/ord_test.md)
  : Permutation tests for constrained ordinations
- [`ord_select()`](https://tidydiversity.in4metrix.dev/reference/ord_select.md)
  : Forward selection of explanatory variables
- [`ord_varpart()`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)
  [`autoplot(`*`<td_varpart>`*`)`](https://tidydiversity.in4metrix.dev/reference/ord_varpart.md)
  : Variation partitioning
- [`autoplot(`*`<td_ordination>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot.td_ordination.md)
  : Plot an ordination
- [`tidy(`*`<td_ordination>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy.td_ordination.md)
  [`glance(`*`<td_ordination>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy.td_ordination.md)
  : Tidy and glance methods for ordinations

## Functional traits

- [`trait_dist()`](https://tidydiversity.in4metrix.dev/reference/trait_dist.md)
  : Trait dissimilarity between species
- [`trait_cwm()`](https://tidydiversity.in4metrix.dev/reference/trait_cwm.md)
  : Community-weighted mean traits
- [`trait_cwm_test()`](https://tidydiversity.in4metrix.dev/reference/trait_cwm_test.md)
  : Test CWM-environment relationships with the max test
- [`trait_fd_indices()`](https://tidydiversity.in4metrix.dev/reference/trait_fd_indices.md)
  : Classic functional diversity indices
- [`trait_rao()`](https://tidydiversity.in4metrix.dev/reference/trait_rao.md)
  : Rao's quadratic entropy: alpha, beta and gamma functional diversity
- [`trait_ses()`](https://tidydiversity.in4metrix.dev/reference/trait_ses.md)
  : Standardised effect sizes from null models
- [`trait_itv()`](https://tidydiversity.in4metrix.dev/reference/trait_itv.md)
  : Intra- and interspecific trait variability
- [`trait_fourth_corner()`](https://tidydiversity.in4metrix.dev/reference/trait_fourth_corner.md)
  : Fourth-corner analysis
- [`trait_tpd()`](https://tidydiversity.in4metrix.dev/reference/trait_tpd.md)
  [`trait_tpd_dissim()`](https://tidydiversity.in4metrix.dev/reference/trait_tpd.md)
  : Functional diversity from trait probability densities
- [`phylo_signal()`](https://tidydiversity.in4metrix.dev/reference/phylo_signal.md)
  : Phylogenetic signal of traits
- [`phylo_dist()`](https://tidydiversity.in4metrix.dev/reference/phylo_dist.md)
  : Phylogenetic distances between species
- [`phylo_combine_dist()`](https://tidydiversity.in4metrix.dev/reference/phylo_combine_dist.md)
  : Combine functional and phylogenetic distances
- [`data_aravo()`](https://tidydiversity.in4metrix.dev/reference/data_aravo.md)
  : Alpine plant communities with traits (aravo) in long format

## Plots and tables for publication

- [`autoplot(`*`<td_rarefy>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_standardise>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_beta_decay>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_hill>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_estimate>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_coverage>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_beta_pair>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_beta_hill_pair>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_beta_multi>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_beta_hill>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_dispersion>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_completeness>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_evenness>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  [`autoplot(`*`<td_mde>`*`)`](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
  : Plot tidydiversity results
- [`theme_tidydiversity()`](https://tidydiversity.in4metrix.dev/reference/theme_tidydiversity.md)
  [`plot_palette()`](https://tidydiversity.in4metrix.dev/reference/theme_tidydiversity.md)
  [`scale_colour_tidydiversity()`](https://tidydiversity.in4metrix.dev/reference/theme_tidydiversity.md)
  [`scale_fill_tidydiversity()`](https://tidydiversity.in4metrix.dev/reference/theme_tidydiversity.md)
  : Publication theme and colour palettes
- [`plot_venn()`](https://tidydiversity.in4metrix.dev/reference/plot_venn.md)
  : Venn diagram of species shared between groups
- [`plot_phylo()`](https://tidydiversity.in4metrix.dev/reference/plot_phylo.md)
  : Plot a phylogeny with species abundances and phylogenetic diversity
- [`plot_trait_space()`](https://tidydiversity.in4metrix.dev/reference/plot_trait_space.md)
  : Plot functional trait space
- [`plot_panel()`](https://tidydiversity.in4metrix.dev/reference/plot_panel.md)
  : Combine plots into a publication figure
- [`plot_save()`](https://tidydiversity.in4metrix.dev/reference/plot_save.md)
  : Save a figure at journal sizes
- [`div_table()`](https://tidydiversity.in4metrix.dev/reference/div_table.md)
  : Publication-ready tables

## Modelling

- [`tidy(`*`<td_estimate>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_standardise>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_rarefy>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_boot>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`tidy(`*`<td_beta_pair>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`glance(`*`<td_coverage>`*`)`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  [`add_site_data()`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
  : Tidy and model-ready output
- [`model_group_folds()`](https://tidydiversity.in4metrix.dev/reference/model_group_folds.md)
  : Grouped cross-validation folds for community data
- [`model_case_weights()`](https://tidydiversity.in4metrix.dev/reference/model_case_weights.md)
  : Precision weights from estimated diversity
- [`step_hill()`](https://tidydiversity.in4metrix.dev/reference/step_hill.md)
  : Hill number features in a recipe

## Count models and partial-effect plots

- [`model_count()`](https://tidydiversity.in4metrix.dev/reference/model_count.md)
  [`tidy(`*`<td_count_model>`*`)`](https://tidydiversity.in4metrix.dev/reference/model_count.md)
  [`glance(`*`<td_count_model>`*`)`](https://tidydiversity.in4metrix.dev/reference/model_count.md)
  : Overdispersed count and proportion models (aods3-free)
- [`plot_partial()`](https://tidydiversity.in4metrix.dev/reference/plot-partial.md)
  [`plot_surface()`](https://tidydiversity.in4metrix.dev/reference/plot-partial.md)
  : Partial-effect and two-predictor surface plots (visreg / plotmo
  style)

## ForestGEO census tables

- [`stems_as_trees()`](https://tidydiversity.in4metrix.dev/reference/stems.md)
  [`stems_abundance()`](https://tidydiversity.in4metrix.dev/reference/stems.md)
  [`stems_basal_area()`](https://tidydiversity.in4metrix.dev/reference/stems.md)
  [`stems_size_class()`](https://tidydiversity.in4metrix.dev/reference/stems.md)
  [`stems_demography()`](https://tidydiversity.in4metrix.dev/reference/stems.md)
  [`stems_as_community()`](https://tidydiversity.in4metrix.dev/reference/stems.md)
  : ForestGEO-style stem and tree census verbs
