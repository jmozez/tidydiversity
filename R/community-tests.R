# Shared preparation: long data -> site x species matrix (+ site variables).
comm_prep <- function(data, site, species, abundance, env, formula,
                      transform, call = caller_env()) {
  prep <- td_prepare(data, site, species, abundance, rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  env <- ord_env(data, env, prep$site, rownames(y), formula, call = call)
  list(
    y = ord_transform(y, transform), env = env, site_col = prep$site
  )
}

rhs_formula <- function(lhs, formula, env) {
  rhs <- paste(deparse(formula[[length(formula)]]), collapse = " ")
  f <- stats::as.formula(paste(lhs, "~", rhs))
  environment(f) <- env
  f
}

check_one_sided <- function(formula, arg = "formula", call = caller_env()) {
  if (!inherits(formula, "formula") || length(formula) != 2) {
    cli::cli_abort(
      "{.arg {arg}} must be a one-sided formula, such as {.code ~ elevation}.",
      call = call
    )
  }
}

#' PERMANOVA and dispersion tests on community composition
#'
#' `beta_permanova()` tests whether composition differs with site variables
#' using permutational multivariate analysis of variance
#' ([vegan::adonis2()], Anderson 2001). `beta_dispersion()` tests whether
#' groups differ in their spread (multivariate dispersion,
#' [vegan::betadisper()], Anderson 2006). PERMANOVA is sensitive to
#' differences in dispersion, so report both.
#'
#' Site variables are taken from the data when they are constant within
#' sites, as in [ord_fit()], or from `env`.
#'
#' @inheritParams ord_fit
#' @param formula One-sided formula of site variables, such as
#'   `~ elevation + season`.
#' @param by `"margin"` (the default: each term tested after all the
#'   others, so the result does not depend on the order of terms),
#'   `"terms"` (sequential: each term after those listed before it, so
#'   order matters when terms are correlated) or `"model"` (all terms
#'   together). Note that [vegan::adonis2()] defaults to `"terms"`; set
#'   `by = "terms"` to reproduce its default output.
#' @param strata Optional site variable (unquoted) within which to restrict
#'   permutations, for example a block or transect.
#' @return A tibble: one row per term, with `df`, `sum_sq`, `r2`,
#'   `statistic` (pseudo-F) and `p.value`.
#' @references Anderson, M. J. (2001). A new method for non-parametric
#'   multivariate analysis of variance. *Austral Ecology*, 26, 32-46.
#'   \doi{10.1111/j.1442-9993.2001.01070.pp.x}
#'
#'   Anderson, M. J. (2006). Distance-based tests for homogeneity of
#'   multivariate dispersions. *Biometrics*, 62, 245-253.
#'   \doi{10.1111/j.1541-0420.2005.00440.x}
#' @examplesIf rlang::is_installed("vegan")
#' ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
#' set.seed(1)
#' beta_permanova(ants, site = unit, formula = ~ elevation + season,
#'                permutations = 199)
#' beta_dispersion(ants, site = unit, group = season, permutations = 199)
#' @export
beta_permanova <- function(data,
                           site = site,
                           species = species,
                           abundance = NULL,
                           formula,
                           env = NULL,
                           distance = "bray",
                           transform = "none",
                           by = c("margin", "terms", "model"),
                           strata = NULL,
                           permutations = 999) {
  rlang::check_installed("vegan", "for PERMANOVA.")
  check_one_sided(formula)
  by <- rlang::arg_match(by)
  transform <- rlang::arg_match0(
    transform, c("none", "hellinger", "chord", "log", "sqrt", "pa"), "transform"
  )
  p <- comm_prep(
    data, enquo(site), enquo(species), enquo(abundance), env, formula,
    transform
  )
  strata_q <- enquo(strata)
  perm <- permutations
  if (!rlang::quo_is_null(strata_q)) {
    sv <- rlang::as_name(strata_q)
    if (!sv %in% names(p$env)) {
      cli::cli_abort("{.arg strata} must be a site variable.")
    }
    perm <- permute::how(
      nperm = permutations, blocks = factor(p$env[[sv]])
    )
  }
  y <- p$y
  env_df <- as.data.frame(p$env)
  f <- rhs_formula("y", formula, environment())
  res <- vegan::adonis2(f,
    data = env_df, method = distance, by = if (by == "model") NULL else by,
    permutations = perm
  )
  tab <- as.data.frame(res)
  tibble::tibble(
    term = rownames(tab),
    df = tab$Df,
    sum_sq = tab$SumOfSqs,
    r2 = tab$R2,
    statistic = tab$F,
    p.value = tab$`Pr(>F)`
  )
}

#' @rdname beta_permanova
#' @param group Site variable (unquoted) defining the groups.
#' @param type Distance to the group spatial `"median"` (the default, as
#'   in vegan) or `"centroid"`.
#' @return For `beta_dispersion()`, a tibble with one row per site
#'   (`group`, `distance` to its group centre) and the permutation test as
#'   attribute `"test"` (also printed). Use `autoplot()` to draw it.
#' @export
beta_dispersion <- function(data,
                            site = site,
                            species = species,
                            abundance = NULL,
                            group,
                            env = NULL,
                            distance = "bray",
                            transform = "none",
                            type = c("median", "centroid"),
                            permutations = 999) {
  rlang::check_installed("vegan", "for dispersion tests.")
  type <- rlang::arg_match(type)
  g <- rlang::as_name(enquo(group))
  p <- comm_prep(
    data, enquo(site), enquo(species), enquo(abundance), env,
    stats::as.formula(paste("~", g)), transform
  )
  d <- vegan::vegdist(p$y, method = distance)
  grp <- factor(p$env[[g]])
  bd <- vegan::betadisper(d, grp, type = type)
  pt <- vegan::permutest(bd, permutations = permutations)
  tt <- as.data.frame(pt$tab)
  test <- tibble::tibble(
    term = rownames(tt), df = tt$Df, sum_sq = tt$`Sum Sq`,
    statistic = tt$F, p.value = tt$`Pr(>F)`
  )
  out <- tibble::tibble(
    !!p$site_col := rownames(p$y),
    group = grp,
    distance = unname(bd$distances)
  )
  names(out)[2] <- g
  structure(out,
    test = test, group_col = g, centre = type, class = c("td_dispersion", class(out))
  )
}

#' @export
print.td_dispersion <- function(x, ...) {
  cat("Multivariate dispersion by", attr(x, "group_col"), "\n")
  print(tibble::as_tibble(unclass_td(x)), ...)
  cat("\nPermutation test:\n")
  print(attr(x, "test"))
  invisible(x)
}

unclass_td <- function(x) {
  attr(x, "test") <- NULL
  attr(x, "group_col") <- NULL
  attr(x, "centre") <- NULL
  class(x) <- setdiff(class(x), "td_dispersion")
  x
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_dispersion <- function(object, palette = "okabe_ito",
                                   theme = theme_tidydiversity(), ...) {
  rlang::check_installed("ggplot2", "to plot.")
  g <- attr(object, "group_col")
  test <- attr(object, "test")
  df <- unclass_td(object)
  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[[g]], y = .data$distance, fill = .data[[g]]
  )) +
    ggplot2::geom_boxplot(alpha = 0.4, outlier.shape = NA, width = 0.6) +
    ggplot2::geom_jitter(
      ggplot2::aes(colour = .data[[g]]), width = 0.1, height = 0, size = 2
    ) +
    ggplot2::labs(
      x = g, y = paste("Distance to group", attr(object, "centre")),
      caption = sprintf(
        "Permutation test: F = %.2f, p = %.3g",
        test$statistic[1], test$p.value[1]
      )
    ) +
    ggplot2::guides(fill = "none", colour = "none")
  td_style(p, palette, theme)
}

