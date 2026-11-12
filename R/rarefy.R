#' Rarefaction and extrapolation curves
#'
#' Computes size-based rarefaction and extrapolation of Hill numbers for
#' each site, with the matching sample coverage. Rarefaction is exact
#' (Chao et al. 2014) and extrapolation uses the Chao et al. (2014)
#' estimators, reproducing iNEXT.
#'
#' @inheritParams div_estimate
#' @param size Sample sizes at which to compute diversity. If `NULL`, a grid
#'   of `knots` sizes from 1 to `endpoint` is used, always including the
#'   observed sample size.
#' @param endpoint Largest sample size of the default grid. Defaults to
#'   twice the observed sample size of each site, the recommended limit for
#'   extrapolating richness. Larger values give a warning.
#' @param knots Number of sizes in the default grid.
#' @param nboot Number of bootstrap replicates for confidence intervals. The
#'   default, 0, skips them.
#' @return A `td_rarefy` tibble with the grouping columns, the site column,
#'   `q`, `m` (sample size), `method` (`"rarefaction"`, `"observed"` or
#'   `"extrapolation"`), `diversity`, `coverage`, `lower` and `upper`. Use
#'   [ggplot2::autoplot()] to draw the curves.
#' @export
#' @examples
#' curves <- div_rarefy(png_ants, q = 0, .by = season, knots = 20)
#' curves
#'
#' div_rarefy(png_ants, size = c(10, 20, 40), .by = season)
div_rarefy <- function(data,
                       site = site,
                       species = species,
                       abundance = NULL,
                       q = c(0, 1, 2),
                       size = NULL,
                       endpoint = NULL,
                       knots = 40,
                       conf = 0.95,
                       nboot = 0,
                       type = c("TD", "PD", "FD"),
                       tree = NULL,
                       reftime = NULL,
                       pd_unit = c("mean", "total"),
                       distance = NULL,
                       tau = NULL,
                       unit = NULL,
                       n_units = NULL,
                       .by = NULL) {
  if (!missing(type) && td_is_multi_type(type)) {
    return(td_multi_type(match.call(), parent.frame(), type))
  }
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE, unit = enquo(unit), n_units = enquo(n_units)
  )
  td_check_min_n(prep)
  q <- td_check_q(q, integer = TRUE)
  if (!is.null(size) && (!is.numeric(size) || anyNA(size) || any(size < 1))) {
    cli::cli_abort("{.arg size} must be a numeric vector of values of 1 or more.")
  }
  if (!is.null(endpoint)) td_check_number(endpoint, "endpoint", 1)
  td_check_number(knots, "knots", 2, whole = TRUE)
  td_check_number(conf, "conf", 0, 1)
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  z <- stats::qnorm(1 - (1 - conf) / 2)
  far <- character()
  dim <- td_dimension(
    rlang::arg_match(type), prep, tree, reftime, rlang::arg_match(pd_unit),
    distance, tau
  )

  out <- td_per_site(prep, function(x, i) {
    n <- smp_n(x)
    m <- if (is.null(size)) size_grid(n, endpoint %||% (2 * n), knots) else size
    m <- sort(unique(m))
    if (any(m > 2 * n * (1 + 1e-6)) && 0 %in% q) far <<- c(far, "x")
    d <- dim_at_size(x, m, q, dim)
    cov <- coverage_at_size(x, m)
    draws <- boot_draws(x, nboot, function(xb, d) dim_at_size(xb, m, q, d), dim)
    se <- boot_se(draws, dim(d))
    nq <- length(q)
    meth <- rep(size_method(m, n), times = nq)
    cov <- rep(cov, times = nq)
    qq <- rep(q, each = length(m))
    mm <- rep(m, times = nq)
    tibble::tibble(
      q = qq,
      m = mm,
      method = meth,
      diversity = as.vector(d),
      coverage = cov,
      lower = pmax(as.vector(d - z * se), 0),
      upper = as.vector(d + z * se)
    )
  })
  warn_far(length(far))
  td_new(add_dim_cols(out, dim), c("td_rarefy", "td_curve"))
}

size_grid <- function(n, endpoint, knots) {
  if (endpoint <= n) {
    m <- floor(seq(1, endpoint, length.out = knots))
  } else {
    m <- c(
      floor(seq(1, n - 1, length.out = floor(knots / 2) - 1)),
      n,
      floor(seq(n + 1, endpoint, length.out = floor(knots / 2)))
    )
  }
  sort(unique(c(m, n)))
}

size_method <- function(m, n) {
  ifelse(m < n, "rarefaction", ifelse(m == n, "observed", "extrapolation"))
}

