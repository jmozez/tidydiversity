#' Explain and interpret an ordination, its tests and its diagram
#'
#' @description
#' `ord_interpret()` turns the results of an ordination into plain sentences
#' for the reader of a report: how much variation the axes hold (and whether
#' they are worth reading, against the broken-stick expectation), what the
#' permutation tests say, which way each site variable runs across the
#' diagram, where the groups lie, which species define each end of the axes,
#' how faithful an NMDS is (its stress), and how to read the diagram under
#' the scaling used. It works for [ord_fit()] results, for principal
#' response curves ([ord_prc()]) and for variation partitioning
#' ([ord_varpart()]).
#'
#' The sentences describe the results; whether they answer the question is
#' for the analyst to judge. Fitted variables of an unconstrained ordination
#' are a post hoc description, not a test of a hypothesis.
#'
#' @param x An `ord_fit()`, `ord_prc()` or `ord_varpart()` result.
#' @param permutations Number of permutations for the tests of a constrained
#'   ordination or of fitted variables.
#' @param n_species Number of species named at each end of an axis.
#' @param ... Not used.
#' @return A list of class `td_ord_interpretation`: `sections` (a named list
#'   of character vectors, one per topic) and `tables` (the tables they are
#'   based on). Printing it shows the sentences.
#' @references
#' Clarke, K. R. (1993). Non-parametric multivariate analyses of changes in
#' community structure. Australian Journal of Ecology, 18, 117-143.
#'
#' ter Braak, C. J. F. and Smilauer, P. (2012). Canoco Reference Manual and
#' User's Guide: Software for Ordination (version 5.0). Microcomputer Power.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' data("dune", "dune.env", package = "vegan")
#' d <- community_long(cbind(site = rownames(dune), dune.env, dune),
#'   cols = dplyr::all_of(names(dune))
#' )
#' o <- ord_fit(d,
#'   abundance = abundance, method = "rda", transform = "hellinger",
#'   formula = ~ A1 + Management
#' )
#' ord_interpret(o, permutations = 199)
ord_interpret <- function(x, ...) UseMethod("ord_interpret")

# Compass direction of a vector in the diagram
ord_direction <- function(x, y) {
  a <- (atan2(y, x) * 180 / pi) %% 360
  dirs <- c(
    "the right", "the upper right", "the top", "the upper left",
    "the left", "the lower left", "the bottom", "the lower right"
  )
  dirs[(floor((a + 22.5) / 45) %% 8) + 1]
}

ord_pct <- function(v) sprintf("%.1f%%", 100 * v)

# nolint start: line_length_linter. Sentences read better unbroken.

