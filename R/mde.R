#' Range-through interpolation along a gradient
#'
#' @description
#' `range_through()` assumes that a species recorded at two positions on a
#' gradient (elevation, latitude, depth) is also present at every sampled
#' position between them, and adds those records. This is the standard
#' first step for elevational and latitudinal richness patterns (Grytnes
#' and Vetaas 2002; Colwell 2008), because a species missed at an
#' intermediate site is far more likely an undetected than an absent one.
#'
#' Interpolation fills gaps only *inside* each species' observed range, so
#' it raises richness most at mid-gradient sites. It therefore creates part
#' of a mid-domain peak by itself; compare the result with [range_mde()],
#' which applies the same interpolation to its null model.
#'
#' @inheritParams div_hill
#' @param gradient Column with the position of each site on the gradient
#'   (one value per site).
#' @return A tibble with the grouping columns, the site and gradient
#'   columns, `species` and `interpolated` (`TRUE` for added records), one
#'   row per species and site where it is present or interpolated.
#' @references
#' Colwell, R. K. (2008). RangeModel: tools for exploring and assessing
#' geometric constraints on species richness (the mid-domain effect) along
#' transects. Ecography, 31, 4-7. \doi{10.1111/j.2008.0906-7590.05347.x}
#'
#' Grytnes, J.-A. and Vetaas, O. R. (2002). Species richness and altitude: a
#' comparison between null models and interpolated plant species richness
#' along the Himalayan altitudinal gradient, Nepal. American Naturalist,
#' 159, 294-304. \doi{10.1086/338542}
#' @export
#' @examples
#' rt <- range_through(png_frogs, gradient = elevation)
#' dplyr::count(rt, site, elevation, interpolated)
range_through <- function(data,
                          gradient,
                          site = site,
                          species = species,
                          .by = NULL) {
  g <- mde_prepare(data, enquo(gradient), enquo(site), enquo(species), enquo(.by))
  out <- lapply(g$groups, function(grp) {
    occ <- mde_occupancy(grp)
    filled <- mde_fill(occ$mat)
    idx <- which(filled, arr.ind = TRUE)
    res <- tibble::tibble(
      .site = occ$sites[idx[, 1]],
      .gradient = occ$gradient[idx[, 1]],
      species = colnames(occ$mat)[idx[, 2]],
      interpolated = !occ$mat[idx]
    )
    res <- res[order(res$.gradient, res$species), ]
    vctrs::vec_cbind(vctrs::vec_slice(grp$key, rep(1, nrow(res))), res)
  })
  mde_finish(vctrs::vec_rbind(!!!out), g, "species", data)
}

