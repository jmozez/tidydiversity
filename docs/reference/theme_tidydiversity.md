# Publication theme and colour palettes

`theme_tidydiversity()` is a clean ggplot2 theme for journal figures:
white background, light horizontal grid, black text, a legend at the
bottom and plain facet strips. Every
[autoplot()](https://tidydiversity.in4metrix.dev/reference/autoplot-tidydiversity.md)
method uses it by default, and you can add it to any ggplot.

`plot_palette()` returns colour-blind-safe colours: the Okabe-Ito
palette (Okabe and Ito 2008) by default, switching to the viridis
palette when more than eight colours are needed, or a greyscale ramp for
journals that print in black and white. `scale_colour_tidydiversity()`
and `scale_fill_tidydiversity()` are the matching discrete ggplot2
scales.

## Usage

``` r
theme_tidydiversity(
  base_size = 11,
  base_family = "",
  legend_position = "bottom",
  grid = c("y", "x", "xy", "none")
)

plot_palette(n, palette = c("okabe_ito", "grey"))

scale_colour_tidydiversity(palette = c("okabe_ito", "grey"), ...)

scale_fill_tidydiversity(palette = c("okabe_ito", "grey"), ...)
```

## Arguments

- base_size:

  Base font size in points.

- base_family:

  Base font family.

- legend_position:

  Legend position, passed to
  [`ggplot2::theme()`](https://rdrr.io/pkg/ggplot2/man/theme.html).

- grid:

  Draw major grid lines: `"y"`, `"x"`, `"xy"` or `"none"`.

- n:

  Number of colours.

- palette:

  `"okabe_ito"` or `"grey"`.

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://rdrr.io/pkg/ggplot2/man/discrete_scale.html).

## Value

A ggplot2 theme, a character vector of colours or a ggplot2 scale.

## References

Okabe, M. and Ito, K. (2008). Color universal design (CUD): how to make
figures and presentations that are friendly to colour-blind people.
<https://jfly.uni-koeln.de/color/>

## Examples

``` r
library(ggplot2)
plot_palette(3)
#> [1] "#0072B2" "#D55E00" "#009E73"
ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  scale_colour_tidydiversity() +
  theme_tidydiversity(base_size = 9)
```
