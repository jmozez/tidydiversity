# Save a figure at journal sizes

A wrapper around
[`ggplot2::ggsave()`](https://rdrr.io/pkg/ggplot2/man/ggsave.html) with
journal column widths, a white background and 300 dpi by default. Works
for ggplot and patchwork objects.

## Usage

``` r
plot_save(
  plot,
  filename,
  size = c("single", "onehalf", "double"),
  width = NULL,
  height = NULL,
  units = c("mm", "cm", "in", "px"),
  dpi = 300,
  ...
)
```

## Arguments

- plot:

  A ggplot or patchwork object.

- filename:

  File name; the extension sets the format (`.png`, `.pdf`, `.tiff`,
  `.svg`, ...).

- size:

  `"single"` (85 mm wide), `"onehalf"` (120 mm) or `"double"` (175 mm)
  column width. Ignored if `width` is given.

- width, height:

  Size in `units`. `height` defaults to 0.8 x width.

- units:

  Units for `width` and `height` (`"mm"`, `"cm"`, `"in"`, or `"px"`).

- dpi:

  Resolution for raster formats (default 300).

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://rdrr.io/pkg/ggplot2/man/ggsave.html).

## Value

`filename`, invisibly.

## See also

[`tidymapr::geo_save()`](https://rdrr.io/pkg/tidymapr/man/geo_save.html)
for map-oriented defaults (path, 180x140 mm).

## Examples

``` r
r <- div_rarefy(png_ants, q = 0, .by = season, knots = 20)
f <- tempfile(fileext = ".png")
plot_save(ggplot2::autoplot(r), f, size = "single")
```