#' Standardise diversity by coverage or sample size
#'
#' Compares sites at equal sample completeness (coverage) or equal sample
#' size, by rarefying or extrapolating each site to that level (Chao and
#' Jost 2012).
#'
#' When neither `coverage` nor `size` is given, the target coverage of each
#' group is set by `level`:
#'
#' * `"max_extrapolation"` (default, the rule of [iNEXT::estimateD()]): the
#'   lowest coverage that every site reaches at twice its sample size, the
#'   largest extrapolation that is still reliable for richness.
#' * `"min_observed"`: the lowest observed coverage of any site, so the
#'   least complete site is used as observed and the others are rarefied
#'   (the most conservative choice; Chao and Jost 2012).
#'
#' The target is reported in the `target` column. A site whose coverage
#' curve cannot reach the target (for example one with a single
#' singleton and no doubletons) is returned at its highest attainable
#' coverage with a warning, so check `coverage` against `target`.
#' iNEXT rounds the target coverage it prints, so results can differ from
#' iNEXT in the second decimal when a rounded level is passed back to it.
#'
#' @inheritParams div_estimate
#' @param coverage Target sample coverage between 0 and 1. If both
#'   `coverage` and `size` are `NULL`, the target is chosen by `level`.
#' @param level Rule for the default target coverage: `"max_extrapolation"`
#'   or `"min_observed"`; see Details.
#' @param size Target sample size. Supply either `coverage` or `size`.
#' @return A `td_standardise` tibble with the grouping columns, the site
#'   column, `q`, `m`, `method`, `target` (the target coverage, or `NA` for
#'   a target size), `coverage` (coverage reached), `diversity`, `se`,
#'   `lower` and `upper`. A warning is given when a site has to be extrapolated beyond
#'   twice its sample size, where richness estimates become unreliable.
#' @export
#' @examples
#' set.seed(1)
#' div_standardise(png_ants, coverage = 0.95, .by = season, nboot = 10)
#'
#' div_standardise(png_ants, size = 20, .by = season, nboot = 0)
div_standardise <- function(data,
                            site = site,
                            species = species,
                            abundance = NULL,
                            q = c(0, 1, 2),
                            coverage = NULL,
                            size = NULL,
                            level = c("max_extrapolation", "min_observed"),
                            conf = 0.95,
                            nboot = 50,
                            type = c("TD", "PD", "FD"),
                            tree = NULL,
                            reftime = NULL,
                            pd_unit = c("mean", "total"),
                            distance = NULL,
                            tau = NULL,
                            unit = NULL,
                            n_units = NULL,
                            .by = NULL) {
  if (!missing(type) && td_is_multi_type(type)) {
    return(td_multi_type(match.call(), parent.frame(), type))
  }
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE, unit = enquo(unit), n_units = enquo(n_units)
  )
  td_check_min_n(prep)
  q <- td_check_q(q, integer = TRUE)
  if (!is.null(coverage) && !is.null(size)) {
    cli::cli_abort("Supply only one of {.arg coverage} or {.arg size}.")
  }
  if (!is.null(coverage)) td_check_number(coverage, "coverage", 0, 1)
  if (!is.null(size)) td_check_number(size, "size", 1)
  td_check_number(conf, "conf", 0, 1)
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  z <- stats::qnorm(1 - (1 - conf) / 2)

  level <- rlang::arg_match(level)
  if (is.null(coverage) && is.null(size)) {
    level <- default_coverage_level(prep, level)
  }

  far <- 0
  short <- character()
  dim <- td_dimension(
    rlang::arg_match(type), prep, tree, reftime, rlang::arg_match(pd_unit),
    distance, tau
  )
  out <- td_per_site(prep, function(x, i) {
    n <- smp_n(x)
    if (!is.null(size)) {
      m <- size
    } else {
      target <- coverage %||% level[i]
      m <- size_for_coverage(x, target)
    }
    if (m > 2 * n * (1 + 1e-6) && 0 %in% q) far <<- far + 1
    target <- if (!is.null(size)) NA_real_ else coverage %||% level[i]
    reached <- coverage_at_size(x, m)
    if (!is.na(target) && reached < target - 1e-6) {
      short <<- c(short, as.character(prep$site_labels[i] %||% i))
    }
    d <- as.vector(dim_at_size(x, m, q, dim))
    draws <- boot_draws(x, nboot, function(xb, d) {
      as.vector(dim_at_size(xb, m, q, d))
    }, dim)
    se <- as.vector(boot_se(draws, length(q)))
    tibble::tibble(
      q = q,
      m = m,
      method = size_method(m, n),
      target = target,
      coverage = reached,
      diversity = d,
      se = se,
      lower = pmax(d - z * se, 0),
      upper = d + z * se
    )
  })
  warn_far(far)
  if (length(short)) {
    sc <- out[[prep$site]][out$coverage < out$target - 1e-6]
    cli::cli_warn(c(
      "{length(unique(sc))} site{?s} cannot reach the target coverage: \
      {.val {as.character(unique(sc))}}.",
      "i" = "They are returned at their highest attainable coverage; \
      compare {.field coverage} with {.field target}, or use \
      {.code level = \"min_observed\"}."
    ))
  }
  td_new(add_dim_cols(out, dim), "td_standardise")
}

warn_far <- function(k) {
  if (k > 0) {
    cli::cli_warn(c(
      "Extrapolation beyond twice the observed sample size at \\
      {k} site{?s}.",
      "i" = "Richness (q = 0) estimates there may be strongly biased \\
      (Chao et al. 2014)."
    ))
  }
}
