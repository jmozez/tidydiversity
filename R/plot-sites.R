#' Publication-ready study-site maps
#'
#' @description
#' `plot_sites()` draws sampling locations for a manuscript figure: points
#' from an `sf` table or longitude/latitude columns, optional grouping as
#' colour and shape, non-overlapping labels, an optional raster or coastline
#' backdrop, faceting, a simple scale bar and a north arrow. The result is a
#' ggplot object, so further layers can be added. Diversity values mapped as
#' a continuous fill still use [plot_geo()]; this verb is for the study-site
#' map that papers usually need first.
#'
#' The package's Papua New Guinea example tables (`png_ants`, `png_frogs`,
#' `png_tree_ants`) carry elevation but not GPS. Use [geo_example_sites()]
#' for illustrative WGS84 coordinates near those study areas when trying the
#' workflow, and replace them with your own GPS before publication.
#'
#' SDM tools such as biomod2 and Maxent are out of scope here; they can be
#' rebuilt later as tidy verbs.
#'
#' @param data A data frame of sites (or occurrence records) with
#'   coordinates, or an `sf` object.
#' @param lon,lat <[`data-masking`][dplyr::dplyr_data_masking]> Coordinate
#'   columns when `data` is not `sf`.
#' @param colour,shape <[`data-masking`][dplyr::dplyr_data_masking]> Optional
#'   grouping columns (habitat, elevation band, forest type, season).
#' @param label <[`data-masking`][dplyr::dplyr_data_masking]> Optional site
#'   labels; overplotting is avoided with **ggrepel** when installed.
#' @param facet <[`data-masking`][dplyr::dplyr_data_masking]> Optional column
#'   to facet by (taxon, season).
#' @param basemap Basemap for the figure: `"none"`, `"coast"`, `"osm"`,
#'   `"carto"`, `"carto_dark"`, `"esri"`, a `SpatRaster`, or a file path.
#'   See [geo_basemap()]. Online tiles fall back to `"coast"` offline.
#' @param raster Optional `terra::SpatRaster` or file path used as an
#'   elevation / climate backdrop (same as passing that object to
#'   `basemap`). Ignored when `basemap` is not `"none"`.
#' @param coastline Optional `sf` lines or polygons (for example a country
#'   outline) drawn under the sites when using a coast basemap.
#' @param occurrence Optional second data frame of species records with the
#'   same coordinate columns, drawn as smaller points underneath the sites.
#' @param size Point size for sites.
#' @param occurrence_size Point size for occurrence records.
#' @param scale_bar,north_arrow Draw a scale bar and north arrow?
#' @param scale_bar_km Length of the scale bar in kilometres. When `NULL`,
#'   a round length is chosen from the map extent.
#' @param palette Discrete palette: `"okabe_ito"` or `"grey"`.
#' @return A ggplot object.
#' @export
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)
#' sites <- geo_example_sites("wilhelm")
#' plot_sites(sites, lon, lat, colour = elevation_band, label = site,
#'   basemap = "coast")
#'
#' # Facet by a grouping column
#' sites$season <- rep(c("dry", "wet"), length.out = nrow(sites))
#' plot_sites(sites, lon, lat, colour = elevation_band, facet = season)
plot_sites <- function(data,
                       lon = lon,
                       lat = lat,
                       colour = NULL,
                       shape = NULL,
                       label = NULL,
                       facet = NULL,
                       basemap = "none",
                       raster = NULL,
                       coastline = NULL,
                       occurrence = NULL,
                       size = 3.2,
                       occurrence_size = 1.4,
                       scale_bar = TRUE,
                       north_arrow = TRUE,
                       scale_bar_km = NULL,
                       palette = c("okabe_ito", "grey")) {
  rlang::check_installed("ggplot2")
  rlang::check_installed("sf")
  palette <- rlang::arg_match(palette)
  td_check_data(data)

  col_q <- enquo(colour)
  shp_q <- enquo(shape)
  lab_q <- enquo(label)
  fac_q <- enquo(facet)
  col_nm <- if (quo_is_null(col_q)) NULL else td_pick(col_q, data, "colour")
  shp_nm <- if (quo_is_null(shp_q)) NULL else td_pick(shp_q, data, "shape")
  lab_nm <- if (quo_is_null(lab_q)) NULL else td_pick(lab_q, data, "label")
  fac_nm <- if (quo_is_null(fac_q)) NULL else td_pick(fac_q, data, "facet")

  sites <- plot_sites_as_sf(data, enquo(lon), enquo(lat))
  p <- ggplot2::ggplot()

  # Resolve basemap: explicit basemap wins; otherwise honour raster=
  bm <- basemap
  if (identical(bm, "none") && !is.null(raster)) {
    bm <- raster
  }
  bb <- sf::st_bbox(sites)
  # Expand basemap extent a little around the sites
  dx <- max((bb["xmax"] - bb["xmin"]) * 0.15, 0.02)
  dy <- max((bb["ymax"] - bb["ymin"]) * 0.15, 0.02)
  bb["xmin"] <- bb["xmin"] - dx
  bb["xmax"] <- bb["xmax"] + dx
  bb["ymin"] <- bb["ymin"] - dy
  bb["ymax"] <- bb["ymax"] + dy
  bm_layers <- geo_basemap_layers(
    bb,
    basemap = bm,
    coastline = coastline,
    crs = sf::st_crs(sites)
  )
  for (ly in bm_layers$layers) {
    p <- p + ly
  }

  if (!is.null(occurrence)) {
    td_check_data(occurrence)
    occ <- plot_sites_as_sf(occurrence, enquo(lon), enquo(lat))
    p <- p + ggplot2::geom_sf(
      data = occ,
      shape = 16,
      colour = "grey55",
      size = occurrence_size,
      alpha = 0.55
    )
  }

  # Site points. A raster/tile basemap that already uses fill maps grouping
  # to colour instead.
  use_fill <- !isTRUE(bm_layers$uses_fill)
  if (is.null(col_nm) && is.null(shp_nm)) {
    p <- p + ggplot2::geom_sf(
      data = sites,
      shape = 21,
      fill = plot_palette(1, palette = palette),
      colour = "grey15",
      size = size,
      stroke = 0.35
    )
  } else if (!is.null(col_nm) && !is.null(shp_nm) && use_fill) {
    p <- p + ggplot2::geom_sf(
      data = sites,
      ggplot2::aes(fill = .data[[col_nm]], shape = .data[[shp_nm]]),
      colour = "grey15",
      size = size,
      stroke = 0.35
    )
  } else if (!is.null(col_nm) && use_fill) {
    p <- p + ggplot2::geom_sf(
      data = sites,
      ggplot2::aes(fill = .data[[col_nm]]),
      shape = 21,
      colour = "grey15",
      size = size,
      stroke = 0.35
    )
  } else if (!is.null(col_nm) && !is.null(shp_nm)) {
    p <- p + ggplot2::geom_sf(
      data = sites,
      ggplot2::aes(colour = .data[[col_nm]], shape = .data[[shp_nm]]),
      size = size,
      stroke = 0.35
    )
  } else if (!is.null(col_nm)) {
    p <- p + ggplot2::geom_sf(
      data = sites,
      ggplot2::aes(colour = .data[[col_nm]]),
      shape = 16,
      size = size
    )
  } else {
    p <- p + ggplot2::geom_sf(
      data = sites,
      ggplot2::aes(shape = .data[[shp_nm]]),
      fill = plot_palette(1, palette = palette),
      colour = "grey15",
      size = size,
      stroke = 0.35
    )
  }

  if (!is.null(col_nm)) {
    col_v <- sites[[col_nm]]
    if (is.numeric(col_v) && !is.factor(col_v)) {
      if (use_fill) {
        p <- p + ggplot2::scale_fill_viridis_c(
          name = col_nm, option = "C",
          guide = ggplot2::guide_colourbar(order = 2)
        )
      } else {
        p <- p + ggplot2::scale_colour_viridis_c(
          name = col_nm, option = "C",
          guide = ggplot2::guide_colourbar(order = 2)
        )
      }
    } else {
      levs <- if (is.factor(col_v)) levels(col_v) else as.character(
        vctrs::vec_unique(col_v)
      )
      cols <- plot_palette(length(levs), palette = palette)
      names(cols) <- levs
      if (use_fill) {
        p <- p + ggplot2::scale_fill_manual(
          name = col_nm, values = cols,
          guide = ggplot2::guide_legend(order = 2)
        )
      } else {
        p <- p + ggplot2::scale_colour_manual(
          name = col_nm, values = cols,
          guide = ggplot2::guide_legend(order = 2)
        )
      }
    }
  }
  if (!is.null(shp_nm)) {
    p <- p + ggplot2::scale_shape_discrete(name = shp_nm)
  }

  if (!is.null(lab_nm)) {
    rlang::check_installed("ggrepel")
    xy <- sf::st_coordinates(sites)
    labs <- tibble::tibble(
      x = xy[, 1],
      y = xy[, 2],
      .lab = as.character(sites[[lab_nm]])
    )
    if (!is.null(fac_nm)) {
      labs[[fac_nm]] <- sites[[fac_nm]]
    }
    p <- p + ggrepel::geom_text_repel(
      data = labs,
      ggplot2::aes(.data$x, .data$y, label = .data$.lab),
      size = 3,
      min.segment.length = 0,
      box.padding = 0.35,
      max.overlaps = Inf,
      colour = "grey10",
      segment.colour = "grey50",
      segment.size = 0.25
    )
  }

  if (!is.null(fac_nm)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[fac_nm]]))
  }

  bb <- sf::st_bbox(sites)
  if (isTRUE(scale_bar)) {
    p <- p + geo_annotation_scale_bar(
      bb, length_km = scale_bar_km, facet = fac_nm, data = sites
    )
  }
  if (isTRUE(north_arrow)) {
    p <- p + geo_annotation_north_arrow(bb, facet = fac_nm, data = sites)
  }

  p +
    ggplot2::coord_sf(crs = sf::st_crs(sites), expand = TRUE) +
    theme_tidydiversity(grid = "none") +
    ggplot2::labs(x = NULL, y = NULL)
}