#' @rdname ord_interpret
#' @export
ord_interpret.td_ordination <- function(x, permutations = 999, n_species = 3, ...) {
  rlang::check_installed("vegan")
  fit <- x$fit
  sec <- list()
  tabs <- list()
  ax <- x$axes
  nm <- ax$name
  meth <- c(
    pca = "principal component analysis (PCA)", ca = "correspondence analysis (CA)",
    dca = "detrended correspondence analysis (DCA)", pcoa = "principal coordinates analysis (PCoA)",
    nmds = "non-metric multidimensional scaling (NMDS)", rda = "redundancy analysis (RDA)",
    cca = "canonical correspondence analysis (CCA)", dbrda = "distance-based RDA (db-RDA)"
  )[[x$method]]
  sec$Overview <- paste0(
    "A ", meth, " of ", nrow(x$sites), " sites and ", nrow(x$species), " species",
    if (!is.na(x$transform) && !is.null(x$transform) && x$transform != "none") {
      paste0(" (", ord_pretty(x$transform), "-transformed)")
    } else {
      ""
    },
    if (x$constrained) {
      paste0(", constrained by ", paste(all.vars(x$formula), collapse = ", "), ".")
    } else {
      ": an unconstrained ordination, describing the main patterns of composition."
    }
  )

  # ---- Variation ----
  v <- character()
  if (x$method == "nmds") {
    s <- x$stress
    verdict <- if (s < 0.05) {
      "excellent"
    } else if (s < 0.1) {
      "good"
    } else if (s < 0.2) {
      "usable, but details should not be over-read"
    } else {
      "poor: the diagram may mislead; try more dimensions"
    }
    v <- c(v, sprintf(
      "The stress is %.3f, %s (Clarke 1993). NMDS axes have no variance of their own; only the arrangement of the sites matters.",
      s, verdict
    ))
  } else if (x$constrained && !is.null(fit$CCA)) {
    tot <- fit$tot.chi
    cons <- fit$CCA$tot.chi
    adj <- tryCatch(vegan::RsquareAdj(fit)$adj.r.squared, error = function(e) NA)
    v <- c(v, sprintf(
      "The site variables explain %s of the variation in composition (adjusted R\u00b2 = %s, allowing for the number of variables).",
      ord_pct(cons / tot), if (is.na(adj)) "not available" else ord_pct(adj)
    ))
    v <- c(v, sprintf(
      "The first two constrained axes hold %s and %s of the total variation (%s of the explained part).",
      ord_pct(ax$explained[1]), ord_pct(ax$explained[2]),
      ord_pct(sum(ax$explained[1:2]) * tot / cons)
    ))
  } else {
    ev <- if (!is.null(fit$CA$eig)) fit$CA$eig else ax$eigenvalue
    bs <- vegan::bstick(length(ev), sum(ev))
    keep <- which(ev <= bs)[1] - 1
    if (is.na(keep)) keep <- length(ev)
    v <- c(v, sprintf(
      "The first two axes hold %s and %s of the variation (%s together).",
      ord_pct(ax$explained[1]), ord_pct(ax$explained[2]), ord_pct(sum(ax$explained[1:2]))
    ))
    v <- c(v, if (keep >= 2) {
      sprintf("%d axes hold more than expected by chance (broken stick), so at least the first two are worth reading.", keep)
    } else if (keep == 1) {
      "Only the first axis holds more than expected by chance (broken stick); read the second with caution."
    } else {
      "No axis holds more than expected by chance (broken stick): the structure is weak."
    })
  }
  sec$Variation <- v

  # ---- Tests ----
  if (x$constrained) {
    tm <- ord_test(x, by = "model", permutations = permutations)
    tt <- ord_test(x, by = "margin", permutations = permutations)
    tabs$model_test <- tm
    tabs$term_tests <- tt
    t <- sprintf(
      "Overall, composition is %s related to the site variables (permutation F = %.2f, p = %s, %d permutations).",
      if (tm$p.value[1] < 0.05) "significantly" else "not significantly",
      tm$statistic[1], ord_fmt_p(tm$p.value[1]), permutations
    )
    tt <- tt[tt$term != "Residual", ]
    for (i in seq_len(nrow(tt))) {
      t <- c(t, sprintf(
        "%s %s (F = %.2f, p = %s), after allowing for the other variables.",
        ord_pretty(tt$term[i]),
        if (tt$p.value[i] < 0.05) "has a significant unique effect" else "has no significant unique effect",
        tt$statistic[i], ord_fmt_p(tt$p.value[i])
      ))
    }
    sec$Tests <- t
  }

  # ---- Site variables ----
  vars <- character()
  vec <- x$vectors
  if (!x$constrained && !is.null(x$env) && !is.null(x$formula)) {
    sc <- as.data.frame(x$sites[c("axis1", "axis2")])
    env <- as.data.frame(x$env[all.vars(x$formula)])
    ef <- vegan::envfit(sc, env, permutations = permutations)
    if (!is.null(ef$vectors)) {
      vtab <- tibble::tibble(
        term = rownames(ef$vectors$arrows), axis1 = ef$vectors$arrows[, 1],
        axis2 = ef$vectors$arrows[, 2], r2 = ef$vectors$r, p.value = ef$vectors$pvals
      )
      tabs$fitted_variables <- vtab
      for (i in seq_len(nrow(vtab))) {
        vars <- c(vars, sprintf(
          "%s increases towards %s of the diagram (r\u00b2 = %.2f, p = %s; fitted after the ordination, so descriptive).",
          ord_pretty(vtab$term[i]), ord_direction(vtab$axis1[i], vtab$axis2[i]),
          vtab$r2[i], ord_fmt_p(vtab$p.value[i])
        ))
      }
    }
  } else if (nrow(vec)) {
    for (i in seq_len(nrow(vec))) {
      c1 <- vec$axis1[i]
      c2 <- vec$axis2[i]
      main <- if (abs(c1) >= abs(c2)) "first" else "second"
      vars <- c(vars, sprintf(
        "%s increases towards %s of the diagram, mostly along the %s axis (biplot scores %.2f, %.2f).",
        ord_pretty(vec$term[i]), ord_direction(c1, c2), main, c1, c2
      ))
    }
  }
  cen <- x$centroids
  if (!is.null(cen) && nrow(cen)) {
    for (g in unique(cen$variable)) {
      cg <- cen[cen$variable == g, ]
      vars <- c(vars, paste0(
        ord_pretty(g), ": ",
        paste(sprintf("%s lies towards %s", cg$level, ord_direction(cg$axis1, cg$axis2)), collapse = "; "),
        ". The further apart two centroids, the more the composition of their sites differs."
      ))
    }
  }
  if (length(vars)) sec$`Site variables` <- vars

  # ---- Species ----
  sp <- x$species
  spx <- character()
  for (a in 1:2) {
    col <- paste0("axis", a)
    o <- order(sp[[col]])
    lo <- sp$species[utils::head(o, n_species)]
    hi <- sp$species[rev(utils::tail(o, n_species))]
    spx <- c(spx, sprintf(
      "Axis %d (%s) runs from %s (negative end) to %s (positive end).",
      a, nm[a], paste(lo, collapse = ", "), paste(hi, collapse = ", ")
    ))
  }
  sec$Species <- spx

  # ---- How to read the diagram ----
  read <- c(
    "Sites (circles) close together have similar species composition.",
    if (x$method %in% c("pca", "rda")) {
      if (x$scaling == "species") {
        "With species scaling, the angles between species (and between species and variable arrows) approximate their correlations; distances between sites are only approximate."
      } else {
        "With site scaling, distances between sites approximate their dissimilarity; angles between species are not correlations."
      }
    } else if (x$method %in% c("ca", "cca", "dca")) {
      "Species crosses lie near the sites where they are most abundant (their optima)."
    } else {
      "Species are placed at the weighted averages of the sites where they occur."
    },
    if (nrow(vec) || !is.null(tabs$fitted_variables)) {
      "Project a site or species perpendicularly onto an arrow: the further along the arrow, the higher the variable (or the stronger the species' association with it)."
    },
    if (!is.null(cen) && nrow(cen)) "Triangles are the centroids of the factor levels: the average position of their sites."
  )
  sec$`Reading the diagram` <- read
  structure(list(sections = sec, tables = tabs), class = "td_ord_interpretation")
}

