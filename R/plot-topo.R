#' Map tree stems over topography
#'
#' @description
#' `plot_topo()` draws individual trees or stems over a topographic backdrop
#' for ForestGEO-style and similar plot inventories (Wanang and other large
#' forest dynamics plots). Points use local projected coordinates in metres
#' (`gx`, `gy`) or geographic lon/lat. The backdrop can be contour lines,
#' a DEM / hillshade raster, or both. Colour by species or size (DBH), and
#' optionally draw the plot boundary.
#'
#' Expected columns for a ForestGEO-like table: `plot`, `treeID`, `stemID`,
#' `gx`, `gy` (metres from the plot origin), `dbh`, `species`, `status`.
#' Geographic inventories may use `lon` / `lat` instead of `gx` / `gy`.
#'
#' Use [geo_example_stems()] for a small illustrative stem table when you
#' do not yet have GPS or plot coordinates. Replace it with your own
#' inventory before publication. SDM tools such as biomod2 and Maxent stay
#' out of scope here.
#'
#' @param data A data frame of stems/trees, or an `sf` object.
#' @param x,y <[`data-masking`][dplyr::dplyr_data_masking]> Local metre
#'   columns (defaults `gx`, `gy`). Ignored when `lon`/`lat` are set or
#'   `data` is `sf`.
#' @param lon,lat <[`data-masking`][dplyr::dplyr_data_masking]> Optional
#'   geographic coordinates. When supplied, they override `x`/`y`.
#' @param colour <[`data-masking`][dplyr::dplyr_data_masking]> Grouping
#'   column (species, status) or a continuous size such as DBH.
#' @param size <[`data-masking`][dplyr::dplyr_data_masking]> Optional column
#'   mapped to point size (typically `dbh`). When `NULL` and `dbh` exists,
#'   DBH is used.
#' @param dem Optional `terra::SpatRaster` elevation surface for hillshade
#'   and/or contours. In local metre coordinates the raster should use the
#'   same origin as `gx`/`gy`.
#' @param boundary Optional `sf` polygon of the plot boundary, or a numeric
#'   bbox `c(xmin, ymin, xmax, ymax)`.
#' @param contours Draw contour lines from `dem`?
#' @param hillshade Draw a hillshade backdrop from `dem`?
#' @param contour_breaks Contour interval, or a vector of breaks. When
#'   `NULL`, pretty breaks are chosen.
#' @param basemap Passed to [geo_basemap()] when using lon/lat (for example
#'   `"coast"`). Ignored for local metre coordinates.
#' @param palette Discrete palette when `colour` is categorical.
#' @param point_alpha Point opacity.
#' @return A ggplot object.
#' @export
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' stems <- geo_example_stems()
#' dem <- geo_example_dem()
#' plot_topo(stems, colour = species, size = dbh, dem = dem, boundary = c(0, 0, 100, 100))
plot_topo <- function(data,
                      x = gx,
                      y = gy,
                      lon = NULL,
                      lat = NULL,
                      colour = NULL,
                      size = NULL,
                      dem = NULL,
                      boundary = NULL,
                      contours = TRUE,
                      hillshade = TRUE,
                      contour_breaks = NULL,
                      basemap = "none",
                      palette = c("okabe_ito", "grey"),
                      point_alpha = 0.85) {
  rlang::check_installed("ggplot2")
  palette <- rlang::arg_match(palette)
  td_check_data(data)

  lon_q <- enquo(lon)
  lat_q <- enquo(lat)
  use_geo <- !quo_is_null(lon_q) || !quo_is_null(lat_q) || inherits(data, "sf")

  col_q <- enquo(colour)
  size_q <- enquo(size)
  col_nm <- if (quo_is_null(col_q)) NULL else td_pick(col_q, data, "colour")
  if (quo_is_null(size_q)) {
    size_nm <- if ("dbh" %in% names(data)) "dbh" else NULL
  } else {
    size_nm <- td_pick(size_q, data, "size")
  }

  if (use_geo) {
    rlang::check_installed("sf")
    if (inherits(data, "sf")) {
      pts <- geo_as_sf(data, drop_na = TRUE)
    } else {
      lon_col <- td_pick(lon_q, data, "lon")
      lat_col <- td_pick(lat_q, data, "lat")
      pts <- geo_as_sf(
        data,
        lon = !!rlang::sym(lon_col),
        lat = !!rlang::sym(lat_col),
        drop_na = TRUE
      )
    }
    p <- ggplot2::ggplot()
    bb <- sf::st_bbox(pts)
    dx <- max((bb["xmax"] - bb["xmin"]) * 0.05, 1e-4)
    dy <- max((bb["ymax"] - bb["ymin"]) * 0.05, 1e-4)
    bb["xmin"] <- bb["xmin"] - dx
    bb["xmax"] <- bb["xmax"] + dx
    bb["ymin"] <- bb["ymin"] - dy
    bb["ymax"] <- bb["ymax"] + dy
    bm <- geo_basemap_layers(bb, basemap = basemap, crs = sf::st_crs(pts))
    for (ly in bm$layers) p <- p + ly
    p <- plot_topo_dem_layers(
      p, dem,
      contours = contours, hillshade = hillshade,
      contour_breaks = contour_breaks, geographic = TRUE
    )
    p <- plot_topo_boundary(p, boundary, geographic = TRUE, crs = sf::st_crs(pts))
    p <- plot_topo_points_sf(
      p, pts, col_nm, size_nm, palette, point_alpha,
      fill_free = !isTRUE(bm$uses_fill)
    )
    p +
      ggplot2::coord_sf(crs = sf::st_crs(pts), expand = FALSE) +
      theme_tidydiversity(grid = "none") +
      ggplot2::labs(x = NULL, y = NULL)
  } else {
    x_col <- td_pick(enquo(x), data, "x")
    y_col <- td_pick(enquo(y), data, "y")
    xv <- data[[x_col]]
    yv <- data[[y_col]]
    ok <- is.finite(xv) & is.finite(yv)
    if (!any(ok)) {
      cli::cli_abort("No finite stem coordinates remain to plot.")
    }
    df <- tibble::as_tibble(dplyr::ungroup(data)[ok, , drop = FALSE])
    p <- ggplot2::ggplot()
    p <- plot_topo_dem_layers(
      p, dem,
      contours = contours, hillshade = hillshade,
      contour_breaks = contour_breaks, geographic = FALSE
    )
    p <- plot_topo_boundary(p, boundary, geographic = FALSE)
    p <- plot_topo_points_xy(
      p, df, x_col, y_col, col_nm, size_nm, palette, point_alpha
    )
    p +
      ggplot2::coord_fixed(expand = FALSE) +
      theme_tidydiversity(grid = "none") +
      ggplot2::labs(x = paste0(x_col, " (m)"), y = paste0(y_col, " (m)"))
  }
}

