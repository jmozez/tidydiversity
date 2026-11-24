#' Restricted permutation designs
#'
#' @description
#' Describes how sites may be shuffled in a permutation test when they are
#' not independent, as the permutation options of CANOCO do. Give the
#' result as `design` to [ord_test()], [ord_select()] or [ord_effects()].
#'
#' * **Blocks** (`blocks`): sites are shuffled only within blocks, never
#'   between them. Use for randomised block designs; as in CANOCO, also add
#'   the blocks as covariables (`+ Condition(block)` in the formula).
#' * **Split-plot** (`plots`): whole plots (groups of sites) are shuffled
#'   as units (`plots_type`), and the sites within each plot are shuffled
#'   (`within`) or kept in place (`within = "none"`). Use when a treatment
#'   is applied to whole plots.
#' * **Time series and transects** (`within = "series"`): sites keep their
#'   order and are shifted cyclically, which keeps temporal or spatial
#'   autocorrelation intact.
#' * **Rectangular grids** (`within = "grid"`, with `nrow` and `ncol`):
#'   toroidal shifts of a grid of sites.
#'
#' Sites must be in the order the design describes (time, or the grid row
#' by row), which is the order of the site column after sorting.
#'
#' @param blocks Name of the site variable defining blocks.
#' @param plots Name of the site variable defining whole plots.
#' @param within How sites are shuffled within plots (or within blocks, or
#'   overall): `"free"`, `"series"`, `"grid"` or `"none"`.
#' @param plots_type How whole plots are shuffled: `"none"` (kept in
#'   place), `"free"`, `"series"` or `"grid"`.
#' @param nrow,ncol Grid dimensions for `"grid"`.
#' @param mirror Also use mirror images of series and grids.
#' @return A `td_design` object.
#' @references
#' Leps, J. and Smilauer, P. (2003). *Multivariate Analysis of Ecological
#' Data using CANOCO*. Cambridge University Press. Chapter 5.
#'
#' Simpson, G. L. (2022). permute: Functions for Generating Restricted
#' Permutations of Data. R package.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' d <- community_long(dune_species, cols = -site)
#' o <- ord_fit(d, abundance = abundance, method = "rda", formula = ~ A1,
#'   env = dune_env, permutations = 0)
#' # shuffle sites only within management types
#' ord_test(o, permutations = 199, design = ord_design(blocks = "Management"))
ord_design <- function(blocks = NULL, plots = NULL,
                       within = c("free", "series", "grid", "none"),
                       plots_type = c("none", "free", "series", "grid"),
                       nrow = NULL, ncol = NULL, mirror = FALSE) {
  within <- rlang::arg_match(within)
  plots_type <- rlang::arg_match(plots_type)
  if (within == "grid" && (is.null(nrow) || is.null(ncol))) {
    cli::cli_abort("{.code within = \"grid\"} needs {.arg nrow} and {.arg ncol}.")
  }
  structure(
    list(blocks = blocks, plots = plots, within = within, plots_type = plots_type,
         nrow = nrow, ncol = ncol, mirror = mirror),
    class = "td_design"
  )
}

#' @export
print.td_design <- function(x, ...) {
  cli::cli_text("{.strong Permutation design}")
  if (!is.null(x$blocks)) cli::cli_text("Blocks: {.field {x$blocks}} (no shuffling between blocks)")
  if (!is.null(x$plots)) cli::cli_text("Whole plots: {.field {x$plots}}, shuffled: {x$plots_type}")
  grid <- if (x$within == "grid") sprintf(" (%d x %d)", x$nrow, x$ncol) else ""
  cli::cli_text("Sites: {x$within}{grid}")
  invisible(x)
}

# A permute::how() object for `design`, given the site table in the order of
# the community matrix.
td_how <- function(design, env, nperm, call = rlang::caller_env()) {
  if (is.null(design)) {
    return(nperm)
  }
  if (!inherits(design, "td_design")) {
    cli::cli_abort("{.arg design} must come from {.fn ord_design}.", call = call)
  }
  rlang::check_installed("permute", "for restricted permutations.")
  get <- function(v) {
    if (is.null(v)) return(NULL)
    if (is.null(env) || !v %in% names(env)) {
      cli::cli_abort("The site variable {.field {v}} is not among the site variables.", call = call)
    }
    factor(env[[v]])
  }
  blk <- get(design$blocks)
  plt <- get(design$plots)
  wargs <- list(type = design$within, mirror = design$mirror)
  if (design$within == "grid") wargs <- c(wargs, list(nrow = design$nrow, ncol = design$ncol))
  w <- do.call(permute::Within, wargs)
  p <- if (is.null(plt)) {
    permute::Plots()
  } else {
    permute::Plots(strata = plt, type = design$plots_type, mirror = design$mirror)
  }
  permute::how(within = w, plots = p, blocks = blk, nperm = nperm)
}

