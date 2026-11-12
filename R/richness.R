#' Classic species richness estimators
#'
#' @description
#' `div_richness()` gives the non-parametric richness estimators of
#' EstimateS (Colwell 2013) and SpadeR (Chao et al. 2016) for every site,
#' with bootstrap standard errors and log-normal confidence intervals.
#'
#' For abundance data (counts of individuals):
#'
#' * `chao1`: Chao (1984), with the small-sample factor (n - 1)/n.
#' * `chao1_bc`: the bias-corrected Chao1, finite even without doubletons.
#' * `ichao1`: the improved Chao1 of Chiu et al. (2014), which also uses
#'   tripletons and quadrupletons.
#' * `ace`, `ace1`: the abundance-based coverage estimators of Chao and Lee
#'   (1992); species seen more than `k` times are "abundant" and counted as
#'   observed.
#' * `jack1`, `jack2`: first- and second-order jackknife (Burnham and
#'   Overton 1978).
#'
#' For incidence data (detections in sampling units, given with `unit`):
#'
#' * `chao2`, `chao2_bc`, `ichao2`: the incidence versions of the above.
#' * `ice`, `ice1`: the incidence-based coverage estimators of Lee and Chao
#'   (1994), with the improved coverage estimate of Chao et al. (2016).
#' * `jack1`, `jack2`: jackknife estimators on sampling units.
#' * `bootstrap`: the bootstrap estimator of Smith and van Belle (1984).
#'
#' Point estimates equal those of SpadeR (and of vegan's `estimateR()` and
#' `specpool()` where they compute the same estimator); this is checked in
#' the test suite. Standard errors come from `nboot` bootstrap samples of
#' the estimated community, as in [div_estimate()], so every estimator has
#' one.
#'
#' Which to report? Chao1/Chao2 are lower bounds with good statistical
#' properties and are the usual choice; iChao1/iChao2 are less biased when
#' many species are rare. ACE/ICE and the jackknives are given for
#' comparison with older studies. For comparing sites, prefer
#' coverage-standardised diversity ([div_standardise()]).
#'
#' @inheritParams div_estimate
#' @param estimator Estimators to compute; by default all for the data type.
#' @param k Cut-off for rare (ACE) or infrequent (ICE) species.
#' @param nboot Number of bootstrap samples for the standard errors (0 for
#'   none).
#' @return A tibble with the grouping columns, the site column, `estimator`,
#'   `observed`, `estimate`, `se`, `lower` and `upper`.
#' @references
#' Burnham, K. P. and Overton, W. S. (1978). Estimation of the size of a
#' closed population when capture probabilities vary among animals.
#' Biometrika, 65, 625-633.
#'
#' Chao, A. (1984). Nonparametric estimation of the number of classes in a
#' population. Scandinavian Journal of Statistics, 11, 265-270.
#'
#' Chao, A. and Lee, S.-M. (1992). Estimating the number of classes via
#' sample coverage. Journal of the American Statistical Association, 87,
#' 210-217.
#'
#' Chao, A., Ma, K. H., Hsieh, T. C. and Chiu, C.-H. (2016). SpadeR:
#' Species-richness prediction and diversity estimation with R. R package.
#'
#' Chiu, C.-H., Wang, Y.-T., Walther, B. A. and Chao, A. (2014). An improved
#' nonparametric lower bound of species richness via a modified
#' Good-Turing frequency formula. Biometrics, 70, 671-682.
#' \doi{10.1111/biom.12200}
#'
#' Colwell, R. K. (2013). EstimateS: Statistical estimation of species
#' richness and shared species from samples. Version 9.
#'
#' Lee, S.-M. and Chao, A. (1994). Estimating population size via sample
#' coverage for closed capture-recapture models. Biometrics, 50, 88-97.
#'
#' Smith, E. P. and van Belle, G. (1984). Nonparametric estimation of
#' species richness. Biometrics, 40, 119-129.
#' @export
#' @examples
#' div_richness(png_ants, .by = season, nboot = 20)
#' div_richness(png_ants, unit = bait, n_units = baits, .by = season, nboot = 20)
div_richness <- function(data,
                         site = site,
                         species = species,
                         abundance = NULL,
                         unit = NULL,
                         n_units = NULL,
                         estimator = NULL,
                         k = 10,
                         conf = 0.95,
                         nboot = 100,
                         .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE, unit = enquo(unit), n_units = enquo(n_units)
  )
  td_check_number(k, "k", 1, whole = TRUE)
  td_check_number(conf, "conf", 0, 1)
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  incidence <- !is.null(prep$incidence)
  all_est <- if (incidence) richness_inc_names else richness_abu_names
  if (is.null(estimator)) {
    estimator <- all_est
  } else {
    bad <- setdiff(estimator, all_est)
    if (length(bad) > 0) {
      cli::cli_abort(c(
        "{.val {bad}} {?is/are} not {?an estimator/estimators} for \\
        {if (incidence) 'incidence' else 'abundance'} data.",
        i = "Use {.or {.val {all_est}}}."
      ))
    }
  }
  z <- stats::qnorm(1 - (1 - conf) / 2)
  out <- td_per_site(prep, function(x, i) {
    fn <- function(xx, d) richness_all(xx, k)[estimator]
    est <- fn(x)
    draws <- boot_draws(x, nboot, fn)
    se <- if (is.null(draws)) {
      rep(NA_real_, length(estimator))
    } else {
      apply(matrix(draws, nrow = length(estimator)), 1, stats::sd, na.rm = TRUE)
    }
    obs <- rep(length(x), length(estimator))
    lim <- asy_ci(obs, est, se, z, "lognormal", rep(0, length(estimator)))
    tibble::tibble(
      estimator = estimator, observed = obs, estimate = unname(est),
      se = se, lower = lim$lower, upper = lim$upper
    )
  })
  td_new(out, "td_richness")
}

