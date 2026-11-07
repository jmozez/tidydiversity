#' Ants at nutrient baits along Mt Wilhelm, Papua New Guinea
#'
#' Real field data: ground-foraging ants recorded at experimental nutrient
#' baits along the Mt Wilhelm elevational gradient in Papua New Guinea,
#' from 200 to 3700 m, in the dry and the wet season (Moses et al. 2023).
#' Baits offering six nutrient types were placed along transects at eight
#' elevations 500 m apart. Ants were found up to 2200 m in both seasons and
#' at 2700 m only once, in the dry season (one species at three baits); that
#' record is left out so both seasons cover the same five elevations
#' (200 to 2200 m) and can be compared directly. Each row is one
#' species recorded at one bait. Only the Papua New Guinea part of the
#' published cross-continental dataset is included, with the lead author's
#' permission.
#'
#' Because ants recruit to baits, worker counts measure activity rather
#' than independent individuals. tidydiversity therefore counts each row
#' (one species at one bait) as one occurrence when no `abundance` column
#' is given, which is the default here: diversity is estimated from the
#' number of baits at which each species was recorded.
#'
#' @format A tibble with one row per bait and ant species, and 12 columns:
#' \describe{
#'   \item{site}{Elevation band, such as `"MW0200"` for 200 m.}
#'   \item{elevation}{Elevation band in metres.}
#'   \item{season}{Sampling season, `"dry"` or `"wet"`.}
#'   \item{transect}{Transect number within the elevation band.}
#'   \item{bait}{Bait identifier: the sampling unit for incidence-based
#'     estimates (`unit = bait`).}
#'   \item{baits}{Number of baits set at that elevation and season,
#'     including baits no ant visited (`n_units = baits`).}
#'   \item{bait_type}{Nutrient offered: `h2o`, `nacl`, `cho` (sucrose),
#'     `amino_acid`, `cho_amino_acid` or `lipid`.}
#'   \item{species}{Ant morphospecies code.}
#'   \item{genus, subfamily}{Ant genus and subfamily.}
#'   \item{guild}{Trophic guild.}
#'   \item{workers}{Number of workers at the bait.}
#' }
#' @source Mottl, O., Moses, J. and Klimes, P. (2023). Data and code for
#'   "Nutrient use by tropical ant communities varies among three extensive
#'   elevational gradients: a cross-continental comparison". Zenodo.
#'   \doi{10.5281/zenodo.8191946}. Built by `data-raw/png_ants.R` in the
#'   package source.
#' @references Moses, J., Peters, M. K., Tiede, Y., Mottl, O., Donoso, D. A.,
#'   Farwig, N., Fayle, T. M., Novotny, V., Sanders, N. J. and Klimes, P.
#'   (2023). Nutrient use by tropical ant communities varies among three
#'   extensive elevational gradients: a cross-continental comparison.
#'   *Global Ecology and Biogeography*, 32, 2212-2229.
#'   \doi{10.1111/geb.13757}
#' @examples
#' png_ants
#' div_hill(png_ants, q = 0, .by = season)
#'
#' # Incidence-based: baits as sampling units, including empty baits
#' div_estimate(png_ants, unit = bait, n_units = baits, .by = season, nboot = 0)
"png_ants"

#' Tree-nesting ants in rainforest plots at three elevations, Papua New Guinea
#'
#' Real field data: every ant nest in 1254 trees within continuous plots of
#' primary rainforest at Wanang (200 m), Numba (900 m) and Yawan (1800 m),
#' Papua New Guinea (Plowman et al. 2020). Only the 769 trees with at least
#' one nest appear. Each row is one ant species nesting in one tree.
#'
#' @format A tibble with one row per tree and ant species, and nine columns:
#' \describe{
#'   \item{site}{Plot: `"Wanang"`, `"Numba"` or `"Yawan"`.}
#'   \item{elevation}{Elevation of the plot in metres.}
#'   \item{subplot}{Subplot within the plot.}
#'   \item{tree}{Tree identifier.}
#'   \item{tree_family, tree_genus}{Host tree family and genus.}
#'   \item{dbh}{Tree diameter at breast height (cm).}
#'   \item{species}{Ant morphospecies code.}
#'   \item{nests}{Number of nests of the species in the tree.}
#' }
#' @source Plowman, N. S., Mottl, O., Novotny, V., Idigel, C., Philip, F. J.
#'   and Klimes, P. (2019). Data from: Nest microhabitats and
#'   tree size mediate shifts in ant community structure across elevation in
#'   tropical rainforest canopies. Dryad. \doi{10.5061/dryad.2fqz612k6},
#'   released under CC0 1.0. Built by `data-raw/png_tree_ants.R`.
#' @references Plowman, N. S., Mottl, O., Novotny, V., Idigel, C., Philip,
#'   F. J., Rimandai, M. and Klimes, P. (2020). Nest microhabitats and tree
#'   size mediate shifts in ant community structure across elevation in
#'   tropical rainforest canopies. *Ecography*, 43, 431-442.
#'   \doi{10.1111/ecog.04730}
#' @examples
#' png_tree_ants
#' # Nest counts per plot, trees pooled
#' div_estimate(png_tree_ants, site = site, abundance = nests, nboot = 0)
#' # Turnover between trees within each plot
#' beta_multi(png_tree_ants, site = tree, .by = site)
"png_tree_ants"