#' Variation partitioning
#'
#' Partitions the variation in community composition among two to four
#' groups of explanatory variables with adjusted R² (Borcard et al. 1992;
#' Peres-Neto et al. 2006), using [vegan::varpart()]. Fractions that are
#' testable (the unique fraction of each group) are tested by permutation
#' with partial RDA.
#'
#' @inheritParams ord_fit
#' @param ... Two to four one-sided formulas of site variables, named by
#'   group, e.g. `climate = ~ elevation, time = ~ season`.
#' @param transform Transformation before RDA; Hellinger by default.
#' @return A tibble of fractions with columns `fraction`, `label` (e.g.
#'   `"[a] climate only"`), `adj_r2`, `testable` and `p.value`.
#' @references Borcard, D., Legendre, P. and Drapeau, P. (1992). Partialling
#'   out the spatial component of ecological variation. *Ecology*, 73,
#'   1045-1055. \doi{10.2307/1940179}
#'
#'   Peres-Neto, P. R. et al. (2006). Variation partitioning of species
#'   data matrices: estimation and comparison of fractions. *Ecology*, 87,
#'   2614-2625. \doi{10.1890/0012-9658(2006)87[2614:VPOSDM]2.0.CO;2}
#' @examplesIf rlang::is_installed("vegan")
#' ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
#' set.seed(1)
#' ord_varpart(ants, site = unit,
#'             elevation = ~elevation, season = ~season,
#'             permutations = 199)
#' @export
ord_varpart <- function(data,
                        ...,
                        site = site,
                        species = species,
                        abundance = NULL,
                        env = NULL,
                        transform = "hellinger",
                        permutations = 999) {
  rlang::check_installed("vegan", "for variation partitioning.")
  forms <- list(...)
  if (length(forms) < 2 || length(forms) > 4) {
    cli::cli_abort("Supply two to four formulas in {.arg ...}.")
  }
  if (is.null(names(forms)) || any(names(forms) == "")) {
    names(forms) <- paste0("X", seq_along(forms))
  }
  for (f in forms) check_one_sided(f, "...")
  all_f <- stats::as.formula(
    paste("~", paste(unlist(lapply(forms, function(f) all.vars(f))),
      collapse = " + "
    ))
  )
  transform <- rlang::arg_match0(
    transform, c("none", "hellinger", "chord", "log", "sqrt", "pa"), "transform"
  )
  p <- comm_prep(
    data, enquo(site), enquo(species), enquo(abundance), env, all_f,
    transform
  )
  env_df <- as.data.frame(p$env)
  mats <- lapply(forms, function(f) {
    stats::model.matrix(f, env_df)[, -1, drop = FALSE]
  })
  vp <- do.call(vegan::varpart, c(list(p$y), unname(mats)))
  ind <- vp$part$indfract
  nm <- names(forms)
  k <- length(nm)
  labs <- varpart_labels(nm, nrow(ind))
  pvals <- rep(NA_real_, nrow(ind))
  for (i in seq_len(k)) {
    others <- do.call(cbind, mats[-i])
    rd <- vegan::rda(p$y, mats[[i]], others)
    pvals[i] <- vegan::anova.cca(rd, permutations = permutations)$`Pr(>F)`[1]
  }
  tibble::tibble(
    fraction = rownames(ind),
    label = labs,
    adj_r2 = ind$Adj.R.square,
    testable = ind$Testable,
    p.value = pvals
  )
}

