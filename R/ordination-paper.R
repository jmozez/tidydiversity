# "After the overall test" and "For the paper" for ordination results, as
# tidyvisor gives them for tests and models: whether to go on to pairwise
# comparisons of groups of sites, and how to report the result in a
# publication (a sentence, the figure, the table and the Methods).
# nolint start: line_length_linter. Advice strings read better unbroken.

td_no_pairwise <- "Do not go on to pairwise comparisons of the groups: with no overall effect, testing every pair is a search for something significant, and any 'difference' it finds is likely to be a false positive. Report the overall test with its R\u00b2 and the number of permutations."

td_fig_rules <- "Figure style for journals: one column (about 85 mm) or the page (about 180 mm); label only the species that matter (the strongest weights or best fitted); give the variation of each axis in its label; a colour-blind-safe palette and different symbols for groups; text at least 8 pt; vector PDF or SVG."

td_save <- 'ggplot2::ggsave("figure1.pdf", width = 85, height = 85, units = "mm")   # one journal column'

# Pairwise comparisons after a constrained ordination, factor by factor
td_ord_after <- function(x, tt = NULL) {
  if (!x$constrained) {
    return(c(
      "An unconstrained ordination describes the patterns; it has no overall test, so there is nothing to follow up with pairwise comparisons.",
      "To test whether groups of sites differ in composition, use a permutation test, beta_permanova(data, formula = ~ group), and check that the groups have similar spread with beta_dispersion(data, group = group): PERMANOVA cannot tell a difference in location from a difference in spread (Anderson 2006)."
    ))
  }
  env <- x$env
  vars <- intersect(all.vars(x$formula), names(env))
  facs <- vars[vapply(vars, function(v) (is.factor(env[[v]]) || is.character(env[[v]])) && length(unique(env[[v]])) >= 3, TRUE)]
  if (!length(facs) || is.null(tt)) {
    return("The site variables are numeric or have two levels, so the term tests above already say which matter; no pairwise comparisons are needed.")
  }
  out <- character()
  for (f in facs) {
    p <- tt$p.value[tt$term == f]
    k <- length(unique(env[[f]]))
    if (!length(p) || is.na(p)) next
    if (p < 0.05) {
      out <- c(out,
        sprintf("%s (%d levels) has a significant effect (p = %s): the groups are not all alike in composition, but the test does not say which differ. Go on to pairwise PERMANOVA between the levels, with p-values adjusted for the number of pairs (Holm):", ord_pretty(f), k, ord_fmt_p(p)),
        sprintf("env <- ord$env; comm <- ord$community\npairs <- combn(levels(factor(env$%s)), 2, simplify = FALSE)\np <- sapply(pairs, function(l) { k <- env$%s %%in%% l; vegan::adonis2(comm[k, ] ~ %s, data = env[k, , drop = FALSE], method = \"%s\")$`Pr(>F)`[1] })\nstats::setNames(p.adjust(p, \"holm\"), vapply(pairs, paste, \"\", collapse = \" vs \"))", f, f, f, if (is.null(x$distance) || is.na(x$distance)) "bray" else x$distance),
        sprintf("Check that the levels of %s have similar spread (beta_dispersion(data, group = %s)); if they do not, a significant pair may differ in spread rather than in composition.", ord_pretty(f), f)
      )
    } else {
      out <- c(out, sprintf("%s (%d levels) has no significant effect (p = %s). %s", ord_pretty(f), k, ord_fmt_p(p), td_no_pairwise))
    }
  }
  out
}

