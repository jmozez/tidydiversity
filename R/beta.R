#' Partition beta diversity into turnover and nestedness
#'
#' @description
#' `beta_pair()` computes pairwise dissimilarity between sites and splits it
#' into turnover (species replacement) and nestedness (species loss)
#' components following Baselga (2010, 2012). `beta_multi()` computes the
#' multiple-site version for all sites in each group. Both use presence and
#' absence, so any positive abundance counts as presence.
#'
#' With `index = "sorensen"` the components are Simpson turnover, the
#' nestedness-resultant component and Sorensen dissimilarity. With
#' `index = "jaccard"` they are the Jaccard equivalents. With
#' `index = "bray"` abundances are used: `turnover` is the balanced
#' variation in abundance and `nestedness` the abundance gradient component
#' of Bray-Curtis dissimilarity (Baselga 2013), matching
#' [betapart::beta.pair.abund()] and [betapart::beta.multi.abund()].
#'
#' @inheritParams div_hill
#' @param index Family of dissimilarity: `"sorensen"` or `"jaccard"`
#'   (presence and absence) or `"bray"` (abundance-based Bray-Curtis).
#' @return `beta_pair()` returns a tibble with the grouping columns,
#'   `site_1`, `site_2`, `turnover`, `nestedness` and `total`.
#'   `beta_multi()` returns one row per group with `n_sites`, `turnover`,
#'   `nestedness` and `total`.
#' @references Baselga, A. (2010). Partitioning the turnover and nestedness
#'   components of beta diversity. Global Ecology and Biogeography, 19,
#'   134-143. \doi{10.1111/j.1466-8238.2009.00490.x}
#'
#'   Baselga, A. (2012). The relationship between species replacement,
#'   dissimilarity derived from nestedness, and nestedness. Global Ecology
#'   and Biogeography, 21, 1223-1232. \doi{10.1111/j.1466-8238.2011.00756.x}
#'
#'   Baselga, A. (2013). Separating the two components of abundance-based
#'   dissimilarity: balanced changes in abundance vs. abundance gradients.
#'   Methods in Ecology and Evolution, 4, 552-557.
#'   \doi{10.1111/2041-210X.12029}
#' @export
#' @examples
#' beta_pair(ant_gradient, .by = transect)
#'
#' beta_multi(ant_gradient, .by = transect, index = "jaccard")
beta_pair <- function(data,
                      site = site,
                      species = species,
                      abundance = NULL,
                      index = c("sorensen", "jaccard", "bray"),
                      .by = NULL) {
  index <- rlang::arg_match(index)
  call <- rlang::current_env()
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  out <- td_per_group(prep, function(d) beta_pair_impl(d, index, call = call))
  td_new(out, "td_beta_pair")
}

#' @rdname beta_pair
#' @export
beta_multi <- function(data,
                       site = site,
                       species = species,
                       abundance = NULL,
                       index = c("sorensen", "jaccard", "bray"),
                       .by = NULL) {
  index <- rlang::arg_match(index)
  call <- rlang::current_env()
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  out <- td_per_group(prep, function(d) beta_multi_impl(d, index, call = call))
  td_new(out, "td_beta_multi")
}

#' Distance decay of similarity
#'
#' Pairs the pairwise beta diversity from [beta_pair()] with the distance
#' between sites along a gradient, such as elevation, to study how
#' dissimilarity and its components change with distance.
#'
#' @inheritParams beta_pair
#' @param gradient <[`tidy-select`][dplyr::dplyr_tidy_select]> One or more
#'   numeric site attributes, constant within each site. With one column
#'   (such as `elevation`) the distance is the absolute difference; with
#'   several (such as `c(x, y)` coordinates) it is the Euclidean distance.
#' @return A `td_beta_decay` tibble like the output of [beta_pair()], with
#'   `distance` and, for a single gradient column, `gradient_1` and
#'   `gradient_2`. Use
#'   [ggplot2::autoplot()] to plot it.
#' @export
#' @examples
#' decay <- beta_decay(ant_gradient, gradient = elevation, .by = transect)
#' decay
beta_decay <- function(data,
                       gradient,
                       site = site,
                       species = species,
                       abundance = NULL,
                       index = c("sorensen", "jaccard", "bray"),
                       .by = NULL) {
  index <- rlang::arg_match(index)
  call <- rlang::current_env()
  td_check_data(data)
  gcols <- names(tidyselect::eval_select(enquo(gradient), data))
  numeric_ok <- all(vapply(data[gcols], is.numeric, logical(1)))
  if (length(gcols) == 0 || !numeric_ok) {
    cli::cli_abort(
      "{.arg gradient} must select one or more numeric columns."
    )
  }
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  site_col <- prep$site
  sites <- tibble::as_tibble(dplyr::ungroup(data)[prep$by])
  sites$.site <- data[[site_col]]
  sites$.g <- as.matrix(data[gcols])
  sites <- vctrs::vec_unique(sites)
  if (vctrs::vec_duplicate_any(sites[c(prep$by, ".site")])) {
    cli::cli_abort("{.arg gradient} must be constant within each site.")
  }
  pairs <- td_per_group(prep, function(d) beta_pair_impl(d, index, call = call))
  look <- function(s) {
    key <- pairs[prep$by]
    key$.site <- s
    sites$.g[vctrs::vec_match(key, sites[c(prep$by, ".site")]), ,
      drop = FALSE
    ]
  }
  g1 <- look(pairs$site_1)
  g2 <- look(pairs$site_2)
  if (length(gcols) == 1) {
    pairs$gradient_1 <- as.vector(g1)
    pairs$gradient_2 <- as.vector(g2)
  }
  pairs$distance <- sqrt(rowSums((g1 - g2)^2))
  td_new(pairs, "td_beta_decay")
}

