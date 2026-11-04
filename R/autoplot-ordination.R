#' Plot an ordination
#'
#' Draws a publication-quality ordination diagram in the style of CANOCO
#' (ter Braak and Smilauer 2012): a biplot of sites and species for
#' unconstrained methods and a triplot with environmental arrows for
#' constrained ones, with equal axis scaling, zero lines and the
#' variation explained by each axis in the axis titles. Species are drawn
#' as arrows for linear methods (PCA, RDA, PCoA, db-RDA), whose scores are
#' directions of increase, and as points for unimodal methods (CA, CCA,
#' DCA) and NMDS, whose scores are optima.
#'
#' Groups of sites can be summarised with ellipses, convex hulls or
#' spiders. Ellipses follow [vegan::ordiellipse()]: `"sd"` covers one
#' standard deviation of the points, `"ci"` the region expected to hold
#' `level` of the points, and `"se"` a `level` confidence region for the
#' group centroid.
#'
#' Every option is an argument, and the result is an ordinary ggplot that
#' can be changed further with `+`.
#'
#' @param object A `td_ordination` from [ord_fit()].
#' @param axes The two axes to plot.
#' @param colour,shape Site variables (unquoted column names) to map to
#'   point colour and shape, such as `colour = elevation`. Discrete
#'   variables also define the groups for ellipses, hulls and spiders.
#' @param group A site variable defining groups for ellipses, hulls and
#'   spiders, if different from `colour`.
#' @param sites Draw the sites.
#' @param site_labels Label the sites.
#' @param species Number of species to draw and label, those best
#'   represented in the plotted plane (longest scores). Use `Inf` for all
#'   and `0` for none.
#' @param arrows Draw environmental arrows and factor centroids.
#' @param ellipse `"none"` (the default), `"sd"`, `"ci"` or `"se"`.
#' @param level Coverage of `"ci"` and `"se"` ellipses.
#' @param hull Draw convex hulls around groups.
#' @param spider Join each site to its group centroid.
#' @param palette Colours for groups: `"okabe_ito"` or `"grey"`; continuous
#'   variables use the viridis scale.
#' @param theme A ggplot2 theme, by default [theme_tidydiversity()].
#' @param ... Not used.
#' @return A ggplot object.
#' @references ter Braak, C. J. F. and Smilauer, P. (2012). Canoco
#'   reference manual and user's guide: software for ordination (version
#'   5.0). Microcomputer Power, Ithaca, USA.
#' @exportS3Method ggplot2::autoplot
#' @examplesIf rlang::is_installed(c("vegan", "ggplot2"))
#' library(ggplot2)
#' butterflies <- wanang_butterflies
#' butterflies$year <- factor(paste("Year", butterflies$year))
#'
#' # RDA triplot: days coloured by year, one-SD ellipses
#' ord <- ord_fit(butterflies, method = "rda", formula = ~ year + month)
#' autoplot(ord, colour = year, ellipse = "sd")
#'
#' # NMDS of frogs along Mt Wilhelm, elevation as colour
#' nmds <- ord_fit(png_frogs, method = "nmds", formula = ~elevation)
#' autoplot(nmds, colour = elevation, site_labels = TRUE, species = 10)
autoplot.td_ordination <- function(object,
                                   axes = c(1, 2),
                                   colour = NULL,
                                   shape = NULL,
                                   group = NULL,
                                   sites = TRUE,
                                   site_labels = FALSE,
                                   species = 10,
                                   arrows = TRUE,
                                   ellipse = c("none", "sd", "ci", "se"),
                                   level = 0.95,
                                   hull = FALSE,
                                   spider = FALSE,
                                   palette = "okabe_ito",
                                   theme = theme_tidydiversity(grid = "none"),
                                   ...) {
  rlang::check_installed("ggplot2")
  ellipse <- rlang::arg_match(ellipse)
  n_ax <- nrow(object$axes)
  if (length(axes) != 2 || any(!axes %in% seq_len(n_ax))) {
    cli::cli_abort("{.arg axes} must be two of the {n_ax} available axes.")
  }
  ax <- paste0("axis", axes)
  site_df <- object$sites
  site_df$.x <- site_df[[ax[1]]]
  site_df$.y <- site_df[[ax[2]]]
  site_df$.label <- site_df[[object$site_col]]

  col_var <- ord_var(rlang::enquo(colour), site_df, "colour")
  shp_var <- ord_var(rlang::enquo(shape), site_df, "shape")
  grp_var <- ord_var(rlang::enquo(group), site_df, "group") %||%
    (if (!is.null(col_var) && !is.numeric(site_df[[col_var]])) col_var)
  if (!is.null(shp_var)) site_df[[shp_var]] <- as.factor(site_df[[shp_var]])
  if (!is.null(grp_var)) site_df$.group <- as.factor(site_df[[grp_var]])
  if ((ellipse != "none" || hull || spider) && is.null(grp_var)) {
    cli::cli_abort(
      "Ellipses, hulls and spiders need groups: set {.arg group}, or a discrete {.arg colour}."
    )
  }

  p <- ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.3)

  # Groups: hulls, ellipses and spiders sit under the points. They share
  # the colour scale only when the groups are the (discrete) colour.
  if (!is.null(grp_var)) {
    same <- identical(grp_var, col_var)
    line_aes <- function(...) {
      a <- ggplot2::aes(...)
      if (same) a$colour <- rlang::quo(.data$.group)
      a
    }
    line_col <- if (same) NULL else "grey35"
    hulls <- if (hull) ord_hulls(site_df)
    if (hull && NROW(hulls)) {
      p <- p + ggplot2::geom_polygon(
        ggplot2::aes(.data$.x, .data$.y, group = .data$.group, fill = .data$.group),
        data = hulls, alpha = 0.12, colour = "grey40", linewidth = 0.3,
        show.legend = FALSE
      )
    }
    ell <- if (ellipse != "none") ord_ellipses(site_df, ellipse, level)
    if (ellipse != "none" && NROW(ell) == 0) {
      cli::cli_warn("No group has the 3 or more sites needed for an ellipse.")
    }
    if (ellipse != "none" && NROW(ell)) {
      p <- p + ggplot2::geom_polygon(
        ggplot2::aes(.data$.x, .data$.y, group = .data$.group, fill = .data$.group),
        data = ell, alpha = 0.15, colour = NA, show.legend = FALSE
      ) + do.call(ggplot2::geom_path, c(list(
        line_aes(.data$.x, .data$.y, group = .data$.group),
        data = ell, linewidth = 0.5, show.legend = FALSE
      ), if (!same) list(colour = line_col)))
    }
    if (spider) {
      cen <- stats::aggregate(cbind(.cx = .x, .cy = .y) ~ .group, site_df, mean)
      sp <- merge(site_df, cen, by = ".group")
      p <- p + do.call(ggplot2::geom_segment, c(list(
        line_aes(.data$.cx, .data$.cy, xend = .data$.x, yend = .data$.y),
        data = sp, linewidth = 0.3, alpha = 0.7, show.legend = FALSE
      ), if (!same) list(colour = line_col)))
    }
  }

  # Species
  linear <- object$method %in% c("pca", "rda", "pcoa", "dbrda")
  spp <- object$species
  if (species > 0 && nrow(spp)) {
    spp$.x <- spp[[ax[1]]]
    spp$.y <- spp[[ax[2]]]
    spp <- spp[is.finite(spp$.x) & is.finite(spp$.y), ]
    spp <- spp[order(-(spp$.x^2 + spp$.y^2)), ][seq_len(min(species, nrow(spp))), ]
    spp$.label <- spp$species
    if (linear) {
      mul <- ord_arrow_mul(site_df, spp)
      spp$.x <- spp$.x * mul
      spp$.y <- spp$.y * mul
      p <- p + ggplot2::geom_segment(
        ggplot2::aes(0, 0, xend = .data$.x, yend = .data$.y),
        data = spp, colour = "#B2182B", linewidth = 0.35,
        arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm"), type = "closed")
      )
    } else {
      p <- p + ggplot2::geom_point(
        ggplot2::aes(.data$.x, .data$.y),
        data = spp, colour = "#B2182B", shape = 3, size = 1.8
      )
    }
    p <- p + ord_text(spp, colour = "#B2182B", fontface = "italic", size = 3)
  }

  # Sites
  if (sites) {
    aes_pt <- ggplot2::aes(.data$.x, .data$.y)
    if (!is.null(col_var)) aes_pt$colour <- rlang::quo(.data[[col_var]])
    if (!is.null(shp_var)) aes_pt$shape <- rlang::quo(.data[[shp_var]])
    p <- p + ggplot2::geom_point(aes_pt, data = site_df, size = 2.4, alpha = 0.9)
    if (site_labels) {
      p <- p + ord_text(site_df, colour = "grey20", size = 2.8)
    }
  }

  # Environmental arrows and factor centroids
  if (arrows) {
    vec <- object$vectors
    if (nrow(vec) && all(ax %in% names(vec))) {
      vec$.x <- vec[[ax[1]]]
      vec$.y <- vec[[ax[2]]]
      mul <- ord_arrow_mul(site_df, vec)
      vec$.x <- vec$.x * mul
      vec$.y <- vec$.y * mul
      vec$.label <- vec$term
      p <- p + ggplot2::geom_segment(
        ggplot2::aes(0, 0, xend = .data$.x, yend = .data$.y),
        data = vec, colour = "#0E2A47", linewidth = 0.6,
        arrow = ggplot2::arrow(length = ggplot2::unit(0.2, "cm"), type = "closed")
      ) + ord_text(vec, colour = "#0E2A47", fontface = "bold", size = 3.3)
    }
    cen <- object$centroids
    if (nrow(cen) && all(ax %in% names(cen))) {
      cen$.x <- cen[[ax[1]]]
      cen$.y <- cen[[ax[2]]]
      cen$.label <- cen$level %||% cen$term
      p <- p + ggplot2::geom_point(
        ggplot2::aes(.data$.x, .data$.y),
        data = cen, shape = 17, size = 3, colour = "#0E2A47"
      ) + ord_text(cen, colour = "#0E2A47", fontface = "bold", size = 3)
    }
  }

  lab <- ord_axis_labels(object, axes)
  p <- p + ggplot2::coord_equal() +
    ggplot2::labs(
      x = lab[1], y = lab[2],
      colour = col_var, shape = shp_var,
      caption = if (object$method == "nmds") {
        paste0("Stress = ", format(round(object$stress, 3), nsmall = 3))
      }
    )
  if (!is.null(col_var) && is.numeric(site_df[[col_var]])) {
    # Continuous colour: viridis for the sites, the palette for group fills
    p <- p + ggplot2::scale_colour_viridis_c(option = "D", end = 0.9)
    if (!is.null(grp_var)) p <- p + scale_fill_tidydiversity(palette)
    if (!is.null(theme)) p <- p + theme
    p
  } else {
    td_style(p, palette, theme)
  }
}

