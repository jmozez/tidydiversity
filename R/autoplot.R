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
#' * [div_standardise()]: standardised diversity with intervals.
#' * [beta_pair()]: a pairwise dissimilarity heatmap.
#' * [beta_multi()]: multi-site turnover and nestedness as stacked bars.
#' * [beta_decay()]: distance decay of dissimilarity components.
#'
#' Every method returns an ordinary ggplot object, so labels, scales,
#' themes and facets can be changed afterwards with `+`, for example
#' `+ labs(x = "Number of workers")`, and saved with [ggplot2::ggsave()].
#' The defaults use [theme_tidydiversity()] and the colour-blind-safe
#' Okabe-Ito palette. Solid lines show rarefaction (interpolation), dashed
#' lines extrapolation, points the observed sample, and shaded ribbons or
#' bars the bootstrap confidence intervals when they were computed.
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
#' @param palette Colours for sites or groups: `"okabe_ito"` (default),
#'   `"grey"`, a character vector of colours, or `NULL` to keep the ggplot2
#'   default so you can add your own scale.
#' @param theme A ggplot2 theme added to the plot, by default
#'   [theme_tidydiversity()]. Use `NULL` to keep the ggplot2 default.
#' @param ci Draw confidence intervals when the result has them.
#' @param facet For results with several orders `q`, facet by `q`
#'   (`TRUE`, the default) or draw all orders on one panel with `q` mapped
#'   to line type or shape (`FALSE`). Curves computed with `.by` groups are
#'   also faceted by group.
#' @param scales Facet scales, passed to [ggplot2::facet_wrap()].
#' @param ncol Number of facet columns.
#' @param xlab,ylab Axis titles. The defaults describe the quantity and,
#'   where relevant, its unit.
#' @param ... Not used.
#' @return A ggplot object.
#' @name autoplot-tidydiversity
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' library(ggplot2)
#' curves <- div_rarefy(ant_gradient, q = c(0, 1), .by = transect, knots = 20)
#' autoplot(curves)
#' autoplot(curves, x = "coverage")
#'
#' # Customise like any ggplot
#' autoplot(curves, palette = "grey", ncol = 1) +
#'   labs(x = "Number of workers") +
#'   theme_tidydiversity(base_size = 9)
#'
#' div_hill(ant_gradient, q = seq(0, 3, by = 0.25), .by = transect) |>
#'   autoplot()
#' div_hill(ant_gradient, .by = c(transect, elevation)) |>
#'   autoplot(gradient = elevation, xlab = "Elevation (m)")
#'
#' set.seed(1)
#' autoplot(div_estimate(ant_gradient, .by = transect, nboot = 20))
#' autoplot(div_coverage(ant_gradient, .by = transect))
#' autoplot(div_standardise(ant_gradient, .by = transect, nboot = 20))
#'
#' autoplot(beta_pair(ant_gradient, .by = transect))
#' autoplot(beta_multi(ant_gradient, .by = transect))
#'
#' beta_decay(ant_gradient, gradient = elevation, .by = transect) |>
#'   autoplot(xlab = "Difference in elevation (m)")
NULL

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

q_label <- function(q) {
  factor(paste0("q = ", q), levels = paste0("q = ", sort(unique(q))))
}

