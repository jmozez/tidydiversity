#' Coverage-standardised beta diversity with Hill numbers
#'
#' Gamma, alpha and beta diversity of order q, standardised to a common
#' sample coverage, following Chao et al. (2023) (the iNEXT.beta3D
#' framework). Each `.by` group is a region whose sites are its
#' assemblages. Gamma diversity is the diversity of the pooled region;
#' alpha diversity is computed from the species-by-site data and divided by
#' the number of sites; each is rarefied or extrapolated to the sample size
#' at which it reaches the target coverage. Beta = gamma / alpha is the
#' effective number of completely distinct assemblages (1 to N).
#'
#' Standardising by coverage removes the dependence of beta diversity on
#' sample size and completeness, so regions sampled with different effort
#' can be compared (Chao et al. 2023). Four normalised dissimilarities in
#' 0-1 are derived from beta:
#' * `dis_sorensen` (1 - C): Sorensen-type non-overlap;
#' * `dis_jaccard` (1 - U): Jaccard-type non-overlap;
#' * `dis_turnover_sorensen` (1 - V): Sorensen-type turnover;
#' * `dis_turnover_jaccard` (1 - S): Jaccard-type turnover.
#'
#' For q = 0 they reduce to the classic Sorensen and Jaccard family; for
#' q = 1 and 2 they generalise Horn and Morisita-Horn overlap.
#'
#' @section Dimensions and data types:
#' `type = "PD"` gives phylogenetic beta diversity from `tree`, and
#' `type = "FD"` functional beta diversity from `distance`, exactly as in
#' iNEXT.beta3D. Sample sizes are always those at which the taxonomic data
#' reach the target coverage. For FD, `tau = "auc"` integrates gamma, alpha
#' and beta over 30 thresholds between 0 and 1, as iNEXT.beta3D does.
#'
#' With `unit`, the data are incidences: each site was surveyed in the same
#' `T` sampling units (plots, visits, traps), and a unit's label must
#' identify the same unit at every site of a region, because gamma
#' diversity counts a species as present in a unit if it was found there
#' at any site.
#'
#' @section Confidence intervals:
#' With `nboot > 0`, every region is resampled as a whole (Chao et al.
#' 2023): each site's community, including estimated undetected species,
#' is redrawn with its sample size (or units) and all quantities are
#' recomputed at the same coverage. Each estimate gets `_lower` and
#' `_upper` columns, the estimate -/+ z x bootstrap standard error.
#'
#' @inheritParams beta_pair
#' @inheritParams div_hill
#' @param q Orders of diversity.
#' @param coverage Target sample coverage(s) in (0, 1]. By default, the
#'   lowest coverage that the pooled data of every region reaches at twice
#'   its sample size, so no region is extrapolated too far.
#' @param nboot Number of bootstrap replicates for confidence intervals;
#'   0 for none.
#' @param conf Confidence level.
#' @return A tibble with the `.by` columns, `q`, `coverage`, the sample
#'   sizes `m_gamma` and `m_alpha`, `gamma`, `alpha`, `beta`, `n_sites`,
#'   the four dissimilarities and, with `nboot > 0`, their confidence
#'   limits.
#' @references Chao, A., Thorn, S., Chiu, C.-H. et al. (2023).
#'   Rarefaction and extrapolation with beta diversity under a framework of
#'   Hill numbers: the iNEXT.beta3D standardization. *Ecological
#'   Monographs*, 93, e1588. \doi{10.1002/ecm.1588}
#' @examples
#' beta_hill(png_ants, .by = season, coverage = 0.9)
#' @export
beta_hill <- function(data,
                      site = site,
                      species = species,
                      abundance = NULL,
                      q = c(0, 1, 2),
                      coverage = NULL,
                      type = c("TD", "PD", "FD"),
                      tree = NULL,
                      reftime = NULL,
                      pd_unit = c("mean", "total"),
                      distance = NULL,
                      tau = NULL,
                      unit = NULL,
                      n_units = NULL,
                      nboot = 0,
                      conf = 0.95,
                      .by = NULL) {
  td_check_q(q)
  if (!is.null(coverage) &&
        (!is.numeric(coverage) || any(coverage <= 0 | coverage > 1))) {
    cli::cli_abort("{.arg coverage} must be in (0, 1].")
  }
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  td_check_number(conf, "conf", 0, 1)
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    unit = enquo(unit), n_units = enquo(n_units)
  )
  dim <- td_dimension(
    rlang::arg_match(type), prep, tree, reftime, rlang::arg_match(pd_unit),
    distance, tau
  )
  regions <- beta_hill_regions(prep)
  if (is.null(coverage)) {
    coverage <- min(vapply(regions, function(r) {
      g <- bh_gamma_td(r)
      coverage_at_size(g, 2 * smp_n(g))
    }, numeric(1)))
  }
  z <- stats::qnorm(1 - (1 - conf) / 2)
  out <- lapply(regions, function(r) {
    est <- bh_estimate(r, dim, q, coverage)
    nq <- length(q)
    res <- tibble::tibble(
      q = rep(q, times = length(coverage)),
      coverage = rep(coverage, each = nq),
      m_gamma = est$m_gamma, m_alpha = est$m_alpha,
      gamma = est$val[, "gamma"], alpha = est$val[, "alpha"],
      beta = est$val[, "beta"], n_sites = r$n_sites,
      dis_sorensen = est$val[, "C"],
      dis_jaccard = est$val[, "U"],
      dis_turnover_sorensen = est$val[, "V"],
      dis_turnover_jaccard = est$val[, "S"]
    )
    if (nboot > 0) {
      se <- bh_boot_se(r, dim, q, coverage, nboot)
      cols <- c(
        gamma = "gamma", alpha = "alpha", beta = "beta",
        dis_sorensen = "C", dis_jaccard = "U",
        dis_turnover_sorensen = "V", dis_turnover_jaccard = "S"
      )
      for (nm in names(cols)) {
        res[[paste0(nm, "_lower")]] <- res[[nm]] - z * se[, cols[[nm]]]
        res[[paste0(nm, "_upper")]] <- res[[nm]] + z * se[, cols[[nm]]]
      }
    }
    if (length(prep$by) > 0) res <- vctrs::vec_cbind(r$key, res)
    res
  })
  tibble::as_tibble(vctrs::vec_rbind(!!!out))
}