#' Mid-domain null model of richness along a gradient
#'
#' @description
#' If species' ranges are placed at random within a bounded gradient, they
#' overlap most in the middle, so richness peaks at mid-gradient even with
#' no environmental cause: the **mid-domain effect** (Colwell and Hurtt
#' 1994; Colwell and Lees 2000). `range_mde()` builds this null model from
#' the observed ranges, in the spirit of RangeModel (Colwell 2008), and
#' compares it with the observed richness at each site.
#'
#' Each species keeps its observed range size (the number of consecutive
#' sampled sites it spans, after [range_through()] interpolation), and its
#' position is randomised:
#'
#' * `model = "uniform"`: every position where the range fits is equally
#'   likely (Colwell and Hurtt 1994). The expected richness is computed
#'   exactly; the interval comes from `nsim` randomisations.
#' * `model = "spread"`: the range starts at a random site and spreads to
#'   random neighbouring sites (the "spreading dye" model of Jetz and
#'   Rahbek 2001, as in the rangemodelR package), which places more ranges
#'   near the ends than the uniform model.
#'
#' Sites are treated as positions in order along the gradient, so the
#' model assumes the sampled sites represent the domain evenly.
#'
#' @inheritParams range_through
#' @param model `"uniform"` or `"spread"`.
#' @param nsim Number of randomisations.
#' @param conf Width of the simulation interval.
#' @param interpolate Apply [range_through()] first (recommended).
#' @return A tibble of class `td_mde` with the grouping columns, the site
#'   and gradient columns, `observed` richness, `expected` richness under
#'   the null model, its `sd`, `lower` and `upper` simulation limits, and
#'   `outside` (`"above"`, `"below"` or `"within"`). Attributes `r2` (the
#'   variance in observed richness explained by the null model, one value
#'   per group) and `p_value` (a global test: the proportion of
#'   randomisations that deviate from the expectation at least as much as
#'   the observed richness) summarise the fit; see [glance()].
#' @references
#' Colwell, R. K. and Hurtt, G. C. (1994). Nonbiological gradients in
#' species richness and a spurious Rapoport effect. American Naturalist,
#' 144, 570-595. \doi{10.1086/285695}
#'
#' Colwell, R. K. and Lees, D. C. (2000). The mid-domain effect: geometric
#' constraints on the geography of species richness. Trends in Ecology &
#' Evolution, 15, 70-76. \doi{10.1016/S0169-5347(99)01767-X}
#'
#' Colwell, R. K. (2008). RangeModel: tools for exploring and assessing
#' geometric constraints on species richness (the mid-domain effect) along
#' transects. Ecography, 31, 4-7. \doi{10.1111/j.2008.0906-7590.05347.x}
#'
#' Jetz, W. and Rahbek, C. (2001). Geometric constraints explain much of
#' the species richness pattern in African birds. Proceedings of the
#' National Academy of Sciences, 98, 5661-5666. \doi{10.1073/pnas.091100998}
#' @export
#' @examples
#' set.seed(1)
#' mde <- range_mde(png_frogs, gradient = elevation, nsim = 199)
#' mde
#' glance(mde)
range_mde <- function(data,
                      gradient,
                      site = site,
                      species = species,
                      model = c("uniform", "spread"),
                      nsim = 999,
                      conf = 0.95,
                      interpolate = TRUE,
                      .by = NULL) {
  model <- rlang::arg_match(model)
  td_check_number(nsim, "nsim", 1, whole = TRUE)
  td_check_number(conf, "conf", 0, 1)
  g <- mde_prepare(data, enquo(gradient), enquo(site), enquo(species), enquo(.by))
  a <- (1 - conf) / 2
  fits <- list()
  out <- lapply(seq_along(g$groups), function(k) {
    grp <- g$groups[[k]]
    occ <- mde_occupancy(grp)
    mat <- if (interpolate) mde_fill(occ$mat) else occ$mat
    n <- nrow(mat)
    obs <- rowSums(mat)
    size <- colSums(mat)
    if (!interpolate) size <- vapply(seq_len(ncol(mat)), function(j) {
      w <- which(mat[, j])
      max(w) - min(w) + 1
    }, numeric(1))
    sims <- mde_simulate(size, n, nsim, model)
    expected <- if (model == "uniform") mde_expected_uniform(size, n) else rowMeans(sims)
    dev_obs <- sum((obs - expected)^2)
    dev_sim <- colSums((sims - expected)^2)
    ss_tot <- sum((obs - mean(obs))^2)
    r2 <- if (ss_tot > 0) 1 - sum((obs - expected)^2) / ss_tot else NA_real_
    fits[[k]] <<- tibble::tibble(
      model = model, n_sites = n, n_species = ncol(mat),
      r2 = r2, p_value = (sum(dev_sim >= dev_obs) + 1) / (nsim + 1)
    )
    lo <- apply(sims, 1, stats::quantile, probs = a, names = FALSE)
    hi <- apply(sims, 1, stats::quantile, probs = 1 - a, names = FALSE)
    res <- tibble::tibble(
      .site = occ$sites, .gradient = occ$gradient, observed = obs,
      expected = expected, sd = apply(sims, 1, stats::sd), lower = lo, upper = hi,
      outside = ifelse(obs > hi, "above", ifelse(obs < lo, "below", "within"))
    )
    vctrs::vec_cbind(vctrs::vec_slice(grp$key, rep(1, nrow(res))), res)
  })
  out <- mde_finish(vctrs::vec_rbind(!!!out), g, NULL, data)
  fit <- vctrs::vec_rbind(!!!fits)
  if (length(g$by)) fit <- vctrs::vec_cbind(vctrs::vec_rbind(!!!lapply(g$groups, `[[`, "key")), fit)
  out <- td_new(out, "td_mde")
  attr(out, "fit") <- fit
  out
}

#' @rdname range_mde
#' @param x A `range_mde()` result.
#' @param ... Not used.
#' @export
glance.td_mde <- function(x, ...) {
  attr(x, "fit")
}

# ---- internals ---------------------------------------------------------------

