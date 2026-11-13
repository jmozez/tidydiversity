#' Ordination of community data
#'
#' Fits an unconstrained or constrained ordination to long community data
#' and returns its scores as tidy tibbles. The ordination itself is
#' computed by the vegan package, so results are identical to vegan's;
#' tidydiversity adds the data handling, site covariates, tidy output and
#' publication-quality plots ([autoplot()][autoplot.td_ordination]).
#'
#' Unconstrained methods summarise the main gradients in species
#' composition: principal components analysis (`"pca"`), correspondence
#' analysis (`"ca"`), detrended correspondence analysis (`"dca"`),
#' principal coordinates analysis (`"pcoa"`) of a dissimilarity, and
#' non-metric multidimensional scaling (`"nmds"`). Constrained methods
#' find the gradients explained by environmental variables: redundancy
#' analysis (`"rda"`), canonical correspondence analysis (`"cca"`) and
#' distance-based RDA (`"dbrda"`). Add `Condition(x)` to the formula for a
#' partial analysis that removes the effect of `x` first.
#'
#' For an unconstrained method, a `formula` fits the variables passively
#' with [vegan::envfit()], so they appear as supplementary arrows and
#' centroids (as in CANOCO) without changing the ordination.
#'
#' @inheritParams div_hill
#' @param method Ordination method; see Details.
#' @param formula A one-sided formula of site variables, such as
#'   `~ elevation + season`. Required for constrained methods; for
#'   unconstrained methods the variables are fitted passively.
#' @param env A data frame of site variables with a column named like the
#'   site column. By default, site variables are taken from `data`: every
#'   column that is constant within each site.
#' @param transform Transformation of the community matrix before the
#'   analysis: `"hellinger"` (the default for PCA and RDA, which
#'   otherwise overweight abundant species; Legendre and Gallagher 2001),
#'   `"chord"`, `"log"` (log(x) + 1 for x > 0), `"sqrt"`, `"pa"`
#'   (presence-absence) or `"none"` (the default for the other methods).
#' @param distance Dissimilarity for `"pcoa"`, `"nmds"` and `"dbrda"`,
#'   passed to [vegan::vegdist()], such as `"bray"` (the default) or
#'   `"jaccard"`.
#' @param scaling For PCA, CA, PCoA and the constrained methods, which
#'   scores to scale (ter Braak and Smilauer 2012): `"species"` (the
#'   default, vegan scaling 2) preserves the correlations between species
#'   and variables; `"sites"` (scaling 1) preserves the distances between
#'   sites; `"symmetric"` (scaling 3) is a compromise.
#' @param k For `"nmds"`, the number of dimensions.
#' @param permutations Permutations for the tests of passive variables: a
#'   number, or `"exact"` for complete enumeration of all n! orderings of
#'   the sites (feasible up to about 9 sites; with 7 sites, 5,040), which
#'   gives exact p-values.
#' @param choices Axes on which passive variables are fitted and tested,
#'   as in [vegan::envfit()]. The default, the first two, matches the
#'   biplot; the axes used are reported in the `envfit` table.
#' @param seed Optional random seed for the permutation tests.
#' @param ... Passed to the vegan function that fits the ordination.
#' @return A `td_ordination` object: a list with tibbles `sites` (site
#'   scores joined to the site variables), `species`, `vectors`
#'   (environmental arrows), `centroids` (factor levels) and `axes`
#'   (eigenvalues and proportion of variation explained), plus `stress`
#'   for NMDS, `envfit` for passive variables and `fit`, the vegan object.
#'   Use [tidy()][tidy.td_ordination] and [glance()][glance.td_ordination]
#'   to extract them and [ord_test()] for permutation tests.
#' @references Legendre, P. and Gallagher, E. D. (2001). Ecologically
#'   meaningful transformations for ordination of species data. Oecologia,
#'   129, 271-280. \doi{10.1007/s004420100716}
#'
#'   ter Braak, C. J. F. and Smilauer, P. (2012). Canoco reference manual
#'   and user's guide: software for ordination (version 5.0). Microcomputer
#'   Power, Ithaca, USA.
#'
#'   Oksanen, J. et al. vegan: Community Ecology Package.
#'   <https://CRAN.R-project.org/package=vegan>
#' @export
#' @examplesIf requireNamespace("vegan", quietly = TRUE)
#' # Tree-nesting ants: one sample per plot and subplot
#' ants <- png_tree_ants
#' ants$plot <- paste(ants$site, ants$subplot)
#'
#' # Constrained: how much of the composition does elevation explain?
#' ord <- ord_fit(ants,
#'   site = plot, abundance = nests, method = "rda", formula = ~elevation
#' )
#' ord
#' ord_test(ord)
#'
#' # Unconstrained NMDS with elevation fitted passively
#' nmds <- ord_fit(ants,
#'   site = plot, abundance = nests, method = "nmds", formula = ~elevation
#' )
#' tidy(nmds)
ord_fit <- function(data,
                    site = site,
                    species = species,
                    abundance = NULL,
                    method = c(
                      "pca", "ca", "dca", "pcoa", "nmds",
                      "rda", "cca", "dbrda"
                    ),
                    formula = NULL,
                    env = NULL,
                    transform = NULL,
                    distance = "bray",
                    scaling = c("species", "sites", "symmetric"),
                    k = 2,
                    permutations = 999,
                    choices = 1:2,
                    seed = NULL,
                    ...) {
  rlang::check_installed("vegan", "to fit ordinations.")
  if (!is.numeric(choices) || length(choices) < 1 || any(choices < 1) ||
        any(choices != round(choices))) {
    cli::cli_abort("{.arg choices} must be axis numbers, such as {.code 1:2}.")
  }
  if (!is.null(seed)) set.seed(seed)
  method <- rlang::arg_match(method)
  scaling <- rlang::arg_match(scaling)
  constrained <- method %in% c("rda", "cca", "dbrda")
  if (constrained && is.null(formula)) {
    cli::cli_abort(c(
      "{.code method = \"{method}\"} needs a {.arg formula} of site variables.",
      "i" = "For example {.code formula = ~ elevation}."
    ))
  }
  if (!is.null(formula) && !inherits(formula, "formula")) {
    cli::cli_abort("{.arg formula} must be a one-sided formula, such as {.code ~ elevation}.")
  }
  transform <- transform %||% if (method %in% c("pca", "rda")) "hellinger" else "none"
  transform <- rlang::arg_match0(
    transform, c("none", "hellinger", "chord", "log", "sqrt", "pa"), "transform"
  )

  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), rlang::quo(NULL)
  )
  y <- ord_matrix(prep$data)
  y_raw <- y
  site_col <- prep$site
  env <- ord_env(data, env, site_col, rownames(y), formula)
  y <- ord_transform(y, transform)

  scale_num <- c(sites = 1L, species = 2L, symmetric = 3L)[[scaling]]
  fit <- ord_vegan(method, y, formula, env, distance, k, ...)

  disp <- if (constrained) c("sites", "species", "bp", "cn") else c("sites", "species")
  n_ax <- ord_n_axes(fit, method)
  sc <- vegan::scores(fit,
    display = disp, choices = seq_len(min(n_ax, 3)),
    scaling = if (method %in% c("dca", "nmds")) NULL else scale_num,
    tidy = TRUE
  )
  sc <- tibble::as_tibble(sc)
  ax_cols <- setdiff(names(sc), c("score", "label", "weight"))
  axes <- ord_axes(fit, method, ax_cols)
  names(sc)[match(ax_cols, names(sc))] <- paste0("axis", seq_along(ax_cols))
  axis_cols <- paste0("axis", seq_along(ax_cols))

  sites <- sc[sc$score == "sites", c("label", axis_cols)]
  names(sites)[1] <- site_col
  if (!is.null(env)) {
    sites <- dplyr::left_join(sites, env, by = site_col)
  }
  species_sc <- sc[sc$score == "species", c("label", axis_cols)]
  names(species_sc)[1] <- "species"
  vectors <- sc[sc$score == "biplot", c("label", axis_cols)]
  names(vectors)[1] <- "term"
  centroids <- sc[sc$score == "centroids", c("label", axis_cols)]
  names(centroids)[1] <- "term"

  envfit <- NULL
  if (!constrained && !is.null(formula)) {
    ef <- ord_envfit(fit, env, formula, permutations, axis_cols, scale_num, method,
      choices = choices
    )
    vectors <- ef$vectors
    centroids <- ef$centroids
    envfit <- ef$table
  }
  centroids <- ord_split_levels(centroids, env, formula)

  structure(
    list(
      sites = sites, species = species_sc,
      vectors = vectors, centroids = centroids, axes = axes,
      method = method, constrained = constrained, scaling = scaling,
      transform = transform,
      distance = if (method %in% c("pcoa", "nmds", "dbrda")) distance else NA,
      stress = if (method == "nmds") fit$stress else NA_real_,
      envfit = envfit, site_col = site_col, fit = fit,
      community = y_raw, env = env, formula = formula
    ),
    class = "td_ordination"
  )
}