incidence_matrix <- function(d, abundance = FALSE) {
  sites <- vctrs::vec_unique(d$.site)
  spp <- sort(unique(d$.species))
  mat <- matrix(0, length(sites), length(spp))
  idx <- cbind(vctrs::vec_match(d$.site, sites), match(d$.species, spp))
  mat[idx] <- if (abundance) d$.n else 1
  list(mat = mat, sites = sites)
}

pair_parts <- function(mat, ij, abundance) {
  if (abundance) {
    x <- mat[ij[1, ], , drop = FALSE]
    y <- mat[ij[2, ], , drop = FALSE]
    a <- rowSums(pmin(x, y))
    list(a = a, b = rowSums(x) - a, c = rowSums(y) - a)
  } else {
    a <- rowSums(mat[ij[1, ], , drop = FALSE] * mat[ij[2, ], , drop = FALSE])
    s <- rowSums(mat)
    list(a = a, b = s[ij[1, ]] - a, c = s[ij[2, ]] - a)
  }
}

beta_pair_impl <- function(d, index, call = caller_env()) {
  inc <- incidence_matrix(d, abundance = index == "bray")
  mat <- inc$mat
  k <- nrow(mat)
  if (k < 2) {
    cli::cli_abort(
      "Beta diversity needs at least two sites in each group.",
      call = call
    )
  }
  ij <- utils::combn(k, 2)
  pp <- pair_parts(mat, ij, index == "bray")
  a <- pp$a
  b <- pp$b
  cc <- pp$c
  res <- beta_components(a, pmin(b, cc), pmax(b, cc), b + cc, index)
  tibble::tibble(
    site_1 = vctrs::vec_slice(inc$sites, ij[1, ]),
    site_2 = vctrs::vec_slice(inc$sites, ij[2, ]),
    !!!res
  )
}

beta_multi_impl <- function(d, index, call = caller_env()) {
  mat <- incidence_matrix(d, abundance = index == "bray")$mat
  k <- nrow(mat)
  if (k < 2) {
    cli::cli_abort(
      "Beta diversity needs at least two sites in each group.",
      call = call
    )
  }
  ij <- utils::combn(k, 2)
  pp <- pair_parts(mat, ij, index == "bray")
  b <- pp$b
  cc <- pp$c
  if (index == "bray") {
    a <- sum(mat) - sum(apply(mat, 2, max))
  } else {
    a <- sum(rowSums(mat)) - sum(colSums(mat) > 0)
  }
  res <- beta_components(a, sum(pmin(b, cc)), sum(pmax(b, cc)),
    sum(b + cc), index,
    multi = TRUE
  )
  tibble::tibble(n_sites = k, !!!res)
}

beta_components <- function(a, mn, mx, bc, index, multi = FALSE) {
  if (index %in% c("sorensen", "bray")) {
    turnover <- mn / (a + mn)
    nested <- (mx - mn) / (2 * a + bc) * a / (a + mn)
    total <- bc / (2 * a + bc)
  } else {
    turnover <- 2 * mn / (a + 2 * mn)
    nested <- (mx - mn) / (a + bc) * a / (a + 2 * mn)
    total <- bc / (a + bc)
  }
  turnover[is.nan(turnover)] <- 0
  nested[is.nan(nested)] <- 0
  list(turnover = turnover, nestedness = nested, total = total)
}

#' Pairwise dissimilarity as a distance matrix
#'
#' Returns one component of [beta_pair()] as a [stats::dist] object, ready
#' for ordination and testing with vegan, for example
#' [vegan::metaMDS()], [vegan::adonis2()] or [vegan::betadisper()], or for
#' clustering with [stats::hclust()].
#'
#' @param x A `td_beta_pair` tibble from [beta_pair()], without groups.
#' @param component Component to use: `"total"`, `"turnover"` or
#'   `"nestedness"`.
#' @return A `dist` object labelled with the site names, in their order of
#'   first appearance.
#' @export
#' @examples
#' d <- beta_dist(beta_pair(ant_gradient[ant_gradient$transect == "north", ]))
#' hclust(d)
beta_dist <- function(x, component = c("total", "turnover", "nestedness")) {
  component <- rlang::arg_match(component)
  if (!inherits(x, "td_beta_pair") && !inherits(x, "td_beta_decay")) {
    cli::cli_abort("{.arg x} must be the output of {.fn beta_pair}.")
  }
  extra <- setdiff(
    names(x),
    c(
      "site_1", "site_2", "turnover", "nestedness", "total",
      "gradient_1", "gradient_2", "distance"
    )
  )
  if (length(extra) > 0) {
    cli::cli_abort(c(
      "{.arg x} must hold a single group.",
      "i" = "Filter the grouping column{?s} {.field {extra}} first."
    ))
  }
  labs <- unique(c(as.character(x$site_1), as.character(x$site_2)))
  m <- matrix(0, length(labs), length(labs), dimnames = list(labs, labs))
  i <- match(as.character(x$site_1), labs)
  j <- match(as.character(x$site_2), labs)
  m[cbind(i, j)] <- x[[component]]
  m[cbind(j, i)] <- x[[component]]
  stats::as.dist(m)
}