plot_topo_dem_layers <- function(p, dem, contours, hillshade,
                                 contour_breaks, geographic = FALSE) {
  if (is.null(dem)) {
    return(p)
  }
  rlang::check_installed("terra")
  r <- geo_as_raster(dem)[[1]]
  if (isTRUE(hillshade)) {
    slope <- terra::terrain(r, v = "slope", unit = "radians")
    aspect <- terra::terrain(r, v = "aspect", unit = "radians")
    hs <- terra::shade(slope, aspect, angle = 45, direction = 315)
    hdf <- terra::as.data.frame(hs, xy = TRUE, na.rm = TRUE)
    z <- setdiff(names(hdf), c("x", "y"))[1]
    p <- p + ggplot2::geom_raster(
      data = hdf,
      ggplot2::aes(.data$x, .data$y, fill = .data[[z]]),
      alpha = 0.9
    ) +
      ggplot2::scale_fill_gradient(
        low = "grey30", high = "grey95",
        guide = "none"
      )
  }
  if (isTRUE(contours)) {
    # Contour via terra then fortify, avoiding extra packages
    if (is.null(contour_breaks)) {
      v <- terra::values(r)
      v <- v[is.finite(v)]
      contour_breaks <- pretty(range(v), n = 8)
    } else if (length(contour_breaks) == 1) {
      v <- terra::values(r)
      v <- v[is.finite(v)]
      contour_breaks <- seq(
        floor(min(v) / contour_breaks) * contour_breaks,
        ceiling(max(v) / contour_breaks) * contour_breaks,
        by = contour_breaks
      )
    }
    cdf <- tryCatch(
      {
        # densify for smoother lines
        xyz <- terra::as.data.frame(r, xy = TRUE, na.rm = TRUE)
        names(xyz)[3] <- "z"
        xyz
      },
      error = function(e) NULL
    )
    if (!is.null(cdf)) {
      p <- p + ggplot2::geom_contour(
        data = cdf,
        ggplot2::aes(.data$x, .data$y, z = .data$z),
        breaks = contour_breaks,
        colour = "grey25",
        linewidth = 0.3,
        alpha = 0.8
      )
    }
  }
  p
}


