#' Mantel and partial Mantel tests
#'
#' @description
#' `beta_mantel()` tests whether two distance matrices are correlated,
#' for example community dissimilarity and elevational or geographic
#' distance, with the Mantel test (Mantel 1967). With `z`, it gives the
#' partial Mantel test of `x` and `y` controlling for `z` (Smouse et al.
#' 1986). Significance comes from permuting the sites of `x` (vegan's
#' [vegan::mantel()] and [vegan::mantel.partial()]).
#'
#' Pairs of sites are not independent, so do not test distance-decay
#' relationships with ordinary regression p-values; use this test instead.
#' With few sites, use `permutations = "exact"` to enumerate every ordering
#' of the sites (n!; 5,040 for 7 sites); the p-value is then exact.
#'
#' `alternative` sets the tail: `"greater"` (the default) tests for a
#' positive correlation, `"less"` for a negative one (for example
#' similarity decreasing with distance), `"two.sided"` for either.
#'
#' @param x,y,z Distance matrices: `dist` objects (such as the result of
#'   [beta_dist()]), square matrices, or, for `y` and `z`, a numeric vector
#'   of site values (such as elevation), from which Euclidean distances are
#'   computed. All must describe the same sites in the same order; when
#'   they carry labels, the labels are matched.
#' @param method Correlation: `"spearman"` (default), `"pearson"` or
#'   `"kendall"`.
#' @param permutations Number of permutations, or `"exact"`.
#' @param alternative `"greater"`, `"less"` or `"two.sided"`.
#' @param strata Optional grouping of sites within which permutations are
#'   restricted.
#' @param seed Optional random seed.
#' @return A one-row tibble with `statistic` (the Mantel r), `p.value`,
#'   `alternative`, `permutations`, `exact`, `method` and `partial`.
#' @references
#' Mantel, N. (1967). The detection of disease clustering and a
#' generalized regression approach. Cancer Research, 27, 209-220.
#'
#' Smouse, P. E., Long, J. C. and Sokal, R. R. (1986). Multiple regression
#' and correlation extensions of the Mantel test of matrix correspondence.
#' Systematic Zoology, 35, 627-632.
#' @export
#' @examplesIf requireNamespace("vegan", quietly = TRUE)
#' wet <- dplyr::filter(png_ants, season == "wet")
#' d_beta <- beta_dist(beta_pair(wet), "turnover")
#' elev <- dplyr::distinct(wet, site, elevation)
#' beta_mantel(d_beta, stats::setNames(elev$elevation, elev$site),
#'   permutations = "exact"
#' )
beta_mantel <- function(x,
                        y,
                        z = NULL,
                        method = c("spearman", "pearson", "kendall"),
                        permutations = 9999,
                        alternative = c("greater", "less", "two.sided"),
                        strata = NULL,
                        seed = NULL) {
  rlang::check_installed("vegan", "for Mantel tests.")
  method <- rlang::arg_match(method)
  alternative <- rlang::arg_match(alternative)
  x <- mantel_as_dist(x, "x")
  labels <- attr(x, "Labels")
  y <- mantel_as_dist(y, "y", labels, attr(x, "Size"))
  if (!is.null(z)) z <- mantel_as_dist(z, "z", labels, attr(x, "Size"))
  n <- attr(x, "Size")
  perm <- ord_permutations(permutations, n)
  if (!is.null(strata)) {
    if (perm$exact) {
      cli::cli_abort("Exact permutations cannot be combined with {.arg strata}.")
    }
    perm$how <- permute::how(nperm = permutations, blocks = strata)
  }
  if (!is.null(seed)) set.seed(seed)
  res <- suppressMessages(if (is.null(z)) {
    vegan::mantel(x, y, method = method, permutations = perm$how)
  } else {
    vegan::mantel.partial(x, y, z, method = method, permutations = perm$how)
  })
  r <- unname(res$statistic)
  pn <- res$perm
  k <- length(pn)
  p <- switch(alternative,
    greater = (sum(pn >= r - 1e-12) + 1) / (k + 1),
    less = (sum(pn <= r + 1e-12) + 1) / (k + 1),
    two.sided = (sum(abs(pn) >= abs(r) - 1e-12) + 1) / (k + 1)
  )
  tibble::tibble(
    statistic = r, p.value = p, alternative = alternative,
    permutations = k, exact = perm$exact, method = method,
    partial = !is.null(z)
  )
}

mantel_as_dist <- function(x, arg, labels = NULL, size = NULL,
                           call = caller_env()) {
  if (inherits(x, "dist")) {
    d <- x
  } else if (is.matrix(x) && nrow(x) == ncol(x)) {
    d <- stats::as.dist(x)
  } else if (is.numeric(x) && is.null(dim(x))) {
    d <- stats::dist(x)
    if (!is.null(names(x))) attr(d, "Labels") <- names(x)
  } else {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls dist}, a square matrix or a numeric vector.",
      call = call
    )
  }
  if (!is.null(size) && attr(d, "Size") != size) {
    cli::cli_abort(
      "{.arg {arg}} has {attr(d, 'Size')} sites but {.arg x} has {size}.",
      call = call
    )
  }
  lab <- attr(d, "Labels")
  if (!is.null(labels) && !is.null(lab)) {
    if (!setequal(lab, labels)) {
      cli::cli_abort("The sites of {.arg {arg}} and {.arg x} differ.", call = call)
    }
    if (!identical(lab, labels)) {
      m <- as.matrix(d)[labels, labels]
      d <- stats::as.dist(m)
    }
  }
  d
}
