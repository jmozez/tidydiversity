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
#' `index = "jaccard"` they are the Jaccard equivalents.
#'
#' @inheritParams div_hill
#' @param index Family of dissimilarity, `"sorensen"` or `"jaccard"`.
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
#' @export
#' @examples
#' beta_pair(ant_gradient, .by = transect)
#'
#' beta_multi(ant_gradient, .by = transect, index = "jaccard")
beta_pair <- function(data,
                      site = site,
                      species = species,
                      abundance = NULL,
                      index = c("sorensen", "jaccard"),
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
                       index = c("sorensen", "jaccard"),
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
#' @param gradient <[`data-masking`][dplyr::dplyr_data_masking]> A numeric
#'   site attribute, constant within each site.
#' @return A `td_beta_decay` tibble like the output of [beta_pair()], with
#'   `gradient_1`, `gradient_2` and `distance` (absolute difference). Use
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
                       index = c("sorensen", "jaccard"),
                       .by = NULL) {
  index <- rlang::arg_match(index)
  call <- rlang::current_env()
  td_check_data(data)
  grad <- rlang::eval_tidy(enquo(gradient), data)
  if (!is.numeric(grad) || length(grad) != nrow(data)) {
    cli::cli_abort(
      "{.arg gradient} must be a numeric vector with one value per row."
    )
  }
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by)
  )
  site_col <- prep$site
  sites <- tibble::as_tibble(dplyr::ungroup(data)[prep$by])
  sites$.site <- data[[site_col]]
  sites$.g <- grad
  sites <- vctrs::vec_unique(sites)
  if (vctrs::vec_duplicate_any(sites[c(prep$by, ".site")])) {
    cli::cli_abort("{.arg gradient} must be constant within each site.")
  }
  pairs <- td_per_group(prep, function(d) beta_pair_impl(d, index, call = call))
  look <- function(s) {
    key <- pairs[prep$by]
    key$.site <- s
    sites$.g[vctrs::vec_match(key, sites[c(prep$by, ".site")])]
  }
  pairs$gradient_1 <- look(pairs$site_1)
  pairs$gradient_2 <- look(pairs$site_2)
  pairs$distance <- abs(pairs$gradient_2 - pairs$gradient_1)
  td_new(pairs, "td_beta_decay")
}

incidence_matrix <- function(d) {
  sites <- vctrs::vec_unique(d$.site)
  spp <- sort(unique(d$.species))
  mat <- matrix(0, length(sites), length(spp))
  mat[cbind(vctrs::vec_match(d$.site, sites), match(d$.species, spp))] <- 1
  list(mat = mat, sites = sites)
}

beta_pair_impl <- function(d, index, call = caller_env()) {
  inc <- incidence_matrix(d)
  mat <- inc$mat
  k <- nrow(mat)
  if (k < 2) {
    cli::cli_abort(
      "Beta diversity needs at least two sites in each group.",
      call = call
    )
  }
  ij <- utils::combn(k, 2)
  a <- rowSums(mat[ij[1, ], , drop = FALSE] * mat[ij[2, ], , drop = FALSE])
  si <- rowSums(mat)[ij[1, ]]
  sj <- rowSums(mat)[ij[2, ]]
  b <- si - a
  cc <- sj - a
  res <- beta_components(a, pmin(b, cc), pmax(b, cc), b + cc, index)
  tibble::tibble(
    site_1 = vctrs::vec_slice(inc$sites, ij[1, ]),
    site_2 = vctrs::vec_slice(inc$sites, ij[2, ]),
    !!!res
  )
}

beta_multi_impl <- function(d, index, call = caller_env()) {
  mat <- incidence_matrix(d)$mat
  k <- nrow(mat)
  if (k < 2) {
    cli::cli_abort(
      "Beta diversity needs at least two sites in each group.",
      call = call
    )
  }
  ij <- utils::combn(k, 2)
  shared <- rowSums(mat[ij[1, ], , drop = FALSE] * mat[ij[2, ], , drop = FALSE])
  s <- rowSums(mat)
  b <- s[ij[1, ]] - shared
  cc <- s[ij[2, ]] - shared
  a <- sum(s) - sum(colSums(mat) > 0)
  res <- beta_components(a, sum(pmin(b, cc)), sum(pmax(b, cc)),
    sum(b + cc), index,
    multi = TRUE
  )
  tibble::tibble(n_sites = k, !!!res)
}

beta_components <- function(a, mn, mx, bc, index, multi = FALSE) {
  if (index == "sorensen") {
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
