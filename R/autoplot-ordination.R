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
#' How to read the lines:
#' * red arrows from the origin: species (linear methods only);
#' * dark arrows from the origin: quantitative environmental variables;
#' * dark triangles: centroids of factor levels (for example years);
#' * coloured outlines: ellipses or convex hulls around groups of sites,
#'   and, with `spider = TRUE`, lines from each group centroid to its sites;
#' * faint dotted grey lines: label leaders, joining a label that had to
#'   be moved to avoid overlap to its point. They carry no information.
#'
#' Every option is an argument, and the result is an ordinary ggplot that
#' can be changed further with `+`.
#'
#' @param object A `td_ordination` from [ord_fit()].
#' @param axes The two axes to plot.
#' @param colour,shape Site variables (unquoted column names) to map to
#'   point colour and shape, such as `colour = elevation`. Sites are points,
#'   so they are drawn as categories (as in CANOCO), never on a continuous
#'   colour bar: a numeric variable with up to 8 distinct values gets one
#'   class per value, and otherwise is cut into up to 6 classes at pretty
#'   breaks; each class has its own colour and symbol. Discrete variables
#'   also define the groups for ellipses, hulls and spiders.
#' @param type The kind of diagram:
#'   * `"biplot"` (default): sites, species, fitted variables and groups;
#'   * `"gradient"`: the ordination read as a gradient: sites (optionally
#'     joined in the order of `path`), fitted variables whose arrow width
#'     follows their r squared (non-significant ones thin, dashed and
#'     grey), the meaning of the first axis written at its ends, and the
#'     species sorted along the first axis in a panel below;
#'   * `"response"`: species response curves: each species' abundance
#'     against an axis (`axis`) or a site variable (`variable`), fitted by
#'     a quadratic Poisson GLM (ter Braak's Gaussian response) or a GAM
#'     (`model`), with a confidence band from the model on the link scale,
#'     for the `species` best-fitted species, as panels or overlaid
#'     (`layout`);
#'   * `"scree"`: variation explained by each axis, with the broken-stick
#'     expectation (`n_axes` axes);
#'   * `"shepard"`: Shepard diagram of an NMDS with stress and R squared;
#'   * `"tvalue"`: which species increase or decrease with one site
#'     variable (`variable`), the question of CANOCO's t-value biplot:
#'     species arrows coloured by an exact t-test of their coefficient in a
#'     regression of each (transformed) species on all site variables.
#'     Van Dobben circles are not drawn, as they only approximate these
#'     tests under one scaling.
#' @param variable,axis,model,layout,n_axes Options of `type` (see above).
#' @param style Look of every element, from [ord_style()]: colours,
#'   symbols, sizes, line widths and fonts. The result is a ggplot, so any
#'   scale or theme can also be added afterwards.
#' @param path A numeric site variable, such as elevation or time: joins
#'   the sites in its order with a thin line and small arrowheads, so the
#'   reader sees at once how composition changes along the gradient.
#' @param surface A numeric site variable to draw as a fitted surface:
#'   contour lines from a thin-plate GAM of the variable on the two axes
#'   (as in `vegan::ordisurf()`), or a linear trend surface (a plane, as
#'   `vegan::envfit()` assumes) with fewer than 15 sites, where a smooth
#'   surface would overfit. A continuous variable is a gradient, so it is drawn
#'   with lines (contours, or the arrows of the fitted `formula`), not by
#'   colouring the points.
#' @param size A numeric site variable shown by symbol size (a bubble or
#'   attribute plot, as in CANOCO).
#' @param group A site variable defining groups for ellipses, hulls and
#'   spiders, if different from `colour`.
#' @param sites Draw the sites.
#' @param site_labels Label the sites.
#' @param species_arrows Draw species as arrows (a PCA/RDA biplot, as
#'   `vegan::biplot.rda()`), only for linear methods. By default species
#'   are taxa and are drawn as points (crosses) with italic labels, as in
#'   `vegan::plot.rda()`; arrows are kept for continuous explanatory
#'   variables.
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
                                   species_arrows = FALSE,
                                   arrows = TRUE,
                                   ellipse = c("none", "sd", "ci", "se"),
                                   level = 0.95,
                                   hull = FALSE,
                                   spider = FALSE,
                                   palette = "okabe_ito",
                                   theme = theme_tidydiversity(grid = "none"),
                                   surface = NULL,
                                   size = NULL,
                                   path = NULL,
                                   style = ord_style(),
                                   type = c(
                                     "biplot", "gradient", "response", "scree",
                                     "shepard", "tvalue"
                                   ),
                                   variable = NULL,
                                   axis = 1,
                                   model = c("glm", "gam"),
                                   layout = c("facet", "overlay"),
                                   n_axes = 10,
                                   ...) {
  rlang::check_installed("ggplot2")
  st <- style
  type <- rlang::arg_match(type)
  if (type != "biplot") {
    return(ord_plot_dispatch(object, type, st, list(
      path = ord_var(rlang::enquo(path), object$sites, "path"),
      species = if (missing(species)) NULL else species, axes = axes,
      axis = axis, variable = variable, model = rlang::arg_match(model),
      layout = rlang::arg_match(layout), level = level, palette = palette,
      n_axes = n_axes
    )))
  }
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
  srf_var <- ord_var(rlang::enquo(surface), site_df, "surface")
  siz_var <- ord_var(rlang::enquo(size), site_df, "size")
  pth_var <- ord_var(rlang::enquo(path), site_df, "path")
  for (v in c(srf_var, siz_var, pth_var)) {
    if (!is.numeric(site_df[[v]])) {
      cli::cli_abort(
        "{.arg surface} and {.arg size} need a numeric site variable; got {.field {v}}."
      )
    }
  }
  # Keep the numeric values for surfaces and sizes before any classing
  raw <- site_df
  # Points are classes, not a continuous gradient: numeric -> ordered classes
  if (!is.null(col_var) && is.numeric(site_df[[col_var]])) {
    site_df[[col_var]] <- td_point_classes(site_df[[col_var]])
    if (is.null(shp_var)) shp_var <- col_var
  }
  if (!is.null(shp_var) && is.numeric(site_df[[shp_var]])) {
    site_df[[shp_var]] <- td_point_classes(site_df[[shp_var]])
  }
  grp_var <- ord_var(rlang::enquo(group), site_df, "group") %||% col_var
  if (!is.null(shp_var)) site_df[[shp_var]] <- as.factor(site_df[[shp_var]])
  if (!is.null(grp_var)) site_df$.group <- as.factor(site_df[[grp_var]])
  if ((ellipse != "none" || hull || spider) && is.null(grp_var)) {
    cli::cli_abort(
      "Ellipses, hulls and spiders need groups: set {.arg group}, or a discrete {.arg colour}."
    )
  }

  p <- ggplot2::ggplot() +
    ggplot2::geom_hline(
      yintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_vline(
      xintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    )

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

  labs <- list()
  # Element types drawn, for the key legend: name, glyph, colour, shape
  el_env <- new.env(parent = emptyenv())
  el_env$elems <- list()
  add_elem <- function(name, glyph, colour, shape = NA) {
    el_env$elems[[length(el_env$elems) + 1]] <- data.frame(
      name = name, glyph = glyph, colour = colour, shape = shape
    )
  }

  # Species
  linear <- isTRUE(species_arrows) && object$method %in% c("pca", "rda", "pcoa", "dbrda")
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
        data = spp, colour = st$species_colour, linewidth = st$species_linewidth,
        arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm"), type = "closed")
      )
      add_elem("Species", "arrow", st$species_colour)
    } else {
      add_elem("Species", "point", st$species_colour, st$species_shape)
      p <- p + ggplot2::geom_point(
        ggplot2::aes(.data$.x, .data$.y),
        data = spp, colour = st$species_colour, shape = st$species_shape,
        size = st$species_size, stroke = 0.6
      )
    }
    labs <- ord_add_labels(labs, spp, st$species_label_colour, st$species_fontface, st$label_size)
  }

  # A continuous site variable as a fitted surface: contour lines
  srf_cap <- NULL
  if (!is.null(srf_var)) {
    srf <- ord_surface(site_df$.x, site_df$.y, raw[[srf_var]])
    if (nrow(srf$lines)) {
      p <- p + ggplot2::geom_path(
        ggplot2::aes(.data$x, .data$y, group = .data$piece),
        data = srf$lines, colour = st$contour_colour, linewidth = st$contour_linewidth
      )
      add_elem(paste(srf_var, "(contours)"), "line", st$contour_colour)
      # Contour values on a white background, without a border
      p <- p + ggplot2::geom_text(
        ggplot2::aes(.data$x, .data$y, label = .data$level),
        data = srf$labels, colour = "white", size = 0.93 * st$label_size, fontface = "bold"
      ) + ggplot2::geom_text(
        ggplot2::aes(.data$x, .data$y, label = .data$level),
        data = srf$labels, colour = st$contour_colour, size = 0.93 * st$label_size
      )
    }
    srf_cap <- sprintf(
      "Contours: %s fitted by a %s (deviance explained %.0f%%)",
      srf_var, srf$model, 100 * srf$dev_expl
    )
  }

  # Sites in gradient order: a path with arrowheads half-way along
  if (!is.null(pth_var)) {
    o_ <- order(raw[[pth_var]])
    px <- site_df$.x[o_]
    py <- site_df$.y[o_]
    tr <- data.frame(
      x = utils::head(px, -1), y = utils::head(py, -1), xend = px[-1], yend = py[-1]
    )
    p <- p + ggplot2::geom_segment(
      ggplot2::aes(.data$x, .data$y, xend = .data$xend, yend = .data$yend),
      data = tr, colour = st$path_colour, linewidth = st$path_linewidth
    ) + ggplot2::geom_segment(
      ggplot2::aes(.data$x, .data$y,
        xend = (.data$x + .data$xend) / 2, yend = (.data$y + .data$yend) / 2
      ),
      data = tr, colour = st$path_colour, linewidth = st$path_linewidth,
      arrow = ggplot2::arrow(length = ggplot2::unit(1.6, "mm"), type = "closed")
    )
    add_elem(paste("Sites in order of", pth_var), "arrow", st$path_colour)
  }

  # Sites
  if (sites) {
    aes_pt <- ggplot2::aes(.data$.x, .data$.y)
    # Filled symbols with a thin dark outline: legible in colour and grey
    if (!is.null(col_var)) aes_pt$fill <- rlang::quo(.data[[col_var]])
    if (!is.null(shp_var)) aes_pt$shape <- rlang::quo(.data[[shp_var]])
    if (is.null(col_var) && is.null(shp_var)) add_elem("Sites", "point", st$site_outline, 21)
    pt_fixed <- list(colour = st$site_outline, stroke = st$site_stroke, alpha = st$site_alpha)
    if (is.null(shp_var)) pt_fixed$shape <- 21
    if (is.null(col_var)) pt_fixed$fill <- st$site_fill
    if (!is.null(siz_var)) {
      site_df$.size <- raw[[siz_var]]
      aes_pt$size <- rlang::quo(.data$.size)
      p <- p + do.call(ggplot2::geom_point, c(list(aes_pt, data = site_df), pt_fixed)) +
        ggplot2::scale_size_area(name = siz_var, max_size = 7)
    } else {
      pt_args <- c(list(aes_pt, data = site_df, size = st$site_size), pt_fixed)
      p <- p + do.call(ggplot2::geom_point, pt_args)
    }
    if (site_labels) {
      labs <- ord_add_labels(
        labs, site_df, st$site_label_colour, st$site_fontface, 1.1 * st$label_size
      )
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
      vec$.label <- ord_pretty(vec$term)
      p <- p + ggplot2::geom_segment(
        ggplot2::aes(0, 0, xend = .data$.x, yend = .data$.y),
        data = vec, colour = st$env_colour, linewidth = st$env_linewidth,
        arrow = ggplot2::arrow(length = ggplot2::unit(0.2, "cm"), type = "closed")
      )
      add_elem("Site variables (fitted)", "arrow", st$env_colour)
      ef <- object$envfit
      if (isTRUE(st$env_stats) && !is.null(ef) && nrow(ef)) {
        m <- match(vec$term, ef$term)
        vec$.label <- ifelse(is.na(m), vec$term, sprintf(
          "%s  r\u00b2 = %.2f, p = %s", ord_pretty(vec$term), ef$r2[m],
          formatC(ef$p.value[m], format = "g", digits = 2)
        ))
      }
      p <- p + ggplot2::geom_label(
        ggplot2::aes(.data$.x, .data$.y,
          label = .data$.label,
          # Inside the plot: ending at the arrowhead (right-pointing),
          # starting at it (left-pointing), centred (vertical arrows)
          hjust = ifelse(abs(.data$.x) < 0.3 * abs(.data$.y), 0.5, ifelse(.data$.x > 0, 1, 0)),
          vjust = ifelse(.data$.y >= 0, -0.45, 1.45)
        ),
        data = vec, colour = st$env_colour, fill = "white", family = st$font,
        fontface = st$env_fontface, size = st$label_size,
        label.r = ggplot2::unit(0.12, "lines"), show.legend = FALSE
      )
    }
    cen <- object$centroids
    if (nrow(cen) && all(ax %in% names(cen))) {
      cen$.x <- cen[[ax[1]]]
      cen$.y <- cen[[ax[2]]]
      cen$.label <- cen$level %||% cen$term
      p <- p + ggplot2::geom_point(
        ggplot2::aes(.data$.x, .data$.y),
        data = cen, shape = st$centroid_shape, size = st$centroid_size, colour = st$env_colour
      )
      add_elem("Factor levels (centroids)", "point", st$env_colour, st$centroid_shape)
      labs <- ord_add_labels(labs, cen, st$env_colour, st$env_fontface, 1.05 * st$label_size)
    }
  }

  # All labels in one layer, so species, site and variable labels avoid
  # each other and every plotted point instead of overlapping.
  if (length(labs)) {
    lab_df <- vctrs::vec_rbind(!!!labs)
    pts <- vctrs::vec_rbind(site_df[c(".x", ".y")], lab_df[c(".x", ".y")])
    p <- p + ord_text(lab_df, pts, st$font)
  }
  lab <- ord_axis_labels(object, axes)
  p <- p + ggplot2::coord_equal(clip = "off") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0.06)) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.06, 0.1))) +
    ggplot2::labs(
      x = lab[1], y = lab[2],
      fill = col_var, colour = col_var, shape = shp_var,
      caption = paste(c(
        if (object$method == "nmds") {
          paste0("Stress = ", format(round(object$stress, 3), nsmall = 3))
        },
        srf_cap
      ), collapse = "\n")
    )
  if (!is.null(shp_var)) {
    n_shp <- nlevels(site_df[[shp_var]])
    shapes <- rep(st$site_shapes, length.out = n_shp)
    p <- p + ggplot2::scale_shape_manual(name = shp_var, values = shapes)
  }
  p <- td_white(td_style(p, palette, theme)) +
    ggplot2::guides(
      fill = ggplot2::guide_legend(order = 1), colour = ggplot2::guide_legend(order = 1),
      shape = ggplot2::guide_legend(order = 1)
    ) +
    ggplot2::theme(text = ggplot2::element_text(family = st$font))
  ord_element_legend(p, el_env$elems, site_df, st)
}