plot_topo_boundary <- function(p, boundary, geographic = FALSE, crs = NULL) {
  if (is.null(boundary)) {
    return(p)
  }
  if (is.numeric(boundary) && length(boundary) == 4) {
    if (is.null(names(boundary))) {
      names(boundary) <- c("xmin", "ymin", "xmax", "ymax")
    }
    rect <- data.frame(
      x = c(boundary[["xmin"]], boundary[["xmax"]], boundary[["xmax"]],
        boundary[["xmin"]], boundary[["xmin"]]),
      y = c(boundary[["ymin"]], boundary[["ymin"]], boundary[["ymax"]],
        boundary[["ymax"]], boundary[["ymin"]])
    )
    return(p + ggplot2::geom_path(
      data = rect,
      ggplot2::aes(.data$x, .data$y),
      colour = "grey10",
      linewidth = 0.6,
      inherit.aes = FALSE
    ))
  }
  if (inherits(boundary, "sf")) {
    rlang::check_installed("sf")
    if (!is.null(crs)) {
      boundary <- sf::st_transform(boundary, crs)
    }
    return(p + ggplot2::geom_sf(
      data = boundary,
      fill = NA,
      colour = "grey10",
      linewidth = 0.6
    ))
  }
  cli::cli_abort("{.arg boundary} must be an sf polygon or a length-4 bbox.")
}

plot_topo_points_xy <- function(p, df, x_col, y_col, col_nm, size_nm,
                                palette, point_alpha) {
  if (is.null(col_nm) && is.null(size_nm)) {
    return(p + ggplot2::geom_point(
      data = df,
      ggplot2::aes(.data[[x_col]], .data[[y_col]]),
      colour = plot_palette(1, palette = palette),
      alpha = point_alpha,
      size = 1.6
    ))
  }
  if (!is.null(col_nm) && !is.null(size_nm)) {
    p <- p + ggplot2::geom_point(
      data = df,
      ggplot2::aes(
        .data[[x_col]], .data[[y_col]],
        colour = .data[[col_nm]], size = .data[[size_nm]]
      ),
      alpha = point_alpha
    )
  } else if (!is.null(col_nm)) {
    p <- p + ggplot2::geom_point(
      data = df,
      ggplot2::aes(
        .data[[x_col]], .data[[y_col]],
        colour = .data[[col_nm]]
      ),
      alpha = point_alpha,
      size = 1.8
    )
  } else {
    p <- p + ggplot2::geom_point(
      data = df,
      ggplot2::aes(
        .data[[x_col]], .data[[y_col]],
        size = .data[[size_nm]]
      ),
      colour = plot_palette(1, palette = palette),
      alpha = point_alpha
    )
  }
  p <- plot_topo_scales(p, df, col_nm, size_nm, palette, aes = "colour")
  p
}

plot_topo_points_sf <- function(p, pts, col_nm, size_nm, palette,
                                point_alpha, fill_free = TRUE) {
  if (is.null(col_nm) && is.null(size_nm)) {
    return(p + ggplot2::geom_sf(
      data = pts,
      colour = plot_palette(1, palette = palette),
      alpha = point_alpha,
      size = 1.6
    ))
  }
  if (!is.null(col_nm) && !is.null(size_nm)) {
    p <- p + ggplot2::geom_sf(
      data = pts,
      ggplot2::aes(colour = .data[[col_nm]], size = .data[[size_nm]]),
      alpha = point_alpha
    )
  } else if (!is.null(col_nm)) {
    p <- p + ggplot2::geom_sf(
      data = pts,
      ggplot2::aes(colour = .data[[col_nm]]),
      alpha = point_alpha,
      size = 1.8
    )
  } else {
    p <- p + ggplot2::geom_sf(
      data = pts,
      ggplot2::aes(size = .data[[size_nm]]),
      colour = plot_palette(1, palette = palette),
      alpha = point_alpha
    )
  }
  plot_topo_scales(p, pts, col_nm, size_nm, palette, aes = "colour")
}

