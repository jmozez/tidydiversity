#' Local and species contributions to beta diversity
#'
#' @description
#' `beta_lcbd()` measures how unusual the composition of each site is: its
#' local contribution to beta diversity (LCBD), with a permutation test.
#' `beta_scbd()` gives the matching species contributions (SCBD), the
#' species that vary most among sites. Both follow Legendre and De Caceres
#' (2013): the community table is transformed, total beta diversity is the
#' total sum of squares of the transformed table, and each site (row) and
#' species (column) takes its share of that sum. They reproduce
#' `adespatial::beta.div()`.
#'
#' @inheritParams beta_pair
#' @param transform Transformation of the abundances before the sums of
#'   squares are taken: `"hellinger"` (default), `"chord"`, `"profiles"`
#'   (relative abundances), `"presence"` (presence and absence) or
#'   `"none"`. Hellinger and chord give dissimilarities suited to
#'   community data (Legendre and De Caceres 2013).
#' @param nperm Number of permutations for the test of each LCBD. Each
#'   species column is permuted independently. Use `0` to skip the test.
#' @return `beta_lcbd()` returns a `td_lcbd` tibble with the grouping
#'   columns, the site column, `lcbd`, `p_value` and `p_adjusted` (Holm),
#'   plus `ss_total` and `bd_total` (total beta diversity) for the group.
#'   `beta_scbd()` returns a tibble with the grouping columns, `species`
#'   and `scbd`, largest first.
#' @references Legendre, P. and De Caceres, M. (2013). Beta diversity as the
#'   variance of community data: dissimilarity coefficients and
#'   partitioning. Ecology Letters, 16, 951-963. \doi{10.1111/ele.12141}
#' @export
#' @examples
#' set.seed(1)
#' beta_lcbd(png_ants, .by = season, nperm = 99)
#'
#' beta_scbd(png_ants, .by = season)
beta_lcbd <- function(data,
                      site = site,
                      species = species,
                      abundance = NULL,
                      transform = c("hellinger", "chord", "profiles",
                                    "presence", "none"),
                      nperm = 999,
                      .by = NULL) {
  transform <- rlang::arg_match(transform)
  td_check_number(nperm, "nperm", 0, whole = TRUE)
  call <- rlang::current_env()
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  out <- td_per_group(prep, function(d) {
    inc <- incidence_matrix(d, abundance = TRUE)
    lcbd_impl(inc, transform, nperm, call = call)$sites
  })
  td_new(td_rename_site(out, prep$site), "td_lcbd")
}

#' @rdname beta_lcbd
#' @export
beta_scbd <- function(data,
                      site = site,
                      species = species,
                      abundance = NULL,
                      transform = c("hellinger", "chord", "profiles",
                                    "presence", "none"),
                      .by = NULL) {
  transform <- rlang::arg_match(transform)
  call <- rlang::current_env()
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  out <- td_per_group(prep, function(d) {
    inc <- incidence_matrix(d, abundance = TRUE)
    lcbd_impl(inc, transform, 0, call = call)$species
  })
  tibble::as_tibble(out)
}

td_transform <- function(mat, transform) {
  rs <- rowSums(mat)
  switch(transform,
    hellinger = sqrt(mat / rs),
    chord = mat / sqrt(rowSums(mat^2)),
    profiles = mat / rs,
    presence = (mat > 0) * 1,
    none = mat
  )
}

lcbd_sums <- function(y) {
  s <- sweep(y, 2, colMeans(y))^2
  tot <- sum(s)
  list(total = tot, rows = rowSums(s) / tot, cols = colSums(s) / tot)
}

lcbd_impl <- function(inc, transform, nperm, call = caller_env()) {
  mat <- inc$mat
  n <- nrow(mat)
  if (n < 3) {
    cli::cli_abort(
      "LCBD needs at least three sites in each group.",
      call = call
    )
  }
  y <- td_transform(mat, transform)
  obs <- lcbd_sums(y)
  p <- rep(NA_real_, n)
  if (nperm > 0) {
    ge <- rep(1, n)
    for (k in seq_len(nperm)) {
      yp <- apply(y, 2, sample)
      ge <- ge + (lcbd_sums(yp)$rows >= obs$rows - 1e-12)
    }
    p <- ge / (nperm + 1)
  }
  sites <- tibble::tibble(
    .site = inc$sites,
    lcbd = obs$rows,
    p_value = p,
    p_adjusted = stats::p.adjust(p, "holm"),
    ss_total = obs$total,
    bd_total = obs$total / (n - 1)
  )
  sp <- tibble::tibble(species = inc$species, scbd = obs$cols)
  sp <- sp[order(-sp$scbd), , drop = FALSE]
  list(sites = sites, species = sp)
}

