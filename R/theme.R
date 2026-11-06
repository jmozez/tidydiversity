#' Publication theme and colour palettes
#'
#' @description
#' `theme_tidydiversity()` is a clean ggplot2 theme for journal figures:
#' white background, light horizontal grid, black text, a legend at the
#' bottom and plain facet strips. Every [autoplot()][autoplot-tidydiversity]
#' method uses it by default, and you can add it to any ggplot.
#'
#' `plot_palette()` returns colour-blind-safe colours: the Okabe-Ito palette
#' (Okabe and Ito 2008) by default, switching to the viridis palette when
#' more than eight colours are needed, or a greyscale ramp for journals that
#' print in black and white. `scale_colour_tidydiversity()` and
#' `scale_fill_tidydiversity()` are the matching discrete ggplot2 scales.
#'
#' @param base_size Base font size in points.
#' @param base_family Base font family.
#' @param legend_position Legend position, passed to
#'   [ggplot2::theme()].
#' @param grid Draw major grid lines: `"y"`, `"x"`, `"xy"` or `"none"`.
#' @param n Number of colours.
#' @param palette `"okabe_ito"` or `"grey"`.
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 theme, a character vector of colours or a ggplot2
#'   scale.
#' @references Okabe, M. and Ito, K. (2008). Color universal design (CUD):
#'   how to make figures and presentations that are friendly to colorblind
#'   people. <https://jfly.uni-koeln.de/color/>
#' @name theme_tidydiversity
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' library(ggplot2)
#' plot_palette(3)
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
#'   geom_point() +
#'   scale_colour_tidydiversity() +
#'   theme_tidydiversity(base_size = 9)
NULL

#' @rdname theme_tidydiversity
#' @export
theme_tidydiversity <- function(base_size = 11,
                                base_family = "",
                                legend_position = "bottom",
                                grid = c("y", "x", "xy", "none")) {
  rlang::check_installed("ggplot2")
  grid <- rlang::arg_match(grid)
  blank <- ggplot2::element_blank()
  line <- ggplot2::element_line(colour = "grey90", linewidth = 0.3)
  ggplot2::theme_bw(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      panel.grid.minor = blank,
      panel.grid.major.x = if (grid %in% c("x", "xy")) line else blank,
      panel.grid.major.y = if (grid %in% c("y", "xy")) line else blank,
      panel.border = ggplot2::element_rect(
        colour = "grey30", fill = NA,
        linewidth = 0.4
      ),
      axis.ticks = ggplot2::element_line(colour = "grey30", linewidth = 0.3),
      axis.text = ggplot2::element_text(colour = "black"),
      strip.background = ggplot2::element_rect(
        fill = "grey95",
        colour = "grey30", linewidth = 0.4
      ),
      strip.text = ggplot2::element_text(
        colour = "black",
        face = "bold"
      ),
      legend.position = legend_position,
      legend.key = blank,
      legend.background = blank,
      plot.title.position = "plot",
      # Room between facets so neighbouring axis labels never touch
      panel.spacing = ggplot2::unit(0.9, "lines"),
      # Always a white figure, also on dark web pages and slides
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
}

okabe_ito <- c(
  "#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9",
  "#F0E442", "#000000"
)

#' @rdname theme_tidydiversity
#' @export
plot_palette <- function(n, palette = c("okabe_ito", "grey")) {
  palette <- rlang::arg_match(palette)
  td_check_number(n, "n", 0, whole = TRUE)
  if (palette == "grey") {
    return(grDevices::grey.colors(n, start = 0, end = 0.7))
  }
  if (n > length(okabe_ito)) {
    return(grDevices::hcl.colors(n, "viridis"))
  }
  okabe_ito[seq_len(n)]
}

#' @rdname theme_tidydiversity
#' @export
scale_colour_tidydiversity <- function(palette = c("okabe_ito", "grey"),
                                       ...) {
  rlang::check_installed("ggplot2")
  palette <- rlang::arg_match(palette)
  ggplot2::discrete_scale(
    "colour",
    palette = function(n) plot_palette(n, palette), ...
  )
}

#' @rdname theme_tidydiversity
#' @export
scale_fill_tidydiversity <- function(palette = c("okabe_ito", "grey"), ...) {
  rlang::check_installed("ggplot2")
  palette <- rlang::arg_match(palette)
  ggplot2::discrete_scale(
    "fill",
    palette = function(n) plot_palette(n, palette), ...
  )
}

# Add the palette and theme chosen in an autoplot() call.
td_style <- function(p, palette, theme, fill = TRUE) {
  named <- is.character(palette) && length(palette) == 1 &&
    palette %in% c("okabe_ito", "grey")
  if (named) {
    p <- p + scale_colour_tidydiversity(palette)
    if (fill) p <- p + scale_fill_tidydiversity(palette)
  } else if (is.character(palette)) {
    p <- p + ggplot2::scale_colour_manual(values = palette)
    if (fill) p <- p + ggplot2::scale_fill_manual(values = palette)
  } else if (!is.null(palette)) {
    cli::cli_abort(
      "{.arg palette} must be {.val okabe_ito}, {.val grey}, a vector of \\
      colours or {.code NULL}."
    )
  }
  if (!is.null(theme)) p <- p + theme
  td_alt(p)
}

# Default alt text for screen readers (see ggplot2::get_alt_text(), used by
# Shiny), built from the plot's labels unless labs(alt = ) already set one.
td_alt <- function(p) {
  if (!is.null(p$labels$alt)) return(p)
  lab <- function(a) {
    l <- p$labels[[a]]
    if (is.null(l) && !is.null(p$mapping[[a]])) {
      l <- rlang::as_label(p$mapping[[a]])
    }
    if (!is.character(l) || length(l) != 1 || !nzchar(l)) return(NULL)
    gsub("\\s+", " ", sub("^\\.data\\$", "", l))
  }
  x <- lab("x")
  y <- lab("y")
  group <- lab("colour") %||% lab("fill")
  txt <- if (!is.null(x) && !is.null(y)) {
    paste("Plot of", y, "against", x)
  } else {
    "Plot"
  }
  if (!is.null(group) && !startsWith(group, ".")) {
    txt <- paste0(txt, ", coloured by ", group)
  }
  params <- p$facet$params
  panels <- as.character(names(c(params$facets, params$rows, params$cols)))
  panels <- panels[!startsWith(panels, ".")]
  if (length(panels)) {
    txt <- paste0(txt, ", in panels by ", paste(panels, collapse = " and "))
  }
  p + ggplot2::labs(alt = paste0(txt, "."))
}

# Plots with a fixed aspect ratio (ordinations, heatmaps) do not fill the
# whole graphics device, and ggplot leaves the unused margin unpainted, so
# it is transparent on transparent devices (pkgdown, knitr). Marking such
# plots makes print() paint the whole device white first.
td_white <- function(p) {
  class(p) <- unique(c("td_gg", class(p)))
  p
}

#' @export
print.td_gg <- function(x, newpage = is.null(vp), vp = NULL, ...) {
  if (newpage) grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
  NextMethod(newpage = FALSE)
}