varpart_labels <- function(nm, n) {
  k <- length(nm)
  if (k == 2) {
    c(
      paste(nm[1], "only"), paste(nm[2], "only"),
      paste("shared", nm[1], "&", nm[2]), "residual"
    )[seq_len(n)]
  } else {
    lab <- c(paste(nm, "only"))
    c(lab, rep("shared", n - k - 1), "residual")
  }
}

#' Forward selection of explanatory variables
#'
#' Selects site variables for RDA (or CCA, db-RDA) by forward selection
#' with the double stopping criterion of Blanchet et al. (2008): a variable
#' enters only if it is significant *and* the adjusted R² of the model stays
#' below that of the full model. Uses [vegan::ordiR2step()].
#'
#' @inheritParams ord_fit
#' @param formula One-sided formula of all candidate site variables.
#' @param method `"rda"`, `"cca"` or `"dbrda"`.
#' @param alpha Significance level for entry.
#' @return A tibble with one row per selected step: `step`, `term`,
#'   `adj_r2` (cumulative), `statistic` and `p.value`, and the adjusted R²
#'   of the full model as attribute `"adj_r2_full"`.
#' @references Blanchet, F. G., Legendre, P. and Borcard, D. (2008).
#'   Forward selection of explanatory variables. *Ecology*, 89, 2623-2632.
#'   \doi{10.1890/07-0986.1}
#' @examplesIf rlang::is_installed("vegan")
#' ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
#' set.seed(1)
#' ord_select(ants, site = unit, formula = ~ elevation + season,
#'            permutations = 199)
#' @export
ord_select <- function(data,
                       site = site,
                       species = species,
                       abundance = NULL,
                       formula,
                       env = NULL,
                       method = c("rda", "cca", "dbrda"),
                       transform = NULL,
                       distance = "bray",
                       alpha = 0.05,
                       permutations = 999) {
  rlang::check_installed("vegan", "for forward selection.")
  check_one_sided(formula)
  method <- rlang::arg_match(method)
  transform <- transform %||% if (method == "rda") "hellinger" else "none"
  p <- comm_prep(
    data, enquo(site), enquo(species), enquo(abundance), env, formula,
    transform
  )
  y <- p$y
  env_df <- as.data.frame(p$env)
  # vegan re-evaluates the stored call (`rda(...)`) in the formula's
  # environment, so provide the functions and data there.
  e <- new.env(parent = environment())
  e$rda <- vegan::rda
  e$cca <- vegan::cca
  e$dbrda <- vegan::dbrda
  e$y <- y
  e$env_df <- env_df
  extra <- if (method == "dbrda") list(distance = distance) else list()
  f0 <- y ~ 1
  environment(f0) <- e
  f1 <- rhs_formula("y", formula, e)
  fun <- as.name(method)
  m0 <- eval(as.call(c(list(fun, f0, data = quote(env_df)), extra)), e)
  m1 <- eval(as.call(c(list(fun, f1, data = quote(env_df)), extra)), e)
  sel <- vegan::ordiR2step(m0, scope = stats::formula(m1),
    Pin = alpha, permutations = permutations, trace = FALSE
  )
  a <- as.data.frame(sel$anova)
  full <- vegan::RsquareAdj(m1)$adj.r.squared
  if (nrow(a) == 0) {
    out <- tibble::tibble(
      step = integer(), term = character(), adj_r2 = double(),
      statistic = double(), p.value = double()
    )
  } else {
    a <- a[rownames(a) != "<All variables>", , drop = FALSE]
    out <- tibble::tibble(
      step = seq_len(nrow(a)),
      term = sub("^\\+ ", "", rownames(a)),
      adj_r2 = a$R2.adj,
      statistic = a$F,
      p.value = a$`Pr(>F)`
    )
  }
  attr(out, "adj_r2_full") <- full
  out
}