#' Frogs along the Mt Wilhelm elevational gradient, Papua New Guinea
#'
#' Real field data: 3390 frogs of 55 species recorded at eight sites from
#' 200 to 3700 m on Mt Wilhelm, Papua New Guinea (Dahl et al. 2024).
#' Species not formally described carry a provisional name such as
#' `"Copiula sp 1"`.
#'
#' @format A tibble with one row per site and species recorded, and seven
#'   columns:
#' \describe{
#'   \item{site}{Site, such as `"MW0200"` for 200 m.}
#'   \item{elevation}{Elevation in metres.}
#'   \item{species}{Species code.}
#'   \item{scientific_name}{Scientific or provisional name.}
#'   \item{family}{Frog family.}
#'   \item{reproduction}{Reproductive mode, `"terrestrial"` (direct
#'     development) or `"aquatic"`.}
#'   \item{abundance}{Number of individuals recorded.}
#' }
#' @source Dahl, C., Richards, S. J., Basien, I., Mungkaje, A. J. and
#'   Novotny, V. (2023). Data from: Local and regional diversity of frog
#'   communities along an extensive rainforest elevation gradient in Papua
#'   New Guinea. Dryad. \doi{10.5061/dryad.3n5tb2rqf}, released under CC0
#'   1.0. Built by `data-raw/png_frogs.R`.
#' @references Dahl, C., Richards, S. J., Basien, I., Mungkaje, A. J. and
#'   Novotny, V. (2024). Local and regional diversity of frog communities
#'   along an extensive rainforest elevation gradient in Papua New Guinea.
#'   *Biotropica*, 56, 90-97. \doi{10.1111/btp.13283}
#' @examples
#' png_frogs
#' div_estimate(png_frogs, nboot = 0)
"png_frogs"

#' Butterflies in the Wanang forest dynamics plot, Papua New Guinea
#'
#' Real field data: butterflies counted on 36 sampling days, three days a
#' month over 12 months spread across three years, in the Wanang 50 ha
#' forest dynamics plot, Papua New Guinea (Luk et al. 2019). Each sampling
#' day is one site, which makes the data suited to sample-based
#' accumulation and to partitioning diversity across days, months and
#' years. Only the Wanang part of the published multi-site dataset is
#' included.
#'
#' @format A tibble with one row per day and species recorded, and six
#'   columns:
#' \describe{
#'   \item{site}{Sampling day, `"day01"` to `"day36"`.}
#'   \item{day}{Sampling day number, 1 to 36.}
#'   \item{month}{Sampling month, 1 to 12, in order of sampling.}
#'   \item{year}{Sampling year, 1 to 3, in order of sampling.}
#'   \item{species}{Butterfly species.}
#'   \item{abundance}{Number of individuals counted.}
#' }
#' @source Luk, C.-L., Basset, Y., Kongnoo, P., Hau, B. C. H. and
#'   Bonebrake, T. C. (2019). Data from: Inter-annual monitoring improves
#'   diversity estimation of tropical butterfly assemblages. Dryad.
#'   \doi{10.5061/dryad.j35fq7r}, released under CC0 1.0. Built by
#'   `data-raw/wanang_butterflies.R`.
#' @references Luk, C.-L., Basset, Y., Kongnoo, P., Hau, B. C. H. and
#'   Bonebrake, T. C. (2019). Inter-annual monitoring improves diversity
#'   estimation of tropical butterfly assemblages. *Biotropica*, 51, 519-528.
#'   \doi{10.1111/btp.12671}
#' @examples
#' wanang_butterflies
#' div_hill(wanang_butterflies, q = 0, .by = year) |> head()
"wanang_butterflies"

