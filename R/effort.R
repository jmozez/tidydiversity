#' Additional sampling effort needed
#'
#' @description
#' `div_effort()` answers the planning question "how much more do I need to
#' sample?" for each site. It gives the number of additional individuals
#' (abundance data) or sampling units (incidence data: traps, plots, days)
#' needed to reach
#'
#' * a target **sample coverage** (`coverage`), from the coverage
#'   extrapolation of Chao and Jost (2012); and/or
#' * a target **fraction of the estimated richness** (`fraction`), that is
#'   detecting `fraction` x Chao1 (or Chao2) species, as proposed by Chao et
#'   al. (2009). The richness extrapolation of Shen et al. (2003) is solved
#'   exactly, so the answer agrees with the extrapolated curves of
#'   [div_rarefy()].
#'
#' Targets the sample has already reached give zero. A target fraction of
#' 1 cannot be reached with finite effort and is refused; fractions of 0.8
#' to 0.95 are typical. Extrapolating far beyond about twice or three times
#' the current sample is uncertain, so treat large values as indications
#' of order of magnitude.
#'
#' @inheritParams div_estimate
#' @param coverage Target coverage levels in (0, 1).
#' @param fraction Target fractions of the estimated richness in (0, 1).
#' @return A tibble with the grouping columns, the site column, `n` (current
#'   sample size), `s_obs`, `coverage_now`, `s_est` (Chao1 or Chao2),
#'   `target` (`"coverage"` or `"fraction"`), `level`, `additional`
#'   (additional individuals or units, rounded up) and `total`.
#' @references
#' Chao, A., Colwell, R. K., Lin, C.-W. and Gotelli, N. J. (2009).
#' Sufficient sampling for asymptotic minimum species richness estimators.
#' Ecology, 90, 1125-1133. \doi{10.1890/07-2147.1}
#'
#' Chao, A. and Jost, L. (2012). Coverage-based rarefaction and
#' extrapolation: standardizing samples by completeness rather than size.
#' Ecology, 93, 2533-2547. \doi{10.1890/11-1952.1}
#'
#' Shen, T.-J., Chao, A. and Lin, C.-F. (2003). Predicting the number of new
#' species in further taxonomic sampling. Ecology, 84, 798-804.
#' @export
#' @examples
#' div_effort(png_ants, unit = bait, n_units = baits, .by = season)
div_effort <- function(data,
                       site = site,
                       species = species,
                       abundance = NULL,
                       unit = NULL,
                       n_units = NULL,
                       coverage = c(0.9, 0.95),
                       fraction = c(0.8, 0.9),
                       .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE, unit = enquo(unit), n_units = enquo(n_units)
  )
  td_check_min_n(prep)
  for (v in list(coverage = coverage, fraction = fraction)) {
    if (!is.null(v) && (!is.numeric(v) || anyNA(v) || any(v <= 0 | v >= 1))) {
      cli::cli_abort("{.arg coverage} and {.arg fraction} must be between 0 and 1 (exclusive).")
    }
  }
  if (length(coverage) + length(fraction) == 0) {
    cli::cli_abort("Give at least one {.arg coverage} or {.arg fraction} target.")
  }
  out <- td_per_site(prep, function(x, i) {
    n <- smp_n(x)
    xv <- as.vector(x[x > 0])
    s <- length(xv)
    f1 <- sum(xv == 1)
    f2 <- sum(xv == 2)
    f0 <- f0_hat(n, f1, f2)
    now <- coverage_at_size(x, n)
    m_cov <- vapply(coverage, function(lv) {
      if (now >= lv) 0 else size_for_coverage(x, lv) - n
    }, numeric(1))
    m_frac <- vapply(fraction, function(g) effort_fraction(n, s, f1, f0, g), numeric(1))
    lev <- c(coverage, fraction)
    add <- ceiling(c(m_cov, m_frac) - 1e-9)
    tibble::tibble(
      n = n, s_obs = s, coverage_now = now, s_est = s + f0,
      target = rep(c("coverage", "fraction"), c(length(coverage), length(fraction))),
      level = lev, additional = add, total = n + add
    )
  })
  td_new(out, "td_effort")
}

# Additional sample m at which the extrapolated richness
# S + f0 * (1 - (1 - f1 / (n f0 + f1))^m) reaches g * (S + f0).
effort_fraction <- function(n, s, f1, f0, g) {
  target <- g * (s + f0)
  if (s >= target) {
    return(0)
  }
  if (f0 <= 0 || f1 == 0) {
    return(Inf)
  }
  r <- 1 - (target - s) / f0
  log(r) / log(1 - f1 / (n * f0 + f1))
}
