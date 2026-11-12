#' Shared species and similarity corrected for unseen species
#'
#' @description
#' For every pair of sites:
#'
#' * `beta_shared()` estimates the total number of species the two sites
#'   share, including shared species that neither sample detected, with
#'   the Chao1-shared estimator for abundance data and the Chao2-shared
#'   estimator for incidence data (Chao et al. 2000; Pan et al. 2009).
#' * `beta_chao()` gives the abundance-based Jaccard and Sørensen
#'   similarities of Chao et al. (2005), which correct for shared species
#'   missed by incomplete samples, next to the classic indices.
#'
#' Classic indices underestimate similarity when samples are incomplete,
#' because a species shared by two sites but rare in one of them is often
#' missed. The Chao versions estimate the probability that an individual
#' of one site belongs to a species shared with the other (`u`, `v`),
#' adding the shared species that were seen once in one sample. They are
#' the estimators of EstimateS and SpadeR; the values equal SpadeR's, and
#' `chao_jaccard` equals one minus vegan's `vegdist(method = "chao")`.
#' This is checked in the test suite.
#'
#' @inheritParams div_estimate
#' @return `beta_shared()`: a tibble with the grouping columns, `site_1`,
#'   `site_2`, `s_1`, `s_2` (observed richness), `observed` (observed
#'   shared species) and `estimate`. `beta_chao()`: a tibble with `site_1`,
#'   `site_2`, `jaccard`, `sorensen` (classic, on species lists), `u`, `v`,
#'   `chao_jaccard` and `chao_sorensen` (similarities, 0-1).
#' @references
#' Chao, A., Hwang, W.-H., Chen, Y.-C. and Kuo, C.-Y. (2000). Estimating
#' the number of shared species in two communities. Statistica Sinica, 10,
#' 227-246.
#'
#' Chao, A., Chazdon, R. L., Colwell, R. K. and Shen, T.-J. (2005). A new
#' statistical approach for assessing similarity of species composition
#' with incidence and abundance data. Ecology Letters, 8, 148-159.
#' \doi{10.1111/j.1461-0248.2004.00707.x}
#'
#' Pan, H.-Y., Chao, A. and Foissner, W. (2009). A nonparametric lower
#' bound for the number of species shared by multiple communities. Journal
#' of Agricultural, Biological and Environmental Statistics, 14, 452-468.
#' @export
#' @examples
#' beta_shared(png_ants, .by = season)
#' beta_chao(png_ants, .by = season)
beta_shared <- function(data,
                        site = site,
                        species = species,
                        abundance = NULL,
                        unit = NULL,
                        n_units = NULL,
                        .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE, unit = enquo(unit), n_units = enquo(n_units)
  )
  incidence <- !is.null(prep$incidence)
  out <- pair_apply(prep, function(x1, x2, w1, w2) {
    tibble::tibble(
      s_1 = sum(x1 > 0), s_2 = sum(x2 > 0),
      observed = sum(x1 > 0 & x2 > 0),
      estimate = chao_shared(x1, x2, w1, w2, incidence)
    )
  })
  td_new(out, "td_beta_shared")
}

#' @rdname beta_shared
#' @export
beta_chao <- function(data,
                      site = site,
                      species = species,
                      abundance = NULL,
                      unit = NULL,
                      n_units = NULL,
                      .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE, unit = enquo(unit), n_units = enquo(n_units)
  )
  out <- pair_apply(prep, function(x1, x2, w1, w2) {
    sh <- x1 > 0 & x2 > 0
    a <- sum(sh)
    j <- a / sum(x1 + x2 > 0)
    s <- 2 * a / (sum(x1 > 0) + sum(x2 > 0))
    uv <- chao_uv(x1, x2, w1, w2)
    u <- uv[1]
    v <- uv[2]
    tibble::tibble(
      jaccard = j, sorensen = s, u = u, v = v,
      chao_jaccard = if (u + v > 0) u * v / (u + v - u * v) else 0,
      chao_sorensen = if (u + v > 0) 2 * u * v / (u + v) else 0
    )
  })
  td_new(out, "td_beta_chao")
}