plot_sites_as_sf <- function(data, lon, lat) {
  if (inherits(data, "sf")) {
    out <- geo_as_sf(data, drop_na = TRUE)
  } else {
    lon_col <- td_pick(lon, data, "lon")
    lat_col <- td_pick(lat, data, "lat")
    out <- geo_as_sf(
      data,
      lon = !!rlang::sym(lon_col),
      lat = !!rlang::sym(lat_col),
      drop_na = TRUE
    )
  }
  if (nrow(out) == 0) {
    cli::cli_abort("No rows with finite coordinates remain to plot.")
  }
  out
}

# Scale bar in map units for a geographic CRS, without map-package Suggests.
geo_annotation_scale_bar <- function(bb, length_km = NULL, facet = NULL,
                                     data = NULL) {
  xmin <- unname(bb["xmin"])
  xmax <- unname(bb["xmax"])
  ymin <- unname(bb["ymin"])
  ymax <- unname(bb["ymax"])
  width <- xmax - xmin
  height <- ymax - ymin
  mid_lat <- (ymin + ymax) / 2
  m_per_deg <- 111320 * cos(mid_lat * pi / 180)
  if (is.null(length_km) || !is.finite(length_km)) {
    # Aim for about one fifth of the map width
    target_m <- max(width * m_per_deg * 0.2, 1000)
    nice <- c(1, 2, 5, 10, 20, 50, 100, 200, 500, 1000)
    length_km <- nice[which.min(abs(nice - target_m / 1000))]
  }
  td_check_number(length_km, "scale_bar_km", 0)
  len_deg <- (length_km * 1000) / m_per_deg
  x0 <- xmin + 0.08 * width
  x1 <- x0 + len_deg
  y0 <- ymin + 0.08 * height
  bar <- tibble::tibble(
    x = c(x0, x1),
    y = c(y0, y0)
  )
  ticks <- tibble::tibble(
    x = c(x0, x1),
    y = c(y0, y0),
    yend = c(y0 + 0.02 * height, y0 + 0.02 * height)
  )
  lab <- tibble::tibble(
    x = (x0 + x1) / 2,
    y = y0 + 0.045 * height,
    label = paste0(length_km, " km")
  )
  if (!is.null(facet) && !is.null(data) && facet %in% names(data)) {
    first <- vctrs::vec_slice(data, 1L)[[facet]]
    bar[[facet]] <- first
    ticks[[facet]] <- first
    lab[[facet]] <- first
  }
  list(
    ggplot2::geom_line(
      data = bar,
      ggplot2::aes(.data$x, .data$y),
      linewidth = 0.7,
      colour = "grey10",
      inherit.aes = FALSE
    ),
    ggplot2::geom_segment(
      data = ticks,
      ggplot2::aes(.data$x, .data$y, xend = .data$x, yend = .data$yend),
      colour = "grey10",
      linewidth = 0.6,
      inherit.aes = FALSE
    ),
    ggplot2::geom_text(
      data = lab,
      ggplot2::aes(.data$x, .data$y, label = .data$label),
      size = 2.8,
      colour = "grey10",
      inherit.aes = FALSE
    )
  )
}