td_ord_paper <- function(x, tm = NULL, tt = NULL, permutations = 999) {
  meth <- c(pca = "PCA", ca = "CA", dca = "DCA", pcoa = "PCoA", nmds = "NMDS", rda = "RDA", cca = "CCA", dbrda = "db-RDA")[[x$method]]
  ax <- x$axes
  tr <- if (!is.null(x$transform) && !is.na(x$transform) && x$transform != "none") paste0(ord_pretty(x$transform), "-transformed ") else ""
  sentence <- if (x$constrained && !is.null(tm)) {
    adj <- tryCatch(vegan::RsquareAdj(x$fit)$adj.r.squared, error = function(e) NA)
    sprintf("Results: 'Community composition was %srelated to %s (%s on %sabundances; pseudo-F = %.2f, p = %s, %d permutations; adjusted R\u00b2 = %s).'",
            if (tm$p.value[1] < 0.05) "" else "not significantly ", td_and(vapply(all.vars(x$formula), ord_pretty, "")),
            meth, tr, tm$statistic[1], ord_fmt_p(tm$p.value[1]), as.integer(permutations),
            if (is.na(adj)) "n.a." else ord_pct(adj))
  } else if (x$method == "nmds") {
    sprintf("Results: 'The NMDS ordination of %d sites (%s dissimilarity) had a stress of %.3f; the main gradient ran from ... to ... (describe the sites and species at each end).'", nrow(x$sites), if (is.null(x$distance) || is.na(x$distance)) "Bray-Curtis" else x$distance, x$stress)
  } else {
    sprintf("Results: 'The first two %s axes explained %s and %s of the variation in %scommunity composition; axis 1 separated ... from ... (describe the sites and species at each end).'", meth, ord_pct(ax$explained[1]), ord_pct(ax$explained[2]), tr)
  }
  c(sentence,
    if (x$constrained) "Report the test with its statistic, p-value and number of permutations, and the variation explained as an adjusted R\u00b2." else if (x$method == "nmds") "Report the stress and the number of dimensions; NMDS axes have no variance of their own." else "Report the variation explained by each axis shown, and how many axes are worth reading (broken stick).",
    "Figure: the ordination diagram with the sites as points (coloured or shaped by group), the variables as arrows or centroids, and only the species that matter labelled:",
    "ord_plot <- ggplot2::autoplot(ord)\nord_plot",
    td_save, td_fig_rules,
    if (x$constrained) "Table: the permutation test for the whole model and for each variable (df, variance, pseudo-F, p), and the variation explained by the axes." else "Table: the eigenvalues and the variation explained by the first axes, and, if needed, the species scores on them.",
    sprintf("Methods: the method (%s), the transformation (%s), %sthe scaling, the permutation scheme and number of permutations, and the software (R %s, vegan %s; citation(\"vegan\"), citation(\"tidydiversity\")).",
            meth, if (nzchar(tr)) sub("-transformed ", "", tr) else "none", if (x$method %in% c("pcoa", "nmds", "dbrda")) "the dissimilarity, " else "",
            paste(R.version$major, R.version$minor, sep = "."), as.character(utils::packageVersion("vegan")))
  )
}

td_and <- function(v) if (length(v) < 2) v else paste(paste(v[-length(v)], collapse = ", "), "and", v[length(v)])

td_prc_paper <- function(x) {
  c(sprintf("Results: 'Treatment changed community composition over time relative to the control (PRC, first axis: F = %.2f, p = %s); treatment explained %s of the variation once time was accounted for.'", x$test$statistic, ord_fmt_p(x$test$p.value), ord_pct(x$explained)),
    if (x$test$p.value >= 0.05) td_no_pairwise else "To say at which times the treatments differ, test each time separately (an RDA of composition on treatment for each sampling date) and adjust the p-values for the number of dates (Holm).",
    "Figure: the principal response curves with the species weights alongside (the standard PRC diagram):",
    "ggplot2::autoplot(prc)",
    td_save, td_fig_rules,
    "Table: the test of the first PRC axis, and the species with the largest positive and negative weights.",
    sprintf("Methods: the PRC (van den Brink and ter Braak 1999), the transformation, the permutation scheme (restricted within time where samples are repeated), and the software (R %s; citation(\"vegan\"), citation(\"tidydiversity\")).", paste(R.version$major, R.version$minor, sep = ".")))
}

td_varpart_paper <- function(x) {
  sets <- attr(x, "sets")
  k <- length(sets)
  c(sprintf("Results: 'Variation partitioning showed that %s.'", td_and(sprintf("%s alone explained %s", sets, ord_pct(pmax(x$adj_r2[seq_len(k)], 0))))),
    "Report each fraction as an adjusted R\u00b2, mark the testable fractions with their permutation p-values, and say that shared fractions cannot be tested.",
    "Figure: the Venn diagram of the fractions:",
    "ggplot2::autoplot(vp)",
    td_save,
    "Table: every fraction with its adjusted R\u00b2 and, where testable, its p-value.",
    sprintf("Methods: the sets of variables and why they were grouped so, the method (Borcard et al. 1992; Peres-Neto et al. 2006), and the software (R %s; citation(\"vegan\"), citation(\"tidydiversity\")).", paste(R.version$major, R.version$minor, sep = ".")))
}
# nolint end
