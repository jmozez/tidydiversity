# Trait probability densities and phylogenetic methods, following
# de Bello et al. (2021) Handbook of Trait-Based Ecology, chapters 6 and 8.

# ---- Trait probability densities ---------------------------------------------

#' Functional diversity from trait probability densities
#'
#' The trait probability density (TPD) approach (Carmona et al. 2016,
#' 2019) describes each species by the probability density of its trait
#' values, estimated from individual measurements, so intraspecific
#' variability is part of every index. Community TPDs are the
#' abundance-weighted sums of species TPDs. From them, `trait_tpd()` returns
#' functional richness, evenness and divergence ([TPD::REND()]) and
#' functional redundancy ([TPD::redundancy()]) per site, and
#' `trait_tpd_dissim()` returns pairwise functional dissimilarity between
#' sites, split into shared and non-shared parts ([TPD::dissim()]).
#'
#' @inheritParams trait_cwm
#' @param traits A data frame with one row per measured individual: a
#'   species column (named as in `data`) and one to four numeric trait
#'   columns. Traits are often log-transformed first.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> The trait
#'   columns (one to four).
#' @param alpha Proportion of the probability density kept for each
#'   species (removes outliers).
#' @param n_divisions Number of grid divisions per trait axis; defaults to
#'   those of [TPD::TPDs()].
#' @return `trait_tpd()`: a tibble with the site column, `FRic`, `FEve`,
#'   `FDiv` and `redundancy`. `trait_tpd_dissim()`: a tibble of site pairs
#'   with `dissimilarity`, its parts due to shared (`p_shared`) and
#'   non-shared (`p_nonshared`) trait space.
#' @references Carmona, C. P. et al. (2016). Traits without borders:
#'   integrating functional diversity across scales. *Trends in Ecology &
#'   Evolution*, 31, 382-394. \doi{10.1016/j.tree.2016.02.003}
#'
#'   Carmona, C. P. et al. (2019). Trait probability density (TPD):
#'   measuring functional diversity across scales based on TPD with R.
#'   *Ecology*, 100, e02876. \doi{10.1002/ecy.2876}
#' @export
trait_tpd <- function(data,
                      traits,
                      site = site,
                      species = species,
                      abundance = NULL,
                      cols,
                      alpha = 0.95,
                      n_divisions = NULL) {
  tc <- tpd_community(
    data, traits, enquo(site), enquo(species), enquo(abundance),
    enquo(cols), alpha, n_divisions
  )
  cm <- tc$comm
  occ <- cm > 0
  fric <- unname(rowSums(occ)) * tc$cell_volume
  feve <- vapply(seq_len(nrow(cm)), function(i) {
    v <- cm[i, occ[i, ]]
    sum(pmin(v, 1 / length(v)))
  }, numeric(1))
  fdiv <- vapply(seq_len(nrow(cm)), function(i) {
    g <- tc$grid[occ[i, ], , drop = FALSE]
    rng <- apply(g, 2, range)
    g <- sweep(sweep(g, 2, rng[1, ]), 2, rng[2, ] - rng[1, ], "/")
    d <- sqrt(rowSums(sweep(g, 2, colMeans(g))^2))
    md <- mean(d)
    v <- cm[i, occ[i, ]]
    (sum(v * (d - md)) + md) / (sum(v * abs(d - md)) + md)
  }, numeric(1))
  # Number of species of the site occupying each cell, weighted by the
  # community density (Carmona et al. 2019).
  m <- (tc$p > 0) %*% (tc$species_tpd > 0)
  red <- rowSums(m * cm) - 1
  tibble::tibble(
    !!tc$site_col := rownames(cm),
    FRic = fric, FEve = feve, FDiv = fdiv, redundancy = unname(red)
  )
}

#' @rdname trait_tpd
#' @export
trait_tpd_dissim <- function(data,
                             traits,
                             site = site,
                             species = species,
                             abundance = NULL,
                             cols,
                             alpha = 0.95,
                             n_divisions = NULL) {
  tc <- tpd_community(
    data, traits, enquo(site), enquo(species), enquo(abundance),
    enquo(cols), alpha, n_divisions
  )
  cm <- tc$comm
  n <- nrow(cm)
  pairs <- utils::combn(n, 2)
  res <- apply(pairs, 2, function(ij) {
    a <- cm[ij[1], ]
    b <- cm[ij[2], ]
    o <- sum(pmin(a, b))
    sh <- a > 0 & b > 0
    aa <- sum(pmax(a[sh], b[sh])) - o
    bb <- sum(a[a > 0 & b == 0])
    cc <- sum(b[a == 0 & b > 0])
    pn <- if (1 - o == 0) NA_real_ else 2 * min(bb, cc) / (aa + 2 * min(bb, cc))
    c(1 - o, 1 - pn, pn)
  })
  tibble::tibble(
    site_1 = rownames(cm)[pairs[1, ]],
    site_2 = rownames(cm)[pairs[2, ]],
    dissimilarity = res[1, ],
    p_shared = res[2, ],
    p_nonshared = res[3, ]
  )
}