#' @rdname ord_interpret
#' @export
ord_interpret.td_prc <- function(x, ...) {
  cu <- x$curves[x$curves$treatment != x$control, ]
  big <- cu[which.max(abs(cu$coefficient)), ]
  sp <- x$species
  pos <- utils::head(sp$species[order(-sp$weight)], 3)
  neg <- utils::head(sp$species[order(sp$weight)], 3)
  sec <- list(
    Overview = sprintf(
      "Principal response curves of %d treatments against the control (%s) over %d times.",
      nlevels(x$curves$treatment) - 1, x$control, length(unique(x$curves$time))
    ),
    Variation = sprintf(
      "Treatment explains %s of the variation after the differences between times are removed; the first PRC axis is %s (F = %.2f, p = %s).",
      ord_pct(x$explained), if (x$test$p.value < 0.05) "significant" else "not significant",
      x$test$statistic, ord_fmt_p(x$test$p.value)
    ),
    Curves = c(
      sprintf(
        "The largest departure from the control is in treatment %s at time %s (coefficient %.2f).",
        big$treatment, big$time, big$coefficient
      ),
      "Curves near zero mean communities like the control; the further a curve from zero, the more the community differs."
    ),
    Species = c(
      sprintf(
        "Species with the largest positive weights (%s) follow the curves: where a curve goes up they increase relative to the control; where it goes down they decrease.",
        paste(pos, collapse = ", ")
      ),
      sprintf(
        "Species with the largest negative weights (%s) do the opposite.",
        paste(neg, collapse = ", ")
      ),
      "The expected change of a species is roughly exp(weight \u00d7 coefficient) times its abundance in the control, on the scale of the transformation used."
    )
  )
  structure(list(sections = sec, tables = list(curves = x$curves, species = x$species)),
    class = "td_ord_interpretation"
  )
}

#' @rdname ord_interpret
#' @export
ord_interpret.td_varpart <- function(x, ...) {
  sets <- attr(x, "sets")
  k <- length(sets)
  fr <- x$adj_r2
  resid <- fr[length(fr)]
  uni <- fr[seq_len(k)]
  shared <- sum(fr[(k + 1):(length(fr) - 1)], na.rm = TRUE)
  sig <- !is.na(x$p.value[seq_len(k)]) & x$p.value[seq_len(k)] < 0.05
  sec <- list(
    Overview = sprintf(
      "Variation partitioning of composition among %d sets of variables: %s.",
      k, paste(sets, collapse = ", ")
    ),
    Fractions = c(
      sprintf(
        "%s alone explains %s%s.",
        sets, ord_pct(pmax(uni, 0)),
        ifelse(sig, " (significant)", ifelse(is.na(x$p.value[seq_len(k)]), "", " (not significant)"))
      ),
      sprintf("Fractions shared between sets add up to %s: variation that cannot be attributed to one set alone, because the sets are correlated.", ord_pct(max(shared, 0))),
      sprintf("%s of the variation is not explained by any set (residual).", ord_pct(resid)),
      if (any(fr < 0, na.rm = TRUE)) {
        "Negative fractions (shown as < 0%) arise from adjusting R\u00b2 and mean the sets explain less together than apart; read them as zero."
      }
    ),
    `Reading the diagram` = "Each circle is a set of variables; the number in each region is the adjusted R\u00b2 of that fraction; an asterisk marks a unique fraction significant by permutation."
  )
  structure(list(sections = sec, tables = list(fractions = x)), class = "td_ord_interpretation")
}

#' @export
print.td_ord_interpretation <- function(x, ...) {
  cli::cli_h1("Interpretation")
  for (s in names(x$sections)) {
    cli::cli_h2(s)
    for (line in x$sections[[s]]) cli::cli_bullets(c("*" = gsub("([{}])", "\\1\\1", line)))
  }
  invisible(x)
}
# nolint end