#' Zeta diversity: species shared by several sites at once
#'
#' @description
#' Zeta diversity (Hui and McGeoch 2014) is the mean number of species
#' shared by any `i` sites. Order 1 is mean richness, order 2 the mean
#' number shared by pairs, and so on, so the decline of zeta with order
#' shows how rare and common species contribute to turnover. The mean for
#' each order is computed exactly from the number of sites occupied by each
#' species, \eqn{\zeta_i = \sum_j \binom{k_j}{i} / \binom{n}{i}}, so no
#' sampling of site combinations is needed.
#'
#' The shape of the decline is summarised by fitting an exponential form
#' (log zeta against order) and a power law (log zeta against log order);
#' an exponential decline points to turnover driven by chance (species
#' occupy sites independently), a power law to turnover structured by
#' niche or dispersal differences (Hui and McGeoch 2014). The fits are
#' returned by [glance()].
#'
#' @inheritParams beta_pair
#' @param orders Orders of zeta to compute. Defaults to 1 to the number of
#'   sites, up to a maximum of 10.
#' @return A `td_zeta` tibble with the grouping columns, `order`, `zeta`
#'   (mean number of shared species), `ratio` (zeta of this order over the
#'   previous one, the retention rate) and `zeta_simpson` (zeta scaled by
#'   the minimum richness of the sites in each combination, from 0 to 1;
#'   found by enumerating the combinations, so it is `NA` when an order
#'   has more than 5000 of them).
#'   `glance()` gives one row per group and model with `slope`,
#'   `r_squared` and `aic`.
#' @references Hui, C. and McGeoch, M. A. (2014). Zeta diversity as a
#'   concept and metric that unifies incidence-based biodiversity patterns.
#'   The American Naturalist, 184, 684-694. \doi{10.1086/678125}
#'
#'   McGeoch, M. A., Latombe, G., Andrew, N. R., Nakagawa, S., Nipperess,
#'   D. A., Roige, M., Marzinelli, E. M., Campbell, A. H., Verges, A.,
#'   Thomas, T., Steinberg, P. D., Selwood, K. E., Henriksen, M. C. and
#'   Hui, C. (2019). Measuring continuous compositional change using
#'   decline and decay in zeta diversity. Ecology, 100, e02832.
#'   \doi{10.1002/ecy.2832}
#' @export
#' @examples
#' z <- beta_zeta(png_ants, .by = season)
#' z
#' glance(z)
beta_zeta <- function(data,
                      site = site,
                      species = species,
                      abundance = NULL,
                      orders = NULL,
                      .by = NULL) {
  call <- rlang::current_env()
  whole <- function(x) all(abs(x - round(x)) < 1e-8)
  ok <- is.null(orders) ||
    (is.numeric(orders) && !anyNA(orders) && all(orders >= 1) && whole(orders))
  if (!ok) {
    cli::cli_abort("{.arg orders} must be whole numbers of 1 or more.")
  }
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  out <- td_per_group(prep, function(d) {
    mat <- incidence_matrix(d)$mat
    zeta_impl(mat, orders, call = call)
  })
  td_new(out, "td_zeta")
}

zeta_impl <- function(mat, orders, call = caller_env()) {
  n <- nrow(mat)
  if (n < 2) {
    cli::cli_abort("Zeta diversity needs at least two sites.", call = call)
  }
  ord <- sort(unique(orders %||% seq_len(min(n, 10))))
  if (any(ord > n)) {
    cli::cli_abort(
      "{.arg orders} can't exceed the number of sites ({n}).",
      call = call
    )
  }
  k <- colSums(mat)
  zeta <- vapply(ord, function(i) sum(choose(k, i)) / choose(n, i), 1)
  prev <- vapply(ord, function(i) {
    if (i == 1) NA_real_ else sum(choose(k, i - 1)) / choose(n, i - 1)
  }, 1)
  rich <- rowSums(mat)
  simp <- vapply(ord, function(i) {
    if (choose(n, i) > 5000) return(NA_real_)
    cmb <- utils::combn(n, i)
    shared <- apply(cmb, 2, function(s) sum(colSums(mat[s, , drop = FALSE]) == i))
    mins <- apply(cmb, 2, function(s) min(rich[s]))
    mean(ifelse(mins > 0, shared / mins, NA_real_), na.rm = TRUE)
  }, 1)
  tibble::tibble(
    order = as.integer(ord), zeta = zeta,
    ratio = ifelse(prev > 0, zeta / prev, NA_real_),
    zeta_simpson = simp
  )
}

