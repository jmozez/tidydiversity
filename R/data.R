#' Simulated ant counts along two elevational transects
#'
#' A synthetic dataset, simulated for examples and tests. It is not real
#' field data. Counts of 40 ant morphospecies were simulated at eight
#' elevations on each of two transects, with Gaussian elevational niches
#' and negative binomial sampling noise. The code that generates it is in
#' `data-raw/ant_gradient.R` in the package source.
#'
#' @format A tibble with one row per transect, site and species recorded,
#'   and five columns:
#' \describe{
#'   \item{transect}{Transect, `"north"` or `"south"`.}
#'   \item{site}{Site identifier, transect and elevation.}
#'   \item{elevation}{Elevation of the site in metres.}
#'   \item{species}{Morphospecies code.}
#'   \item{abundance}{Number of workers counted, always positive.}
#' }
#' @source Simulated with `data-raw/ant_gradient.R`.
"ant_gradient"

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
#'   E. K., Christensen, E. M., Diaz, R. M. et al. (2020). The Portal
#'   Project: a long-term study of a Chihuahuan desert ecosystem. bioRxiv.
#'   \doi{10.1101/332783}
#' @examples
#' portal_rodents
#' div_hill(portal_rodents, q = 0, .by = c(treatment, year))
"portal_rodents"
