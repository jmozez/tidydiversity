# Combine plots into a publication figure

`plot_panel()` arranges ggplots (for example several
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
results) into one multi-panel figure with
[patchwork](https://patchwork.data-imaginist.com). It adds panel tags
(a, b, c, ...), collects shared legends and applies the tidydiversity
theme. The result is an ordinary patchwork object, so you can still add
[`patchwork::plot_annotation()`](https://patchwork.data-imaginist.com/reference/plot_annotation.html)
or `&` theme changes.

## Usage

``` r
plot_panel(
  ...,
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
  heights = NULL
)
```

## Arguments

- ...:

  ggplot objects, or one list of them.

- ncol, nrow:

  Layout grid, passed to
  [`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html).

- tag_levels:

  Panel tag style: `"a"`, `"A"`, `"1"`, `"i"`, `"I"`, or `NULL` for no
  tags.

- tag_prefix, tag_suffix:

  Text around each tag, for example `"("` and `")"`.

- guides:

  `"collect"` (default) merges identical legends; `"keep"` leaves them
  on each panel.

- legend_position:

  Position of collected legends.

- title, subtitle, caption:

  Figure annotations.

- widths, heights:

  Relative panel sizes.

## Value

A patchwork object.

## See also

[`plot_save()`](https://tidydiversity.in4metrix.dev/reference/plot_save.md)

## Examples

``` r
r0 <- div_rarefy(png_ants, q = 0, .by = season, knots = 20)
r2 <- div_rarefy(png_ants, q = 2, .by = season, knots = 20)
plot_panel(ggplot2::autoplot(r0), ggplot2::autoplot(r2), ncol = 2)
```
