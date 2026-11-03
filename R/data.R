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
