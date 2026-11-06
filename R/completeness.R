#' Sample completeness profiles
#'
#' Estimates sample completeness of order `q` for each site (Chao et al.
#' 2020). Completeness at q = 0 is the proportion of species richness
#' detected, at q = 1 it is the sample coverage, and higher orders give
#' increasing weight to abundant species. Values lie between 0 and 1.
#'
#' @inheritParams div_estimate
#' @param nboot Number of bootstrap replicates. Use 0 to skip them.
#' @param q Orders of completeness, non-negative numbers. Defaults to a
#'   profile from 0 to 2.
#' @return A `td_completeness` tibble with the grouping columns, the site
#'   column, `q`, `completeness`, `se`, `lower` and `upper`.
#' @references Chao, A., Kubota, Y., Zeleny, D., Chiu, C.-H., Li, C.-F.,
#'   Kusumoto, B., Yasuhara, M., Thorn, S., Wei, C.-L., Costello, M. J. and
#'   Colwell, R. K. (2020). Quantifying sample completeness and comparing
#'   diversities among assemblages. Ecological Research, 35, 292-314.
#'   \doi{10.1111/1440-1703.12102}
#' @export
#' @examples
#' div_completeness(png_ants, q = c(0, 1, 2), .by = season, nboot = 0)
div_completeness <- function(data,
                             site = site,
                             species = species,
                             abundance = NULL,
                             q = seq(0, 2, 0.2),
                             conf = 0.95,
                             nboot = 50,
                             .by = NULL) {
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE
  )
  td_check_min_n(prep)
  q <- td_check_q(q, finite = TRUE)
  td_check_number(conf, "conf", 0, 1)
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  z <- stats::qnorm(1 - (1 - conf) / 2)
  out <- td_per_site(prep, function(x, i) {
    est <- completeness_q(x, q)
    draws <- boot_draws(x, nboot, function(xb, d) completeness_q(xb, q))
    se <- as.vector(boot_se(draws, length(q)))
    tibble::tibble(
      q = q,
      completeness = est,
      se = se,
      lower = pmax(est - z * se, 0),
      upper = pmin(est + z * se, 1)
    )
  })
  td_new(out, "td_completeness")
}

completeness_q <- function(x, q) {
  x <- x[x > 0]
  n <- sum(x)
  f1 <- sum(x == 1)
  f2 <- sum(x == 2)
  big_a <- coverage_big_a(n, f1, f2)
  vapply(q, function(qq) {
    if (qq == 0) {
      length(x) / (length(x) + f0_hat(n, f1, f2))
    } else if (qq == 1) {
      1 - f1 / n * (1 - big_a)
    } else if (qq == 2) {
      x2 <- x[x >= 2]
      1 - f1 / n * (big_a * (1 - big_a) / sum(x2 * (x2 - 1) / (n * (n - 1))))
    } else {
      lambda <- hill_asy_q(x, qq, n, f1, f2)
      1 - f1 / n * big_a^(qq - 1) * (1 - big_a) / lambda
    }
  }, numeric(1))
}