richness_abu_names <- c("chao1", "chao1_bc", "ichao1", "ace", "ace1", "jack1", "jack2")
richness_inc_names <- c(
  "chao2", "chao2_bc", "ichao2", "ice", "ice1", "jack1", "jack2", "bootstrap"
)

# All estimators for one site: abundance counts, or incidence frequencies
# with attribute n_units.
richness_all <- function(x, k = 10) {
  t <- attr(x, "n_units")
  x <- as.vector(x[x > 0])
  if (is.null(t)) richness_abu(x, k) else richness_inc(x, t, k)
}

# Chao1/Chao2 and their improved versions share one form; `w` is the
# small-sample factor of individuals or sampling units.
chao_lower <- function(s, f1, f2, w) {
  if (f1 > 0 && f2 > 0) {
    s + w * f1^2 / (2 * f2)
  } else if (f1 > 1 && f2 == 0) {
    s + w * f1 * (f1 - 1) / (2 * (f2 + 1))
  } else {
    s
  }
}

richness_abu <- function(x, k) {
  n <- sum(x)
  s <- length(x)
  f <- function(i) sum(x == i)
  f1 <- f(1)
  f2 <- f(2)
  f3 <- f(3)
  f4 <- f(4)
  w <- (n - 1) / n
  chao1 <- chao_lower(s, f1, f2, w)
  f4a <- if (f4 > 0) f4 else f4 + 1
  ichao1 <- chao1 + f3 / 4 / f4a * max(f1 - f2 * f3 / 2 / f4a, 0)
  rare <- x[x <= k]
  n_rare <- sum(rare)
  s_rare <- length(rare)
  s_abun <- s - s_rare
  c_rare <- if (n_rare > 0) 1 - f1 / n_rare else 1
  j <- seq_len(k)
  a1 <- sum(j * (j - 1) * vapply(j, f, numeric(1)))
  if (c_rare > 0 && n_rare > 1) {
    g2 <- max(s_rare / c_rare * a1 / n_rare / (n_rare - 1) - 1, 0)
    g2_1 <- max(g2 * (1 + (1 - c_rare) / c_rare * a1 / (n_rare - 1)), 0)
    ace <- s_abun + s_rare / c_rare + f1 / c_rare * g2
    ace1 <- s_abun + s_rare / c_rare + f1 / c_rare * g2_1
  } else {
    ace <- ace1 <- NA_real_
  }
  jack1 <- s + w * f1
  jack2 <- if (n > 1) s + (2 * n - 3) / n * f1 - (n - 2)^2 / n / (n - 1) * f2 else s
  c(
    chao1 = chao1, chao1_bc = s + w * f1 * (f1 - 1) / (2 * (f2 + 1)),
    ichao1 = ichao1, ace = ace, ace1 = ace1, jack1 = jack1, jack2 = jack2
  )
}