#' @export
glance.td_zeta <- function(x, ...) {
  by <- setdiff(names(x), c("order", "zeta", "ratio", "zeta_simpson"))
  x <- tibble::as_tibble(unclass(x))
  groups <- if (length(by) == 0) {
    list(key = tibble::tibble(.rows = 1), val = list(x))
  } else {
    vctrs::vec_split(x, x[by])
  }
  out <- lapply(seq_along(groups$val), function(i) {
    d <- groups$val[[i]]
    d <- d[d$zeta > 0, , drop = FALSE]
    res <- zeta_decline(d$order, d$zeta)
    key <- vctrs::vec_slice(groups$key, rep(i, nrow(res)))
    vctrs::vec_cbind(key, res)
  })
  tibble::as_tibble(vctrs::vec_rbind(!!!out))
}

zeta_decline <- function(order, zeta) {
  if (length(order) < 3) {
    return(tibble::tibble(
      model = c("exponential", "power_law"), slope = NA_real_,
      r_squared = NA_real_, aic = NA_real_
    ))
  }
  fits <- list(
    exponential = stats::lm(log(zeta) ~ order),
    power_law = stats::lm(log(zeta) ~ log(order))
  )
  tibble::tibble(
    model = names(fits),
    slope = vapply(fits, function(f) unname(stats::coef(f)[2]), 1),
    r_squared = vapply(fits, function(f) summary(f)$r.squared, 1),
    aic = vapply(fits, stats::AIC, 1)
  )
}

#' Raup-Crick dissimilarity against a null model
#'
#' @description
#' Pairwise dissimilarity that controls for differences in richness, using
#' the probabilistic null model of Chase et al. (2011). For each pair of
#' sites, species are drawn at random for both sites, keeping their
#' observed richness and drawing each species with probability
#' proportional to the number of sites it occupies in the group. The
#' observed number of shared species is compared with this null
#' distribution. Values near 1 mean fewer shared species than chance
#' (deterministic divergence), near -1 more than chance (convergence),
#' and near 0 a composition no different from random assembly.
#'
#' @inheritParams beta_pair
#' @param nsim Number of null communities per pair.
#' @return A tibble with the grouping columns, `site_1`, `site_2`,
#'   `shared` (observed shared species), `null_mean`, `raup_crick` (from
#'   -1 to 1, Chase et al. 2011) and `probability` (the same on a 0 to 1
#'   scale). Ties between the null and observed counts count half, as in
#'   Chase et al. (2011), so `probability` lies between the two versions
#'   of `vegan::raupcrick()` (`chase = TRUE` counts no ties, `chase =
#'   FALSE` all of them).
#' @references Chase, J. M., Kraft, N. J. B., Smith, K. G., Vellend, M. and
#'   Inouye, B. D. (2011). Using null models to disentangle variation in
#'   community dissimilarity from variation in alpha-diversity. Ecosphere,
#'   2, art24. \doi{10.1890/ES10-00117.1}
#' @export
#' @examples
#' set.seed(1)
#' beta_raup_crick(png_ants, .by = season, nsim = 199)
beta_raup_crick <- function(data,
                            site = site,
                            species = species,
                            abundance = NULL,
                            nsim = 999,
                            .by = NULL) {
  td_check_number(nsim, "nsim", 1, whole = TRUE)
  call <- rlang::current_env()
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  out <- td_per_group(prep, function(d) {
    inc <- incidence_matrix(d)
    raup_crick_impl(inc, nsim, call = call)
  })
  tibble::as_tibble(out)
}

raup_crick_impl <- function(inc, nsim, call = caller_env()) {
  mat <- inc$mat
  n <- nrow(mat)
  if (n < 2) {
    cli::cli_abort(
      "Raup-Crick dissimilarity needs at least two sites.",
      call = call
    )
  }
  occ <- colSums(mat)
  prob <- occ / sum(occ)
  s <- length(occ)
  rich <- rowSums(mat)
  draw <- function(r) {
    out <- numeric(s)
    out[sample.int(s, r, prob = prob)] <- 1
    out
  }
  ij <- utils::combn(n, 2)
  res <- apply(ij, 2, function(p) {
    obs <- sum(mat[p[1], ] * mat[p[2], ])
    null <- vapply(seq_len(nsim), function(k) {
      sum(draw(rich[p[1]]) * draw(rich[p[2]]))
    }, 1)
    pr <- (sum(null > obs) + 0.5 * sum(null == obs)) / nsim
    c(obs, mean(null), pr)
  })
  tibble::tibble(
    site_1 = vctrs::vec_slice(inc$sites, ij[1, ]),
    site_2 = vctrs::vec_slice(inc$sites, ij[2, ]),
    shared = res[1, ],
    null_mean = res[2, ],
    raup_crick = 2 * (res[3, ] - 0.5),
    probability = res[3, ]
  )
}