# ---- Helpers ----------------------------------------------------------------

ord_matrix <- function(d) {
  sites <- unique(as.character(d$.site))
  spp <- sort(unique(d$.species))
  m <- matrix(0, length(sites), length(spp), dimnames = list(sites, spp))
  m[cbind(match(as.character(d$.site), sites), match(d$.species, spp))] <- d$.n
  m
}

ord_transform <- function(y, transform) {
  switch(transform,
    none = y,
    hellinger = vegan::decostand(y, "hellinger"),
    chord = vegan::decostand(y, "normalize"),
    log = vegan::decostand(y, "log"),
    sqrt = sqrt(y),
    pa = (y > 0) * 1
  )
}

# Site variables: from `env`, or the columns of `data` constant within sites.
ord_env <- function(data, env, site_col, sites, formula, call = caller_env()) {
  if (is.null(env)) {
    cand <- setdiff(names(data), site_col)
    keep <- vapply(cand, function(cl) {
      tab <- vctrs::vec_unique(data[c(site_col, cl)])
      !vctrs::vec_duplicate_any(tab[[site_col]])
    }, logical(1))
    if (!any(keep)) {
      env <- NULL
    } else {
      env <- vctrs::vec_unique(tibble::as_tibble(dplyr::ungroup(data)[c(site_col, cand[keep])]))
    }
  } else {
    if (!is.data.frame(env) || !site_col %in% names(env)) {
      cli::cli_abort(
        "{.arg env} must be a data frame with a {.field {site_col}} column.",
        call = call
      )
    }
    env <- tibble::as_tibble(env)
    if (vctrs::vec_duplicate_any(env[[site_col]])) {
      cli::cli_abort("{.arg env} must have one row per site.", call = call)
    }
  }
  if (!is.null(env)) {
    env[[site_col]] <- as.character(env[[site_col]])
    env <- env[match(sites, env[[site_col]]), , drop = FALSE]
    env[[site_col]] <- sites
  }
  if (!is.null(formula)) {
    vars <- all.vars(formula)
    miss <- setdiff(vars, names(env))
    if (length(miss)) {
      cli::cli_abort(c(
        "Every variable in {.arg formula} must be a site variable.",
        "x" = "Not found or not constant within sites: {.field {miss}}.",
        "i" = "Supply them in {.arg env}, one row per site."
      ), call = call)
    }
    if (anyNA(env[vars])) {
      cli::cli_abort("The variables in {.arg formula} must not have missing values.",
        call = call
      )
    }
  }
  env
}