# ---- Regions -------------------------------------------------------------

# Each region as a species-by-site matrix `y` (abundances, or incidence
# frequencies) and, for incidence data, the number of units `nt` and each
# site's species-by-unit detection matrix with units aligned across sites.
beta_hill_regions <- function(prep) {
  if (length(prep$by) == 0) {
    split <- list(key = list(NULL), val = list(prep$data))
  } else {
    split <- vctrs::vec_split(prep$data, prep$data[prep$by])
  }
  lapply(seq_along(split$val), function(i) {
    d <- split$val[[i]]
    key <- if (length(prep$by) > 0) vctrs::vec_slice(split$key, i) else NULL
    y <- t(ord_matrix(d))
    if (ncol(y) < 2) {
      cli::cli_abort("Each region needs at least two sites.")
    }
    r <- list(key = key, y = y, n_sites = ncol(y), nt = NULL, mats = NULL)
    if (!is.null(prep$incidence)) {
      r <- bh_region_incidence(r, d, prep)
    }
    r
  })
}

bh_region_incidence <- function(r, d, prep) {
  inc <- prep$incidence
  sites <- colnames(r$y)
  keys <- vctrs::vec_unique(d[c(prep$by, ".site")])
  keys <- keys[match(sites, as.character(keys$.site)), , drop = FALSE]
  ks <- inc$key_of(keys)
  nt <- unique(unname(inc$n_units[ks]))
  if (length(nt) > 1) {
    cli::cli_abort(
      "Every site of a region must have the same number of sampling units."
    )
  }
  units <- sort(unique(unlist(lapply(inc$mats[ks], colnames))))
  if (length(units) > nt) {
    cli::cli_abort(c(
      "Unit labels must name the same sampling units at every site.",
      "x" = "A region has {length(units)} distinct units but {nt} per site."
    ))
  }
  spp <- rownames(r$y)
  r$mats <- lapply(ks, function(k) {
    m <- matrix(FALSE, length(spp), nt, dimnames = list(spp, NULL))
    s <- inc$mats[[k]]
    m[rownames(s), match(colnames(s), units)] <- s
    m
  })
  r$nt <- nt
  r
}

# Taxonomic gamma (pooled) and alpha (all site-species cells) vectors.
bh_gamma_td <- function(r) {
  if (is.null(r$nt)) {
    g <- rowSums(r$y)
    return(g[g > 0])
  }
  u <- Reduce(`|`, r$mats)
  g <- rowSums(u)
  as_incidence(g[g > 0], r$nt, u[g > 0, , drop = FALSE])
}

bh_alpha_td <- function(r) {
  a <- as.vector(r$y)
  a <- a[a > 0]
  if (is.null(r$nt)) a else as_incidence(a, r$nt)
}