#' Indicator species analysis
#'
#' Finds species associated with groups of sites (Dufrene and Legendre
#' 1997; De Caceres et al. 2010) using [indicspecies::multipatt()], and
#' returns a tidy table.
#'
#' @inheritParams ord_fit
#' @param group Site variable (unquoted) defining the groups.
#' @param func `"IndVal.g"` (group-equalised indicator value, the default),
#'   `"IndVal"`, `"r.g"` or `"r"` (point-biserial correlation).
#' @param combinations Allow species to indicate combinations of groups?
#' @param adjust Correction for testing many species at once, passed to
#'   [stats::p.adjust()]: `"holm"` (the default, controls the family-wise
#'   error rate), `"fdr"` (false discovery rate) or `"none"`.
#' @param alpha Return only species with adjusted `p.adj <= alpha`; `1` for
#'   all.
#' @return A tibble with `species`, `group` (the group or combination the
#'   species indicates), `stat`, `A` (specificity) and `B` (fidelity; for
#'   IndVal only), the permutation `p.value` and the adjusted `p.adj`,
#'   sorted by group and decreasing `stat`.
#' @details Every species is tested, so with many species some reach
#'   `p.value < 0.05` by chance. Following De Caceres et al. (2010) and
#'   Legendre and Legendre (2012), p-values are corrected for multiple
#'   testing before species are selected.
#' @references Dufrene, M. and Legendre, P. (1997). Species assemblages and
#'   indicator species: the need for a flexible asymmetrical approach.
#'   *Ecological Monographs*, 67, 345-366.
#'   \doi{10.1890/0012-9615(1997)067[0345:SAAIST]2.0.CO;2}
#'
#'   De Caceres, M., Legendre, P. and Moretti, M. (2010). Improving
#'   indicator species analysis by combining groups of sites. *Oikos*, 119,
#'   1674-1684. \doi{10.1111/j.1600-0706.2010.18334.x}
#' @examplesIf rlang::is_installed("indicspecies")
#' ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect),
#'                       zone = ifelse(elevation <= 700, "lowland", "montane"))
#' set.seed(1)
#' beta_indicator(ants, site = unit, group = zone, permutations = 199)
#' @export
beta_indicator <- function(data,
                           site = site,
                           species = species,
                           abundance = NULL,
                           group,
                           env = NULL,
                           func = c("IndVal.g", "IndVal", "r.g", "r"),
                           combinations = FALSE,
                           adjust = "holm",
                           alpha = 0.05,
                           permutations = 999) {
  rlang::check_installed("indicspecies", "for indicator species analysis.")
  func <- rlang::arg_match(func)
  adjust <- rlang::arg_match0(adjust, stats::p.adjust.methods, "adjust")
  g <- rlang::as_name(enquo(group))
  p <- comm_prep(
    data, enquo(site), enquo(species), enquo(abundance), env,
    stats::as.formula(paste("~", g)), "none"
  )
  grp <- p$env[[g]]
  mp <- indicspecies::multipatt(as.data.frame(p$y), grp,
    func = func, duleg = !combinations,
    control = permute::how(nperm = permutations)
  )
  sg <- mp$sign
  gcols <- grep("^s\\.", names(sg), value = TRUE)
  levs <- sub("^s\\.", "", gcols)
  combo <- apply(sg[gcols], 1, function(r) paste(levs[r == 1], collapse = "+"))
  out <- tibble::tibble(
    species = rownames(sg),
    group = combo,
    stat = sg$stat,
    p.value = sg$p.value
  )
  if (func %in% c("IndVal.g", "IndVal")) {
    idx <- sg$index
    out$A <- mp$A[cbind(seq_len(nrow(sg)), idx)]
    out$B <- mp$B[cbind(seq_len(nrow(sg)), idx)]
    out <- out[c("species", "group", "stat", "A", "B", "p.value")]
  }
  out <- out[!is.na(out$p.value), , drop = FALSE]
  out$p.adj <- stats::p.adjust(out$p.value, method = adjust)
  out <- out[out$p.adj <= alpha, , drop = FALSE]
  out[order(out$group, -out$stat), , drop = FALSE]
}