ord_vegan <- function(method, y, formula, env, distance, k, ...) {
  env_df <- if (is.null(env)) NULL else as.data.frame(env)
  rhs <- if (is.null(formula)) NULL else paste(deparse(formula[[length(formula)]]), collapse = " ")
  f <- if (is.null(rhs)) NULL else stats::as.formula(paste("y ~", rhs))
  if (!is.null(f)) environment(f) <- environment()
  switch(method,
    pca = vegan::rda(y, ...),
    ca = vegan::cca(y, ...),
    dca = vegan::decorana(y, ...),
    pcoa = {
      f0 <- y ~ 1
      environment(f0) <- environment()
      vegan::capscale(f0, distance = distance, ...)
    },
    nmds = vegan::metaMDS(y,
      distance = distance, k = k, trace = FALSE,
      autotransform = FALSE, ...
    ),
    rda = vegan::rda(f, data = env_df, ...),
    cca = vegan::cca(f, data = env_df, ...),
    dbrda = vegan::capscale(f, data = env_df, distance = distance, ...)
  )
}

ord_n_axes <- function(fit, method) {
  if (method == "nmds") {
    return(fit$ndim)
  }
  if (method == "dca") {
    return(4)
  }
  length(vegan::eigenvals(fit))
}

ord_axes <- function(fit, method, ax_cols) {
  if (method %in% c("nmds", "dca")) {
    eig <- if (method == "dca") unname(fit$evals[seq_along(ax_cols)]) else NA_real_
    return(tibble::tibble(
      axis = paste0("axis", seq_along(ax_cols)), name = ax_cols,
      eigenvalue = eig, explained = NA_real_
    ))
  }
  ev <- vegan::eigenvals(fit)
  tot <- if (method %in% c("pca", "ca", "pcoa")) sum(ev[ev > 0]) else fit$tot.chi
  tibble::tibble(
    axis = paste0("axis", seq_along(ax_cols)), name = ax_cols,
    eigenvalue = unname(ev[ax_cols]),
    explained = unname(ev[ax_cols]) / tot
  )
}

