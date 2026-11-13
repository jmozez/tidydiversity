#' Native and alien species in communities
#'
#' @description
#' `div_invasion()` summarises, for each site (and group), how much of a
#' community is made up of alien (introduced, non-native) species: the
#' number of native and alien species, the alien share of the species and,
#' with abundances, the alien share of the individuals. These are the
#' standard measures of the level of invasion of a community (Catford et
#' al. 2012).
#'
#' @inheritParams div_hill
#' @param status Column giving each record's status. Values in `alien`
#'   count as alien; all others as native.
#' @param alien Values of `status` that mean alien (default `"alien"`,
#'   `"introduced"`, `"exotic"`, `"non-native"`, `"invasive"`).
#' @return A tibble with one row per site (and group): `site`, `richness`,
#'   `native`, `alien`, `alien_share` (of species) and, with `abundance`,
#'   `alien_abundance_share`.
#' @references
#' Catford, J. A., Vesk, P. A., Richardson, D. M. and Pysek, P. (2012).
#' Quantifying levels of biological invasion: towards the objective
#' classification of invaded and invasible ecosystems. Global Change
#' Biology, 18, 44-62.
#' @export
#' @examples
#' # A small illustrative table
#' d <- data.frame(
#'   site = rep(c("a", "b"), each = 4),
#'   species = c("s1", "s2", "s3", "s4", "s1", "s5", "s6", "s7"),
#'   status = c("native", "native", "native", "alien", "native", "alien", "alien", "native"),
#'   count = c(10, 5, 3, 2, 4, 20, 6, 1)
#' )
#' div_invasion(d, status = status, abundance = count)
div_invasion <- function(data,
                         status,
                         site = site,
                         species = species,
                         abundance = NULL,
                         alien = c("alien", "introduced", "exotic", "non-native", "invasive"),
                         .by = NULL) {
  td_check_data(data)
  st_col <- td_pick(enquo(status), data, "status")
  site_col <- td_pick(enquo(site), data, "site")
  sp_col <- td_pick(enquo(species), data, "species")
  ab_q <- enquo(abundance)
  ab_col <- if (quo_is_null(ab_q)) NULL else td_pick(ab_q, data, "abundance")
  by_cols <- td_group_cols(data, enquo(.by))
  d <- dplyr::ungroup(data)
  d$.n <- if (is.null(ab_col)) 1 else d[[ab_col]]
  d <- d[!is.na(d$.n) & d$.n > 0, , drop = FALSE]
  d$.alien <- tolower(as.character(d[[st_col]])) %in% tolower(alien)
  d$.sp <- as.character(d[[sp_col]])
  d$.site <- d[[site_col]]
  out <- d |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(by_cols, ".site")))) |>
    dplyr::summarise(
      richness = dplyr::n_distinct(.data$.sp),
      alien = dplyr::n_distinct(.data$.sp[.data$.alien]),
      ab_alien = sum(.data$.n[.data$.alien]), ab_total = sum(.data$.n),
      .groups = "drop"
    )
  res <- tibble::tibble(
    !!!as.list(out[by_cols]),
    site = out$.site, richness = out$richness, native = out$richness - out$alien,
    alien = out$alien, alien_share = out$alien / out$richness
  )
  if (!is.null(ab_col)) res$alien_abundance_share <- out$ab_alien / out$ab_total
  td_new(res, "td_invasion")
}