#' Welch-type PERMANOVA robust to unequal dispersion
#'
#' Tests whether community composition differs among groups with the W*d
#' statistic of Hamidi et al. (2019), a distance-based generalisation of
#' Welch's ANOVA. Unlike classic PERMANOVA ([beta_permanova()]), it does
#' not assume that groups have the same multivariate dispersion, so a
#' significant result reflects a shift in location even when groups differ
#' in spread or size. For two groups it equals the Tw2 test of Alekseyenko
#' (2016). With one variable and Euclidean distance it equals Welch's
#' F statistic ([stats::oneway.test()] with `var.equal = FALSE`).
#'
#' The p-value is obtained by permuting group labels.
#'
#' @inheritParams beta_dispersion
#' @param permutations Number of permutations.
#' @return A one-row tibble with `statistic` (W*d), `n_groups`, `n_sites`
#'   and `p.value`.
#' @references Hamidi, B. et al. (2019). W*d-test: robust distance-based
#'   multivariate analysis of variance. *Microbiome*, 7, 51.
#'   \doi{10.1186/s40168-019-0659-9}
#'
#'   Alekseyenko, A. V. (2016). Multivariate Welch t-test on distances.
#'   *Bioinformatics*, 32, 3552-3558. \doi{10.1093/bioinformatics/btw524}
#' @examplesIf rlang::is_installed("vegan")
#' ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
#' set.seed(1)
#' beta_welch(ants, site = unit, group = season, permutations = 199)
#' @export
beta_welch <- function(data,
                       site = site,
                       species = species,
                       abundance = NULL,
                       group,
                       env = NULL,
                       distance = "bray",
                       transform = "none",
                       permutations = 999) {
  rlang::check_installed("vegan", "for community distances.")
  g <- rlang::as_name(enquo(group))
  transform <- rlang::arg_match0(
    transform, c("none", "hellinger", "chord", "log", "sqrt", "pa"), "transform"
  )
  p <- comm_prep(
    data, enquo(site), enquo(species), enquo(abundance), env,
    stats::as.formula(paste("~", g)), transform
  )
  d2 <- as.matrix(vegan::vegdist(p$y, method = distance))^2
  grp <- factor(p$env[[g]])
  if (nlevels(grp) < 2 || any(table(grp) < 2)) {
    cli::cli_abort("{.arg group} needs at least two groups of at least two sites.")
  }
  obs <- welch_wd(d2, grp)
  perm <- vapply(seq_len(permutations), function(i) {
    welch_wd(d2, sample(grp))
  }, numeric(1))
  tibble::tibble(
    statistic = obs, n_groups = nlevels(grp), n_sites = length(grp),
    p.value = (sum(perm >= obs) + 1) / (permutations + 1)
  )
}

# W*d (Hamidi et al. 2019) from a matrix of squared distances. For group i,
# SS_i = sum of within-group squared distances / n_i and s2_i = SS_i /
# (n_i - 1); the squared distance between centroids i and j is the mean
# cross-group squared distance minus SS_i / n_i and SS_j / n_j.
welch_wd <- function(d2, grp) {
  lev <- levels(grp)
  a <- length(lev)
  idx <- lapply(lev, function(l) which(grp == l))
  n <- lengths(idx)
  ss <- vapply(seq_len(a), function(i) {
    sum(d2[idx[[i]], idx[[i]]]) / (2 * n[i])
  }, numeric(1))
  s2 <- ss / (n - 1)
  w <- n / s2
  ww <- sum(w)
  num <- 0
  for (i in seq_len(a - 1)) {
    for (j in (i + 1):a) {
      cross <- mean(d2[idx[[i]], idx[[j]]])
      dc <- cross - ss[i] / n[i] - ss[j] / n[j]
      num <- num + w[i] * w[j] / ww * dc
    }
  }
  num <- num / (a - 1)
  den <- 1 + 2 * (a - 2) / (a^2 - 1) * sum((1 - w / ww)^2 / (n - 1))
  num / den
}