plot_topo_scales <- function(p, data, col_nm, size_nm, palette, aes = "colour") {
  if (!is.null(col_nm)) {
    col_v <- data[[col_nm]]
    if (is.numeric(col_v) && !is.factor(col_v)) {
      p <- p + ggplot2::scale_colour_viridis_c(name = col_nm, option = "C")
    } else {
      levs <- if (is.factor(col_v)) levels(col_v) else as.character(
        vctrs::vec_unique(col_v)
      )
      cols <- plot_palette(length(levs), palette = palette)
      names(cols) <- levs
      p <- p + ggplot2::scale_colour_manual(name = col_nm, values = cols)
    }
  }
  if (!is.null(size_nm)) {
    p <- p + ggplot2::scale_size_area(name = size_nm, max_size = 7)
  }
  p
}

#' Illustrative ForestGEO-style stem table
#'
#' Returns a small stem inventory in local metre coordinates (`gx`, `gy`)
#' for trying [plot_topo()]. Columns follow the ForestGEO convention
#' (`plot`, `treeID`, `stemID`, `gx`, `gy`, `dbh`, `species`, `status`).
#' Positions are simulated on a 100 m x 100 m plot for examples only; they
#' are not real Wanang or ForestGEO coordinates. Replace with your own
#' inventory for publication.
#'
#' @param n Number of stems.
#' @param seed RNG seed for reproducibility.
#' @return A tibble.
#' @references Condit, R. et al. (2019). Complete data from the Barro
#'   Colorado 50-ha plot: 423617 trees, 35 years. *Dryad*.
#'   \doi{10.15146/5xcp-0d46}. ForestGEO network:
#'   <https://forestgeo.si.edu/>. Wanang forest dynamics plot, Papua New
#'   Guinea: Anderson-Teixeira, K. J. et al. (2015). CTFS-ForestGEO: a
#'   worldwide network monitoring forests in an era of global change.
#'   *Global Change Biology*, 21, 528-549. \doi{10.1111/gcb.12712}.
#' @export
#' @examples
#' geo_example_stems()
geo_example_stems <- function(n = 120, seed = 1) {
  td_check_number(n, "n", 1, whole = TRUE)
  if (!is.null(seed)) set.seed(seed)
  spp <- c("Pometia_pinnata", "Intsia_bijuga", "Pterocarpus_indicus",
    "Homalanthus_novoguineensis", "Ficus_sp")
  tibble::tibble(
    plot = "demo100",
    treeID = seq_len(n),
    stemID = seq_len(n),
    gx = stats::runif(n, 2, 98),
    gy = stats::runif(n, 2, 98),
    dbh = pmax(1, round(stats::rlnorm(n, meanlog = 2.2, sdlog = 0.55), 1)),
    species = sample(spp, n, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
    status = sample(c("A", "A", "A", "D"), n, replace = TRUE)
  )
}

#' Illustrative DEM for local metre stem maps
#'
#' Builds a small elevation raster in the same 0-100 m local coordinates as
#' [geo_example_stems()], for topographic backdrops in [plot_topo()].
#'
#' @param res Grid resolution in metres.
#' @return A `terra::SpatRaster`.
#' @export
#' @examplesIf requireNamespace("terra", quietly = TRUE)
#' geo_example_dem()
geo_example_dem <- function(res = 2) {
  rlang::check_installed("terra")
  td_check_number(res, "res", 0)
  r <- terra::rast(
    xmin = 0, xmax = 100, ymin = 0, ymax = 100,
    resolution = res
  )
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
  # Gentle ridge plus noise, elevation in metres
  z <- 120 + 8 * sin(xy[, 1] / 18) + 5 * cos(xy[, 2] / 22) +
    0.03 * xy[, 2]
  terra::values(r) <- z
  names(r) <- "elevation"
  r
}
