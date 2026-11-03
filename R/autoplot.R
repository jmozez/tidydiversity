#' Plot tidydiversity results
#'
#' `autoplot()` methods draw rarefaction and extrapolation curves from
#' [div_rarefy()] and distance decay plots from [beta_decay()]. They need
#' the ggplot2 package.
#'
#' @param object A `td_rarefy` or `td_beta_decay` tibble.
#' @param x For curves, plot against sample size (`"size"`) or sample
#'   coverage (`"coverage"`).
#' @param ... Not used.
#' @return A ggplot object.
#' @name autoplot-tidydiversity
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' library(ggplot2)
#' curves <- div_rarefy(ant_gradient, q = c(0, 1), .by = transect, knots = 20)
#' autoplot(curves)
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