mde_prepare <- function(data, gradient, site, species, by, call = caller_env()) {
  td_check_data(data, call = call)
  if (rlang::quo_is_missing(gradient)) {
    cli::cli_abort("{.arg gradient} is required.", call = call)
  }
  site_col <- td_pick(site, data, "site", call = call)
  sp_col <- td_pick(species, data, "species", call = call)
  gr_col <- td_pick(gradient, data, "gradient", call = call)
  by_cols <- td_group_cols(data, by, call = call)
  if (!is.numeric(data[[gr_col]])) {
    cli::cli_abort("{.arg gradient} must be a numeric column.", call = call)
  }
  d <- tibble::tibble(
    !!!as.list(data[by_cols]), .site = data[[site_col]],
    .gradient = data[[gr_col]], .species = as.character(data[[sp_col]])
  )
  d <- d[!is.na(d$.species) & !is.na(d$.gradient), ]
  keys <- d[c(by_cols, ".site")]
  per_site <- vctrs::vec_split(d$.gradient, keys)
  if (any(vapply(per_site$val, function(v) length(unique(v)) > 1, logical(1)))) {
    cli::cli_abort("Each site must have a single {.arg gradient} value.", call = call)
  }
  split <- if (length(by_cols)) vctrs::vec_split(d, d[by_cols]) else
    list(key = list(tibble::tibble()), val = list(d))
  groups <- lapply(seq_along(split$val), function(i) {
    key <- if (length(by_cols)) {
      vctrs::vec_slice(split$key, i)
    } else {
      tibble::new_tibble(list(), nrow = 1)
    }
    list(key = key, data = split$val[[i]])
  })
  for (grp in groups) {
    if (length(unique(grp$data$.site)) < 3) {
      cli::cli_abort("Each group needs at least three sites along the gradient.", call = call)
    }
  }
  list(groups = groups, by = by_cols, site = site_col, gradient = gr_col)
}

# Site-by-species presence matrix with sites in gradient order.
mde_occupancy <- function(grp) {
  d <- grp$data
  s <- unique(d[c(".site", ".gradient")])
  s <- s[order(s$.gradient), ]
  sp <- sort(unique(d$.species))
  mat <- matrix(FALSE, nrow(s), length(sp), dimnames = list(NULL, sp))
  mat[cbind(match(d$.site, s$.site), match(d$.species, sp))] <- TRUE
  list(mat = mat, sites = s$.site, gradient = s$.gradient)
}

# Fill each column between its first and last presence.
mde_fill <- function(mat) {
  for (j in seq_len(ncol(mat))) {
    w <- which(mat[, j])
    mat[min(w):max(w), j] <- TRUE
  }
  mat
}

# Exact expected richness when each range of `size` sites is placed
# uniformly among the n - size + 1 positions where it fits.
mde_expected_uniform <- function(size, n) {
  i <- seq_len(n)
  rowSums(vapply(size, function(l) {
    pos <- n - l + 1
    covers <- pmin(i, pos) - pmax(i - l + 1, 1) + 1
    covers / pos
  }, numeric(n)))
}

# n-by-nsim matrix of simulated richness.
mde_simulate <- function(size, n, nsim, model) {
  out <- matrix(0, n, nsim)
  for (l in size) {
    if (model == "uniform") {
      start <- sample.int(n - l + 1, nsim, replace = TRUE)
    } else {
      start <- vapply(seq_len(nsim), function(b) mde_spread_start(l, n), numeric(1))
    }
    for (b in seq_len(nsim)) {
      idx <- start[b]:(start[b] + l - 1)
      out[idx, b] <- out[idx, b] + 1
    }
  }
  out
}

# Spreading-dye placement: a random seed site, then repeated growth into a
# randomly chosen free neighbour of the occupied block. Returns the start.
mde_spread_start <- function(l, n) {
  lo <- hi <- sample.int(n, 1)
  while (hi - lo + 1 < l) {
    cand <- c(if (lo > 1) lo - 1, if (hi < n) hi + 1)
    nxt <- if (length(cand) == 1) cand else sample(cand, 1)
    if (nxt < lo) lo <- nxt else hi <- nxt
  }
  lo
}

mde_finish <- function(out, g, species_col, data) {
  names(out)[names(out) == ".site"] <- g$site
  names(out)[names(out) == ".gradient"] <- g$gradient
  tibble::as_tibble(out)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_mde <- function(object,
                            palette = "okabe_ito",
                            theme = theme_tidydiversity(),
                            xlab = NULL,
                            ylab = "Species richness",
                            ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  gcol <- setdiff(names(df), c(
    "observed", "expected", "sd", "lower", "upper", "outside"
  ))
  gcol <- gcol[vapply(df[gcol], is.numeric, logical(1))]
  gcol <- gcol[length(gcol)]
  df$.x <- df[[gcol]]
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$.x)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower, ymax = .data$upper, fill = "Null model"),
      alpha = 0.25
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .data$expected, colour = "Null model"),
      linetype = "dashed"
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .data$observed, colour = "Observed")) +
    ggplot2::geom_point(ggplot2::aes(y = .data$observed, colour = "Observed"), size = 2) +
    ggplot2::labs(x = xlab %||% gcol, y = ylab, colour = NULL, fill = NULL) +
    ggplot2::guides(fill = "none")
  stats_cols <- c("observed", "expected", "sd", "lower", "upper", "outside")
  facet <- setdiff(names(df), c(gcol, ".x", stats_cols))
  facet <- facet[seq_len(max(length(facet) - 1, 0))]
  if (length(facet)) p <- p + ggplot2::facet_wrap(facet)
  td_style(p, palette, theme)
}