# A legend keying every kind of element in the diagram (sites, species,
# environmental arrows, centroids, contours), each with its own symbol:
# lines for gradients, points for objects and factor levels. It uses the
# linetype scale, so it never disturbs the colour and shape legends of the
# sites.
ord_element_legend <- function(p, elems, site_df, st) {
  if (!length(elems)) {
    return(p)
  }
  e <- vctrs::vec_rbind(!!!elems)
  e <- e[!duplicated(e$name), , drop = FALSE]
  # Lines and arrows first, then symbols
  e <- e[order(e$glyph == "point"), , drop = FALSE]
  e$name <- factor(e$name, levels = e$name)
  proxy <- data.frame(name = e$name, x = site_df$.x[1], y = site_df$.y[1])
  is_line <- e$glyph != "point"
  key <- function(data, params, size) {
    if (!is.na(data$shape)) {
      return(ggplot2::draw_key_point(transform(data, linetype = 1, stroke = 0.6), params, size))
    }
    g <- if (identical(data$label_glyph, "arrow")) {
      grid::arrow(length = grid::unit(0.12, "inches"), type = "closed")
    }
    grid::segmentsGrob(0.1, 0.5, 0.9, 0.5,
      arrow = g,
      gp = grid::gpar(col = data$colour, fill = data$colour, lwd = 1.6, lineend = "butt")
    )
  }
  p +
    ggplot2::geom_segment(
      ggplot2::aes(.data$x, .data$y, xend = .data$x, yend = .data$y, linetype = .data$name),
      data = proxy, alpha = 0, inherit.aes = FALSE, key_glyph = key
    ) +
    ggplot2::scale_linetype_manual(
      name = NULL, values = stats::setNames(rep("solid", nrow(e)), e$name),
      guide = ggplot2::guide_legend(
        order = 99, nrow = if (nrow(e) > 3) 2 else 1, byrow = TRUE,
        override.aes = list(
          alpha = 1, colour = e$colour, linewidth = ifelse(is_line, 0.7, 0.5),
          shape = ifelse(is_line, NA, e$shape), size = ifelse(is_line, 0.7, 2.6),
          fill = ifelse(e$shape %in% 21:25, st$site_fill, e$colour),
          label_glyph = e$glyph
        )
      )
    ) +
    ggplot2::theme(
      legend.position = "bottom", legend.box = "vertical",
      legend.spacing.y = ggplot2::unit(0, "mm"), legend.key.width = ggplot2::unit(9, "mm")
    )
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

ord_add_labels <- function(labs, df, colour, face, size) {
  c(labs, list(tibble::tibble(
    .x = df$.x, .y = df$.y, .label = as.character(df$.label),
    .col = colour, .face = face, .size = size
  )))
}

# One repelled text layer for every label. Every plotted point is added as
# an empty label so that text is pushed off it. A label pushed away from its
# point gets a faint dotted leader line, drawn so that it cannot be mistaken
# for a species or variable arrow.
ord_text <- function(lab, pts, family = "") {
  if (!requireNamespace("ggrepel", quietly = TRUE)) {
    return(ggplot2::geom_text(
      ggplot2::aes(.data$.x, .data$.y,
        label = .data$.label, colour = I(.data$.col),
        fontface = .data$.face, size = I(.data$.size)
      ),
      data = lab, vjust = -0.7, check_overlap = TRUE, show.legend = FALSE, family = family
    ))
  }
  obst <- tibble::tibble(
    .x = pts$.x, .y = pts$.y, .label = "", .col = "black",
    .face = "plain", .size = 3
  )
  df <- vctrs::vec_rbind(lab, obst)
  ggrepel::geom_text_repel(
    ggplot2::aes(.data$.x, .data$.y,
      label = .data$.label, colour = I(.data$.col),
      fontface = .data$.face, size = I(.data$.size)
    ),
    data = df, seed = 3, max.overlaps = Inf, box.padding = 0.5,
    point.padding = 0.35, min.segment.length = 0.2, show.legend = FALSE,
    segment.colour = "grey65", segment.size = 0.3, family = family,
    force = 4, force_pull = 0.5,
    max.time = 5, max.iter = 1e5
  )
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

# Numeric site variables as ordered classes for point symbols: one class per
# value when there are few values, else up to 6 classes at pretty breaks.
td_point_classes <- function(x, max_values = 8, n_classes = 6) {
  u <- sort(unique(x[!is.na(x)]))
  fmt <- function(v) format(v, big.mark = ",", trim = TRUE, scientific = FALSE)
  if (length(u) <= max_values) {
    return(factor(fmt(x), levels = fmt(u)))
  }
  br <- pretty(range(u), n = n_classes)
  lab <- paste0(fmt(utils::head(br, -1)), " to ", fmt(br[-1]))
  cut(x, br, labels = lab, include.lowest = TRUE)
}

# Smooth (or planar) surface of a site variable on two ordination axes, as
# in vegan::ordisurf(): GAM with a thin-plate spline (REML, with shrinkage),
# predicted on a grid and kept within the convex hull of the sites.
ord_surface <- function(x, y, z, n_grid = 41) {
  ok <- is.finite(x) & is.finite(y) & is.finite(z)
  x <- x[ok]
  y <- y[ok]
  z <- z[ok]
  d <- data.frame(x = x, y = y, z = z)
  if (length(z) >= 15) {
    rlang::check_installed("mgcv")
    k <- min(10, length(z) %/% 3)
    fit <- mgcv::gam(z ~ s(x, y, k = k, bs = "tp"), data = d, method = "REML", select = TRUE)
    model <- "thin-plate GAM"
    dev <- summary(fit)$dev.expl
  } else {
    fit <- stats::lm(z ~ x + y, data = d)
    model <- "linear trend surface"
    dev <- summary(fit)$r.squared
  }
  gx <- seq(min(x), max(x), length.out = n_grid)
  gy <- seq(min(y), max(y), length.out = n_grid)
  grid <- expand.grid(x = gx, y = gy)
  zz <- as.numeric(stats::predict(fit, newdata = grid))
  h <- grDevices::chull(x, y)
  inside <- ord_in_polygon(grid$x, grid$y, x[h], y[h])
  zz[!inside] <- NA
  m <- matrix(zz, n_grid, n_grid)
  lev <- pretty(range(zz, na.rm = TRUE), 6)
  cl <- grDevices::contourLines(gx, gy, m, levels = lev)
  lines <- do.call(rbind, lapply(seq_along(cl), function(i) {
    data.frame(x = cl[[i]]$x, y = cl[[i]]$y, piece = i, level = cl[[i]]$level)
  }))
  if (is.null(lines)) {
    lines <- data.frame(x = numeric(0), y = numeric(0), piece = integer(0), level = numeric(0))
  }
  # One label per level, at the middle of its longest piece
  labels <- do.call(rbind, lapply(split(lines, lines$level), function(l) {
    longest <- names(which.max(table(l$piece)))
    l <- l[l$piece == as.integer(longest), ]
    l[ceiling(nrow(l) / 2), c("x", "y", "level")]
  }))
  if (is.null(labels)) labels <- data.frame(x = numeric(0), y = numeric(0), level = numeric(0))
  labels$level <- format(labels$level, big.mark = ",", trim = TRUE)
  list(lines = lines, labels = labels, model = model, dev_expl = dev)
}

# Points inside a polygon (ray casting)
ord_in_polygon <- function(px, py, vx, vy) {
  n <- length(vx)
  inside <- logical(length(px))
  j <- n
  for (i in seq_len(n)) {
    cross <- ((vy[i] > py) != (vy[j] > py)) &
      (px < (vx[j] - vx[i]) * (py - vy[i]) / (vy[j] - vy[i] + 1e-300) + vx[i])
    inside <- xor(inside, cross)
    j <- i
  }
  inside
}

#' Style of ordination diagrams
#'
#' `ord_style()` sets the look of every element of an ordination diagram
#' drawn with `autoplot()`. The defaults follow the conventions of CANOCO 5
#' and vegan, tuned for print: filled site symbols with a thin outline
#' (legible in colour and in grey), small crosses for species with italic
#' names, heavier arrows for continuous environmental variables with bold
#' names, triangles for factor centroids and hairlines through the origin.
#' Change any argument; colours of site groups come from `palette` in
#' `autoplot()`, and further changes can be made by adding ggplot2 scales
#' and themes to the result.
#'
#' @param font Font family of all text (`"serif"`, `"sans"` or any
#'   installed family).
#' @param site_fontface Font face of site labels.
#' @param env_stats Add the fit of each environmental variable (r squared
#'   and p from `envfit`) to its label.
#' @param path_colour,path_linewidth Colour and width of the `path` line.
#' @param site_size,site_stroke,site_alpha Size, outline width and opacity
#'   of site symbols.
#' @param site_outline,site_fill Outline colour of site symbols, and their
#'   fill when sites are not grouped.
#' @param site_shapes Filled symbols (21 to 25) used for site classes.
#' @param site_label_colour Colour of site labels.
#' @param species_colour,species_label_colour Colour of species symbols
#'   (or arrows) and of their names.
#' @param species_shape,species_size Symbol and size of species points.
#' @param species_linewidth Line width of species arrows (`species_arrows =
#'   TRUE`).
#' @param species_fontface Font face of species names (`"italic"` for
#'   binomials).
#' @param env_colour,env_linewidth,env_fontface Colour, arrow width and
#'   font face of environmental variables and centroids.
#' @param centroid_shape,centroid_size Symbol and size of factor centroids.
#' @param contour_colour,contour_linewidth Colour and width of contours.
#' @param origin_colour,origin_linewidth Lines through the origin.
#' @param label_size Base size of labels (mm); variable labels are a little
#'   larger.
#' @return A list for the `style` argument of `autoplot()`.
#' @export
#' @examples
#' o <- ord_fit(png_frogs, abundance = abundance, method = "pca", transform = "hellinger")
#' ggplot2::autoplot(o,
#'   colour = elevation,
#'   style = ord_style(site_size = 3.5, species_colour = "grey20", label_size = 3.2)
#' )
ord_style <- function(font = "serif",
                      site_size = 3.4,
                      site_stroke = 0.8,
                      site_alpha = 1,
                      site_outline = "grey15",
                      site_fill = "white",
                      site_shapes = c(21, 24, 22, 23, 25),
                      site_label_colour = "grey10",
                      site_fontface = "bold",
                      species_colour = "grey45",
                      species_label_colour = "grey40",
                      species_shape = 3,
                      species_size = 1.9,
                      species_linewidth = 0.35,
                      species_fontface = "italic",
                      env_colour = "#1F78B4",
                      env_linewidth = 0.9,
                      env_fontface = "plain",
                      env_stats = TRUE,
                      path_colour = "grey60",
                      path_linewidth = 0.35,
                      centroid_shape = 17,
                      centroid_size = 3,
                      contour_colour = "#1B7837",
                      contour_linewidth = 0.45,
                      origin_colour = "grey60",
                      origin_linewidth = 0.25,
                      label_size = 2.8) {
  if (!all(site_shapes %in% 21:25)) {
    cli::cli_abort("{.arg site_shapes} must be filled symbols, 21 to 25.")
  }
  as.list(environment())
}

# Variable names for labels: "soil_moisture" -> "Soil moisture"
ord_pretty <- function(x) {
  x <- gsub("[_.]+", " ", x)
  paste0(toupper(substr(x, 1, 1)), substring(x, 2))
}
