#' Which ordination and which test? Advice from the data and the question
#'
#' @description
#' `ord_advise()` helps choose an ordination method and the test that goes
#' with it. It looks at the community data (number of sites and species,
#' zeros, abundances or presence-absence, the length of the main gradient)
#' and at the question asked, and recommends, with its reasons and the code
#' to run:
#'
#' * **unconstrained or constrained.** To *describe* the main patterns of
#'   composition, without a hypothesis about their causes, use an
#'   unconstrained (indirect) ordination: PCA, CA or NMDS; site variables can
#'   be fitted afterwards (arrows, contours) but are not part of the analysis.
#'   To *test* whether, and how much, measured variables explain
#'   composition, use a constrained (direct, canonical) ordination: RDA, CCA
#'   or distance-based RDA, with a permutation test.
#' * **linear or unimodal.** The length of the first axis of a detrended
#'   correspondence analysis, in standard-deviation units of species
#'   turnover, measures how heterogeneous the data are: below about 3, most
#'   species change monotonically and linear methods (PCA, RDA) fit; above
#'   about 4, species rise and fall along the gradient and unimodal methods
#'   (CA, CCA) fit; in between, either (ter Braak and Smilauer 2012).
#'   Hellinger-transformed PCA and RDA (Legendre and Gallagher 2001) work
#'   well whatever the length, and NMDS or distance-based RDA with
#'   Bray-Curtis or Jaccard dissimilarity suit any data.
#' * **the test.** Constrained ordinations are tested by permutation (overall,
#'   by axis and by term); with many candidate variables, by forward
#'   selection; differences between groups of sites by PERMANOVA, with a test
#'   of dispersion alongside; treatments followed over time by principal
#'   response curves; and the separate and shared effects of sets of
#'   variables by variation partitioning.
#'
#' The advice is a starting point, not a rule: the question, which only the
#' analyst knows, comes first.
#'
#' @inheritParams ord_fit
#' @param formula Optional one-sided formula of site variables (columns of
#'   `data`, one value per site), e.g. `~ elevation + habitat`.
#' @param question What is asked: `"auto"` (from the other arguments),
#'   `"explore"` (describe the main patterns), `"explain"` (test site
#'   variables), `"groups"` (compare groups of sites), `"time"` (treatments
#'   followed over time) or `"partition"` (separate the effects of sets of
#'   variables).
#' @param treatment,time Optional columns for a treatment followed over time.
#' @return A list of class `td_ord_advice`: `checks` (a tibble of what was
#'   measured in the data, its value and what it means), `advice` (a tibble
#'   of steps: `step`, `recommendation`, `reason` and `code`) and
#'   `gradient_length`. Printing it shows the advice.
#' @references
#' ter Braak, C. J. F. and Smilauer, P. (2012). Canoco Reference Manual and
#' User's Guide: Software for Ordination (version 5.0). Microcomputer Power.
#'
#' Legendre, P. and Gallagher, E. D. (2001). Ecologically meaningful
#' transformations for ordination of species data. Oecologia, 129, 271-280.
#'
#' Legendre, P. and Legendre, L. (2012). Numerical Ecology, 3rd ed.
#' Elsevier.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' data("dune", "dune.env", package = "vegan")
#' d <- community_long(cbind(site = rownames(dune), dune.env, dune),
#'   cols = dplyr::all_of(names(dune))
#' )
#' # Describe the meadows
#' ord_advise(d, abundance = abundance)
#' # Test management and soil
#' ord_advise(d, abundance = abundance, formula = ~ A1 + Moisture + Management)
ord_advise <- function(data,
                       site = site,
                       species = species,
                       abundance = NULL,
                       formula = NULL,
                       question = c("auto", "explore", "explain", "groups", "time", "partition"),
                       treatment = NULL,
                       time = NULL) {
  rlang::check_installed("vegan", "to measure the gradient length.")
  td_check_data(data)
  question <- rlang::arg_match(question)
  site_col <- td_pick(enquo(site), data, "site")
  ab_q <- enquo(abundance)
  trt_q <- enquo(treatment)
  time_q <- enquo(time)
  prep <- td_prepare(data, enquo(site), enquo(species), ab_q, rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  y <- y[rowSums(y) > 0, colSums(y) > 0, drop = FALSE]
  n <- nrow(y)
  p <- ncol(y)
  pa <- all(y %in% c(0, 1))
  zeros <- mean(y == 0)
  singletons <- mean(colSums(y > 0) == 1)
  dca <- suppressWarnings(vegan::decorana(if (pa) y else log1p(y)))
  gl <- unname(diff(range(vegan::scores(dca, display = "sites", choices = 1))))

  # Site variables
  vars <- if (is.null(formula)) character() else all.vars(formula)
  site_info <- unique(as.data.frame(data)[c(site_col, vars)])
  site_info <- site_info[match(rownames(y), as.character(site_info[[site_col]])), , drop = FALSE]
  is_num <- vapply(vars, function(v) is.numeric(site_info[[v]]), logical(1))
  k <- if (length(vars)) {
    ncol(stats::model.matrix(stats::reformulate(vars), site_info)) - 1
  } else {
    0
  }
  vif <- NULL
  if (sum(is_num) >= 2) {
    m <- tryCatch(vegan::rda(y ~ ., data = site_info[vars[is_num]]), error = function(e) NULL)
    if (!is.null(m)) vif <- vegan::vif.cca(m)
  }
  has_time <- !rlang::quo_is_null(trt_q) && !rlang::quo_is_null(time_q)

  if (question == "auto") {
    question <- if (has_time) {
      "time"
    } else if (!length(vars)) {
      "explore"
    } else if (!any(is_num)) {
      "groups"
    } else {
      "explain"
    }
  }

  # nolint start: line_length_linter. Advice strings read better unbroken.
  # ---- What the data show ----
  linear <- gl < 3
  unimodal <- gl > 4
  checks <- tibble::tibble(
    check = c(
      "Sites", "Species", "Data", "Zeros", "Species in one site only",
      "Gradient length (DCA axis 1, SD units)", "Site variables (model terms)"
    ),
    value = c(
      n, p, if (pa) "presence-absence" else "abundances", sprintf("%.0f%%", 100 * zeros),
      sprintf("%.0f%%", 100 * singletons), sprintf("%.2f", gl), k
    ),
    meaning = c(
      if (n < 10) "few sites: tests have little power" else "",
      "",
      if (pa) "use Jaccard or Sorensen; PCA and RDA on 0/1 data need a transformation" else "",
      if (zeros > 0.5) {
        "many zeros: shared absences must not make sites similar (Hellinger or Bray-Curtis)"
      } else {
        ""
      },
      if (singletons > 0.3) "many rare species: they add noise; consider removing or down-weighting" else "",
      if (linear) {
        "short: most species change monotonically; linear methods (PCA, RDA)"
      } else if (unimodal) {
        "long: species rise and fall along the gradient; unimodal methods (CA, CCA)"
      } else {
        "intermediate: linear or unimodal methods both suit"
      },
      if (k >= n - 1) {
        "as many terms as sites: a constrained ordination is not constrained at all"
      } else if (k > n / 3) {
        "many terms for the sites: select variables (forward selection)"
      } else {
        ""
      }
    )
  )
  if (!is.null(vif)) {
    checks <- vctrs::vec_rbind(checks, tibble::tibble(
      check = "Collinearity (largest VIF)",
      value = sprintf("%.1f (%s)", max(vif), names(vif)[which.max(vif)]),
      meaning = if (max(vif) > 10) "above 10: variables are redundant; drop or combine some" else ""
    ))
  }

  # ---- The advice ----
  lin_m <- if (unimodal) "cca" else "rda"
  un_m <- if (unimodal) "ca" else "pca"
  tr <- if (unimodal) "none" else "hellinger"
  ab_txt <- if (rlang::quo_is_null(ab_q)) "" else paste0(", abundance = ", rlang::as_label(ab_q))
  f_txt <- if (length(vars)) paste0(", formula = ", paste(deparse(formula), collapse = "")) else ""
  dist <- if (pa) "jaccard" else "bray"
  step <- function(s, r, why, code) tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  adv <- switch(question,
    explore = vctrs::vec_rbind(
      step(
        "Approach", "Unconstrained (indirect) ordination",
        "You want to describe the main patterns of composition, not test their causes.", ""
      ),
      step(
        "Method", if (unimodal) "CA, or NMDS" else "PCA on Hellinger-transformed data, or NMDS",
        sprintf("Gradient length %.1f SD; NMDS on %s dissimilarity suits any data.", gl, dist),
        sprintf(
          "ord_fit(data%s, method = \"%s\", transform = \"%s\")\nord_fit(data%s, method = \"nmds\", distance = \"%s\")",
          ab_txt, un_m, tr, ab_txt, dist
        )
      ),
      step(
        "Interpret", "Fit site variables afterwards (arrows, contours, centroids)",
        "Fitted variables are a post hoc interpretation of the axes; their permutation p-values are descriptive.",
        "autoplot(ord, surface = <numeric variable>)"
      ),
      step(
        "Check", "Scree diagram (PCA, CA) or Shepard diagram and stress (NMDS)",
        "How many axes are worth reading, and how faithful the diagram is.",
        "autoplot(ord, type = \"scree\")   # or type = \"shepard\""
      ),
      step(
        "Plots", "Biplot with numeric variables as contours or symbol size, factors as centroids; scree or Shepard inset; stability ellipses",
        "Contours show non-linear change that an arrow hides; the inset shows how faithful the diagram is; ellipses show which sites are placed firmly.",
        "autoplot(ord, surface = <numeric>, colour = <factor>, inset = \"scree\")   # \"shepard\" for NMDS\nautoplot(ord, type = \"gradient\", path = <numeric>)\nautoplot(ord, type = \"stability\")"
      ),
      step(
        "Interpret", "Plain-language explanation of the tables and the diagram",
        "Variation explained, tests, directions of variables, groups, species at each end of the axes, and how to read the plot.",
        "ord_interpret(ord)"
      )
    ),
    explain = vctrs::vec_rbind(
      step(
        "Approach", "Constrained (direct, canonical) ordination",
        "You have a hypothesis that measured site variables explain composition.", ""
      ),
      step(
        "Method", if (unimodal) "CCA (or db-RDA)" else "RDA on Hellinger-transformed data (or db-RDA)",
        sprintf("Gradient length %.1f SD.", gl),
        sprintf("ord <- ord_fit(data%s, method = \"%s\", transform = \"%s\"%s)", ab_txt, lin_m, tr, f_txt)
      ),
      if (k > n / 3 || (!is.null(vif) && max(vif) > 10)) {
        step(
          "Select", "Forward selection of variables",
          "Too many or collinear variables inflate the explained variation and make the test unreliable.",
          sprintf("ord_select(data%s%s)", ab_txt, f_txt)
        )
      },
      step(
        "Test", "Permutation tests: the whole model, each axis and each term",
        "The F-test of a constrained ordination has no parametric distribution; permuting sites gives p-values.",
        "ord_test(ord, by = \"model\"); ord_test(ord, by = \"axis\"); ord_test(ord, by = \"margin\")"
      ),
      step(
        "Plots", "Triplot; species response curves along the main variable; t-value biplot or Van Dobben circles",
        "The triplot shows sites, species and variables together; response curves show each species' optimum and tolerance with confidence bands; Van Dobben circles single out the species that respond significantly.",
        "autoplot(ord)\nautoplot(ord, type = \"response\", variable = \"<numeric>\")\nautoplot(ord, type = \"vandobben\", variable = \"<numeric>\")"
      ),
      step(
        "Interpret", "Plain-language explanation of the tables and the diagram",
        "Variation explained, tests, directions of variables, groups, species at each end of the axes, and how to read the plot.",
        "ord_interpret(ord)"
      )
    ),
    groups = vctrs::vec_rbind(
      step(
        "Approach", "Compare groups of sites: PERMANOVA, shown by a constrained ordination",
        "Your site variables are factors (groups).", ""
      ),
      step(
        "Test", "PERMANOVA, with a test of the dispersion within groups",
        "PERMANOVA is sensitive to differences in spread as well as in location; test both.",
        sprintf(
          "beta_permanova(data%s%s)\nbeta_welch(data%s, group = %s)   # robust to unequal dispersion",
          ab_txt, f_txt, ab_txt, vars[1]
        )
      ),
      step(
        "Fit", "db-RDA (or RDA) with the groups as constraints",
        sprintf("Gradient length %.1f SD.", gl),
        sprintf(
          "ord <- ord_fit(data%s, method = \"dbrda\", distance = \"%s\"%s)\nautoplot(ord, colour = <factor>, ellipse = \"sd\")",
          ab_txt, dist, f_txt
        )
      ),
      step(
        "Plots", "Sites filled by group with SD ellipses (or hulls, spiders) and group centroids",
        "Ellipses show both the location and the spread that PERMANOVA and the dispersion test compare.",
        "autoplot(ord, colour = <factor>, ellipse = \"sd\")   # or hull = TRUE, spider = TRUE"
      ),
      step(
        "Interpret", "Plain-language explanation of the tables and the diagram",
        "Variation explained, tests, directions of variables, groups, species at each end of the axes, and how to read the plot.",
        "ord_interpret(ord)"
      )
    ),
    time = vctrs::vec_rbind(
      step(
        "Approach", "Principal response curves (PRC)",
        "Treatments followed over time: the question is how each departs from the control.", ""
      ),
      step(
        "Test", "Permutation test of the first PRC axis, permuting within times",
        "Samples at the same time are not exchangeable with samples at other times.",
        sprintf(
          "pr <- ord_prc(data, treatment = %s, time = %s%s)\nautoplot(pr)",
          rlang::as_label(trt_q), rlang::as_label(time_q), ab_txt
        )
      ),
      step(
        "Plots", "Principal response curves with the species weights beside them",
        "Each treatment's departure from the control over time, and which species drive it.",
        "autoplot(pr, weights = 0.5)"
      ),
      step(
        "Interpret", "Plain-language explanation of the tables and the diagram",
        "Variation explained, tests, directions of variables, groups, species at each end of the axes, and how to read the plot.",
        "ord_interpret(pr)"
      )
    ),
    partition = vctrs::vec_rbind(
      step(
        "Approach", "Variation partitioning",
        "You want the separate and shared contributions of sets of variables (e.g. environment and space).", ""
      ),
      step(
        "Test", "Adjusted R2 of each fraction; permutation tests of the testable fractions",
        "Only unique fractions can be tested; shared fractions are differences of R2.",
        sprintf("vp <- ord_varpart(data%s, Set1 = ~ ..., Set2 = ~ ...)\nautoplot(vp)", ab_txt)
      ),
      step(
        "Plots", "Venn diagram of the fractions (bars for four sets)",
        "Areas labelled with adjusted R2 show unique and shared contributions at a glance.",
        "autoplot(vp)"
      ),
      step(
        "Interpret", "Plain-language explanation of the tables and the diagram",
        "Variation explained, tests, directions of variables, groups, species at each end of the axes, and how to read the plot.",
        "ord_interpret(vp)"
      )
    )
  )
  # nolint end
  structure(list(checks = checks, advice = adv, gradient_length = gl, question = question),
    class = "td_ord_advice"
  )
}

#' @export
print.td_ord_advice <- function(x, ...) {
  cli::cli_h1("tidyvisor: which analysis?")
  cli::cli_text("Question: {.strong {x$question}}")
  cli::cli_h2("What the data show")
  for (i in seq_len(nrow(x$checks))) {
    r <- x$checks[i, ]
    note <- if (nzchar(r$meaning)) paste0(" \u2014 ", r$meaning) else ""
    cli::cli_bullets(c("*" = paste0(r$check, ": {.val ", r$value, "}", note)))
  }
  cli::cli_h2("Recommended")
  for (i in seq_len(nrow(x$advice))) {
    r <- x$advice[i, ]
    cli::cli_text("{.strong {r$step}}: {r$recommendation}")
    cli::cli_text("  {.emph {r$reason}}")
    if (nzchar(r$code)) cli::cli_code(strsplit(r$code, "\n")[[1]])
  }
  invisible(x)
}
