#' Observed Hill numbers
#'
#' Computes Hill numbers of order `q` for each site from the observed
#' relative abundances. Order 0 is species richness, order 1 is the
#' exponential of Shannon entropy and order 2 is the inverse Simpson index.
#'
#' @inheritParams as_community
#' @param q Orders of diversity, non-negative numbers.
#' @return A tibble with the grouping columns, the site column, `q`,
#'   `n` (number of individuals) and `diversity`.
#' @references Hill, M. O. (1973). Diversity and evenness: a unifying
#'   notation and its consequences. Ecology, 54, 427-432.
#'   \doi{10.2307/1934352}
#' @export
#' @examples
#' div_hill(ant_gradient, .by = transect)
#'
#' # Grouped data frames work too
#' ant_gradient |>
#'   dplyr::group_by(transect) |>
#'   div_hill(q = c(0, 0.5, 1, 2))
div_hill <- function(data,
                     site = site,
                     species = species,
                     abundance = NULL,
                     q = c(0, 1, 2),
                     .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  q <- td_check_q(q)
  td_per_site(prep, function(x, i) {
    tibble::tibble(q = q, n = sum(x), diversity = hill_obs(x, q))
  })
}

#' Asymptotic diversity estimates
#'
#' Estimates the asymptotic Hill numbers of order 0, 1 and 2 for each site
#' using the Chao1 richness estimator, the Chao et al. (2013) Shannon
#' estimator and the unbiased Simpson estimator. Standard errors and
#' confidence intervals come from bootstrap resampling of the estimated
#' community, as in iNEXT.
#'
#' @inheritParams div_hill
#' @param q Orders of diversity: any of 0, 1 and 2.
#' @param conf Confidence level of the intervals.
#' @param nboot Number of bootstrap replicates. Use 0 to skip them.
#' @return A tibble with the grouping columns, the site column, `q`,
#'   `observed`, `estimate`, `se`, `lower` and `upper`.
#' @references Chao, A., Gotelli, N. J., Hsieh, T. C., Sander, E. L.,
#'   Ma, K. H., Colwell, R. K. and Ellison, A. M. (2014). Rarefaction and
#'   extrapolation with Hill numbers. Ecological Monographs, 84, 45-67.
#'   \doi{10.1890/13-0133.1}
#' @export
#' @examples
#' set.seed(1)
#' div_estimate(ant_gradient, .by = transect, nboot = 20)
div_estimate <- function(data,
                         site = site,
                         species = species,
                         abundance = NULL,
                         q = c(0, 1, 2),
                         conf = 0.95,
                         nboot = 50,
                         .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE
  )
  td_check_min_n(prep)
  q <- td_check_q(q, integer = TRUE)
  td_check_number(conf, "conf", 0, 1)
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  z <- stats::qnorm(1 - (1 - conf) / 2)
  td_per_site(prep, function(x, i) {
    est <- hill_asy(x, q)
    draws <- boot_draws(x, nboot, function(xb) hill_asy(xb, q))
    se <- as.vector(boot_se(draws, length(q)))
    tibble::tibble(
      q = q,
      observed = hill_obs(x, q),
      estimate = est,
      se = se,
      lower = pmax(est - z * se, 0),
      upper = est + z * se
    )
  })
}

#' Sample coverage
#'
#' Estimates the sample coverage of each site, the proportion of the
#' individuals in the community that belong to species already recorded
#' (Chao and Jost 2012).
#'
#' @inheritParams div_hill
#' @return A tibble with the grouping columns, the site column, `n`,
#'   `s_obs`, `f1`, `f2` (singletons and doubletons) and `coverage`.
#' @references Chao, A. and Jost, L. (2012). Coverage-based rarefaction and
#'   extrapolation: standardizing samples by completeness rather than size.
#'   Ecology, 93, 2533-2547. \doi{10.1890/11-1952.1}
#' @export
#' @examples
#' div_coverage(ant_gradient, .by = transect)
div_coverage <- function(data,
                         site = site,
                         species = species,
                         abundance = NULL,
                         .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE
  )
  td_check_min_n(prep)
  td_per_site(prep, function(x, i) {
    tibble::tibble(
      n = sum(x),
      s_obs = length(x),
      f1 = sum(x == 1),
      f2 = sum(x == 2),
      coverage = coverage_at_size(x, sum(x))
    )
  })
}