ord_envfit <- function(fit, env, formula, permutations, axis_cols, scale_num,
                       method, choices = 1:2) {
  vars <- all.vars(formula)
  choices <- choices[choices <= length(axis_cols)]
  if (length(choices) == 0) choices <- seq_along(axis_cols)
  perm <- ord_permutations(permutations, nrow(env))
  ef <- suppressMessages(vegan::envfit(fit, as.data.frame(env)[vars],
    permutations = perm$how, choices = choices,
    scaling = if (method %in% c("dca", "nmds")) NULL else scale_num
  ))
  axis_cols <- axis_cols[choices]
  vec <- vegan::scores(ef, "vectors")
  vectors <- if (is.null(vec)) {
    tibble::tibble(term = character())
  } else {
    v <- tibble::as_tibble(as.data.frame(vec), rownames = "term")
    names(v)[-1] <- axis_cols[seq_len(ncol(v) - 1)]
    v
  }
  fac <- vegan::scores(ef, "factors")
  centroids <- if (is.null(fac)) {
    tibble::tibble(term = character())
  } else {
    v <- tibble::as_tibble(as.data.frame(fac), rownames = "term")
    names(v)[-1] <- axis_cols[seq_len(ncol(v) - 1)]
    v
  }
  tab <- list()
  if (!is.null(ef$vectors)) {
    tab$v <- tibble::tibble(
      term = names(ef$vectors$r), type = "vector",
      r2 = unname(ef$vectors$r), p.value = unname(ef$vectors$pvals)
    )
  }
  if (!is.null(ef$factors)) {
    tab$f <- tibble::tibble(
      term = names(ef$factors$r), type = "factor",
      r2 = unname(ef$factors$r), p.value = unname(ef$factors$pvals)
    )
  }
  table <- dplyr::bind_rows(tab)
  if (nrow(table)) {
    table$axes <- paste(choices, collapse = ", ")
    table$permutations <- perm$n
    table$exact <- perm$exact
  }
  list(vectors = vectors, centroids = centroids, table = table)
}

# Permutation design: a number of random permutations, or complete
# enumeration ("exact") of all n! orderings of n sites.
ord_permutations <- function(permutations, n, call = caller_env()) {
  if (identical(permutations, "exact")) {
    if (n > 9) {
      cli::cli_abort(
        "{.code permutations = \"exact\"} needs 9 or fewer sites ({n}! orderings is too many).",
        call = call
      )
    }
    rlang::check_installed("permute", "for exact permutation tests.")
    how <- permute::how(complete = TRUE, maxperm = factorial(n) + 1)
    return(list(how = how, n = factorial(n) - 1, exact = TRUE))
  }
  if (!is.numeric(permutations) || length(permutations) != 1 || permutations < 0) {
    cli::cli_abort(
      "{.arg permutations} must be a number or {.val exact}.",
      call = call
    )
  }
  list(how = permutations, n = permutations, exact = FALSE)
}

# ---- Methods ------------------------------------------------------------------

method_label <- function(method) {
  c(
    pca = "PCA", ca = "CA", dca = "DCA", pcoa = "PCoA", nmds = "NMDS",
    rda = "RDA", cca = "CCA", dbrda = "db-RDA"
  )[[method]]
}

