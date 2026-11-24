# Plain-language interpretations of the CANOCO-style analyses, for
# ord_interpret() and so for tidyvisor().

# nolint start: line_length_linter. Sentences read better unbroken.

#' @rdname ord_interpret
#' @export
ord_interpret.td_cva <- function(x, ...) {
  ax <- x$axes
  sec <- list(
    Overview = sprintf("Canonical variate analysis of %d sites in %d groups (%s): the axes that best separate the groups by their composition.",
                       nrow(x$sites), nrow(x$centroids), paste(x$centroids$group, collapse = ", ")),
    Separation = c(
      sprintf("The first axis carries %.1f%% of the separation between groups (canonical correlation %.2f).", 100 * ax$proportion[1], ax$canonical_correlation[1]),
      sprintf("Permutation test of the separation: Pillai trace %.3f, p = %s (%d permutations)%s", x$test$statistic, format.pval(x$test$p.value, digits = 2), x$test$permutations,
              if (x$test$p.value < 0.05) "; the groups differ in composition." else "; no evidence that the groups differ in composition.")
    ),
    `Reading the plot` = "Plot the site scores coloured by group; group centroids far apart on an axis are well separated. CVA maximises separation, so it overstates it for new data; check with cross-validation (MASS::lda(CV = TRUE))."
  )
  structure(list(sections = sec, tables = list(axes = ax, centroids = x$centroids)), class = "td_ord_interpretation")
}

#' @rdname ord_interpret
#' @export
ord_interpret.td_dcca <- function(x, ...) {
  t <- x$test
  pm <- t$p.value[t$level == "max"]
  sec <- list(
    Overview = "Double constrained correspondence analysis (dc-CA): axes that are combinations of species traits and of site variables at once, so they show how traits respond to the environment.",
    Axes = sprintf("The first axis carries %.1f%% of the trait-environment inertia.", 100 * x$axes$proportion[1]),
    Test = c(
      sprintf("Site-level test p = %s; species-level test p = %s.", format.pval(t$p.value[1], digits = 2), format.pval(t$p.value[2], digits = 2)),
      sprintf("Max test (the larger p-value, which controls the error rate): p = %s%s", format.pval(pm, digits = 2),
              if (pm < 0.05) "; the traits are related to the environment." else "; no reliable trait-environment relation."),
      "A significant site-level test alone is not enough: it can arise from the environment structuring composition, not traits."
    )
  )
  structure(list(sections = sec, tables = list(axes = x$axes, test = t)), class = "td_ord_interpretation")
}

#' @rdname ord_interpret
#' @export
ord_interpret.td_rlq <- function(x, ...) {
  t <- x$test
  pm <- t$p.value[3]
  top <- function(tab, id) {
    tab <- tab[order(-abs(tab$axis1)), ]
    paste(sprintf("%s (%.2f)", tab[[id]][seq_len(min(3, nrow(tab)))], tab$axis1[seq_len(min(3, nrow(tab)))]), collapse = ", ")
  }
  sec <- list(
    Overview = "RLQ analysis: the axes of greatest co-variation between site variables (R) and species traits (Q), weighted by the community (L).",
    Axes = c(
      sprintf("The first axis carries %.1f%% of the co-inertia.", 100 * x$axes$proportion[1]),
      sprintf("Site variables most related to it: %s.", top(x$env_scores, "variable")),
      sprintf("Traits most related to it: %s; traits and variables with the same sign go together.", top(x$trait_scores, "trait"))
    ),
    Test = sprintf("Combined fourth-corner test (models 2 and 4, larger p-value): p = %s%s", format.pval(pm, digits = 2),
                   if (pm < 0.05) "; traits are related to the environment." else "; no reliable trait-environment relation.")
  )
  structure(list(sections = sec, tables = list(axes = x$axes, env = x$env_scores, traits = x$trait_scores)), class = "td_ord_interpretation")
}

#' @rdname ord_interpret
#' @export
ord_interpret.td_coca <- function(x, ...) {
  sec <- list(Overview = sprintf("Co-correspondence analysis (%s) of two communities at %d shared sites.", x$method, length(unique(x$sites$site))))
  sec$Axes <- if (x$method == "predictive") {
    c(sprintf("The first axis explains %.1f%% of the variation of the response community from the predictor community.", 100 * x$axes$variance_explained[1]),
      "Choose the number of axes by cross-validation (cocorresp::crossval()); more axes always fit better but may predict worse.")
  } else {
    sprintf("The first axis carries %.1f%% of the shared structure of the two communities.", 100 * x$axes$proportion[1])
  }
  structure(list(sections = sec, tables = list(axes = x$axes)), class = "td_ord_interpretation")
}

# nolint end
