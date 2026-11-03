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
  out <- td_per_site(prep, function(x, i) {
    tibble::tibble(q = q, n = sum(x), diversity = hill_obs(x, q))
  })
  td_new(out, "td_hill")
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
#' @param ci How to build the confidence intervals from the bootstrap
#'   standard error. With `"lognormal"` (the default) the richness (q = 0)
#'   interval uses the log-transformation of Chao (1987), as in SpadeR, so
#'   it is asymmetric and its lower limit never falls below the observed
#'   richness; orders 1 and 2 use `estimate +/- z * se`. With `"normal"`
#'   every order uses `estimate +/- z * se`, as in [iNEXT::iNEXT()]. In both
#'   cases the lower limit is truncated at the observed diversity, which the
#'   asymptotic diversity cannot fall below.
#' @return A tibble with the grouping columns, the site column, `q`,
#'   `observed`, `estimate`, `se`, `lower` and `upper`.
#' @references Chao, A., Gotelli, N. J., Hsieh, T. C., Sander, E. L.,
#'   Ma, K. H., Colwell, R. K. and Ellison, A. M. (2014). Rarefaction and
#'   extrapolation with Hill numbers. Ecological Monographs, 84, 45-67.
#'   \doi{10.1890/13-0133.1}
#'
#'   Chao, A. (1987). Estimating the population size for capture-recapture
#'   data with unequal catchability. Biometrics, 43, 783-791.
#'   \doi{10.2307/2531532}
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
                         ci = c("lognormal", "normal"),
                         .by = NULL) {
  ci <- rlang::arg_match(ci)
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE
  )
  td_check_min_n(prep)
  q <- td_check_q(q, integer = TRUE)
  td_check_number(conf, "conf", 0, 1)
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  z <- stats::qnorm(1 - (1 - conf) / 2)
  out <- td_per_site(prep, function(x, i) {
    est <- hill_asy(x, q)
    draws <- boot_draws(x, nboot, function(xb) hill_asy(xb, q))
    se <- as.vector(boot_se(draws, length(q)))
    obs <- hill_obs(x, q)
    lim <- asy_ci(obs, est, se, z, ci, q)
    tibble::tibble(
      q = q,
      observed = obs,
      estimate = est,
      se = se,
      lower = lim$lower,
      upper = lim$upper
    )
  })
  td_new(out, "td_estimate")
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
  out <- td_per_site(prep, function(x, i) {
    tibble::tibble(
      n = sum(x),
      s_obs = length(x),
      f1 = sum(x == 1),
      f2 = sum(x == 2),
      coverage = coverage_at_size(x, sum(x))
    )
  })
  td_new(out, "td_coverage")
}

# Confidence limits for asymptotic estimates, never below the observed value.
# The log-normal interval of Chao (1987) applies to richness (q = 0) only.
asy_ci <- function(obs, est, se, z, type, q) {
  lower <- pmax(est - z * se, obs)
  upper <- est + z * se
  if (type == "lognormal") {
    t <- est - obs
    use <- q == 0 & t > 0 & !is.na(se)
    k <- exp(z * sqrt(log(1 + se[use]^2 / t[use]^2)))
    lower[use] <- obs[use] + t[use] / k
    upper[use] <- obs[use] + t[use] * k
  }
  list(lower = lower, upper = upper)
}