# ---- Estimates -------------------------------------------------------------

# Gamma, alpha, beta and the dissimilarities of one region, for every
# coverage (outer) and order q (inner).
bh_estimate <- function(r, dim, q, coverage) {
  g_td <- bh_gamma_td(r)
  a_td <- bh_alpha_td(r)
  n <- smp_n(g_td)
  nn <- r$n_sites
  mg <- vapply(coverage, function(cv) size_for_coverage(g_td, cv), numeric(1))
  ma <- vapply(coverage, function(cv) size_for_coverage(a_td, cv), numeric(1))
  ga <- switch(dim$type,
    TD = list(
      gamma = dim_at_size(g_td, mg, q, dim),
      alpha = dim_at_size(a_td, ma, q, dim) / nn
    ),
    PD = bh_pd(r, dim, n, mg, ma, q),
    FD = bh_fd(r, dim, n, mg, ma, q)
  )
  gam <- as.vector(t(ga$gamma))
  alp <- as.vector(t(ga$alpha))
  bet <- if (is.null(ga$beta)) gam / alp else as.vector(t(ga$beta))
  qq <- rep(q, times = length(coverage))
  val <- cbind(
    gamma = gam, alpha = alp, beta = bet,
    C = beta_dis(bet, qq, nn, "C"), U = beta_dis(bet, qq, nn, "U"),
    V = beta_dis(bet, qq, nn, "V"), S = beta_dis(bet, qq, nn, "S")
  )
  list(
    m_gamma = rep(mg, each = length(q)), m_alpha = rep(ma, each = length(q)),
    val = val
  )
}

# Phylogenetic gamma and alpha: alpha pools the branch tables of all sites.
bh_pd <- function(r, dim, n, mg, ma, q) {
  und <- dim$undetected
  if (is.null(r$nt)) {
    at_g <- phylo_attr(rowSums(r$y), dim$tree, dim$reftime, und)
    sites <- lapply(seq_len(r$n_sites), function(k) {
      x <- r$y[, k]
      phylo_attr(x[x > 0], dim$tree, dim$reftime, und)
    })
  } else {
    at_g <- phylo_attr_inc(Reduce(`|`, r$mats), dim$tree, dim$reftime, und)
    sites <- lapply(r$mats, phylo_attr_inc, dim$tree, dim$reftime, und)
  }
  at_a <- list(
    a = unlist(lapply(sites, `[[`, "a")),
    w = unlist(lapply(sites, `[[`, "w")), kind = "PD"
  )
  list(
    gamma = attr_at_size(at_g, n, mg, q) / dim$divisor,
    alpha = attr_at_size(at_a, n, ma, q) / dim$divisor / r$n_sites
  )
}

# Functional gamma and alpha under threshold tau (Chao et al. 2023): the
# functional abundances of each site, with every site's attribute
# contributions taken from the pooled region.
bh_fd_tau <- function(r, dist, tau, n, mg, ma, q) {
  y <- r$y[rowSums(r$y) > 0, , drop = FALSE]
  if (!is.null(r$nt)) {
    g <- rowSums(Reduce(`|`, r$mats))[rownames(y)]
  } else {
    g <- rowSums(y)
  }
  d <- dist[rownames(y), rownames(y), drop = FALSE]
  if (tau == 0) {
    d[d > 0] <- 1
    tau <- 1
  } else {
    d[d > tau] <- tau
  }
  k <- 1 - d / tau
  ga <- as.vector(k %*% g)
  aa <- k %*% y
  cap <- if (is.null(r$nt)) Inf else n
  ga <- pmin(ga, cap)
  aa <- pmin(as.vector(aa), cap)
  int <- function(a) ifelse(a > 0 & a < 1, 1, round(a))
  keep <- ga > 0
  gai <- int(ga[keep])
  gv <- g[keep] / gai
  aai <- int(aa)
  av <- rep(g / int(ga), r$n_sites)
  ka <- aai > 0
  at_g <- list(a = gai, w = gv, kind = "FD")
  at_a <- list(a = aai[ka], w = av[ka], kind = "FD")
  list(
    gamma = attr_at_size(at_g, n, mg, q),
    alpha = attr_at_size(at_a, n, ma, q) / r$n_sites
  )
}

