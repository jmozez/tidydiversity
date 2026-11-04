#' Combine plots into a publication figure
#'
#' `plot_panel()` arranges ggplots (for example several `autoplot()`
#' results) into one multi-panel figure with
#' [patchwork](https://patchwork.data-imaginist.com). It adds panel tags
#' (a, b, c, ...), collects shared legends and applies the tidydiversity
#' theme. The result is an ordinary patchwork object, so you can still add
#' `patchwork::plot_annotation()` or `&` theme changes.
#'
#' @param ... ggplot objects, or one list of them.
#' @param ncol,nrow Layout grid, passed to [patchwork::wrap_plots()].
#' @param tag_levels Panel tag style: `"a"`, `"A"`, `"1"`, `"i"`, `"I"`, or
#'   `NULL` for no tags.
#' @param tag_prefix,tag_suffix Text around each tag, for example `"("`
#'   and `")"`.
#' @param guides `"collect"` (default) merges identical legends; `"keep"`
#'   leaves them on each panel.
#' @param legend_position Position of collected legends.
#' @param title,subtitle,caption Figure annotations.
#' @param widths,heights Relative panel sizes.
#' @return A patchwork object.
#' @seealso [plot_save()]
#' @examplesIf rlang::is_installed(c("ggplot2", "patchwork"))
#' r0 <- div_rarefy(png_ants, q = 0, .by = season, knots = 20)
#' r2 <- div_rarefy(png_ants, q = 2, .by = season, knots = 20)
#' plot_panel(ggplot2::autoplot(r0), ggplot2::autoplot(r2), ncol = 2)
#' @export
plot_panel <- function(...,
                       ncol = NULL,
                       nrow = NULL,
                       tag_levels = "a",
                       tag_prefix = "",
                       tag_suffix = "",
                       guides = c("collect", "keep"),
                       legend_position = "bottom",
                       title = NULL,
                       subtitle = NULL,
                       caption = NULL,
                       widths = NULL,
                       heights = NULL) {
  rlang::check_installed("patchwork",
    version = "1.3.0", reason = "to combine plots."
  )
  guides <- match.arg(guides)
  plots <- list(...)
  if (length(plots) == 1 && !inherits(plots[[1]], "gg") &&
        is.list(plots[[1]])) {
    plots <- plots[[1]]
  }
  if (length(plots) == 0) {
    cli::cli_abort("Supply at least one plot.")
  }
  ok <- vapply(plots, function(p) inherits(p, c("gg", "patchwork")), logical(1))
  if (!all(ok)) {
    cli::cli_abort("All inputs to {.fn plot_panel} must be ggplot objects.")
  }
  th <- ggplot2::theme(
    plot.tag = ggplot2::element_text(face = "bold"),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = legend_position
  )
  plots <- lapply(plots, function(p) p + th)
  out <- patchwork::wrap_plots(plots,
    ncol = ncol, nrow = nrow, guides = guides,
    widths = widths, heights = heights
  )
  out + patchwork::plot_annotation(
    title = title, subtitle = subtitle, caption = caption,
    tag_levels = if (is.null(tag_levels)) NULL else list(tag_levels),
    tag_prefix = tag_prefix, tag_suffix = tag_suffix,
    theme = th
  )
}

#' Save a figure at journal sizes
#'
#' A wrapper around [ggplot2::ggsave()] with journal column widths, a
#' white background and 300 dpi by default. Works for ggplot and patchwork
#' objects.
#'
#' @param plot A ggplot or patchwork object.
#' @param filename File name; the extension sets the format (`.png`,
#'   `.pdf`, `.tiff`, `.svg`, ...).
#' @param size `"single"` (85 mm wide), `"onehalf"` (120 mm) or `"double"`
#'   (175 mm) column width. Ignored if `width` is given.
#' @param width,height Size in `units`. `height` defaults to 0.8 x width.
#' @param units Units for `width` and `height`.
#' @param dpi Resolution for raster formats.
#' @param ... Passed to [ggplot2::ggsave()].
#' @return `filename`, invisibly.
#' @examplesIf rlang::is_installed("ggplot2")
#' r <- div_rarefy(png_ants, q = 0, .by = season, knots = 20)
#' f <- tempfile(fileext = ".png")
#' plot_save(ggplot2::autoplot(r), f, size = "single")
#' @export
plot_save <- function(plot,
                      filename,
                      size = c("single", "onehalf", "double"),
                      width = NULL,
                      height = NULL,
                      units = c("mm", "cm", "in"),
                      dpi = 300,
                      ...) {
  rlang::check_installed("ggplot2", reason = "to save plots.")
  size <- match.arg(size)
  units <- match.arg(units)
  if (is.null(width)) {
    mm <- c(single = 85, onehalf = 120, double = 175)[[size]]
    width <- switch(units, mm = mm, cm = mm / 10, `in` = mm / 25.4)
  }
  if (is.null(height)) {
    height <- 0.8 * width
  }
  ggplot2::ggsave(filename,
    plot = plot, width = width, height = height,
    units = units, dpi = dpi, bg = "white", ...
  )
  invisible(filename)
}
