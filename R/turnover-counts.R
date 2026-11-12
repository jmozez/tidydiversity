#' Shared, lost and gained species between pairs of sites
#'
#' @description
#' For each pair of sites, `beta_turnover_counts()` counts the species
#' they share, the species found only in the first site (lost on moving
#' to the second) and only in the second (gained), and gives the pairwise
#' dissimilarities with Baselga's partitions:
#'
#' * `sorensen` = `turnover` (Simpson dissimilarity, beta.sim) +
#'   `nestedness` (beta.sne) (Baselga 2010);
#' * `jaccard` = `turnover_j` + `nestedness_j` (Baselga 2012);
#' * with abundances, `bray` = `balanced` (balanced variation in
#'   abundance) + `gradient` (abundance gradient) (Baselga 2013).
#'
#' The values equal those of the betapart package. Along a gradient, use
#' `pairs = "adjacent"` with `order_by` to compare each site with the next.
#'
#' A site with no species makes the dissimilarities undefined (0 / 0 when
#' both sites are empty, or a pure loss): such pairs are returned with a
#' warning, their counts are kept and undefined indices are `NA`.
#'
#' @inheritParams div_hill
#' @param pairs `"adjacent"` (each site with the next in `order_by`
#'   order), `"all"` (every pair), or a data frame with two columns of
#'   site names.
#' @param order_by Column giving the order of sites for `"adjacent"`
#'   pairs, such as elevation; by default the natural site order.
#' @return A tibble with the grouping columns, `site_1`, `site_2`,
#'   `s_1`, `s_2` (richness), `shared`, `lost`, `gained`, `sorensen`,
#'   `turnover`, `nestedness`, `jaccard`, `turnover_j`, `nestedness_j`, and
#'   with abundances `bray`, `balanced` and `gradient`.
#' @references
#' Baselga, A. (2010). Partitioning the turnover and nestedness components
#' of beta diversity. Global Ecology and Biogeography, 19, 134-143.
#'
#' Baselga, A. (2012). The relationship between species replacement,
#' dissimilarity derived from nestedness, and nestedness. Global Ecology
#' and Biogeography, 21, 1223-1232.
#'
#' Baselga, A. (2013). Separating the two components of abundance-based
#' dissimilarity: balanced changes in abundance vs. abundance gradients.
#' Methods in Ecology and Evolution, 4, 552-557.
#' @export
#' @examples
#' wet <- dplyr::filter(png_ants, season == "wet")
#' beta_turnover_counts(wet, abundance = workers, order_by = elevation)
beta_turnover_counts <- function(data,
                                 site = site,
                                 species = species,
                                 abundance = NULL,
                                 pairs = "adjacent",
                                 order_by = NULL,
                                 .by = NULL) {
  td_check_data(data)
  site_col <- td_pick(enquo(site), data, "site")
  sp_col <- td_pick(enquo(species), data, "species")
  ab_q <- enquo(abundance)
  ab_col <- if (quo_is_null(ab_q)) NULL else td_pick(ab_q, data, "abundance")
  ob_q <- enquo(order_by)
  ob_col <- if (quo_is_null(ob_q)) NULL else td_pick(ob_q, data, "order_by")
  by_cols <- td_group_cols(data, enquo(.by))
  n <- if (is.null(ab_col)) rep(1, nrow(data)) else data[[ab_col]]
  if (!is.numeric(n) || anyNA(n) || any(n < 0)) {
    cli::cli_abort("{.arg abundance} must be non-negative numbers.")
  }
  d <- tibble::tibble(
    !!!as.list(dplyr::ungroup(data)[by_cols]),
    .site = data[[site_col]], .species = as.character(data[[sp_col]]), .n = n
  )
  if (!is.null(ob_col)) d$.order <- data[[ob_col]]
  groups <- if (length(by_cols)) {
    vctrs::vec_split(d, d[by_cols])
  } else {
    list(key = list(NULL), val = list(d))
  }
  out <- lapply(seq_along(groups$val), function(g) {
    gd <- groups$val[[g]]
    # Every site in the input, even one whose counts are all zero
    sites <- unique(gd$.site)
    if (!is.null(ob_col)) {
      ord <- vapply(sites, function(s) {
        v <- unique(gd$.order[gd$.site == s])
        if (length(v) != 1) {
          cli::cli_abort("{.arg order_by} must have one value per site.")
        }
        as.numeric(v)
      }, numeric(1))
      sites <- sites[order(ord)]
    } else {
      sites <- sites[order(td_natural_rank(sites))]
    }
    spp <- sort(unique(gd$.species[gd$.n > 0]))
    m <- matrix(0, length(sites), length(spp), dimnames = list(as.character(sites), spp))
    pos <- gd$.n > 0
    m[cbind(match(as.character(gd$.site[pos]), rownames(m)), match(gd$.species[pos], spp))] <-
      stats::ave(gd$.n[pos], gd$.site[pos], gd$.species[pos], FUN = sum)
    ij <- turnover_pairs(pairs, rownames(m))
    empty <- rownames(m)[rowSums(m) == 0]
    if (length(empty)) {
      cli::cli_warn(c(
        "{length(empty)} site{?s} {?has/have} no species: {.val {empty}}.",
        "i" = "Pairs with {cli::qty(length(empty))}{?it/them} have undefined dissimilarities, \\
        returned as {.code NA}."
      ))
    }
    res <- lapply(seq_len(nrow(ij)), function(k) {
      a <- m[ij[k, 1], ]
      b <- m[ij[k, 2], ]
      turnover_row(a, b, abundance = !is.null(ab_col))
    })
    res <- vctrs::vec_rbind(!!!res)
    res <- vctrs::vec_cbind(
      tibble::tibble(site_1 = ij[, 1], site_2 = ij[, 2]), res
    )
    if (length(by_cols)) {
      res <- vctrs::vec_cbind(vctrs::vec_slice(groups$key, rep(g, nrow(res))), res)
    }
    res
  })
  td_new(vctrs::vec_rbind(!!!out), "td_turnover_counts")
}