geo_annotation_north_arrow <- function(bb, facet = NULL, data = NULL) {
  xmin <- unname(bb["xmin"])
  xmax <- unname(bb["xmax"])
  ymin <- unname(bb["ymin"])
  ymax <- unname(bb["ymax"])
  width <- xmax - xmin
  height <- ymax - ymin
  cx <- xmax - 0.08 * width
  cy <- ymax - 0.12 * height
  arrow_h <- 0.07 * height
  tip <- tibble::tibble(
    x = c(cx, cx - 0.015 * width, cx + 0.015 * width),
    y = c(cy + arrow_h, cy, cy)
  )
  stem <- tibble::tibble(
    x = c(cx, cx),
    y = c(cy - 0.02 * height, cy)
  )
  lab <- tibble::tibble(x = cx, y = cy + arrow_h + 0.03 * height, label = "N")
  if (!is.null(facet) && !is.null(data) && facet %in% names(data)) {
    first <- vctrs::vec_slice(data, 1L)[[facet]]
    tip[[facet]] <- first
    stem[[facet]] <- first
    lab[[facet]] <- first
  }
  list(
    ggplot2::geom_polygon(
      data = tip,
      ggplot2::aes(.data$x, .data$y),
      fill = "grey10",
      colour = NA,
      inherit.aes = FALSE
    ),
    ggplot2::geom_line(
      data = stem,
      ggplot2::aes(.data$x, .data$y),
      colour = "grey10",
      linewidth = 0.6,
      inherit.aes = FALSE
    ),
    ggplot2::geom_text(
      data = lab,
      ggplot2::aes(.data$x, .data$y, label = .data$label),
      fontface = "bold",
      size = 3,
      colour = "grey10",
      inherit.aes = FALSE
    )
  )
}

