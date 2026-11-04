#' Observed Hill numbers
#'
#' Computes Hill numbers of order `q` for each site from the observed
#' relative abundances. Order 0 is species richness, order 1 is the
#' exponential of Shannon entropy and order 2 is the inverse Simpson index.
#'
#' @inheritParams as_community
#' @param q Orders of diversity, non-negative numbers.
#' @param type Diversity dimension: `"TD"` (taxonomic, the default), `"PD"`
#'   (phylogenetic, needs `tree`) or `"FD"` (functional, needs `distance`).
#'   All three are Hill numbers of the same order `q`, in units of
#'   effective numbers of species (Chao, Chiu and Jost 2014), and reproduce
#'   [iNEXT.3D](https://CRAN.R-project.org/package=iNEXT.3D).
#' @param tree For `type = "PD"`, a rooted [ape::phylo] tree with branch
#'   lengths whose tip labels include every species.
#' @param reftime For `type = "PD"`, the reference time (tree depth) at
#'   which diversity is measured. Defaults to the age of the root of the tree
#'   pruned to the species in `data`.
#' @param pd_unit For `type = "PD"`, `"mean"` (the default) divides
#'   phylogenetic diversity by `reftime`, giving the effective number of
#'   lineages on the same scale as species; `"total"` gives effective total
#'   branch length.
#' @param distance For `type = "FD"`, a species-by-species distance matrix
#'   (or [stats::dist] object) with names matching the species, scaled to
#'   lie between 0 and 1, for example from Gower distances of traits.
#' @param tau For `type = "FD"`, the distance threshold below which species
#'   are treated as functionally identical. Defaults to the mean distance
#'   between two individuals in the pooled data. Use `"auc"` to integrate
#'   over all thresholds from 0 to 1 (Chao et al. 2019).
#' @return A tibble with the grouping columns, the site column, `q`,
#'   `n` (number of individuals) and `diversity`. Phylogenetic and
#'   functional results also have `type` and `reftime` or `tau`.
#' @references Hill, M. O. (1973). Diversity and evenness: a unifying
#'   notation and its consequences. Ecology, 54, 427-432.
#'   \doi{10.2307/1934352}
#'
#'   Chao, A., Chiu, C.-H. and Jost, L. (2014). Unifying species diversity,
#'   phylogenetic diversity, functional diversity, and related similarity and
#'   differentiation measures through Hill numbers. Annual Review of Ecology,
#'   Evolution, and Systematics, 45, 297-324.
#'   \doi{10.1146/annurev-ecolsys-120213-091540}
#'
#'   Chao, A., Chiu, C.-H., Villeger, S., Sun, I.-F., Thorn, S., Lin, Y.-C.,
#'   Chiang, J.-M. and Sherwin, W. B. (2019). An attribute-diversity
#'   approach to functional diversity, functional beta diversity, and related
#'   (dis)similarity measures. Ecological Monographs, 89, e01343.
#'   \doi{10.1002/ecm.1343}
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
                     type = c("TD", "PD", "FD"),
                     tree = NULL,
                     reftime = NULL,
                     pd_unit = c("mean", "total"),
                     distance = NULL,
                     tau = NULL,
                     .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  q <- td_check_q(q)
  dim <- td_dimension(
    rlang::arg_match(type), prep, tree, reftime, rlang::arg_match(pd_unit),
    distance, tau
  )
  out <- td_per_site(prep, function(x, i) {
    tibble::tibble(q = q, n = sum(x), diversity = dim_obs(x, q, dim))
  })
  td_new(add_dim_cols(out, dim), "td_hill")
}

#' Asymptotic diversity estimates
#'
#' Estimates the asymptotic Hill numbers of order 0, 1 and 2 for each site
#' using the Chao1 richness estimator, the Chao et al. (2013) Shannon
#' estimator and the unbiased Simpson estimator. Standard errors and
#' confidence intervals come from bootstrap resampling of the estimated
#' community, as in iNEXT.
#'
#' @details
#' For `type = "PD"` and `type = "FD"` the bootstrap resamples an
#' estimated community that includes undetected species, as for taxonomic
#' diversity. Under PD each undetected species is given its own branch, of
#' length equal to the estimated undetected branch length divided by the
#' estimated number of undetected species (Chao et al. 2015; Hsieh and Chao
#' 2017). Under FD undetected species are assumed to resemble the rarest
#' observed species: their distance to each observed species is the mean
#' distance from the singletons to that species, and their distance to each
#' other is the mean distance among the singletons. The reference time
#' (PD) and threshold `tau` (FD) are held fixed across replicates.
#'
#' @inheritParams div_hill
#' @param q Orders of diversity: any of 0, 1 and 2.
#' @param conf Confidence level of the intervals.
#' @param nboot Number of bootstrap replicates. Use 0 to skip them. For PD
#'   and FD the bootstrap community adds undetected species with estimated
#'   branch lengths (PD) or distances (FD); see Details in [div_estimate()].
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
                         type = c("TD", "PD", "FD"),
                         tree = NULL,
                         reftime = NULL,
                         pd_unit = c("mean", "total"),
                         distance = NULL,
                         tau = NULL,
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
  dim <- td_dimension(
    rlang::arg_match(type), prep, tree, reftime, rlang::arg_match(pd_unit),
    distance, tau
  )
  out <- td_per_site(prep, function(x, i) {
    est <- dim_asy(x, q, dim)
    draws <- boot_draws(x, nboot, function(xb, d) dim_asy(xb, q, d), dim)
    se <- as.vector(boot_se(draws, length(q)))
    obs <- dim_obs(x, q, dim)
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
  td_new(add_dim_cols(out, dim), "td_estimate")
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