turnover_pairs <- function(pairs, sites, call = caller_env()) {
  if (is.data.frame(pairs)) {
    if (ncol(pairs) < 2) {
      cli::cli_abort("{.arg pairs} needs two columns of site names.", call = call)
    }
    p <- cbind(as.character(pairs[[1]]), as.character(pairs[[2]]))
    bad <- setdiff(c(p), sites)
    if (length(bad)) {
      cli::cli_abort("Unknown site{?s} in {.arg pairs}: {.val {bad}}.", call = call)
    }
    return(p)
  }
  pairs <- rlang::arg_match0(pairs, c("adjacent", "all"), "pairs", error_call = call)
  if (length(sites) < 2) {
    cli::cli_abort("At least two sites are needed.", call = call)
  }
  if (pairs == "adjacent") {
    return(cbind(sites[-length(sites)], sites[-1]))
  }
  t(utils::combn(sites, 2))
}

turnover_row <- function(a, b, abundance) {
  pa <- a > 0
  pb <- b > 0
  sh <- sum(pa & pb)
  lo <- sum(pa & !pb)
  ga <- sum(!pa & pb)
  sor <- if (2 * sh + lo + ga > 0) (lo + ga) / (2 * sh + lo + ga) else NA_real_
  sim <- if (min(lo, ga) + sh > 0) min(lo, ga) / (min(lo, ga) + sh) else NA_real_
  jac <- if (sh + lo + ga > 0) (lo + ga) / (sh + lo + ga) else NA_real_
  jtu <- if (sh + 2 * min(lo, ga) > 0) 2 * min(lo, ga) / (sh + 2 * min(lo, ga)) else NA_real_
  out <- tibble::tibble(
    s_1 = sum(pa), s_2 = sum(pb), shared = sh, lost = lo, gained = ga,
    sorensen = sor, turnover = sim, nestedness = sor - sim,
    jaccard = jac, turnover_j = jtu, nestedness_j = jac - jtu
  )
  if (abundance) {
    w <- sum(pmin(a, b))
    ua <- sum(a) - w
    ub <- sum(b) - w
    bray <- if (2 * w + ua + ub > 0) (ua + ub) / (2 * w + ua + ub) else NA_real_
    bal <- if (w + min(ua, ub) > 0) min(ua, ub) / (w + min(ua, ub)) else NA_real_
    out$bray <- bray
    out$balanced <- bal
    out$gradient <- bray - bal
  }
  out
}
