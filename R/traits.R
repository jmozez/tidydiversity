# Trait-based methods, following de Bello et al. (2021) Handbook of
# Trait-Based Ecology (Cambridge University Press).

# ---- Internal helpers --------------------------------------------------------

# Species x trait data frame, rows named by species.
trait_frame <- function(traits, species, cols, call = caller_env()) {
  if (!is.data.frame(traits)) {
    cli::cli_abort("{.arg traits} must be a data frame.", call = call)
  }
  sp <- names(tidyselect::eval_select(species, traits))
  if (length(sp) != 1) {
    cli::cli_abort("{.arg species} must select one column of {.arg traits}.",
      call = call
    )
  }
  if (vctrs::vec_duplicate_any(traits[[sp]])) {
    cli::cli_abort("{.arg traits} must have one row per species.", call = call)
  }
  tcols <- names(tidyselect::eval_select(cols, traits))
  tcols <- setdiff(tcols, sp)
  if (length(tcols) == 0) {
    cli::cli_abort("No trait columns selected.", call = call)
  }
  out <- as.data.frame(traits[tcols])
  for (i in seq_along(out)) {
    if (is.character(out[[i]]) || is.logical(out[[i]])) {
      out[[i]] <- factor(out[[i]])
    }
  }
  rownames(out) <- as.character(traits[[sp]])
  out
}