#' Biotic homogenisation between two surveys
#'
#' @description
#' `div_homogenisation()` asks whether communities have become more alike
#' over time, as when widespread alien species spread and local endemics
#' are lost (biotic homogenisation; McKinney and Lockwood 1999; Olden and
#' Rooney 2006). It computes the mean pairwise similarity among the same
#' sites in two surveys (Jaccard or Sorensen, presence-absence) and the
#' change, \eqn{\Delta = \bar S_{after} - \bar S_{before}}: positive values
#' mean homogenisation, negative values differentiation.
#'
#' Site pairs share sites, so they are not independent. The confidence
#' interval therefore resamples sites (a site bootstrap): sites are drawn
#' with replacement, and the change is recomputed over the pairs of
#' distinct drawn sites.
#'
#' With `status`, the change is also computed with native species only:
#' the difference between the two (`alien_contribution`) is the part of the
#' change due to alien species.
#'
#' @param before,after Long-format data of the two surveys.
#' @inheritParams div_invasion
#' @param index `"jaccard"` or `"sorensen"` similarity.
#' @param nboot Number of bootstrap resamples of sites.
#' @param conf Confidence level.
#' @param seed Optional random seed.
#' @return A tibble with one row per species set (`"all"` and, with
#'   `status`, `"native"`): `species_set`, `sites`, `similarity_before`,
#'   `similarity_after`, `change`, `lower`, `upper` (bootstrap interval of
#'   the change); with `status`, an attribute `alien_contribution`.
#' @references
#' McKinney, M. L. and Lockwood, J. L. (1999). Biotic homogenization: a few
#' winners replacing many losers in the next mass extinction. Trends in
#' Ecology & Evolution, 14, 450-453.
#'
#' Olden, J. D. and Rooney, T. P. (2006). On defining and quantifying biotic
#' homogenization. Global Ecology and Biogeography, 15, 113-120.
#' @export
#' @examples
#' # A small illustrative example: one alien species spreads to every site
#' before <- data.frame(
#'   site = rep(1:4, each = 2),
#'   species = c("a", "b", "c", "d", "e", "f", "g", "h"),
#'   status = "native"
#' )
#' after <- rbind(before, data.frame(site = 1:4, species = "x", status = "alien"))
#' div_homogenisation(before, after, status = status, nboot = 99, seed = 1)
div_homogenisation <- function(before,
                               after,
                               site = site,
                               species = species,
                               status = NULL,
                               alien = c("alien", "introduced", "exotic", "non-native", "invasive"),
                               index = c("jaccard", "sorensen"),
                               nboot = 999,
                               conf = 0.95,
                               seed = NULL) {
  index <- rlang::arg_match(index)
  td_check_data(before)
  td_check_data(after)
  site_col <- td_pick(enquo(site), before, "site")
  sp_col <- td_pick(enquo(species), before, "species")
  st_q <- enquo(status)
  st_col <- if (quo_is_null(st_q)) NULL else td_pick(st_q, before, "status")
  inc <- function(d, native_only = FALSE) {
    if (native_only) {
      d <- d[!tolower(as.character(d[[st_col]])) %in% tolower(alien), , drop = FALSE]
    }
    table(factor(d[[site_col]], levels = sites), as.character(d[[sp_col]])) > 0
  }
  sites <- sort(intersect(unique(before[[site_col]]), unique(after[[site_col]])))
  if (length(sites) < 3) {
    cli::cli_abort("At least 3 sites must be in both surveys.")
  }
  sim <- function(m) {
    m <- m * 1
    a <- tcrossprod(m)
    n <- rowSums(m)
    tot <- outer(n, n, "+")
    if (index == "jaccard") a / (tot - a) else 2 * a / tot
  }
  if (!is.null(seed)) set.seed(seed)
  alpha <- (1 - conf) / 2
  one <- function(native_only) {
    sb <- sim(inc(before, native_only))
    sa <- sim(inc(after, native_only))
    k <- length(sites)
    mean_pairs <- function(s, idx) {
      ii <- outer(seq_along(idx), seq_along(idx), "<") & outer(idx, idx, "!=")
      v <- s[idx, idx][ii]
      mean(v[is.finite(v)])
    }
    all_idx <- seq_len(k)
    mb <- mean_pairs(sb, all_idx)
    ma <- mean_pairs(sa, all_idx)
    boot <- vapply(seq_len(nboot), function(i) {
      idx <- sample.int(k, k, replace = TRUE)
      mean_pairs(sa, idx) - mean_pairs(sb, idx)
    }, numeric(1))
    tibble::tibble(
      species_set = if (native_only) "native" else "all", sites = k,
      similarity_before = mb, similarity_after = ma, change = ma - mb,
      lower = unname(stats::quantile(boot, alpha, na.rm = TRUE)),
      upper = unname(stats::quantile(boot, 1 - alpha, na.rm = TRUE))
    )
  }
  out <- one(FALSE)
  if (!is.null(st_col)) {
    nat <- one(TRUE)
    out <- vctrs::vec_rbind(out, nat)
    attr(out, "alien_contribution") <- out$change[1] - nat$change
  }
  td_new(out, "td_homogenisation")
}