bh_fd <- function(r, dim, n, mg, ma, q) {
  if (!identical(dim$tau, "auc")) {
    return(bh_fd_tau(r, dim$distance, dim$tau, n, mg, ma, q))
  }
  cut <- seq(1e-8, 1, length.out = 30)
  w <- diff(cut)
  vals <- lapply(cut, function(t) bh_fd_tau(r, dim$distance, t, n, mg, ma, q))
  integ <- function(f) {
    v <- lapply(vals, f)
    acc <- 0
    for (i in seq_along(w)) acc <- acc + (v[[i]] + v[[i + 1]]) / 2 * w[i]
    acc
  }
  list(
    gamma = integ(function(v) v$gamma),
    alpha = integ(function(v) v$alpha),
    beta = integ(function(v) v$gamma / v$alpha)
  )
}

# Normalised dissimilarities from beta (Chao et al. 2023, Table 2).
beta_dis <- function(beta, q, n, type) {
  vapply(seq_along(beta), function(i) {
    b <- beta[i]
    qq <- q[i]
    switch(type,
      C = if (qq == 1) {
        log(b) / log(n)
      } else {
        1 - ((1 / b)^(qq - 1) - (1 / n)^(qq - 1)) / (1 - (1 / n)^(qq - 1))
      },
      U = if (qq == 1) {
        log(b) / log(n)
      } else {
        1 - ((1 / b)^(1 - qq) - (1 / n)^(1 - qq)) / (1 - (1 / n)^(1 - qq))
      },
      V = (b - 1) / (n - 1),
      S = (1 - 1 / b) / (1 - 1 / n)
    )
  }, numeric(1))
}

# ---- Bootstrap -------------------------------------------------------------

# Bootstrap standard errors (Chao et al. 2023). Undetected species, as
# many as estimated for the pooled region, are shared slots; each site's
# undetected probability mass goes to randomly chosen slots among the
# species it did not detect. PD gives each undetected species its own
# branch from the root, FD treats it as resembling the rarest species.
bh_boot_se <- function(r, dim, q, coverage, nboot) {
  g_td <- bh_gamma_td(r)
  inc <- !is.null(r$nt)
  n <- smp_n(g_td)
  f1 <- sum(g_td == 1)
  f2 <- sum(g_td == 2)
  k0 <- ceiling(f0_hat(n, f1, f2))
  und <- if (k0 > 0) paste0(".undetected", seq_len(k0)) else character()
  spp <- c(rownames(r$y), und)
  dim_b <- dim
  if (k0 > 0 && dim$type == "PD") {
    at <- if (inc) {
      phylo_attr_inc(attr(g_td, "inc"), dim$tree, dim$reftime)
    } else {
      phylo_attr(g_td, dim$tree, dim$reftime)
    }
    g0 <- undetected_0(
      n, sum(at$a == 1), sum(at$a == 2), sum(at$w[at$a == 1]),
      sum(at$w[at$a == 2]), "PD"
    )
    dim_b$undetected <- list(names = und, length = g0 / k0)
  }
  if (k0 > 0 && dim$type == "FD") {
    dim_b$distance <- extend_distance(g_td, dim$distance, und)
  }
  pop <- vapply(seq_len(r$n_sites), function(s) {
    x <- r$y[, s]
    p <- if (inc) boot_community_inc(x, n) else boot_community(x)
    obs <- c(p[seq_along(x)], rep(0, k0))
    extra <- p[-seq_along(x)]
    if (length(extra) > 0) {
      cand <- which(obs == 0)
      pick <- cand[sample.int(length(cand), min(length(extra), length(cand)))]
      obs[pick] <- if (inc) extra[1] else (1 - sum(obs)) / length(pick)
    }
    obs
  }, numeric(length(spp)))
  rownames(pop) <- spp
  draws <- lapply(seq_len(nboot), function(b) {
    rb <- r
    if (inc) {
      mats <- lapply(seq_len(r$n_sites), function(s) {
        m <- matrix(stats::runif(length(spp) * n) < pop[, s], length(spp), n)
        rownames(m) <- spp
        m
      })
      y <- vapply(mats, rowSums, numeric(length(spp)))
      keep <- rowSums(y) > 0
      rb$mats <- lapply(mats, function(m) m[keep, , drop = FALSE])
    } else {
      y <- vapply(seq_len(r$n_sites), function(s) {
        as.vector(stats::rmultinom(1, sum(r$y[, s]), pop[, s]))
      }, numeric(length(spp)))
      keep <- rowSums(y) > 0
    }
    rownames(y) <- spp
    rb$y <- y[keep, , drop = FALSE]
    suppressWarnings(bh_estimate(rb, dim_b, q, coverage)$val)
  })
  arr <- simplify2array(draws)
  apply(arr, c(1, 2), stats::sd)
}