# Community matrix (sites x species) matched to the trait table.
trait_comm <- function(data, site, species, abundance, traits, call) {
  prep <- td_prepare(data, site, species, abundance, rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  miss <- setdiff(colnames(y), rownames(traits))
  if (length(miss)) {
    cli::cli_abort(c(
      "Every species in {.arg data} needs a row in {.arg traits}.",
      "x" = "Missing: {.val {utils::head(miss, 5)}}{if (length(miss) > 5) ', ...'}."
    ), call = call)
  }
  list(y = y, traits = traits[colnames(y), , drop = FALSE], site_col = prep$site)
}

# CWM of each numeric trait (NA-aware) and proportion of each factor level.
cwm_matrix <- function(y, traits) {
  p <- y / rowSums(y)
  res <- list()
  for (tr in names(traits)) {
    x <- traits[[tr]]
    if (is.numeric(x)) {
      ok <- !is.na(x)
      w <- p[, ok, drop = FALSE]
      res[[tr]] <- as.vector(w %*% x[ok]) / rowSums(w)
    } else {
      x <- factor(x)
      for (lv in levels(x)) {
        ok <- !is.na(x)
        w <- p[, ok, drop = FALSE]
        res[[paste0(tr, "_", lv)]] <- as.vector(w %*% (x[ok] == lv)) / rowSums(w)
      }
    }
  }
  m <- do.call(cbind, res)
  rownames(m) <- rownames(y)
  m
}

# ---- Trait dissimilarity -----------------------------------------------------

#' Trait dissimilarity between species
#'
#' Computes functional dissimilarity between species from traits of any type
#' (numeric, ordinal, categorical, binary, with missing values). `"gower"`
#' uses Gower distance with Podani's extension ([FD::gowdis()]); `"gawdis"`
#' uses [gawdis::gawdis()], which weights traits so that each contributes
#' equally to the dissimilarity, an improvement on Gower when trait types
#' are mixed (de Bello et al. 2021).
#'
#' @param traits A data frame of traits, one row per species.
#' @param species <[`tidy-select`][dplyr::dplyr_tidy_select]> The column of
#'   species names.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Trait columns;
#'   all other columns by default.
#' @param method `"gower"` or `"gawdis"`.
#' @param groups For `"gawdis"`, an integer vector giving a group to each
#'   trait column, so that traits measuring the same thing (e.g. fuzzy-coded
#'   life forms) count as one.
#' @param ... Passed to [gawdis::gawdis()].
#' @return A `dist` object labelled with species names, usable as `dist` in
#'   [div_hill()] and other FD functions.
#' @references de Bello, F. et al. (2021). Towards a more balanced
#'   combination of multiple traits when computing functional differences
#'   between species. *Methods in Ecology and Evolution*, 12, 443-448.
#'   \doi{10.1111/2041-210X.13537}
#' @examplesIf rlang::is_installed(c("ade4", "FD"))
#' data(aravo, package = "ade4")
#' tr <- data.frame(species = rownames(aravo$traits), aravo$traits)
#' d <- trait_dist(tr)
#' as.matrix(d)[1:3, 1:3]
#' @export
trait_dist <- function(traits,
                       species = species,
                       cols = tidyselect::everything(),
                       method = c("gower", "gawdis"),
                       groups = NULL,
                       ...) {
  method <- rlang::arg_match(method)
  tr <- trait_frame(traits, enquo(species), enquo(cols))
  if (method == "gower") {
    rlang::check_installed("FD", "for Gower distance.")
    d <- FD::gowdis(tr)
  } else {
    rlang::check_installed("gawdis", "for balanced trait dissimilarity.")
    d <- gawdis::gawdis(tr, groups = groups, silent = TRUE, ...)
  }
  attr(d, "Labels") <- rownames(tr)
  d
}

# ---- CWM ---------------------------------------------------------------------

#' Community-weighted mean traits
#'
#' The abundance-weighted mean of each numeric trait in each site, and the
#' abundance-weighted proportion of each level of categorical traits
#' (Garnier et al. 2004; de Bello et al. 2021, ch. 5). Species with a
#' missing trait value are left out of that trait's mean, and the weights
#' of the remaining species are rescaled.
#'
#' @inheritParams ord_fit
#' @param traits A data frame of traits, one row per species, with a column
#'   whose name matches the `species` column of `data`.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Trait columns of
#'   `traits`.
#' @return A tibble with one row per site and trait: the site column,
#'   `trait` and `cwm`. Site variables (constant within sites) are kept.
#' @references Garnier, E. et al. (2004). Plant functional markers capture
#'   ecosystem properties during secondary succession. *Ecology*, 85,
#'   2630-2637. \doi{10.1890/03-0799}
#' @examplesIf rlang::is_installed("ade4")
#' aravo <- data_aravo()
#' trait_cwm(aravo$community, aravo$traits, abundance = cover)
#' @export
trait_cwm <- function(data,
                      traits,
                      site = site,
                      species = species,
                      abundance = NULL,
                      cols = tidyselect::everything()) {
  sp_name <- rlang::as_name(enquo(species))
  tr <- trait_frame(traits, rlang::sym(sp_name), enquo(cols))
  cm <- trait_comm(data, enquo(site), enquo(species), enquo(abundance), tr,
    call = environment()
  )
  m <- cwm_matrix(cm$y, cm$traits)
  out <- tibble::tibble(
    !!cm$site_col := rep(rownames(m), times = ncol(m)),
    trait = rep(colnames(m), each = nrow(m)),
    cwm = as.vector(m)
  )
  env <- ord_env(data, NULL, cm$site_col, rownames(m), NULL)
  if (!is.null(env) && ncol(env) > 1) {
    out <- dplyr::left_join(out, env, by = cm$site_col)
  }
  out
}

#' Test CWM-environment relationships with the max test
#'
#' Relating community-weighted means to site variables with an ordinary
#' test inflates Type I error, because CWMs of different sites share the
#' same species traits (Zeleny 2018; Peres-Neto et al. 2017). The *max
#' test* (ter Braak et al. 2012) combines a row-based permutation (shuffle
#' sites) with a column-based permutation (shuffle traits among species)
#' and reports the larger p-value. It controls Type I error whether the
#' null hypothesis concerns the environment or the traits.
#'
#' @inheritParams trait_cwm
#' @param env_vars <[`tidy-select`][dplyr::dplyr_tidy_select]> Numeric site
#'   variables in `data` (constant within sites) to test.
#' @param permutations Number of permutations.
#' @return A tibble with one row per numeric trait x variable: `trait`,
#'   `variable`, Pearson `r` between CWM and the variable, `p_row`,
#'   `p_col` and `p_max`.
#' @references Zeleny, D. (2018). Which results of the standard test for
#'   community-weighted mean approach are too optimistic? *Journal of
#'   Vegetation Science*, 29, 953-966. \doi{10.1111/jvs.12688}
#'
#'   ter Braak, C. J. F., Cormont, A. and Dray, S. (2012). Improved testing
#'   of species traits-environment relationships in the fourth-corner
#'   problem. *Ecology*, 93, 1525-1526. \doi{10.1890/12-0126.1}
#' @examplesIf rlang::is_installed("ade4")
#' aravo <- data_aravo()
#' set.seed(1)
#' trait_cwm_test(aravo$community, aravo$traits, abundance = cover,
#'             cols = c(Height, SLA), env_vars = Snow, permutations = 199)
#' @export
trait_cwm_test <- function(data,
                           traits,
                           env_vars,
                           site = site,
                           species = species,
                           abundance = NULL,
                           cols = tidyselect::everything(),
                           permutations = 999) {
  sp_name <- rlang::as_name(enquo(species))
  tr <- trait_frame(traits, rlang::sym(sp_name), enquo(cols))
  tr <- tr[vapply(tr, is.numeric, logical(1))]
  if (ncol(tr) == 0) {
    cli::cli_abort("{.fn trait_cwm_test} needs numeric traits.")
  }
  cm <- trait_comm(data, enquo(site), enquo(species), enquo(abundance), tr,
    call = environment()
  )
  env <- ord_env(data, NULL, cm$site_col, rownames(cm$y), NULL)
  ev <- names(tidyselect::eval_select(enquo(env_vars), env))
  if (length(ev) == 0 || !all(vapply(env[ev], is.numeric, logical(1)))) {
    cli::cli_abort("{.arg env_vars} must select numeric site variables.")
  }
  y <- cm$y
  out <- list()
  for (tn in names(cm$traits)) {
    x <- cm$traits[[tn]]
    ok <- !is.na(x)
    yy <- y[, ok, drop = FALSE]
    keep <- rowSums(yy) > 0
    yy <- yy[keep, , drop = FALSE]
    p <- yy / rowSums(yy)
    xx <- x[ok]
    cwm <- as.vector(p %*% xx)
    for (e in ev) {
      ee <- env[[e]][keep]
      r_obs <- stats::cor(cwm, ee)
      # All permutations at once: one matrix of permuted environments
      # (row-based test) and one of CWMs from permuted traits
      # (column-based test), each correlated in a single vectorised call.
      perm_e <- vapply(seq_len(permutations), function(i) sample(ee),
        numeric(length(ee))
      )
      perm_x <- vapply(seq_len(permutations), function(i) sample(xx),
        numeric(length(xx))
      )
      r_row <- as.vector(stats::cor(cwm, perm_e))
      r_col <- as.vector(stats::cor(p %*% perm_x, ee))
      p_row <- (sum(abs(r_row) >= abs(r_obs)) + 1) / (permutations + 1)
      p_col <- (sum(abs(r_col) >= abs(r_obs)) + 1) / (permutations + 1)
      out[[length(out) + 1]] <- tibble::tibble(
        trait = tn, variable = e, r = r_obs,
        p_row = p_row, p_col = p_col, p_max = max(p_row, p_col)
      )
    }
  }
  dplyr::bind_rows(out)
}

# ---- Functional diversity indices ---------------------------------------------

#' Classic functional diversity indices
#'
#' Functional richness (FRic), evenness (FEve), divergence (FDiv),
#' dispersion (FDis) and Rao's quadratic entropy (RaoQ) for each site
#' (Villeger et al. 2008; Laliberte and Legendre 2010), computed by
#' [FD::dbFD()] and returned as a tidy table. These complement the
#' Hill-number functional diversity of [div_hill()].
#'
#' @inheritParams trait_cwm
#' @param dist Optional species dissimilarity (e.g. from [trait_dist()]);
#'   computed with Gower distance from `traits` if `NULL`.
#' @param indices Indices to return.
#' @param m Number of PCoA axes for FRic and FDiv: `"max"` or `"min"` (see
#'   [FD::dbFD()]), or a number.
#' @return A tibble with the site column, `nbsp` (species richness),
#'   `index` and `value`.
#' @references Villeger, S., Mason, N. W. H. and Mouillot, D. (2008). New
#'   multidimensional functional diversity indices for a multifaceted
#'   framework in functional ecology. *Ecology*, 89, 2290-2301.
#'   \doi{10.1890/07-1206.1}
#'
#'   Laliberte, E. and Legendre, P. (2010). A distance-based framework for
#'   measuring functional diversity from multiple traits. *Ecology*, 91,
#'   299-305. \doi{10.1890/08-2244.1}
#' @examplesIf rlang::is_installed(c("ade4", "FD"))
#' aravo <- data_aravo()
#' trait_fd_indices(aravo$community, aravo$traits, abundance = cover,
#'               indices = c("FDis", "RaoQ"))
#' @export
trait_fd_indices <- function(data,
                             traits,
                             site = site,
                             species = species,
                             abundance = NULL,
                             cols = tidyselect::everything(),
                             dist = NULL,
                             indices = c("FRic", "FEve", "FDiv", "FDis", "RaoQ"),
                             m = "max") {
  rlang::check_installed("FD", "for functional diversity indices.")
  indices <- rlang::arg_match(indices, multiple = TRUE)
  sp_name <- rlang::as_name(enquo(species))
  tr <- trait_frame(traits, rlang::sym(sp_name), enquo(cols))
  cm <- trait_comm(data, enquo(site), enquo(species), enquo(abundance), tr,
    call = environment()
  )
  if (is.null(dist)) {
    dist <- FD::gowdis(cm$traits)
  } else {
    dm <- as.matrix(dist)
    dist <- stats::as.dist(dm[colnames(cm$y), colnames(cm$y)])
  }
  need_hull <- any(c("FRic", "FDiv") %in% indices)
  res <- suppressWarnings(utils::capture.output(fd <- FD::dbFD(
    dist, cm$y,
    calc.FRic = need_hull, calc.FDiv = need_hull, m = m,
    calc.CWM = FALSE, corr = "cailliez", messages = FALSE
  )))
  sites <- rownames(cm$y)
  out <- lapply(indices, function(ix) {
    tibble::tibble(
      !!cm$site_col := sites, nbsp = unname(fd$nbsp), index = ix,
      value = unname(fd[[ix]])
    )
  })
  dplyr::bind_rows(out)
}

#' Rao's quadratic entropy: alpha, beta and gamma functional diversity
#'
#' Partitions functional diversity across sites with Rao's quadratic
#' entropy, using the equivalent-numbers correction of de Bello et al.
#' (2010) so that beta = gamma / alpha and is not underestimated. Sites
#' are weighted equally. Dissimilarities are scaled to a maximum of 1.
#'
#' @inheritParams trait_fd_indices
#' @param dist Species dissimilarity; computed with Gower distance from
#'   `traits` if `NULL`. Use a dissimilarity of 1 between all species for
#'   taxonomic (Simpson) diversity.
#' @return A tibble with `component` (`"alpha"`, `"beta"`, `"gamma"`),
#'   `rao` (Rao's Q, for alpha and gamma) and `equivalent` (equivalent
#'   numbers, 1 / (1 - Q)), plus `beta_prop`, the proportional turnover
#'   `1 - alpha / gamma` (in equivalent numbers).
#' @references de Bello, F. et al. (2010). The partitioning of diversity:
#'   showing Theseus a way out of the labyrinth. *Journal of Vegetation
#'   Science*, 21, 992-1000. \doi{10.1111/j.1654-1103.2010.01195.x}
#' @examplesIf rlang::is_installed(c("ade4", "FD"))
#' aravo <- data_aravo()
#' trait_rao(aravo$community, aravo$traits, abundance = cover)
#' @export
trait_rao <- function(data,
                      traits = NULL,
                      site = site,
                      species = species,
                      abundance = NULL,
                      cols = tidyselect::everything(),
                      dist = NULL) {
  prep <- td_prepare(data, enquo(site), enquo(species), enquo(abundance),
    rlang::quo(NULL)
  )
  y <- ord_matrix(prep$data)
  spp <- colnames(y)
  if (is.null(dist)) {
    if (is.null(traits)) {
      cli::cli_abort("Supply {.arg traits} or {.arg dist}.")
    }
    rlang::check_installed("FD", "for Gower distance.")
    sp_name <- rlang::as_name(enquo(species))
    tr <- trait_frame(traits, rlang::sym(sp_name), enquo(cols))
    miss <- setdiff(spp, rownames(tr))
    if (length(miss)) {
      cli::cli_abort("Every species in {.arg data} needs a row in {.arg traits}.")
    }
    dm <- as.matrix(FD::gowdis(tr[spp, , drop = FALSE]))
  } else {
    dm <- as.matrix(dist)[spp, spp]
  }
  dm <- dm / max(dm)
  p <- y / rowSums(y)
  q_site <- rowSums((p %*% dm) * p)
  pg <- colMeans(p)
  q_gamma <- as.numeric(t(pg) %*% dm %*% pg)
  eq <- function(q) 1 / (1 - q)
  alpha_eq <- eq(mean(q_site))
  gamma_eq <- eq(q_gamma)
  tibble::tibble(
    component = c("alpha", "beta", "gamma"),
    rao = c(mean(q_site), NA, q_gamma),
    equivalent = c(alpha_eq, gamma_eq / alpha_eq, gamma_eq),
    beta_prop = c(NA, 1 - alpha_eq / gamma_eq, NA)
  )
}

# ---- Null models -------------------------------------------------------------

#' Standardised effect sizes from null models
#'
#' Compares an observed functional diversity index with its distribution
#' under a null model, to ask whether communities are more (divergence,
#' e.g. limiting similarity) or less (convergence, e.g. environmental
#' filtering) functionally diverse than expected by chance (de Bello et
#' al. 2021, ch. 7). SES = (observed - mean null) / sd null.
#'
#' Null models:
#' * `"traits"`: shuffle trait values among species (keeps every site's
#'   species richness and abundances; tests trait structure).
#' * `"richness"`: shuffle abundances among species within each site
#'   (keeps richness and the abundance distribution of each site).
#' * `"swap"`: independent swap of the site x species matrix, keeping
#'   site and species totals ([vegan::nullmodel()], `"quasiswap_count"`).
#'
#' @inheritParams trait_fd_indices
#' @param index Index to test: `"RaoQ"`, `"FDis"` or `"MPD"` (abundance-
#'   weighted mean pairwise dissimilarity).
#' @param null Null model, see Details.
#' @param times Number of randomisations.
#' @return A tibble with one row per site: `observed`, `null_mean`,
#'   `null_sd`, `ses` and `p.value` (two-sided rank-based).
#' @examplesIf rlang::is_installed(c("ade4", "FD"))
#' aravo <- data_aravo()
#' set.seed(1)
#' trait_ses(aravo$community, aravo$traits, abundance = cover, times = 49)
#' @export
trait_ses <- function(data,
                      traits,
                      site = site,
                      species = species,
                      abundance = NULL,
                      cols = tidyselect::everything(),
                      dist = NULL,
                      index = c("RaoQ", "FDis", "MPD"),
                      null = c("traits", "richness", "swap"),
                      times = 999) {
  index <- rlang::arg_match(index)
  null <- rlang::arg_match(null)
  sp_name <- rlang::as_name(enquo(species))
  tr <- trait_frame(traits, rlang::sym(sp_name), enquo(cols))
  cm <- trait_comm(data, enquo(site), enquo(species), enquo(abundance), tr,
    call = environment()
  )
  y <- cm$y
  spp <- colnames(y)
  if (is.null(dist)) {
    rlang::check_installed("FD", "for Gower distance.")
    dm <- as.matrix(FD::gowdis(cm$traits))
  } else {
    dm <- as.matrix(dist)[spp, spp]
  }
  fun <- switch(index,
    RaoQ = function(y, dm) {
      p <- y / rowSums(y)
      rowSums((p %*% dm) * p)
    },
    MPD = function(y, dm) {
      p <- y / rowSums(y)
      num <- rowSums((p %*% dm) * p)
      num / (1 - rowSums(p^2))
    },
    FDis = function(y, dm) fdis(y, dm)
  )
  obs <- fun(y, dm)
  sims <- switch(null,
    traits = lapply(seq_len(times), function(i) {
      o <- sample(spp)
      dd <- dm[o, o]
      dimnames(dd) <- dimnames(dm)
      fun(y, dd)
    }),
    richness = lapply(seq_len(times), function(i) {
      yy <- t(apply(y, 1, function(r) r[sample.int(length(r))]))
      dimnames(yy) <- dimnames(y)
      fun(yy, dm)
    }),
    swap = {
      rlang::check_installed("vegan", "for swap null models.")
      nm <- vegan::nullmodel(round(y), "quasiswap_count")
      s <- stats::simulate(nm, nsim = times)
      lapply(seq_len(times), function(i) fun(s[, , i], dm))
    }
  )
  sm <- do.call(cbind, sims)
  mu <- rowMeans(sm)
  sdv <- apply(sm, 1, stats::sd)
  lower <- rowSums(sm <= obs)
  upper <- rowSums(sm >= obs)
  pval <- pmin(1, 2 * (pmin(lower, upper) + 1) / (times + 1))
  tibble::tibble(
    !!cm$site_col := rownames(y), index = index, null = null,
    observed = unname(obs), null_mean = unname(mu), null_sd = unname(sdv),
    ses = unname((obs - mu) / sdv), p.value = unname(pval)
  )
}

# FDis (Laliberte and Legendre 2010), as in FD::fdisp() and FD::dbFD().
fdis <- function(y, dm) {
  rlang::check_installed("FD", "for FDis.")
  unname(FD::fdisp(stats::as.dist(dm), y)$FDis)
}

# ---- Intraspecific trait variability ----------------------------------------

#' Intra- and interspecific trait variability
#'
#' Decomposes variation in community trait means into the part caused by
#' species turnover (interspecific) and the part caused by trait change
#' within species (intraspecific), following Leps et al. (2011). It
#' compares the *specific* average (CWM from site-specific species means)
#' with the *fixed* average (CWM from species means over all sites).
#'
#' @inheritParams trait_cwm
#' @param traits A data frame of trait values measured per site: columns for
#'   site, species and the trait(s). Several rows per site and species
#'   (individuals) are averaged.
#' @param formula Optional one-sided formula of site variables. If given,
#'   the sums of squares are those explained by the formula; otherwise the
#'   total sums of squares are decomposed.
#' @return A tibble with one row per trait and component (`"turnover"`,
#'   `"intraspecific"`, `"covariation"`, `"total"`), the sum of squares
#'   `ss` and its share `prop` of the total.
#' @references Leps, J. et al. (2011). Community trait response to
#'   environment: disentangling species turnover vs intraspecific trait
#'   variability effects. *Ecography*, 34, 856-863.
#'   \doi{10.1111/j.1600-0587.2010.06904.x}
#' @export
trait_itv <- function(data,
                      traits,
                      site = site,
                      species = species,
                      abundance = NULL,
                      cols,
                      formula = NULL) {
  site_q <- enquo(site)
  sp_q <- enquo(species)
  prep <- td_prepare(data, site_q, sp_q, enquo(abundance), rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  s_col <- rlang::as_name(site_q)
  sp_col <- rlang::as_name(sp_q)
  if (!all(c(s_col, sp_col) %in% names(traits))) {
    cli::cli_abort(
      "{.arg traits} must have {.field {s_col}} and {.field {sp_col}} columns."
    )
  }
  tcols <- names(tidyselect::eval_select(enquo(cols), traits))
  tcols <- setdiff(tcols, c(s_col, sp_col))
  env <- ord_env(data, NULL, prep$site, rownames(y), formula)
  out <- list()
  for (tn in tcols) {
    tv <- traits[c(s_col, sp_col, tn)]
    names(tv) <- c(".s", ".sp", ".x")
    tv <- tv[!is.na(tv$.x), ]
    tv$.s <- as.character(tv$.s)
    site_mean <- stats::aggregate(.x ~ .s + .sp, tv, mean)
    fixed <- stats::aggregate(.x ~ .sp, tv, mean)
    spec <- fix <- numeric(nrow(y))
    for (i in seq_len(nrow(y))) {
      s <- rownames(y)[i]
      a <- y[i, y[i, ] > 0]
      sm <- site_mean[site_mean$.s == s, ]
      sp_ok <- intersect(names(a), sm$.sp)
      if (length(sp_ok) == 0) {
        spec[i] <- fix[i] <- NA
        next
      }
      w <- a[sp_ok] / sum(a[sp_ok])
      spec[i] <- sum(w * sm$.x[match(sp_ok, sm$.sp)])
      fix[i] <- sum(w * fixed$.x[match(sp_ok, fixed$.sp)])
    }
    itv <- spec - fix
    ss <- function(v) {
      ok <- !is.na(v)
      if (is.null(formula)) {
        sum((v[ok] - mean(v[ok]))^2)
      } else {
        d <- as.data.frame(env)[ok, , drop = FALSE]
        d$.v <- v[ok]
        f <- stats::as.formula(paste(".v ~", deparse(formula[[2]])))
        fit <- stats::fitted(stats::lm(f, d))
        sum((fit - mean(d$.v))^2)
      }
    }
    s_spec <- ss(spec)
    s_fix <- ss(fix)
    s_itv <- ss(itv)
    out[[tn]] <- tibble::tibble(
      trait = tn,
      component = c("turnover", "intraspecific", "covariation", "total"),
      ss = c(s_fix, s_itv, s_spec - s_fix - s_itv, s_spec),
      prop = c(s_fix, s_itv, s_spec - s_fix - s_itv, s_spec) / s_spec
    )
  }
  dplyr::bind_rows(out)
}

# ---- Fourth corner -------------------------------------------------------------

#' Fourth-corner analysis
#'
#' Tests every trait x environment association with the fourth-corner
#' method (Legendre et al. 1997; Dray and Legendre 2008) and the max test
#' (model 6, ter Braak et al. 2012), using [ade4::fourthcorner()], and
#' returns a tidy table.
#'
#' @inheritParams trait_cwm_test
#' @param adjust Method for adjusting p-values across all tests, passed
#'   to [stats::p.adjust()]; `"none"` for no adjustment.
#' @return A tibble with `trait`, `variable`, the test `statistic` (Pearson
#'   r for two numeric variables, otherwise as in ade4), `p.value` and
#'   `p.adj`.
#' @references Dray, S. and Legendre, P. (2008). Testing the species
#'   traits-environment relationships: the fourth-corner problem revisited.
#'   *Ecology*, 89, 3400-3412. \doi{10.1890/08-0349.1}
#' @examplesIf rlang::is_installed("ade4")
#' aravo <- data_aravo()
#' set.seed(1)
#' trait_fourth_corner(aravo$community, aravo$traits, abundance = cover,
#'                  cols = c(Height, SLA), env_vars = c(Snow, PhysD),
#'                  permutations = 199)
#' @export
trait_fourth_corner <- function(data,
                                traits,
                                env_vars,
                                site = site,
                                species = species,
                                abundance = NULL,
                                cols = tidyselect::everything(),
                                permutations = 999,
                                adjust = "fdr") {
  rlang::check_installed("ade4", "for fourth-corner analysis.")
  sp_name <- rlang::as_name(enquo(species))
  tr <- trait_frame(traits, rlang::sym(sp_name), enquo(cols))
  cm <- trait_comm(data, enquo(site), enquo(species), enquo(abundance), tr,
    call = environment()
  )
  env <- ord_env(data, NULL, cm$site_col, rownames(cm$y), NULL)
  ev <- names(tidyselect::eval_select(enquo(env_vars), env))
  if (length(ev) == 0) {
    cli::cli_abort("{.arg env_vars} must select site variables.")
  }
  e <- as.data.frame(env[ev])
  rownames(e) <- rownames(cm$y)
  fc <- ade4::fourthcorner(e, as.data.frame(cm$y), cm$traits,
    modeltype = 6, nrepet = permutations, p.adjust.method.G = "none",
    p.adjust.method.D = "none"
  )
  tab <- fc$tabD2
  res <- tibble::tibble(
    term = tab$names,
    statistic = unname(tab$obs),
    p.value = unname(tab$pvalue)
  )
  parts <- strsplit(res$term, " / ", fixed = TRUE)
  res$variable <- vapply(parts, `[`, character(1), 1)
  res$trait <- vapply(parts, `[`, character(1), 2)
  res$p.adj <- stats::p.adjust(res$p.value, method = adjust)
  res[c("trait", "variable", "statistic", "p.value", "p.adj")]
}

# ---- Example data ------------------------------------------------------------

#' Alpine plant communities with traits (aravo) in long format
#'
#' Converts the `aravo` data of the ade4 package (Choler 2005) into the
#' long format used by tidydiversity: 82 alpine plant species in 75 sites
#' in the Aravo valley (French Alps), with 6 site variables (including
#' snowmelt date, `Snow`, and physical disturbance, `PhysD`) and 8
#' functional traits. The data are loaded from ade4, not copied into
#' tidydiversity.
#'
#' @return A list with `community` (a tibble with `site`, `species`,
#'   `cover` (abundance class 0-5) and the site variables) and `traits` (a
#'   tibble with `species` and the 8 traits).
#' @references Choler, P. (2005). Consistent shifts in Alpine plant traits
#'   along a mesotopographical gradient. *Arctic, Antarctic, and Alpine
#'   Research*, 37, 444-453.
#'   \doi{10.1657/1523-0430(2005)037[0444:CSIAPT]2.0.CO;2}
#' @examplesIf rlang::is_installed("ade4")
#' aravo <- data_aravo()
#' aravo$community
#' aravo$traits
#' @export
data_aravo <- function() {
  rlang::check_installed("ade4", "for the aravo data.")
  e <- new.env()
  utils::data("aravo", package = "ade4", envir = e)
  a <- e$aravo
  spe <- as.matrix(a$spe)
  long <- tibble::tibble(
    site = rep(rownames(spe), times = ncol(spe)),
    species = rep(colnames(spe), each = nrow(spe)),
    cover = as.vector(spe)
  )
  long <- long[long$cover > 0, ]
  env <- tibble::as_tibble(a$env)
  env$site <- rownames(a$env)
  long <- dplyr::left_join(long, env, by = "site")
  traits <- tibble::as_tibble(a$traits)
  traits <- tibble::add_column(traits, species = rownames(a$traits), .before = 1)
  list(community = long, traits = traits)
}