#' Temporal beta diversity: losses and gains at each site
#'
#' @description
#' Compares the composition of each site at two times with the temporal
#' beta diversity index (TBI) of Legendre (2019). The dissimilarity of
#' each site between the two surveys is split into species losses (`b`)
#' and gains (`c`), and a permutation test identifies the sites whose
#' change is exceptional. With the percentage difference (Bray-Curtis)
#' the losses and gains are in abundance; with Sorensen and Jaccard they
#' are in species. The results match `adespatial::TBI()`.
#'
#' @inheritParams beta_pair
#' @param time <[`tidy-select`][dplyr::dplyr_tidy_select]> The column with
#'   the survey time. It must have exactly two values within each group;
#'   the earlier (in sort order or factor level) is the first survey.
#' @param index `"bray"` (percentage difference, default), `"sorensen"`
#'   or `"jaccard"`.
#' @param nperm Number of permutations for the test of each site. Each
#'   species is permuted independently among sites at both times. Use `0`
#'   to skip the test.
#' @return A `td_tbi` tibble with the grouping columns, the site column,
#'   `losses` and `gains` (B/den and C/den of Legendre 2019, which sum to
#'   `tbi`), `tbi`, `change` (`"loss"`, `"gain"` or `"none"`, whichever
#'   is larger), `p_value` and `p_adjusted` (Holm).
#' @references Legendre, P. (2019). A temporal beta-diversity index to
#'   identify sites that have changed in exceptional ways in space-time
#'   surveys. Ecology and Evolution, 9, 3500-3514. \doi{10.1002/ece3.4984}
#' @export
#' @examples
#' set.seed(1)
#' surveys <- subset(portal_rodents, year %in% c(2016, 2019))
#' beta_tbi(surveys, time = year, site = plot, nperm = 99)
beta_tbi <- function(data,
                     time,
                     site = site,
                     species = species,
                     abundance = NULL,
                     index = c("bray", "sorensen", "jaccard"),
                     nperm = 999,
                     .by = NULL) {
  index <- rlang::arg_match(index)
  td_check_number(nperm, "nperm", 0, whole = TRUE)
  call <- rlang::current_env()
  td_check_data(data)
  time_col <- td_pick(enquo(time), data, "time")
  by_cols <- td_group_cols(data, enquo(.by))
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance),
    rlang::quo(dplyr::all_of(!!c(by_cols, time_col)))
  )
  prep$by <- by_cols
  d <- prep$data
  names(d)[names(d) == time_col] <- ".time"
  prep$data <- d
  out <- td_per_group(prep, function(g) tbi_impl(g, index, nperm, call))
  td_new(td_rename_site(out, prep$site), "td_tbi")
}

tbi_impl <- function(g, index, nperm, call) {
  times <- sort(unique(g$.time))
  if (length(times) != 2) {
    cli::cli_abort(
      "{.arg time} must have exactly two values in each group, not \\
      {length(times)}.",
      call = call
    )
  }
  s1 <- unique(g$.site[g$.time == times[1]])
  s2 <- unique(g$.site[g$.time == times[2]])
  sites <- intersect(s1, s2)
  if (length(sites) < 2 || length(sites) != length(union(s1, s2))) {
    cli::cli_abort(
      "Each site must be surveyed at both times (at least two sites).",
      call = call
    )
  }
  spp <- sort(unique(g$.species))
  make <- function(tm) {
    m <- matrix(0, length(sites), length(spp))
    h <- g[g$.time == tm, , drop = FALSE]
    m[cbind(match(h$.site, sites), match(h$.species, spp))] <- h$.n
    if (index != "bray") m <- (m > 0) * 1
    m
  }
  m1 <- make(times[1])
  m2 <- make(times[2])
  obs <- tbi_parts(m1, m2, index)
  p <- rep(NA_real_, length(sites))
  if (nperm > 0) {
    ge <- rep(1, length(sites))
    for (k in seq_len(nperm)) {
      p1 <- m1
      p2 <- m2
      for (j in seq_along(spp)) {
        o <- sample.int(length(sites))
        p1[, j] <- m1[o, j]
        p2[, j] <- m2[o, j]
      }
      ge <- ge + (tbi_parts(p1, p2, index)$d >= obs$d - 1e-12)
    }
    p <- ge / (nperm + 1)
  }
  change <- ifelse(obs$b > obs$c, "loss", ifelse(obs$c > obs$b, "gain", "none"))
  tibble::tibble(
    .site = sites, losses = obs$b, gains = obs$c, tbi = obs$d,
    change = change, p_value = p, p_adjusted = stats::p.adjust(p, "holm")
  )
}

tbi_parts <- function(m1, m2, index) {
  a <- rowSums(pmin(m1, m2))
  b <- rowSums(m1) - a
  cc <- rowSums(m2) - a
  den <- switch(index,
    bray = 2 * a + b + cc,
    sorensen = 2 * a + b + cc,
    jaccard = a + b + cc
  )
  den[den == 0] <- NA_real_
  list(b = b / den, c = cc / den, d = (b + cc) / den)
}