#' Simple and conditional effects of explanatory variables
#'
#' The two tables CANOCO reports for the explanatory variables of a
#' constrained ordination:
#'
#' * **simple effects**: the variation each variable explains on its own
#'   (a separate analysis with only that variable), with its own
#'   permutation test;
#' * **conditional effects**: the variation each variable adds to those
#'   before it, in the order of the formula (or the order chosen by
#'   [ord_select()]), with its permutation test.
#'
#' Testing many variables inflates the chance of false positives, so
#' adjusted p-values are given as well (Holm by default, or the false
#' discovery rate, as in CANOCO 5).
#'
#' @param x A constrained `td_ordination` from [ord_fit()].
#' @param permutations Number of permutations.
#' @param design Optional restricted permutation design from [ord_design()].
#' @param adjust Method for adjusting p-values ([stats::p.adjust()]):
#'   `"holm"`, `"fdr"`, `"bonferroni"` or `"none"`.
#' @return A tibble with `effect` (`"simple"` or `"conditional"`), `term`,
#'   `explained` (variance or inertia), `explained_pct` (percent of the
#'   total), `statistic` (pseudo-F), `p.value` and `p.adjusted`.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' v <- community_long(vare_species, cols = -site)
#' o <- ord_fit(v, abundance = abundance, method = "cca",
#'   formula = ~ Al + P + K, env = vare_env, permutations = 0)
#' ord_effects(o, permutations = 199)
ord_effects <- function(x, permutations = 999, design = NULL,
                        adjust = c("holm", "fdr", "bonferroni", "none")) {
  if (!inherits(x, "td_ordination") || !x$constrained) {
    cli::cli_abort("{.arg x} must be a constrained ordination (rda, cca or dbrda).")
  }
  adjust <- rlang::arg_match(adjust)
  env <- as.data.frame(x$env)
  how <- td_how(design, env, permutations)
  tot <- x$fit$tot.chi
  labs <- attr(stats::terms(x$formula), "term.labels")
  cond <- labs[grepl("^Condition\\(", labs)]
  labs <- setdiff(labs, cond)
  simple <- lapply(labs, function(t) {
    f <- stats::reformulate(c(t, cond))
    m <- ord_refit(x, f)
    a <- vegan::anova.cca(m, permutations = how)
    tibble::tibble(effect = "simple", term = t, explained = m$CCA$tot.chi,
                   explained_pct = 100 * m$CCA$tot.chi / tot,
                   statistic = a$F[1], p.value = a$`Pr(>F)`[1])
  })
  simple <- do.call(rbind, simple)
  a <- as.data.frame(vegan::anova.cca(x$fit, by = "terms", permutations = how))
  a <- a[rownames(a) != "Residual", , drop = FALSE]
  sc <- intersect(c("Variance", "ChiSquare", "SumOfSqs"), names(a))[1]
  conditional <- tibble::tibble(effect = "conditional", term = rownames(a),
                                explained = a[[sc]], explained_pct = 100 * a[[sc]] / tot,
                                statistic = a$F, p.value = a$`Pr(>F)`)
  simple$p.adjusted <- stats::p.adjust(simple$p.value, adjust)
  conditional$p.adjusted <- stats::p.adjust(conditional$p.value, adjust)
  rbind(simple, conditional)
}

# Refit the ordination in `x` with another right-hand side
ord_refit <- function(x, formula) {
  y <- x$analysed
  env_df <- as.data.frame(x$env)
  f <- stats::as.formula(paste("y ~", paste(deparse(formula[[2]]), collapse = " ")))
  environment(f) <- environment()
  switch(x$method,
    rda = vegan::rda(f, data = env_df),
    cca = vegan::cca(f, data = env_df),
    dbrda = vegan::capscale(f, data = env_df, distance = x$distance)
  )
}

#' How well the ordination axes fit each species and site
#'
#' CANOCO's species and sample fit: the percentage of the variation of each
#' species (or site) that the first `axes` ordination axes explain
#' ([vegan::goodness()]). Species with a low fit are poorly represented in
#' the diagram and are usually left out of it; [autoplot()] takes
#' `species_fit` for that.
#'
#' @param x A `td_ordination` from a PCA, CA, RDA, CCA or db-RDA.
#' @param axes Number of axes.
#' @param display `"species"` or `"sites"`.
#' @return A tibble with `species` (or `site`) and `fit_pct`.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' d <- community_long(dune_species, cols = -site)
#' o <- ord_fit(d, abundance = abundance, method = "ca")
#' ord_species_fit(o)
ord_species_fit <- function(x, axes = 2, display = c("species", "sites")) {
  display <- rlang::arg_match(display)
  if (!inherits(x, "td_ordination") || !x$method %in% c("pca", "ca", "rda", "cca", "dbrda")) {
    cli::cli_abort("Fit statistics need a PCA, CA, RDA, CCA or db-RDA.")
  }
  if (x$method == "dbrda" && display == "species") {
    cli::cli_abort("db-RDA has no species fit; use {.code display = \"sites\"}.")
  }
  model <- if (x$constrained) "CCA" else "CA"
  g <- vegan::goodness(x$fit, display = display, model = model, choices = seq_len(axes))
  g <- as.matrix(g)
  out <- tibble::tibble(name = rownames(g), fit_pct = unname(100 * g[, min(axes, ncol(g))]))
  names(out)[1] <- if (display == "species") "species" else "site"
  out
}
