#' Coverage-standardised beta diversity with Hill numbers
#'
#' Gamma, alpha and beta diversity of order q, standardised to a common
#' sample coverage, following Chao et al. (2023) (the iNEXT.beta3D
#' framework). Each `.by` group is a region whose sites are its
#' assemblages. Gamma diversity is the diversity of the pooled region;
#' alpha diversity is computed from the species-by-site abundances and
#' divided by the number of sites; each is rarefied or extrapolated to the
#' sample size at which it reaches the target coverage. Beta =
#' gamma / alpha is the effective number of completely distinct
#' assemblages (1 to N).
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
#' @inheritParams beta_pair
#' @param q Orders of diversity.
#' @param coverage Target sample coverage(s) in (0, 1]. By default, the
#'   lowest coverage that the pooled data of every region reaches at twice
#'   its sample size, so no region is extrapolated too far.
#' @return A tibble with the `.by` columns, `q`, `coverage`, the sample
#'   sizes `m_gamma` and `m_alpha`, `gamma`, `alpha`, `beta`, `n_sites`
#'   and the four dissimilarities.
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
                      .by = NULL) {
  td_check_q(q)
  if (!is.null(coverage) &&
        (!is.numeric(coverage) || any(coverage <= 0 | coverage > 1))) {
    cli::cli_abort("{.arg coverage} must be in (0, 1].")
  }
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  pieces <- beta_hill_pieces(prep)
  if (is.null(coverage)) {
    coverage <- min(vapply(pieces, function(p) {
      coverage_at_size(p$gamma, 2 * sum(p$gamma))
    }, numeric(1)))
  }
  td_per_group(prep, function(d) beta_hill_impl(d, q, coverage))
}

beta_hill_pieces <- function(prep) {
  groups <- if (length(prep$by) == 0) {
    list(prep$data)
  } else {
    vctrs::vec_split(prep$data, prep$data[prep$by])$val
  }
  lapply(groups, beta_hill_vectors)
}

# Pooled (gamma) and species-by-site (alpha) abundance vectors.
beta_hill_vectors <- function(d) {
  y <- ord_matrix(d)
  g <- colSums(y)
  a <- as.vector(y)
  list(gamma = g[g > 0], alpha = a[a > 0], n_sites = nrow(y))
}

beta_hill_impl <- function(d, q, coverage) {
  v <- beta_hill_vectors(d)
  n <- v$n_sites
  if (n < 2) {
    cli::cli_abort("Each region needs at least two sites.")
  }
  out <- lapply(coverage, function(cv) {
    mg <- size_for_coverage(v$gamma, cv)
    ma <- size_for_coverage(v$alpha, cv)
    gam <- as.vector(hill_at_size(v$gamma, mg, q))
    alp <- as.vector(hill_at_size(v$alpha, ma, q)) / n
    bet <- gam / alp
    tibble::tibble(
      q = q, coverage = cv, m_gamma = mg, m_alpha = ma,
      gamma = gam, alpha = alp, beta = bet, n_sites = n,
      dis_sorensen = beta_dis(bet, q, n, "C"),
      dis_jaccard = beta_dis(bet, q, n, "U"),
      dis_turnover_sorensen = beta_dis(bet, q, n, "V"),
      dis_turnover_jaccard = beta_dis(bet, q, n, "S")
    )
  })
  dplyr::bind_rows(out)
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