# Apply fn(x1, x2, w1, w2) to every pair of sites in each group. x1 and x2
# are aligned count (or incidence frequency) vectors; w1 and w2 the sample
# sizes (individuals, or sampling units for incidence data).
pair_apply <- function(prep, fn, call = caller_env()) {
  store <- new.env()
  store$x <- list()
  keys <- td_per_site(prep, function(x, i) {
    store$x[[i]] <- x
    tibble::tibble(.i = i)
  })
  site_col <- prep$site
  grp <- if (length(prep$by)) vctrs::vec_group_loc(keys[prep$by]) else NULL
  locs <- if (is.null(grp)) list(seq_len(nrow(keys))) else grp$loc
  out <- lapply(seq_along(locs), function(g) {
    idx <- locs[[g]]
    if (length(idx) < 2) {
      cli::cli_abort("Each group needs at least two sites.", call = call)
    }
    xs <- store$x[keys$.i[idx]]
    sp <- sort(unique(unlist(lapply(xs, names))))
    ij <- utils::combn(length(idx), 2)
    rows <- lapply(seq_len(ncol(ij)), function(p) {
      a <- xs[[ij[1, p]]]
      b <- xs[[ij[2, p]]]
      x1 <- stats::setNames(numeric(length(sp)), sp)
      x2 <- x1
      x1[names(a)] <- a
      x2[names(b)] <- b
      res <- fn(unname(x1), unname(x2), smp_n(a), smp_n(b))
      tibble::tibble(
        site_1 = keys[[site_col]][idx[ij[1, p]]],
        site_2 = keys[[site_col]][idx[ij[2, p]]], res
      )
    })
    rows <- vctrs::vec_rbind(!!!rows)
    if (length(prep$by)) {
      vctrs::vec_cbind(vctrs::vec_slice(grp$key, rep(g, nrow(rows))), rows)
    } else {
      rows
    }
  })
  vctrs::vec_rbind(!!!out)
}

# Chao1-shared (abundance) and Chao2-shared (incidence) estimators, with
# the bias-corrected form when a doubleton count is zero (SpadeR).
chao_shared <- function(x1, x2, w1, w2, incidence = FALSE) {
  sh <- x1 > 0 & x2 > 0
  a <- x1[sh]
  b <- x2[sh]
  c1 <- if (incidence) (w1 - 1) / w1 else 1
  c2 <- if (incidence) (w2 - 1) / w2 else 1
  f11 <- sum(a == 1 & b == 1)
  f1p <- sum(a == 1)
  fp1 <- sum(b == 1)
  f2p <- sum(a == 2)
  fp2 <- sum(b == 2)
  if (f2p == 0 || fp2 == 0) {
    sum(sh) + c1 * c2 * f11 * f1p * fp1 / (4 * (f2p + 1) * (fp2 + 1)) +
      c1 * f1p * (f1p - 1) / (2 * (f2p + 1)) +
      c2 * fp1 * (fp1 - 1) / (2 * (fp2 + 1))
  } else {
    sum(sh) + c1 * c2 * f11 * f1p * fp1 / (4 * f2p * fp2) +
      c1 * f1p^2 / (2 * f2p) + c2 * fp1^2 / (2 * fp2)
  }
}

# Chao et al. (2005) estimates of U and V, the relative abundance (or
# incidence) of shared species in each sample, capped at 1.
chao_uv <- function(x1, x2, w1, w2) {
  sh <- x1 > 0 & x2 > 0
  n1 <- sum(x1)
  n2 <- sum(x2)
  fp1 <- sum(sh & x2 == 1)
  fp2 <- max(sum(sh & x2 == 2), 1)
  f1p <- sum(sh & x1 == 1)
  f2p <- max(sum(sh & x1 == 2), 1)
  u <- sum(x1[sh]) / n1 +
    (w2 - 1) / w2 * fp1 / 2 / fp2 * sum(x1[sh & x2 == 1]) / n1
  v <- sum(x2[sh]) / n2 +
    (w1 - 1) / w1 * f1p / 2 / f2p * sum(x2[sh & x1 == 1]) / n2
  c(min(u, 1), min(v, 1))
}