#' Illustrative coordinates for the package PNG example sites
#'
#' Returns a small tibble of WGS84 longitude and latitude for the Mt Wilhelm
#' elevational bands used by [png_ants] and [png_frogs], or for the three
#' canopy plots in [png_tree_ants]. Positions are approximate, for trying
#' study-site maps and geospatial verbs; replace them with your own GPS
#' records in a published figure.
#'
#' @param which `"wilhelm"` (Mt Wilhelm elevation bands) or `"wanang"`
#'   (Wanang, Numba and Yawan canopy plots).
#' @return A tibble with `site`, `lon`, `lat`, `elevation` and
#'   `elevation_band`.
#' @export
#' @examples
#' geo_example_sites("wilhelm")
#' geo_example_sites("wanang")
geo_example_sites <- function(which = c("wilhelm", "wanang")) {
  which <- rlang::arg_match(which)
  if (which == "wilhelm") {
    out <- tibble::tibble(
      site = c(
        "MW0200", "MW0700", "MW1200", "MW1700",
        "MW2200", "MW2700", "MW3200", "MW3700"
      ),
      lon = c(
        145.23, 145.18, 145.12, 145.06,
        145.01, 144.97, 144.94, 144.92
      ),
      lat = c(
        -5.72, -5.74, -5.78, -5.81,
        -5.85, -5.88, -5.90, -5.92
      ),
      elevation = c(200L, 700L, 1200L, 1700L, 2200L, 2700L, 3200L, 3700L)
    )
  } else {
    out <- tibble::tibble(
      site = c("Wanang", "Numba", "Yawan"),
      lon = c(145.08, 145.77, 146.30),
      lat = c(-5.23, -5.95, -6.15),
      elevation = c(200L, 900L, 1800L)
    )
  }
  out$elevation_band <- paste0(out$elevation, " m")
  out
}