#' Evenness profiles
#'
#' Computes the five classes of Hill-number evenness of Chao and Ricotta
#' (2019) for each site, either from the observed sample or from diversity
#' standardised to a common sample coverage, as in iNEXT.4steps.
#'
#' @inheritParams div_completeness
#' @param class Evenness classes to return, any of `"E1"` to `"E5"`.
#' @param method `"estimated"` (the default) uses diversity standardised to
#'   `coverage`; `"observed"` uses the observed sample.
#' @param coverage Target coverage for `method = "estimated"`. Defaults to
#'   the lowest coverage that every site in a group reaches at twice its
#'   sample size.
#' @return A `td_evenness` tibble with the grouping columns, the site
#'   column, `class`, `q`, `evenness`, `se`, `lower` and `upper`, and
#'   `coverage` for the estimated method.
#' @references Chao, A. and Ricotta, C. (2019). Quantifying evenness and
#'   linking it to diversity, beta diversity, and similarity. Ecology, 100,
#'   e02852. \doi{10.1002/ecy.2852}
#'
#'   Chao, A. et al. (2020). Quantifying sample completeness and comparing
#'   diversities among assemblages. Ecological Research, 35, 292-314.
#'   \doi{10.1111/1440-1703.12102}
#' @export
#' @examples
#' div_evenness(png_ants, q = c(0, 1, 2), .by = season, nboot = 0)
div_evenness <- function(data,
                         site = site,
                         species = species,
                         abundance = NULL,
                         q = seq(0, 2, 0.2),
                         class = c("E1", "E2", "E3", "E4", "E5"),
                         method = c("estimated", "observed"),
                         coverage = NULL,
                         conf = 0.95,
                         nboot = 50,
                         .by = NULL) {
  method <- rlang::arg_match(method)
  class <- rlang::arg_match(class, multiple = TRUE)
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE
  )
  td_check_min_n(prep)
  q <- td_check_q(q)
  td_check_number(conf, "conf", 0, 1)
  td_check_number(nboot, "nboot", 0, whole = TRUE)
  if (!is.null(coverage)) td_check_number(coverage, "coverage", 0, 1)
  z <- stats::qnorm(1 - (1 - conf) / 2)
  level <- if (method == "estimated") {
    coverage %||% default_coverage(prep)
  } else {
    NULL
  }
  out <- td_per_site(prep, function(x, i) {
    target <- if (is.null(level)) NULL else level[min(i, length(level))]
    est <- evenness_q(x, q, class, target)
    draws <- boot_draws(x, nboot, function(xb, d) evenness_q(xb, q, class, target))
    se <- as.vector(boot_se(draws, length(est)))
    nq <- length(q)
    ncl <- length(class)
    res <- tibble::tibble(
      class = rep(class, each = nq),
      q = rep(q, times = ncl),
      evenness = est,
      se = se,
      lower = pmax(est - z * se, 0),
      upper = pmin(est + z * se, 1)
    )
    if (!is.null(target)) res$coverage <- target
    res
  })
  td_new(out, "td_evenness")
}

evenness_q <- function(x, q, class, target) {
  if (is.null(target)) {
    d <- hill_obs(x, q)
    s <- length(x[x > 0])
  } else {
    m <- size_for_coverage(x, target)
    d <- as.vector(hill_at_size(x, m, q))
    s <- as.vector(hill_at_size(x, m, 0))
  }
  unlist(lapply(class, function(cl) {
    switch(cl,
      E1 = ifelse(q != 1, (1 - d^(1 - q)) / (1 - s^(1 - q)), log(d) / log(s)),
      E2 = ifelse(q != 1, (1 - d^(q - 1)) / (1 - s^(q - 1)), log(d) / log(s)),
      E3 = (d - 1) / (s - 1),
      E4 = (1 - 1 / d) / (1 - 1 / s),
      E5 = log(d) / log(s)
    )
  }))
}

# Lowest coverage that every site in a group reaches at twice its size,
# returned per site in td_per_site order.
default_coverage <- function(prep) {
  sites <- vctrs::vec_split(prep$data, prep$data[c(prep$by, ".site")])
  c2n <- vapply(sites$val, function(s) {
    coverage_at_size(s$.n, 2 * sum(s$.n))
  }, numeric(1))
  grp <- vctrs::vec_group_id(sites$key[prep$by])
  if (length(prep$by) == 0) grp <- rep(1L, length(c2n))
  stats::ave(c2n, grp, FUN = min)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_completeness <- function(object,
                                     palette = "okabe_ito",
                                     theme = theme_tidydiversity(),
                                     xlab = "Order q",
                                     ylab = "Sample completeness",
                                     ...) {
  profile_plot(object, "completeness", palette, theme, xlab, ylab, NULL)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_evenness <- function(object,
                                 palette = "okabe_ito",
                                 theme = theme_tidydiversity(),
                                 xlab = "Order q",
                                 ylab = "Evenness",
                                 ...) {
  profile_plot(object, "evenness", palette, theme, xlab, ylab, "class")
}

profile_plot <- function(object, value, palette, theme, xlab, ylab, facet) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  stats_cols <- c(facet, "q", value, "se", "lower", "upper", "coverage")
  keys <- setdiff(names(df), stats_cols)
  df$.group <- td_label_col(df, keys)
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$q, .data[[value]],
    colour = .data$.group, fill = .data$.group
  ))
  if (any(!is.na(df$se))) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
      alpha = 0.2, colour = NA
    )
  }
  p <- p + ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::labs(x = xlab, y = ylab, colour = NULL, fill = NULL)
  if (!is.null(facet)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[facet]]))
  }
  td_style(p, palette, theme, fill = TRUE)
}