# ---- Plot helpers -------------------------------------------------------------

ord_var <- function(quo, df, arg) {
  if (rlang::quo_is_null(quo)) {
    return(NULL)
  }
  names(tidyselect::eval_select(quo, df, error_call = caller_env(2)))[1]
}

ord_axis_labels <- function(object, axes) {
  a <- object$axes[axes, ]
  vapply(seq_len(nrow(a)), function(i) {
    nm <- a$name[i]
    if (is.na(a$explained[i])) nm else sprintf("%s (%.1f%%)", nm, 100 * a$explained[i])
  }, character(1))
}

# Scale arrows to fill most of the site cloud, as vegan's ordiArrowMul().
ord_arrow_mul <- function(site_df, vec) {
  r_sites <- max(abs(c(site_df$.x, site_df$.y)), na.rm = TRUE)
  r_vec <- max(sqrt(vec$.x^2 + vec$.y^2), na.rm = TRUE)
  if (!is.finite(r_vec) || r_vec == 0) 1 else 0.85 * r_sites / r_vec
}

ord_text <- function(df, ...) {
  if (requireNamespace("ggrepel", quietly = TRUE)) {
    ggrepel::geom_text_repel(
      ggplot2::aes(.data$.x, .data$.y, label = .data$.label),
      data = df, seed = 1, max.overlaps = 30, min.segment.length = 0.3,
      ...
    )
  } else {
    ggplot2::geom_text(
      ggplot2::aes(.data$.x, .data$.y, label = .data$.label),
      data = df, vjust = -0.7, check_overlap = TRUE, ...
    )
  }
}