richness_inc <- function(x, t, k) {
  s <- length(x)
  q <- function(i) sum(x == i)
  q1 <- q(1)
  q2 <- q(2)
  q3 <- q(3)
  q4 <- q(4)
  w <- (t - 1) / t
  chao2 <- chao_lower(s, q1, q2, w)
  ichao2 <- if (q4 > 0) {
    chao2 + (t - 3) / t * q3 / 4 / q4 * max(q1 - (t - 3) / (t - 1) * q2 * q3 / 2 / q4, 0)
  } else {
    chao2 + (t - 3) / t * q3 / 4 / (q4 + 1) * max(q1 - (t - 3) / (t - 1) * q2 * q3 / 2, 0)
  }
  # ICE with the improved coverage estimate of the infrequent species
  infreq <- x[x <= k]
  s_infreq <- length(infreq)
  s_freq <- s - s_infreq
  a <- if (q1 > 0 && q2 > 0) {
    2 * q2 / ((t - 1) * q1 + 2 * q2)
  } else if (q1 > 0) {
    2 / ((t - 1) * (q1 - 1) + 2)
  } else {
    1
  }
  n_infreq <- sum(infreq)
  c_inf <- if (n_infreq > 0) 1 - q1 / n_infreq * (1 - a) else 1
  j <- seq_len(k)
  b1 <- sum(j * (j - 1) * vapply(j, q, numeric(1)))
  if (c_inf > 0 && n_infreq > 1 && t > 1) {
    g2 <- max(s_infreq / c_inf * t / (t - 1) * b1 / n_infreq / (n_infreq - 1) - 1, 0)
    g2_1 <- max(g2 * (1 + q1 / c_inf * t / (t - 1) * b1 / n_infreq / (n_infreq - 1)), 0)
    ice <- s_freq + s_infreq / c_inf + q1 / c_inf * g2
    ice1 <- s_freq + s_infreq / c_inf + q1 / c_inf * g2_1
  } else {
    ice <- ice1 <- NA_real_
  }
  jack1 <- s + w * q1
  jack2 <- if (t > 1) s + (2 * t - 3) / t * q1 - (t - 2)^2 / t / (t - 1) * q2 else s
  c(
    chao2 = chao2, chao2_bc = s + w * q1 * (q1 - 1) / (2 * (q2 + 1)),
    ichao2 = ichao2, ice = ice, ice1 = ice1, jack1 = jack1, jack2 = jack2,
    bootstrap = s + sum((1 - x / t)^t)
  )
}

#' Fisher's alpha
#'
#' Fisher's log-series diversity index alpha (Fisher, Corbet and Williams
#' 1943), the parameter that satisfies S = alpha log(1 + n / alpha). It is
#' nearly independent of sample size when abundances follow a log-series,
#' which made it the standard index in tropical ecology, and EstimateS
#' reports it. The values equal vegan's `fisher.alpha()`.
#'
#' @inheritParams div_hill
#' @return A tibble with the grouping columns, the site column, `n`, `s_obs`
#'   and `alpha`.
#' @references Fisher, R. A., Corbet, A. S. and Williams, C. B. (1943). The
#'   relation between the number of species and the number of individuals
#'   in a random sample of an animal population. Journal of Animal Ecology,
#'   12, 42-58. \doi{10.2307/1411}
#' @export
#' @examples
#' div_fisher_alpha(png_ants, .by = season)
div_fisher_alpha <- function(data,
                             site = site,
                             species = species,
                             abundance = NULL,
                             .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE
  )
  out <- td_per_site(prep, function(x, i) {
    x <- x[x > 0]
    n <- sum(x)
    s <- length(x)
    alpha <- if (s < 2 || s >= n) {
      NA_real_
    } else {
      stats::uniroot(
        function(a) a * log1p(n / a) - s, c(1e-8, 1e8), tol = 1e-12
      )$root
    }
    tibble::tibble(n = n, s_obs = s, alpha = alpha)
  })
  td_new(out, "td_fisher_alpha")
}