y_hill <- "Diversity (effective number of species)"

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_rarefy <- function(object,
                               x = c("size", "coverage"),
                               palette = "okabe_ito",
                               theme = theme_tidydiversity(),
                               ci = TRUE,
                               facet = TRUE,
                               scales = "free_y",
                               ncol = NULL,
                               xlab = NULL,
                               ylab = y_hill,
                               ...) {
  rlang::check_installed("ggplot2")
  x <- rlang::arg_match(x)
  xvar <- if (x == "size") "m" else "coverage"
  known <- c("q", "m", "method", "diversity", "coverage", "se", "lower",
    "upper")
  site_col <- td_site_col(object, known)
  by_cols <- setdiff(names(object), c(site_col, known))
  df <- tibble::as_tibble(unclass(object))
  df$.x <- df[[xvar]]
  df$.site <- as.character(df[[site_col]])
  df$.by <- td_label_col(df, by_cols)
  df$.q <- q_label(df$q)
  # Split into rarefied and extrapolated parts that share the observed point.
  rare <- df[df$method != "extrapolation", ]
  rare$.line <- "rarefaction"
  extra <- df[df$method != "rarefaction", ]
  extra$.line <- "extrapolation"
  lines <- vctrs::vec_rbind(rare, extra)
  lines$.line <- factor(lines$.line, c("rarefaction", "extrapolation"))
  lines$.grp <- paste(lines$.by, lines$.site, lines$q, lines$.line)
  aes_col <- if (facet) {
    ggplot2::aes(.data$.x, .data$diversity, colour = .data$.site)
  } else {
    ggplot2::aes(.data$.x, .data$diversity, colour = .data$.site,
      shape = .data$.q)
  }
  p <- ggplot2::ggplot(lines, aes_col)
  if (ci && !all(is.na(df$lower))) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(
        x = .data$.x, ymin = .data$lower, ymax = .data$upper,
        fill = .data$.site, group = paste(.data$.by, .data$.site, .data$q)
      ),
      data = df, alpha = 0.2, colour = NA, inherit.aes = FALSE
    )
  }
  p <- p +
    ggplot2::geom_line(ggplot2::aes(linetype = .data$.line,
      group = .data$.grp), linewidth = 0.7) +
    ggplot2::geom_point(data = df[df$method == "observed", ], size = 2.2) +
    ggplot2::scale_linetype_manual(
      values = c(rarefaction = "solid", extrapolation = "dashed"),
      drop = FALSE
    ) +
    ggplot2::scale_y_continuous(limits = c(0, NA)) +
    ggplot2::labs(
      x = xlab %||% if (x == "size") {
        "Number of individuals"
      } else {
        "Sample coverage"
      },
      y = ylab,
      colour = site_col,
      fill = site_col,
      shape = "Order",
      linetype = NULL
    )
  if (x == "coverage") {
    p <- p + ggplot2::scale_x_continuous(limits = c(NA, 1))
  }
  if (facet && length(by_cols)) {
    p <- p + ggplot2::facet_grid(ggplot2::vars(.data$.by),
      ggplot2::vars(.data$.q), scales = scales)
  } else if (facet) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.q), scales = scales,
      ncol = ncol)
  } else if (length(by_cols)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.by), scales = scales,
      ncol = ncol)
  }
  td_style(p, palette, theme)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_standardise <- function(object,
                                    palette = "okabe_ito",
                                    theme = theme_tidydiversity(),
                                    ci = TRUE,
                                    facet = TRUE,
                                    scales = "free_x",
                                    ncol = NULL,
                                    xlab = NULL,
                                    ylab = NULL,
                                    ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  site_col <- td_site_col(
    df, c("q", "m", "method", "coverage", "diversity", "se", "lower",
      "upper")
  )
  by_cols <- setdiff(
    names(df), c(site_col, "q", "m", "method", "coverage", "diversity",
      "se", "lower", "upper")
  )
  df$.group <- td_label_col(df, by_cols)
  lab <- td_label_col(df, c(by_cols, site_col))
  df$.site <- factor(lab, levels = rev(unique(lab)))
  df$.q <- q_label(df$q)
  df$method <- factor(df$method,
    c("rarefaction", "observed", "extrapolation"))
  cov <- unique(round(df$coverage, 3))
  sub <- if (length(cov) <= 3) {
    paste0("Sample coverage: ", paste(format(cov * 100, nsmall = 1),
      collapse = ", "), "%")
  }
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$diversity, .data$.site,
    colour = .data$.group))
  if (ci && !all(is.na(df$lower))) {
    p <- p + ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$lower, xmax = .data$upper),
      width = 0.25, orientation = "y"
    )
  }
  p <- p +
    ggplot2::geom_point(ggplot2::aes(shape = .data$method), size = 2.4) +
    ggplot2::scale_shape_manual(
      values = c(rarefaction = 16, observed = 17, extrapolation = 1),
      drop = TRUE
    ) +
    ggplot2::labs(
      x = xlab %||% y_hill, y = ylab %||% site_col, shape = NULL,
      colour = if (length(by_cols)) paste(by_cols, collapse = " "),
      subtitle = sub
    )
  if (!length(by_cols)) p <- p + ggplot2::guides(colour = "none")
  if (facet) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.q), scales = scales,
      ncol = ncol)
  }
  td_style(p, palette, theme, fill = FALSE)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_beta_decay <- function(object,
                                   palette = "okabe_ito",
                                   theme = theme_tidydiversity(),
                                   ci = TRUE,
                                   xlab = "Distance between sites",
                                   ylab = "Dissimilarity",
                                   ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  comps <- c("total", "turnover", "nestedness")
  long <- data.frame(
    distance = rep(df$distance, 3),
    component = factor(rep(comps, each = nrow(df)), levels = comps),
    value = c(df$total, df$turnover, df$nestedness)
  )
  p <- ggplot2::ggplot(
    long,
    ggplot2::aes(.data$distance, .data$value, colour = .data$component,
      fill = .data$component)
  ) +
    ggplot2::geom_point(alpha = 0.6, size = 1.6, shape = 16) +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = ci,
      alpha = 0.15, linewidth = 0.8) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(x = xlab, y = ylab, colour = NULL, fill = NULL)
  td_style(p, palette, theme)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_hill <- function(object,
                             gradient = NULL,
                             palette = "okabe_ito",
                             theme = theme_tidydiversity(),
                             facet = TRUE,
                             scales = "free_y",
                             ncol = NULL,
                             xlab = NULL,
                             ylab = y_hill,
                             ...) {
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
    df$.q <- q_label(df$q)
    df <- df[order(df$.group, df$q, df$.x), ]
    p <- ggplot2::ggplot(
      df, ggplot2::aes(.data$.x, .data$diversity, colour = .data$.group)
    ) +
      ggplot2::geom_line(linewidth = 0.7) +
      ggplot2::geom_point(size = 2) +
      ggplot2::labs(
        x = xlab %||% gcol, y = ylab,
        colour = if (length(by_cols)) paste(by_cols, collapse = " ")
      )
    if (!length(by_cols)) p <- p + ggplot2::guides(colour = "none")
    if (facet) {
      p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.q), scales = scales,
        ncol = ncol)
    }
    return(td_style(p, palette, theme, fill = FALSE))
  }
  by_cols <- setdiff(names(df), c(site_col, "q", "n", "diversity"))
  df$.site <- as.character(df[[site_col]])
  df$.by <- td_label_col(df, by_cols)
  p <- ggplot2::ggplot(
    df, ggplot2::aes(.data$q, .data$diversity, colour = .data$.site,
      group = paste(.data$.by, .data$.site))
  ) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_y_continuous(limits = c(0, NA)) +
    ggplot2::labs(x = xlab %||% "Order q", y = ylab, colour = site_col)
  if (length(by_cols)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.by), ncol = ncol)
  }
  td_style(p, palette, theme, fill = FALSE)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_estimate <- function(object,
                                 palette = "okabe_ito",
                                 theme = theme_tidydiversity(),
                                 ci = TRUE,
                                 facet = TRUE,
                                 scales = "free_x",
                                 ncol = NULL,
                                 xlab = y_hill,
                                 ylab = NULL,
                                 ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  known <- c("q", "observed", "estimate", "se", "lower", "upper")
  site_col <- td_site_col(df, known)
  by_cols <- setdiff(names(df), c(site_col, known))
  lab <- td_label_col(df, c(by_cols, site_col))
  df$.site <- factor(lab, levels = rev(unique(lab)))
  df$.q <- q_label(df$q)
  long <- vctrs::vec_rbind(
    transform(df, .value = df$observed, .type = "observed"),
    transform(df, .value = df$estimate, .type = "asymptotic estimate")
  )
  long$.type <- factor(long$.type, c("observed", "asymptotic estimate"))
  p <- ggplot2::ggplot(long, ggplot2::aes(y = .data$.site))
  if (ci && !all(is.na(df$lower))) {
    p <- p + ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$lower, xmax = .data$upper),
      data = df, width = 0.25, colour = "grey40", orientation = "y"
    )
  }
  p <- p +
    ggplot2::geom_point(
      ggplot2::aes(x = .data$.value, shape = .data$.type,
        colour = .data$.type),
      size = 2.2
    ) +
    ggplot2::scale_shape_manual(values = c(1, 16)) +
    ggplot2::labs(x = xlab, y = ylab %||% site_col, shape = NULL,
      colour = NULL)
  if (facet) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.q), scales = scales,
      ncol = ncol)
  }
  td_style(p, palette, theme, fill = FALSE)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_coverage <- function(object,
                                 palette = "okabe_ito",
                                 theme = theme_tidydiversity(),
                                 xlab = "Number of individuals",
                                 ylab = "Sample coverage",
                                 ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  site_col <- td_site_col(df, c("n", "s_obs", "f1", "f2", "coverage"))
  by_cols <- setdiff(
    names(df), c(site_col, "n", "s_obs", "f1", "f2", "coverage")
  )
  df$.group <- td_label_col(df, by_cols)
  p <- ggplot2::ggplot(
    df, ggplot2::aes(.data$n, .data$coverage, colour = .data$.group)
  ) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_y_continuous(limits = c(NA, 1),
      labels = function(x) paste0(x * 100, "%")) +
    ggplot2::labs(
      x = xlab, y = ylab,
      colour = if (length(by_cols)) paste(by_cols, collapse = " ")
    )
  if (!length(by_cols)) p <- p + ggplot2::guides(colour = "none")
  td_style(p, palette, theme, fill = FALSE)
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_beta_pair <- function(object,
                                  component = c("total", "turnover",
                                                "nestedness"),
                                  theme = theme_tidydiversity(grid = "none"),
                                  ...) {
  rlang::check_installed("ggplot2")
  component <- rlang::arg_match(component)
  df <- tibble::as_tibble(unclass(object))
  by_cols <- setdiff(
    names(df), c("site_1", "site_2", "turnover", "nestedness", "total",
      "gradient_1", "gradient_2", "distance")
  )
  lev <- unique(c(as.character(df$site_1), as.character(df$site_2)))
  swap <- df
  swap$site_1 <- df$site_2
  swap$site_2 <- df$site_1
  both <- vctrs::vec_rbind(df, swap)
  both$site_1 <- factor(both$site_1, lev)
  both$site_2 <- factor(both$site_2, lev)
  both$.value <- both[[component]]
  p <- ggplot2::ggplot(
    both, ggplot2::aes(.data$site_1, .data$site_2, fill = .data$.value)
  ) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_viridis_c(limits = c(0, 1), option = "D") +
    ggplot2::labs(x = NULL, y = NULL,
      fill = paste0(tools::toTitleCase(component), "\ndissimilarity"))
  if (length(by_cols)) {
    both$.group <- td_label_col(both, by_cols)
    p <- ggplot2::`%+%`(p, both) +
      ggplot2::facet_wrap(ggplot2::vars(.data$.group), scales = "free")
  } else {
    p <- p + ggplot2::coord_equal()
  }
  if (!is.null(theme)) p <- p + theme
  p + ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
    legend.position = "right"
  )
}