ord_hulls <- function(df) {
  out <- lapply(split(df, df$.group), function(d) {
    if (nrow(d) < 3) {
      return(d[0, ])
    }
    d[grDevices::chull(d$.x, d$.y), ]
  })
  vctrs::vec_rbind(!!!out)
}

# Ellipses as in vegan::ordiellipse(): sd (one standard deviation), ci
# (a `level` region for the points) and se (a `level` region for the mean).
ord_ellipses <- function(df, kind, level) {
  theta <- seq(0, 2 * pi, length.out = 100)
  circle <- cbind(cos(theta), sin(theta))
  out <- lapply(split(df, df$.group), function(d) {
    if (nrow(d) < 3) {
      return(NULL)
    }
    xy <- cbind(d$.x, d$.y)
    v <- stats::cov(xy)
    if (kind == "se") v <- v / nrow(d)
    s <- if (kind == "sd") 1 else sqrt(stats::qchisq(level, 2))
    ch <- tryCatch(chol(v), error = function(e) NULL)
    if (is.null(ch)) {
      return(NULL)
    }
    e <- sweep(s * circle %*% ch, 2, colMeans(xy), "+")
    tibble::tibble(.x = e[, 1], .y = e[, 2], .group = d$.group[1])
  })
  vctrs::vec_rbind(!!!out)
}
