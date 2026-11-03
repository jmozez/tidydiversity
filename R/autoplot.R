#' Plot tidydiversity results
#'
#' `autoplot()` methods draw a ggplot for every result type:
#'
#' * [div_hill()]: a Hill diversity profile across `q`, or diversity along a
#'   gradient column when `gradient` is given.
#' * [div_estimate()]: observed and asymptotic diversity with intervals.
#' * [div_coverage()]: sample coverage against sample size.
#' * [div_rarefy()]: rarefaction and extrapolation curves by sample size or
#'   by sample coverage.
#' * [beta_pair()]: a pairwise dissimilarity heatmap.
#' * [beta_multi()]: multi-site turnover and nestedness as stacked bars.
#' * [beta_decay()]: distance decay of dissimilarity components.
#'
#' They need the ggplot2 package.
#'
#' @param object A tibble returned by one of the functions above.
#' @param x For curves, plot against sample size (`"size"`) or sample
#'   coverage (`"coverage"`).
#' @param gradient For [div_hill()] results, an optional numeric column
#'   (such as `elevation`, kept by `.by`) to plot diversity along.
#' @param component For [beta_pair()] results, the component to map to
#'   colour: `"total"`, `"turnover"` or `"nestedness"`.
#' @param ... Not used.
#' @return A ggplot object.
#' @name autoplot-tidydiversity
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' library(ggplot2)
#' curves <- div_rarefy(ant_gradient, q = c(0, 1), .by = transect, knots = 20)
#' autoplot(curves)
#' autoplot(curves, x = "coverage")
#'
#' div_hill(ant_gradient, q = seq(0, 3, by = 0.25), .by = transect) |>
#'   autoplot()
#' div_hill(ant_gradient, .by = c(transect, elevation)) |>
#'   autoplot(gradient = elevation)
#'
#' set.seed(1)
#' autoplot(div_estimate(ant_gradient, .by = transect, nboot = 20))
#' autoplot(div_coverage(ant_gradient, .by = transect))
#'
#' autoplot(beta_pair(ant_gradient, .by = transect))
#' autoplot(beta_multi(ant_gradient, .by = transect))
#'
#' beta_decay(ant_gradient, gradient = elevation, .by = transect) |>
#'   autoplot()
NULL

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_rarefy <- function(object, x = c("size", "coverage"), ...) {
  rlang::check_installed("ggplot2")
  x <- rlang::arg_match(x)
  xvar <- if (x == "size") "m" else "coverage"
  site_col <- setdiff(
    names(object),
    c("q", "m", "method", "diversity", "coverage", "lower", "upper")
  )
  site_col <- site_col[length(site_col)]
  df <- tibble::as_tibble(unclass(object))
  df$.x <- df[[xvar]]
  df$.site <- as.character(df[[site_col]])
  df$.q <- paste0("q = ", df$q)
  df$.line <- ifelse(df$method == "extrapolation", "extrapolation",
    "rarefaction"
  )
  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(.data$.x, .data$diversity, colour = .data$.site)
  )
  if (!all(is.na(df$lower))) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$lower, ymax = .data$upper, fill = .data$.site
      ),
      alpha = 0.15, colour = NA
    )
  }
  p +
    ggplot2::geom_line(ggplot2::aes(linetype = .data$.line)) +
    ggplot2::geom_point(data = df[df$method == "observed", ], size = 2) +
    ggplot2::scale_linetype_manual(
      values = c(rarefaction = "solid", extrapolation = "dashed")
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$.q), scales = "free_y") +
    ggplot2::labs(
      x = if (x == "size") "Number of individuals" else "Sample coverage",
      y = "Diversity",
      colour = site_col,
      fill = site_col,
      linetype = NULL
    )
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_beta_decay <- function(object, ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  long <- data.frame(
    distance = rep(df$distance, 3),
    component = factor(
      rep(c("total", "turnover", "nestedness"), each = nrow(df)),
      levels = c("total", "turnover", "nestedness")
    ),
    value = c(df$total, df$turnover, df$nestedness)
  )
  ggplot2::ggplot(
    long,
    ggplot2::aes(.data$distance, .data$value, colour = .data$component)
  ) +
    ggplot2::geom_point(alpha = 0.7) +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE) +
    ggplot2::labs(x = "Distance along gradient", y = "Dissimilarity",
      colour = NULL
    )
}

td_site_col <- function(object, drop) {
  cols <- setdiff(names(object), drop)
  cols[length(cols)]
}