# Species TPDs from TPD::TPDs() (kernel density estimation with ks), then
# community TPDs by matrix algebra: sites x cells = relative abundances
# (sites x species) %*% species TPDs (species x cells).
tpd_community <- function(data, traits, site, species, abundance, cols,
                          alpha, n_divisions, call = caller_env()) {
  rlang::check_installed("TPD", "for trait probability densities.")
  prep <- td_prepare(data, site, species, abundance, rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  sp_col <- rlang::as_name(species)
  if (!sp_col %in% names(traits)) {
    cli::cli_abort("{.arg traits} needs a {.field {sp_col}} column.",
      call = call
    )
  }
  tcols <- setdiff(names(tidyselect::eval_select(cols, traits)), sp_col)
  if (length(tcols) < 1 || length(tcols) > 4) {
    cli::cli_abort("Select one to four trait columns in {.arg cols}.",
      call = call
    )
  }
  if (!all(vapply(traits[tcols], is.numeric, logical(1)))) {
    cli::cli_abort("TPD traits must be numeric.", call = call)
  }
  tr <- as.data.frame(traits[c(sp_col, tcols)])
  tr <- tr[stats::complete.cases(tr), , drop = FALSE]
  tr[[sp_col]] <- as.character(tr[[sp_col]])
  y <- y[, colnames(y) %in% tr[[sp_col]], drop = FALSE]
  if (ncol(y) == 0) {
    cli::cli_abort("No species of {.arg data} has trait measurements.",
      call = call
    )
  }
  y <- y[rowSums(y) > 0, , drop = FALSE]
  y <- y[, colSums(y) > 0, drop = FALSE]
  tr <- tr[tr[[sp_col]] %in% colnames(y), , drop = FALSE]
  n_per <- table(tr[[sp_col]])
  if (any(n_per < 3)) {
    cli::cli_abort(c(
      "Each species needs at least 3 measured individuals for a TPD.",
      "x" = "Too few: {.val {names(n_per)[n_per < 3]}}."
    ), call = call)
  }
  args <- list(species = tr[[sp_col]], traits = tr[tcols], alpha = alpha)
  if (!is.null(n_divisions)) {
    args$n_divisions <- n_divisions
  }
  tpds <- quiet_tpd(do.call(TPD::TPDs, args))
  spp <- colnames(y)
  s <- do.call(rbind, tpds$TPDs[spp])
  p <- y / rowSums(y)
  list(
    comm = p %*% s, p = p, species_tpd = s,
    grid = as.matrix(tpds$data$evaluation_grid),
    cell_volume = tpds$data$cell_volume, site_col = prep$site
  )
}

quiet_tpd <- function(expr) {
  out <- NULL
  utils::capture.output(out <- suppressMessages(expr))
  out
}

# ---- Phylogenetic signal -----------------------------------------------------

#' Phylogenetic signal of traits
#'
#' Measures how strongly closely related species resemble each other in
#' each trait, with Blomberg's K (Blomberg et al. 2003) or Pagel's lambda
#' (Pagel 1999), using [phytools::phylosig()]. K = 1 and lambda = 1 match
#' Brownian-motion evolution; values near 0 mean no phylogenetic signal.
#'
#' @param traits A data frame with a species column and numeric traits.
#' @param tree A phylogeny of class `phylo` (ape); tip labels must match
#'   species names.
#' @param species <[`tidy-select`][dplyr::dplyr_tidy_select]> The species
#'   column of `traits`.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Numeric trait
#'   columns.
#' @param method `"K"` or `"lambda"`.
#' @param nsim Number of randomisations for the test of K.
#' @return A tibble with `trait`, `method`, `n_species` (with data and in
#'   the tree), `statistic` and `p.value` (randomisation test for K,
#'   likelihood-ratio test against lambda = 0 for lambda).
#' @references Blomberg, S. P., Garland, T. and Ives, A. R. (2003).
#'   Testing for phylogenetic signal in comparative data: behavioral traits
#'   are more labile. *Evolution*, 57, 717-745.
#'   \doi{10.1111/j.0014-3820.2003.tb00285.x}
#'
#'   Pagel, M. (1999). Inferring the historical patterns of biological
#'   evolution. *Nature*, 401, 877-884. \doi{10.1038/44766}
#' @export
phylo_signal <- function(traits,
                         tree,
                         species = species,
                         cols = tidyselect::everything(),
                         method = c("K", "lambda"),
                         nsim = 999) {
  method <- rlang::arg_match(method)
  rlang::check_installed(
    if (method == "K") "ape" else c("ape", "phytools"),
    "for phylogenetic signal."
  )
  if (!inherits(tree, "phylo")) {
    cli::cli_abort("{.arg tree} must be a {.cls phylo} object.")
  }
  tr <- trait_frame(traits, enquo(species), enquo(cols))
  tr <- tr[vapply(tr, is.numeric, logical(1))]
  out <- lapply(names(tr), function(tn) {
    x <- tr[[tn]]
    names(x) <- rownames(tr)
    x <- x[!is.na(x) & names(x) %in% tree$tip.label]
    if (length(x) < 4) {
      cli::cli_abort(
        "Trait {.field {tn}} has fewer than 4 species in the tree."
      )
    }
    tt <- ape::keep.tip(tree, names(x))
    x <- x[tt$tip.label]
    res <- if (method == "K") {
      blomberg_k(tt, x, nsim)
    } else {
      ps <- phytools::phylosig(tt, x, method = "lambda", test = TRUE)
      c(ps$lambda, ps$P)
    }
    tibble::tibble(
      trait = tn, method = method, n_species = length(x),
      statistic = unname(res[1]), p.value = unname(res[2])
    )
  })
  dplyr::bind_rows(out)
}

#' Phylogenetic distances between species
#'
#' Cophenetic (patristic) distances from a phylogeny, scaled to a maximum
#' of 1 by default. Use them as `dist` in [trait_rao()], [trait_ses()] or
#' [trait_fd_indices()] to measure phylogenetic instead of functional
#' diversity, or combine them with trait distances in
#' [phylo_combine_dist()].
#'
#' @inheritParams phylo_signal
#' @param scale Scale distances to a maximum of 1?
#' @return A `dist` object labelled by tip labels.
#' @export
phylo_dist <- function(tree, scale = TRUE) {
  rlang::check_installed("ape", "for phylogenetic distances.")
  if (!inherits(tree, "phylo")) {
    cli::cli_abort("{.arg tree} must be a {.cls phylo} object.")
  }
  m <- ape::cophenetic.phylo(tree)
  if (scale) {
    m <- m / max(m)
  }
  stats::as.dist(m)
}

#' Combine functional and phylogenetic distances
#'
#' Combines a functional and a phylogenetic dissimilarity into one, as
#' `sqrt(w * F^2 + (1 - w) * P^2)` after scaling each to a maximum of 1
#' (the approach of Cadotte et al. 2013 and de Bello et al. 2017). Only
#' species present in both are kept.
#'
#' @param functional,phylogenetic `dist` objects labelled by species.
#' @param weight Weight `w` of the functional part, between 0 and 1.
#' @return A `dist` object.
#' @references Cadotte, M. W. et al. (2013). The ecology of differences:
#'   assessing community assembly with trait and evolutionary distances.
#'   *Ecology Letters*, 16, 1234-1244. \doi{10.1111/ele.12161}
#' @export
phylo_combine_dist <- function(functional, phylogenetic, weight = 0.5) {
  if (!is.numeric(weight) || length(weight) != 1 || weight < 0 ||
        weight > 1) {
    cli::cli_abort("{.arg weight} must be a single number between 0 and 1.")
  }
  f <- as.matrix(functional)
  p <- as.matrix(phylogenetic)
  sp <- intersect(rownames(f), rownames(p))
  if (length(sp) < 2) {
    cli::cli_abort("The two distances share fewer than 2 species.")
  }
  f <- f[sp, sp] / max(f[sp, sp])
  p <- p[sp, sp] / max(p[sp, sp])
  stats::as.dist(sqrt(weight * f^2 + (1 - weight) * p^2))
}

# Blomberg's K. The tree-dependent parts (GLS weights of the root state and
# the expected mean-square ratio under Brownian motion) are computed once;
# each randomisation then needs only phylogenetic independent contrasts
# (ape::pic, linear time), so tests with many randomisations are fast.
# Identical to phytools::phylosig(method = "K").
blomberg_k <- function(tree, x, nsim) {
  n <- length(x)
  bt <- ape::multi2di(tree, random = FALSE)
  cv <- ape::vcv.phylo(tree)
  w <- solve(cv, rep(1, n))
  sw <- sum(w)
  w <- w / sw
  expct <- (sum(diag(cv)) - n / sw) / (n - 1)
  tips <- tree$tip.label
  kfun <- function(v) {
    names(v) <- tips
    a <- sum(w * v)
    mse0 <- sum((v - a)^2)
    mse <- sum(ape::pic(v, bt, scaled = TRUE)^2)
    (mse0 / mse) / expct
  }
  k <- kfun(x)
  sims <- vapply(seq_len(nsim), function(i) kfun(sample(x)), numeric(1))
  c(k, (sum(sims >= k) + 1) / (nsim + 1))
}