#' @export
print.td_ordination <- function(x, ...) {
  cli::cli_text("{.strong {method_label(x$method)}} of {nrow(x$sites)} sites and \\
    {nrow(x$species)} species")
  if (x$transform != "none") cli::cli_text("Transformation: {x$transform}")
  if (!is.na(x$distance)) cli::cli_text("Dissimilarity: {x$distance}")
  if (x$method == "nmds") {
    cli::cli_text("Stress: {format(round(x$stress, 3), nsmall = 3)}")
  }
  if (!all(is.na(x$axes$explained))) {
    ex <- paste0(x$axes$name, " ", round(100 * x$axes$explained, 1), "%")
    cli::cli_text("Variation explained: {paste(ex, collapse = ', ')}")
  }
  if (x$constrained) {
    tot <- x$fit$tot.chi
    con <- x$fit$CCA$tot.chi
    cli::cli_text("Constrained: {round(100 * con / tot, 1)}% of the total")
  }
  if (!is.null(x$envfit) && nrow(x$envfit)) {
    cli::cli_text("Passive variables (envfit):")
    print(x$envfit)
  }
  invisible(x)
}

#' Tidy and glance methods for ordinations
#'
#' `tidy()` returns one set of ordination scores as a tibble, and
#' `glance()` a one-row summary of the ordination.
#'
#' @param x A `td_ordination` from [ord_fit()].
#' @param display Scores to return: `"sites"`, `"species"`, `"vectors"`
#'   (environmental arrows), `"centroids"` (factor levels), `"axes"`
#'   (eigenvalues and variation explained) or `"envfit"` (fit of passive
#'   variables).
#' @param ... Not used.
#' @return A tibble.
#' @export
#' @examplesIf requireNamespace("vegan", quietly = TRUE)
#' ord <- ord_fit(png_frogs, method = "ca")
#' tidy(ord, "species")
#' glance(ord)
tidy.td_ordination <- function(x,
                               display = c(
                                 "sites", "species", "vectors",
                                 "centroids", "axes", "envfit"
                               ),
                               ...) {
  display <- rlang::arg_match(display)
  x[[display]] %||% tibble::tibble()
}

#' @rdname tidy.td_ordination
#' @export
glance.td_ordination <- function(x, ...) {
  constrained_prop <- if (x$constrained) x$fit$CCA$tot.chi / x$fit$tot.chi else NA_real_
  tibble::tibble(
    method = x$method, n_sites = nrow(x$sites), n_species = nrow(x$species),
    transform = x$transform, distance = x$distance, scaling = x$scaling,
    stress = x$stress, constrained = constrained_prop
  )
}

#' Permutation tests for constrained ordinations
#'
#' Tests the significance of a constrained ordination ([ord_fit()] with
#' `"rda"`, `"cca"` or `"dbrda"`) by permutation, with
#' [vegan::anova.cca()], and returns a tidy table.
#'
#' @param x A `td_ordination` from a constrained method.
#' @param by `"model"` (the whole model, the default), `"axis"` (each
#'   constrained axis), `"terms"` (each term, added sequentially) or
#'   `"margin"` (each term given the others).
#' @param permutations Number of permutations.
#' @return A tibble with `term`, `df`, `variance` (or `chi_square` for
#'   CCA), `statistic` (pseudo-F) and `p.value`.
#' @export
#' @examplesIf requireNamespace("vegan", quietly = TRUE)
#' ord <- ord_fit(png_frogs, method = "cca", formula = ~elevation)
#' ord_test(ord, permutations = 199)
ord_test <- function(x, by = c("model", "axis", "terms", "margin"),
                     permutations = 999) {
  if (!inherits(x, "td_ordination") || !x$constrained) {
    cli::cli_abort("{.arg x} must be a constrained ordination (rda, cca or dbrda).")
  }
  by <- rlang::arg_match(by)
  a <- vegan::anova.cca(x$fit,
    by = if (by == "model") NULL else by,
    permutations = permutations
  )
  a <- as.data.frame(a)
  stat_col <- intersect(c("Variance", "ChiSquare", "SumOfSqs"), names(a))[1]
  out <- tibble::tibble(
    term = rownames(a), df = a$Df,
    statistic = a$F, p.value = a[["Pr(>F)"]]
  )
  out[[if (stat_col == "ChiSquare") "chi_square" else "variance"]] <- a[[stat_col]]
  out[c(
    "term", "df", if (stat_col == "ChiSquare") "chi_square" else "variance",
    "statistic", "p.value"
  )]
}

# vegan labels factor centroids as variable name plus level ("yearYear 1").
# Split them into `variable` and `level`, and label plots with the level.
ord_split_levels <- function(centroids, env, formula) {
  if (!nrow(centroids) || is.null(formula)) {
    return(centroids)
  }
  vars <- all.vars(formula)
  vars <- vars[vapply(vars, function(v) !is.numeric(env[[v]]), logical(1))]
  centroids$variable <- NA_character_
  centroids$level <- centroids$term
  for (v in vars[order(-nchar(vars))]) {
    hit <- is.na(centroids$variable) & startsWith(centroids$term, v)
    centroids$variable[hit] <- v
    centroids$level[hit] <- substring(centroids$term[hit], nchar(v) + 1)
  }
  centroids
}