td_label_col <- function(df, cols) {
  if (length(cols) == 0) {
    return(rep("all", nrow(df)))
  }
  do.call(paste, c(lapply(df[cols], as.character), sep = " "))
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_hill <- function(object, gradient = NULL, ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  grad <- rlang::enquo(gradient)
  site_col <- td_site_col(df, c("q", "n", "diversity"))
  if (!rlang::quo_is_null(grad)) {
    gcol <- tidyselect::eval_select(grad, df)
    gcol <- names(gcol)
    if (length(gcol) != 1 || !is.numeric(df[[gcol]])) {
      cli::cli_abort("{.arg gradient} must select one numeric column.")
    }
    by_cols <- setdiff(
      names(df), c(gcol, site_col, "q", "n", "diversity")
    )
    df$.x <- df[[gcol]]
    df$.group <- td_label_col(df, by_cols)
    df$.q <- paste0("q = ", df$q)
    return(
      ggplot2::ggplot(
        df, ggplot2::aes(.data$.x, .data$diversity, colour = .data$.group)
      ) +
        ggplot2::geom_line() +
        ggplot2::geom_point(size = 2) +
        ggplot2::facet_wrap(ggplot2::vars(.data$.q), scales = "free_y") +
        ggplot2::labs(
          x = gcol, y = "Diversity",
          colour = if (length(by_cols)) paste(by_cols, collapse = " ")
        )
    )
  }
  df$.site <- as.character(df[[site_col]])
  ggplot2::ggplot(
    df, ggplot2::aes(.data$q, .data$diversity, colour = .data$.site)
  ) +
    ggplot2::geom_line() +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::labs(
      x = "Order q", y = "Hill number", colour = site_col
    )
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_estimate <- function(object, ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  site_col <- td_site_col(
    df, c("q", "observed", "estimate", "se", "lower", "upper")
  )
  df$.site <- factor(df[[site_col]], levels = unique(df[[site_col]]))
  df$.q <- paste0("q = ", df$q)
  ggplot2::ggplot(df, ggplot2::aes(y = .data$.site)) +
    ggplot2::geom_linerange(
      ggplot2::aes(xmin = .data$lower, xmax = .data$upper),
      colour = "grey55"
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = .data$observed, shape = "observed"), size = 2
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = .data$estimate, shape = "asymptotic"), size = 2
    ) +
    ggplot2::scale_shape_manual(
      values = c(observed = 1, asymptotic = 16)
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$.q), scales = "free_x") +
    ggplot2::labs(x = "Diversity", y = site_col, shape = NULL)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_coverage <- function(object, ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  site_col <- td_site_col(df, c("n", "s_obs", "f1", "f2", "coverage"))
  by_cols <- setdiff(
    names(df), c(site_col, "n", "s_obs", "f1", "f2", "coverage")
  )
  df$.group <- td_label_col(df, by_cols)
  ggplot2::ggplot(
    df, ggplot2::aes(.data$n, .data$coverage, colour = .data$.group)
  ) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::labs(
      x = "Number of individuals", y = "Sample coverage",
      colour = if (length(by_cols)) paste(by_cols, collapse = " ")
    )
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_beta_pair <- function(object,
                                  component = c("total", "turnover",
                                                "nestedness"),
                                  ...) {
  rlang::check_installed("ggplot2")
  component <- rlang::arg_match(component)
  df <- tibble::as_tibble(unclass(object))
  by_cols <- setdiff(
    names(df), c("site_1", "site_2", "turnover", "nestedness", "total")
  )
  swap <- df
  swap$site_1 <- df$site_2
  swap$site_2 <- df$site_1
  both <- vctrs::vec_rbind(df, swap)
  both$.value <- both[[component]]
  p <- ggplot2::ggplot(
    both, ggplot2::aes(.data$site_1, .data$site_2, fill = .data$.value)
  ) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_viridis_c(limits = c(0, 1)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = NULL, y = NULL, fill = component) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    )
  if (length(by_cols)) {
    both$.group <- td_label_col(both, by_cols)
    p <- ggplot2::`%+%`(p, both) +
      ggplot2::facet_wrap(ggplot2::vars(.data$.group), scales = "free")
    p$coordinates <- ggplot2::coord_cartesian()
  }
  p
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_beta_multi <- function(object, ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  by_cols <- setdiff(
    names(df), c("n_sites", "turnover", "nestedness", "total")
  )
  df$.group <- td_label_col(df, by_cols)
  long <- data.frame(
    group = rep(df$.group, 2),
    component = factor(
      rep(c("nestedness", "turnover"), each = nrow(df)),
      levels = c("nestedness", "turnover")
    ),
    value = c(df$nestedness, df$turnover)
  )
  ggplot2::ggplot(
    long, ggplot2::aes(.data$group, .data$value, fill = .data$component)
  ) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::labs(
      x = if (length(by_cols)) paste(by_cols, collapse = " "),
      y = "Multi-site dissimilarity", fill = NULL
    )
}