#' @rdname autoplot-tidydiversity
#' @exportS3Method ggplot2::autoplot
autoplot.td_beta_multi <- function(object,
                                   palette = "okabe_ito",
                                   theme = theme_tidydiversity(),
                                   xlab = NULL,
                                   ylab = "Multiple-site dissimilarity",
                                   ...) {
  rlang::check_installed("ggplot2")
  df <- tibble::as_tibble(unclass(object))
  by_cols <- setdiff(
    names(df), c("n_sites", "turnover", "nestedness", "total")
  )
  # With several grouping columns, the first goes on the x axis and the
  # rest become facets.
  df$.group <- td_label_col(df, by_cols[1])
  df$.panel <- td_label_col(df, by_cols[-1])
  long <- vctrs::vec_rbind(
    transform(df, .component = "nestedness", .value = df$nestedness),
    transform(df, .component = "turnover", .value = df$turnover)
  )
  long$.component <- factor(long$.component, c("nestedness", "turnover"))
  p <- ggplot2::ggplot(
    long, ggplot2::aes(.data$.group, .data$.value, fill = .data$.component)
  ) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    ggplot2::labs(
      x = xlab %||% if (length(by_cols)) by_cols[1],
      y = ylab, fill = NULL
    )
  if (length(by_cols) > 1) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.panel), nrow = 1)
  }
  td_style(p, palette, theme)
}
