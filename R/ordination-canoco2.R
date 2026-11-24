# nolint start: line_length_linter. Messages and tables read better unbroken.

#' Place new sites in an existing ordination (supplementary sites)
#'
#' CANOCO's supplementary samples: sites that did not take part in the
#' analysis are placed in its diagram from their species composition, as
#' weighted averages of the species scores ([vegan::predict.cca()] with
#' `type = "wa"`). Use it to show where new, disturbed or resurveyed sites
#' fall relative to the reference sites.
#'
#' @param x A `td_ordination` from a PCA, CA, RDA or CCA.
#' @param newdata Long community data for the new sites, with the same
#'   species (species not in the analysis are ignored).
#' @param site,species,abundance Columns of `newdata`, as in [ord_fit()].
#' @param axes Number of axes.
#' @return A tibble with `site` and the axis scores, in the scaling of the
#'   sites of `x`.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' d <- community_long(dune_species, cols = -site)
#' ref <- d[d$site %in% as.character(1:15), ]
#' new <- d[d$site %in% as.character(16:20), ]
#' o <- ord_fit(ref, abundance = abundance, method = "ca")
#' ord_predict(o, new, abundance = abundance)
ord_predict <- function(x, newdata, site = site, species = species, abundance = NULL, axes = 2) {
  if (!inherits(x, "td_ordination") || !x$method %in% c("pca", "ca", "rda", "cca")) {
    cli::cli_abort("{.fn ord_predict} needs a PCA, CA, RDA or CCA from {.fn ord_fit}.")
  }
  if (isTRUE(x$downweight)) {
    cli::cli_abort("Supplementary sites cannot be placed in an analysis with downweighting.")
  }
  prep <- td_prepare(newdata, enquo(site), enquo(species), enquo(abundance), rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  sp <- colnames(x$community)
  full <- matrix(0, nrow(y), length(sp), dimnames = list(rownames(y), sp))
  common <- intersect(colnames(y), sp)
  full[, common] <- y[, common]
  z <- ord_transform(full, x$transform)
  scl <- c(sites = 1L, species = 2L, symmetric = 3L)[[x$scaling]]
  sc <- stats::predict(x$fit, newdata = z, type = "wa", rank = axes, scaling = scl)
  out <- tibble::as_tibble(as.data.frame(sc))
  names(out) <- paste0("axis", seq_len(ncol(out)))
  tibble::add_column(out, site = rownames(z), .before = 1)
}

#' Canonical variate analysis (discriminant analysis)
#'
#' CANOCO's canonical variate analysis (CVA): the axes that best separate
#' predefined groups of sites by their species composition (linear
#' discriminant analysis, [MASS::lda()]). It needs fewer species than sites
#' minus groups; with more species, analyse the first axes of a PCA, or
#' species selected beforehand. The separation of the groups is tested by
#' permuting group labels, with the sum of the squared canonical
#' correlations (the Pillai trace) as statistic.
#'
#' @inheritParams ord_fit
#' @param group Name of the site variable defining the groups.
#' @param permutations Number of permutations.
#' @return A list of class `td_cva`: `sites` (site scores and group),
#'   `centroids` (group means on the axes), `axes` (eigenvalues, canonical
#'   correlations and the share of the separation per axis), `test` (a
#'   tibble with the statistic and p-value) and `fit` (the [MASS::lda()]
#'   object).
#' @references ter Braak, C. J. F. and Smilauer, P. (2012). *Canoco
#'   Reference Manual and User's Guide: Software for Ordination (version
#'   5.0)*. Microcomputer Power, Ithaca.
#' @export
#' @examplesIf rlang::is_installed("MASS")
#' v <- community_long(vare_species, cols = -site)
#' v <- v[v$species %in% c("Cladstel", "Cladrang", "Pleuschr", "Vaccviti", "Empenigr"), ]
#' env <- vare_env
#' env$humus <- ifelse(env$Humdepth > stats::median(env$Humdepth), "deep", "shallow")
#' ord_cva(v, abundance = abundance, group = "humus", env = env, permutations = 199)
ord_cva <- function(data, site = site, species = species, abundance = NULL, group,
                    env = NULL, transform = "none", permutations = 999) {
  rlang::check_installed("MASS", "for canonical variate analysis.")
  prep <- td_prepare(data, enquo(site), enquo(species), enquo(abundance), rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  e <- ord_env(data, env, prep$site, rownames(y), stats::reformulate(group))
  g <- factor(e[[group]])
  y <- ord_transform(y, transform)
  y <- y[, apply(y, 2, stats::var) > 0, drop = FALSE]
  if (ncol(y) >= nrow(y) - nlevels(g)) {
    cli::cli_abort(c(
      "CVA needs fewer species ({ncol(y)}) than sites minus groups ({nrow(y) - nlevels(g)}).",
      i = "Use the first axes of a PCA, or a selection of species."
    ))
  }
  fit <- MASS::lda(y, grouping = g)
  sc <- stats::predict(fit, y)$x
  pillai <- function(gg) {
    cc <- stats::cancor(y, stats::model.matrix(~ gg)[, -1, drop = FALSE])$cor
    sum(cc^2)
  }
  obs <- pillai(g)
  perm <- vapply(seq_len(permutations), function(i) pillai(sample(g)), 0)
  ev <- fit$svd^2
  cc <- stats::cancor(y, stats::model.matrix(~g)[, -1, drop = FALSE])$cor
  axes <- tibble::tibble(
    axis = colnames(sc), eigenvalue = ev, canonical_correlation = cc[seq_along(ev)],
    proportion = ev / sum(ev)
  )
  sites <- tibble::as_tibble(as.data.frame(sc))
  sites <- tibble::add_column(sites, site = rownames(y), group = g, .before = 1)
  cen <- stats::aggregate(sc, list(group = g), mean)
  structure(list(
    sites = sites, centroids = tibble::as_tibble(cen), axes = axes,
    test = tibble::tibble(statistic = obs, p.value = (sum(perm >= obs) + 1) / (permutations + 1),
                          permutations = permutations),
    fit = fit
  ), class = "td_cva")
}

#' @export
print.td_cva <- function(x, ...) {
  cli::cli_text("{.strong Canonical variate analysis} of {nrow(x$sites)} sites in {nrow(x$centroids)} groups")
  print(x$axes)
  cli::cli_text("Separation of the groups: Pillai trace {round(x$test$statistic, 3)}, p = {signif(x$test$p.value, 3)} ({x$test$permutations} permutations)")
  invisible(x)
}

#' Trait-environment analysis: double constrained correspondence analysis
#'
#' Double constrained correspondence analysis of CANOCO 5 (dc-CA; ter Braak
#' et al. 2018), fitted with [douconca::dc_CA()]: the axes are at the same
#' time combinations of site variables and of species traits, so they show
#' how traits respond to the environment. The relation is tested at both
#' levels (sites and species) and the larger p-value is reported (the
#' max test), which keeps the error rate right.
#'
#' @inheritParams ord_fit
#' @param traits A data frame of species traits, one row per species.
#' @param trait_formula,env_formula One-sided formulas of traits and of
#'   site variables.
#' @param trait_species Name of the species column of `traits`.
#' @param permutations Number of permutations.
#' @return A list of class `td_dcca`: `axes` (eigenvalues and share of the
#'   trait-environment inertia), `test` (site-level, species-level and max
#'   test) and `fit` (the `dcca` object).
#' @references ter Braak, C. J. F., Smilauer, P. and Dray, S. (2018).
#'   Algorithms and biplots for double constrained correspondence analysis.
#'   *Environmental and Ecological Statistics*, 25, 171-197.
#'   \doi{10.1007/s10651-017-0395-x}
#' @export
#' @examplesIf rlang::is_installed("douconca")
#' a <- data_aravo()
#' trait_dcca(a$community, abundance = cover, traits = a$traits,
#'   trait_formula = ~ Height + SLA, env_formula = ~ Snow + PhysD,
#'   permutations = 99)
trait_dcca <- function(data, site = site, species = species, abundance = NULL, traits,
                       trait_formula, env_formula, env = NULL, trait_species = "species",
                       permutations = 999) {
  rlang::check_installed("douconca", "for double constrained correspondence analysis.")
  prep <- td_prepare(data, enquo(site), enquo(species), enquo(abundance), rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  e <- as.data.frame(ord_env(data, env, prep$site, rownames(y), env_formula))
  tr <- as.data.frame(traits)
  rownames(tr) <- tr[[trait_species]]
  miss <- setdiff(colnames(y), rownames(tr))
  if (length(miss)) cli::cli_abort("Every species needs a row in {.arg traits}; missing {.val {utils::head(miss, 5)}}.")
  tr <- tr[colnames(y), , drop = FALSE]
  fit <- douconca::dc_CA(formulaEnv = env_formula, formulaTraits = trait_formula,
                         response = as.data.frame(y), dataEnv = e, dataTraits = tr, verbose = FALSE)
  a <- stats::anova(fit, permutations = permutations)
  row1 <- function(t, level) {
    t <- as.data.frame(t$table %||% t)
    tibble::tibble(level = level, statistic = t$F[1], p.value = t$`Pr(>F)`[1])
  }
  test <- rbind(row1(a$sites, "sites"), row1(a$species, "species"))
  test <- rbind(test, tibble::tibble(level = "max", statistic = NA_real_, p.value = max(test$p.value)))
  ev <- fit$eigenvalues
  structure(list(
    axes = tibble::tibble(axis = names(ev), eigenvalue = unname(ev), proportion = unname(ev / sum(ev))),
    test = test, fit = fit
  ), class = "td_dcca")
}

#' @export
print.td_dcca <- function(x, ...) {
  cli::cli_text("{.strong Double constrained correspondence analysis} (dc-CA)")
  print(x$axes)
  print(x$test)
  invisible(x)
}

#' Trait-environment analysis: RLQ
#'
#' RLQ analysis (Doledec et al. 1996; [ade4::rlq()]) finds the axes of
#' greatest co-variation between site variables (R), weighted by the
#' community table (L), and species traits (Q). It is tested with the
#' combined fourth-corner permutation models 2 and 4 (Dray et al. 2014):
#' permuting sites and permuting species; the larger p-value is reported.
#'
#' @inheritParams trait_dcca
#' @param env_vars,trait_vars Names of the site variables and the traits.
#' @return A list of class `td_rlq`: `axes`, `env_scores` (coefficients of
#'   site variables), `trait_scores` (coefficients of traits), `sites`,
#'   `species`, `test` and `fit`.
#' @references Doledec, S., Chessel, D., ter Braak, C. J. F. and Champely,
#'   S. (1996). Matching species traits to environmental variables: a new
#'   three-table ordination method. *Environmental and Ecological
#'   Statistics*, 3, 143-166.
#'
#'   Dray, S., Choler, P., Doledec, S. et al. (2014). Combining the
#'   fourth-corner and the RLQ methods for assessing trait responses to
#'   environmental variation. *Ecology*, 95, 14-21. \doi{10.1890/13-0196.1}
#' @export
#' @examplesIf rlang::is_installed("ade4")
#' a <- data_aravo()
#' trait_rlq(a$community, abundance = cover, traits = a$traits,
#'   env_vars = c("Snow", "PhysD", "Slope"), trait_vars = c("Height", "SLA"),
#'   permutations = 99)
trait_rlq <- function(data, site = site, species = species, abundance = NULL, traits,
                      env_vars, trait_vars, env = NULL, trait_species = "species",
                      permutations = 999) {
  rlang::check_installed("ade4", "for RLQ analysis.")
  prep <- td_prepare(data, enquo(site), enquo(species), enquo(abundance), rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  e <- as.data.frame(ord_env(data, env, prep$site, rownames(y), stats::reformulate(env_vars)))[env_vars]
  rownames(e) <- rownames(y)
  tr <- as.data.frame(traits)
  rownames(tr) <- tr[[trait_species]]
  tr <- tr[colnames(y), trait_vars, drop = FALSE]
  for (d in c("e", "tr")) {
    z <- get(d)
    for (i in seq_along(z)) if (is.character(z[[i]])) z[[i]] <- factor(z[[i]])
    assign(d, z)
  }
  # ade4's randtest() re-evaluates the stored calls of the three analyses,
  # so fit and test them in one environment that holds the tables.
  w <- new.env(parent = asNamespace("ade4"))
  w$tab_l <- as.data.frame(y)
  w$tab_r <- e
  w$tab_q <- tr
  w$nrepet <- permutations
  local(
    {
      dudi_l <- dudi.coa(tab_l, scannf = FALSE)
      dudi_r <- dudi.hillsmith(tab_r, row.w = dudi_l$lw, scannf = FALSE)
      dudi_q <- dudi.hillsmith(tab_q, row.w = dudi_l$cw, scannf = FALSE)
      fit <- rlq(dudi_r, dudi_l, dudi_q, scannf = FALSE, nf = 2)
      # models 2 and 4 separately: modeltype = 6 calls itself and then
      # cannot find the tables
      rt2 <- randtest(fit, modeltype = 2, nrepet = nrepet)
      rt4 <- randtest(fit, modeltype = 4, nrepet = nrepet)
    },
    envir = w
  )
  fit <- w$fit
  obs <- c(w$rt2$obs, w$rt4$obs)
  pv <- c(w$rt2$pvalue, w$rt4$pvalue)
  ev <- fit$eig
  tidy_sc <- function(m, id) {
    out <- tibble::as_tibble(as.data.frame(m))
    names(out) <- paste0("axis", seq_len(ncol(out)))
    out <- tibble::add_column(out, .id = rownames(m), .before = 1)
    names(out)[1] <- id
    out
  }
  structure(list(
    axes = tibble::tibble(axis = paste0("RLQ", seq_along(ev)), eigenvalue = ev, proportion = ev / sum(ev)),
    env_scores = tidy_sc(fit$l1, "variable"), trait_scores = tidy_sc(fit$c1, "trait"),
    sites = tidy_sc(fit$lR, "site"), species = tidy_sc(fit$lQ, "species"),
    test = tibble::tibble(model = c("2 (sites)", "4 (species)", "max"),
                          statistic = c(obs, NA), p.value = c(pv, max(pv))),
    fit = fit
  ), class = "td_rlq")
}

#' @export
print.td_rlq <- function(x, ...) {
  cli::cli_text("{.strong RLQ analysis}")
  print(utils::head(x$axes, 3))
  print(x$test)
  invisible(x)
}

#' Co-correspondence analysis
#'
#' CANOCO's co-correspondence analysis (ter Braak and Schaffers 2004;
#' [cocorresp::coca()]): relates two communities sampled at the same sites,
#' such as plants and insects. The *predictive* form explains one community
#' (`response`) from the other (`predictor`); the *symmetric* form finds
#' the axes the two share.
#'
#' @param response,predictor Long community data for the two communities.
#' @param site,species,abundance Columns, the same in both data sets.
#' @param method `"predictive"` or `"symmetric"`.
#' @param axes Number of axes for the predictive form.
#' @return A list of class `td_coca`: `axes` (the variance of the response
#'   community explained, predictive; or the eigenvalues, symmetric),
#'   `sites` (site scores of both communities) and `fit`.
#' @references ter Braak, C. J. F. and Schaffers, A. P. (2004).
#'   Co-correspondence analysis: a new ordination method to relate two
#'   community compositions. *Ecology*, 85, 834-846. \doi{10.1890/03-0021}
#' @export
ord_coca <- function(response, predictor, site = site, species = species, abundance = NULL,
                     method = c("predictive", "symmetric"), axes = 2) {
  rlang::check_installed("cocorresp", "for co-correspondence analysis.")
  method <- rlang::arg_match(method)
  mk <- function(d) {
    p <- td_prepare(d, enquo(site), enquo(species), enquo(abundance), rlang::quo(NULL))
    ord_matrix(p$data)
  }
  y <- mk(response)
  x <- mk(predictor)
  common <- intersect(rownames(y), rownames(x))
  if (length(common) < 3) cli::cli_abort("The two communities share fewer than 3 sites.")
  y <- as.data.frame(y[common, colSums(y[common, , drop = FALSE]) > 0, drop = FALSE])
  x <- as.data.frame(x[common, colSums(x[common, , drop = FALSE]) > 0, drop = FALSE])
  fit <- if (method == "predictive") {
    cocorresp::coca(y, x, method = "predictive", reg.method = "simpls", n.axes = axes, quiet = TRUE)
  } else {
    cocorresp::coca(y, x, method = "symmetric", quiet = TRUE)
  }
  ax <- if (method == "predictive") {
    v <- fit$varianceExp$Yblock
    tibble::tibble(axis = paste0("COCA", seq_along(v)), variance_explained = unname(v))
  } else {
    ev <- fit$lambda
    tibble::tibble(axis = paste0("COCA", seq_along(ev)), eigenvalue = unname(ev),
                   proportion = unname(ev / sum(ev)))
  }
  sc <- function(m, who) {
    m <- as.matrix(m)[, seq_len(min(axes, ncol(as.matrix(m)))), drop = FALSE]
    out <- tibble::as_tibble(as.data.frame(m))
    names(out) <- paste0("axis", seq_len(ncol(out)))
    tibble::add_column(out, site = common, community = who, .before = 1)
  }
  sites <- rbind(sc(fit$scores$site$Y, "response"), sc(fit$scores$site$X, "predictor"))
  structure(list(axes = ax, sites = sites, method = method, fit = fit), class = "td_coca")
}

#' @export
print.td_coca <- function(x, ...) {
  cli::cli_text("{.strong Co-correspondence analysis} ({x$method}) of {length(unique(x$sites$site))} sites")
  print(x$axes)
  invisible(x)
}

# nolint end