#' Geometry or environment? Partitioning richness along a gradient
#'
#' @description
#' `range_partition()` splits the variation in observed richness along a
#' gradient into the part explained by the mid-domain null model
#' (geometry), the part explained by environmental variables, the part
#' they share, and the unexplained rest. It is variation partitioning
#' (Borcard et al. 1992; Peres-Neto et al. 2006) with adjusted R², applied
#' to the debate on whether geometric constraints or the environment
#' drive richness gradients (Colwell et al. 2004; Dunn et al. 2007).
#'
#' Unique fractions are tested with an F test of the nested linear models.
#' With few sites (as on most single-mountain transects) tests have little
#' power and adjusted fractions can be negative (read negative values as
#' zero); report them as descriptive. Sites along a gradient are also
#' spatially autocorrelated, which makes the p-values too small.
#'
#' @param mde A [range_mde()] result.
#' @param env A formula of environmental predictors, e.g. `~ temperature`,
#'   evaluated in `mde` joined with `data`.
#' @param data Optional site-level data frame with the environmental
#'   variables and the site (and grouping) columns of `mde`.
#' @return A tibble with the grouping columns and, for each fraction
#'   (`geometry only`, `environment only`, `shared`, `residual`), `adj_r2`
#'   and, for the unique fractions, `p_value`.
#' @references
#' Borcard, D., Legendre, P. and Drapeau, P. (1992). Partialling out the
#' spatial component of ecological variation. Ecology, 73, 1045-1055.
#'
#' Colwell, R. K., Rahbek, C. and Gotelli, N. J. (2004). The mid-domain
#' effect and species richness patterns: what have we learned so far?
#' American Naturalist, 163, E1-E23. \doi{10.1086/382056}
#'
#' Dunn, R. R., McCain, C. M. and Sanders, N. J. (2007). When does
#' diversity fit null model predictions? Scale and range size mediate the
#' mid-domain effect. Global Ecology and Biogeography, 16, 305-312.
#' @export
#' @examples
#' set.seed(1)
#' mde <- range_mde(png_frogs, gradient = elevation, nsim = 199)
#' range_partition(mde, ~elevation)
range_partition <- function(mde, env, data = NULL) {
  if (!inherits(mde, "td_mde")) {
    cli::cli_abort("{.arg mde} must be a {.fn range_mde} result.")
  }
  if (!rlang::is_formula(env)) {
    cli::cli_abort("{.arg env} must be a formula such as {.code ~ temperature}.")
  }
  d <- tibble::as_tibble(unclass(mde))
  fit <- attr(mde, "fit")
  by <- setdiff(names(fit), c("model", "n_sites", "n_species", "r2", "p_value"))
  if (!is.null(data)) {
    common <- intersect(names(data), names(d))
    d <- dplyr::left_join(d, data[unique(c(common, all.vars(env)))], by = common)
  }
  missing <- setdiff(all.vars(env), names(d))
  if (length(missing)) {
    cli::cli_abort("Variable{?s} {.field {missing}} not found in {.arg mde} or {.arg data}.")
  }
  groups <- if (length(by)) vctrs::vec_split(d, d[by]) else list(key = list(NULL), val = list(d))
  out <- lapply(seq_along(groups$val), function(k) {
    g <- groups$val[[k]]
    x_env <- stats::model.matrix(env, g)[, -1, drop = FALSE]
    y <- g$observed
    n <- length(y)
    if (n <= ncol(x_env) + 2) {
      cli::cli_abort(
        "Too few sites ({n}) for {ncol(x_env)} environmental variable{?s} plus geometry."
      )
    }
    m_geo <- stats::lm(y ~ g$expected)
    m_env <- stats::lm(y ~ x_env)
    m_all <- stats::lm(y ~ g$expected + x_env)
    adj <- function(m) summary(m)$adj.r.squared
    a <- adj(m_all) - adj(m_env)
    c_ <- adj(m_all) - adj(m_geo)
    b <- adj(m_all) - a - c_
    p_geo <- stats::anova(m_env, m_all)$`Pr(>F)`[2]
    p_env <- stats::anova(m_geo, m_all)$`Pr(>F)`[2]
    res <- tibble::tibble(
      fraction = c("geometry only", "environment only", "shared", "residual"),
      adj_r2 = c(a, c_, b, 1 - adj(m_all)),
      p_value = c(p_geo, p_env, NA, NA)
    )
    if (length(by)) {
      res <- vctrs::vec_cbind(vctrs::vec_slice(groups$key, rep(k, nrow(res))), res)
    }
    res
  })
  td_new(vctrs::vec_rbind(!!!out), "td_range_partition")
}
