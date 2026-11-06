#' Pairwise Hill-number dissimilarity
#'
#' For every pair of sites, `beta_hill_pair()` computes gamma, alpha and
#' beta diversity of order `q` from the observed abundances. It also gives
#' the four normalised dissimilarities of Chao, Chiu and Jost (2014) for
#' two assemblages, with the same names as in [beta_hill()]:
#' `dis_sorensen` (\eqn{1 - C_{qN}}), `dis_jaccard` (\eqn{1 - U_{qN}}),
#' `dis_turnover_sorensen` (\eqn{1 - V_{qN}}) and `dis_turnover_jaccard`
#' (\eqn{1 - S_{qN}}). Classic indices are special cases:
#'
#' | Order | `dis_sorensen` | `dis_jaccard` |
#' |---|---|---|
#' | `q = 0` | Sorensen | Jaccard |
#' | `q = 1` | Horn | Horn |
#' | `q = 2` | Morisita-Horn | Regional overlap |
#'
#' With `weight = "equal"` (the default) each site's abundances are
#' turned into relative abundances before pooling, so a heavily sampled
#' site does not dominate the pair, and `q = 2` gives Morisita-Horn exactly.
#' With `weight = "size"` raw abundances are pooled, as in [beta_hill()]
#' and iNEXT.beta3D. At `q = 0` the weighting makes no difference.
#'
#' These are empirical values. Use [beta_hill()] to compare whole sets of
#' sites at a standardised sample coverage.
#'
#' @inheritParams beta_pair
#' @param q Orders of diversity, between 0 and 3 (non-negative numbers).
#' @param weight `"equal"` or `"size"`, as described above.
#' @return A `td_beta_hill_pair` tibble with the grouping columns,
#'   `site_1`, `site_2`, `q`, `gamma`, `alpha`, `beta` and the four
#'   `dis_` columns. [beta_dist()] turns one order into a distance matrix, and
#'   [ggplot2::autoplot()] draws it as a heatmap.
#' @references Chao, A., Chiu, C.-H. and Jost, L. (2014). Unifying species
#'   diversity, phylogenetic diversity, functional diversity, and related
#'   similarity and differentiation measures through Hill numbers. *Annual
#'   Review of Ecology, Evolution, and Systematics*, 45, 297-324.
#'   \doi{10.1146/annurev-ecolsys-120213-091540}
#'
#'   Jost, L. (2007). Partitioning diversity into independent alpha and beta
#'   components. *Ecology*, 88, 2427-2439. \doi{10.1890/06-1736.1}
#' @export
#' @examples
#' beta_hill_pair(png_ants, abundance = workers, .by = season)
beta_hill_pair <- function(data,
                           site = site,
                           species = species,
                           abundance = NULL,
                           q = c(0, 1, 2),
                           weight = c("equal", "size"),
                           .by = NULL) {
  weight <- rlang::arg_match(weight)
  if (!is.numeric(q) || length(q) == 0 || anyNA(q) || any(q < 0) ||
        !all(is.finite(q))) {
    cli::cli_abort("{.arg q} must be non-negative, finite numbers.")
  }
  call <- rlang::current_env()
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  out <- td_per_group(prep, function(d) {
    hill_pair_impl(d, q, weight, call = call)
  })
  td_new(out, "td_beta_hill_pair")
}

hill_pair_impl <- function(d, q, weight, call = caller_env()) {
  inc <- incidence_matrix(d, abundance = TRUE)
  mat <- inc$mat
  k <- nrow(mat)
  if (k < 2) {
    cli::cli_abort(
      "Beta diversity needs at least two sites in each group.",
      call = call
    )
  }
  if (weight == "equal") mat <- mat / rowSums(mat)
  ij <- utils::combn(k, 2)
  x <- mat[ij[1, ], , drop = FALSE]
  y <- mat[ij[2, ], , drop = FALSE]
  tot <- rowSums(x) + rowSums(y)
  px <- x / tot
  py <- y / tot
  pz <- px + py
  # Hill number of each row of a probability matrix (rows sum to 1, or to
  # 1 jointly with a second matrix for alpha).
  hill_rows <- function(p, qq, p2 = NULL) {
    f <- function(m) {
      if (qq == 1) {
        rowSums(ifelse(m > 0, -m * log(m), 0))
      } else {
        rowSums(ifelse(m > 0, m^qq, 0))
      }
    }
    s <- f(p) + if (is.null(p2)) 0 else f(p2)
    if (qq == 1) exp(s) else s^(1 / (1 - qq))
  }
  rows <- lapply(q, function(qq) {
    g <- hill_rows(pz, qq)
    a <- hill_rows(px, qq, py) / 2
    b <- g / a
    qv <- rep(qq, length(b))
    tibble::tibble(
      site_1 = vctrs::vec_slice(inc$sites, ij[1, ]),
      site_2 = vctrs::vec_slice(inc$sites, ij[2, ]),
      q = qq, gamma = g, alpha = a, beta = b,
      dis_sorensen = beta_dis(b, qv, 2, "C"),
      dis_jaccard = beta_dis(b, qv, 2, "U"),
      dis_turnover_sorensen = beta_dis(b, qv, 2, "V"),
      dis_turnover_jaccard = beta_dis(b, qv, 2, "S")
    )
  })
  out <- dplyr::bind_rows(rows)
  # Rounding can push identical sites a hair below zero.
  for (v in hill_pair_dis) out[[v]] <- pmin(pmax(out[[v]], 0), 1)
  out
}

hill_pair_dis <- c(
  "dis_sorensen", "dis_jaccard", "dis_turnover_sorensen",
  "dis_turnover_jaccard"
)