#' Caterpillars reared from trees in primary and secondary forest at Wanang
#'
#' Real field data: Lepidoptera larvae collected from the foliage of trees
#' in a primary and a secondary forest plot in the Wanang Conservation
#' Area, Madang Province, Papua New Guinea, between 2003 and 2009, and
#' reared to adults where possible by the New Guinea Binatang Research
#' Centre (Butterill and Redmond 2023). Each plot has five sampling units
#' (`WP1`-`WP5` in primary and `WS1`-`WS5` in secondary forest). Counts are
#' the number of individuals of each morphospecies reared from each host
#' plant species. Taxa are morphospecies codes identified to different
#' ranks (species, genus, family or order), so treat them as
#' morphospecies, not as named species. The host plant makes the data
#' suited to species-overlap diagrams ([plot_venn()]) and host-use
#' comparisons.
#'
#' @format A tibble with one row per sampling unit, host plant and
#'   morphospecies, and eight columns:
#' \describe{
#'   \item{site}{Forest type, `"primary"` or `"secondary"`.}
#'   \item{plot}{Sampling unit, `"WP1"`-`"WP5"` and `"WS1"`-`"WS5"`.}
#'   \item{host}{Host plant species (`NA` when not recorded).}
#'   \item{species}{Morphospecies code (GBIF `taxonID`).}
#'   \item{scientific_name}{Most precise name given for the morphospecies.}
#'   \item{rank}{Rank of `scientific_name`.}
#'   \item{family}{Lepidoptera family (`NA` when only identified to
#'     order).}
#'   \item{abundance}{Number of individuals.}
#' }
#' @source Butterill, P. and Redmond, C. (2023). Plot-based sampling and
#'   rearing of adult lepidoptera from lowland rainforest in Wanang, Papua
#'   New Guinea. Version 1.1. New Guinea Binatang Research Centre.
#'   Occurrence dataset, GBIF. \doi{10.15468/7e96ht}, released under CC BY
#'   4.0 (<https://creativecommons.org/licenses/by/4.0/>): cite this source
#'   when you use the data. Built from all 9,354 GBIF occurrence records by
#'   `data-raw/wanang_caterpillars.R`.
#' @examples
#' wanang_caterpillars
#' div_hill(wanang_caterpillars, site = plot, q = 0:2) |> head()
"wanang_caterpillars"

#' Rodent captures at the Portal Project, Arizona
#'
#' Real field data: annual counts of rodent captures on the 24 experimental
#' plots of the Portal Project, a long-term study in the Chihuahuan Desert
#' near Portal, Arizona, USA, from 2016 to 2019. Since 2015 plots have been
#' unmanipulated controls, kangaroo rat (*Dipodomys*) exclosures, or
#' removals of all rodents. Only rodent species that are census targets and
#' identified to species are kept. Each plot and year is one site.
#'
#' @format A tibble with one row per site and species captured, and seven
#'   columns:
#' \describe{
#'   \item{site}{Site identifier, plot and year, such as `"P01-2016"`.}
#'   \item{plot}{Plot number, 1 to 24.}
#'   \item{year}{Census year.}
#'   \item{treatment}{Experimental treatment: `control`,
#'     `krat_exclosure` or `removal`.}
#'   \item{species}{Two-letter species code.}
#'   \item{scientific_name}{Scientific name.}
#'   \item{abundance}{Number of captures in the year.}
#' }
#' @source PortalData, Weecology, <https://github.com/weecology/PortalData>,
#'   released under the CC0 1.0 public domain dedication. Built by
#'   `data-raw/portal_rodents.R` in the package source.
#' @references Ernest, S. K. M., Yenni, G. M., Allington, G., Bledsoe,
#'   E. K., Christensen, E. M., Diaz, R. M. et al. (2018). The Portal
#'   Project: a long-term study of a Chihuahuan desert ecosystem. bioRxiv.
#'   \doi{10.1101/332783}
#' @examples
#' portal_rodents
#' div_hill(portal_rodents, q = 0, .by = c(treatment, year))
"portal_rodents"
