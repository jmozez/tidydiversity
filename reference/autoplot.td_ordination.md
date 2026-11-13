# Plot an ordination

Draws a publication-quality ordination diagram in the style of CANOCO
(ter Braak and Smilauer 2012): a biplot of sites and species for
unconstrained methods and a triplot with environmental arrows for
constrained ones, with equal axis scaling, zero lines and the variation
explained by each axis in the axis titles. Species are drawn as arrows
for linear methods (PCA, RDA, PCoA, db-RDA), whose scores are directions
of increase, and as points for unimodal methods (CA, CCA, DCA) and NMDS,
whose scores are optima.

## Usage

``` r
# S3 method for class 'td_ordination'
autoplot(
  object,
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
  type = c("biplot", "gradient", "response", "scree", "shepard", "tvalue", "vandobben",
    "stability"),
  variable = NULL,
  axis = 1,
  model = c("glm", "gam"),
  layout = c("facet", "overlay"),
  n_axes = 10,
  nboot = 199,
  inset = c("none", "scree", "shepard"),
  ...
)
```

## Arguments

- object:

  A `td_ordination` from
  [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md).

- axes:

  The two axes to plot.

- colour, shape:

  Site variables (unquoted column names) to map to point colour and
  shape, such as `colour = elevation`. Sites are points, so they are
  drawn as categories (as in CANOCO), never on a continuous colour bar:
  a numeric variable with up to 8 distinct values gets one class per
  value, and otherwise is cut into up to 6 classes at pretty breaks;
  each class has its own colour and symbol. Discrete variables also
  define the groups for ellipses, hulls and spiders.

- group:

  A site variable defining groups for ellipses, hulls and spiders, if
  different from `colour`.

- sites:

  Draw the sites.

- site_labels:

  Label the sites.

- species:

  Number of species to draw and label, those best represented in the
  plotted plane (longest scores). Use `Inf` for all and `0` for none.

- species_arrows:

  Draw species as arrows (a PCA/RDA biplot, as
  [`vegan::biplot.rda()`](https://vegandevs.github.io/vegan/reference/biplot.rda.html)),
  only for linear methods. By default species are taxa and are drawn as
  points (crosses) with italic labels, as in `vegan::plot.rda()`; arrows
  are kept for continuous explanatory variables.

- arrows:

  Draw environmental arrows and factor centroids.

- ellipse:

  `"none"` (the default), `"sd"`, `"ci"` or `"se"`.

- level:

  Coverage of `"ci"` and `"se"` ellipses.

- hull:

  Draw convex hulls around groups.

- spider:

  Join each site to its group centroid.

- palette:

  Colours for groups: `"okabe_ito"` or `"grey"`; continuous variables
  use the viridis scale.

- theme:

  A ggplot2 theme, by default
  [`theme_tidydiversity()`](https://tidydiversity.in4metrix.dev/reference/theme_tidydiversity.md).

- surface:

  A numeric site variable to draw as a fitted surface: contour lines
  from a thin-plate GAM of the variable on the two axes (as in
  [`vegan::ordisurf()`](https://vegandevs.github.io/vegan/reference/ordisurf.html)),
  or a linear trend surface (a plane, as
  [`vegan::envfit()`](https://vegandevs.github.io/vegan/reference/envfit.html)
  assumes) with fewer than 15 sites, where a smooth surface would
  overfit. A continuous variable is a gradient, so it is drawn with
  lines (contours, or the arrows of the fitted `formula`), not by
  colouring the points.

- size:

  A numeric site variable shown by symbol size (a bubble or attribute
  plot, as in CANOCO).

- path:

  A numeric site variable, such as elevation or time: joins the sites in
  its order with a thin line and small arrowheads, so the reader sees at
  once how composition changes along the gradient.

- style:

  Look of every element, from
  [`ord_style()`](https://tidydiversity.in4metrix.dev/reference/ord_style.md):
  colours, symbols, sizes, line widths and fonts. The result is a
  ggplot, so any scale or theme can also be added afterwards.

- type:

  The kind of diagram:

  - `"biplot"` (default): sites, species, fitted variables and groups;

  - `"gradient"`: the ordination read as a gradient: sites (optionally
    joined in the order of `path`), fitted variables whose arrow width
    follows their r squared (non-significant ones thin, dashed and
    grey), the meaning of the first axis written at its ends, and the
    species sorted along the first axis in a panel below;

  - `"response"`: species response curves: each species' abundance
    against an axis (`axis`) or a site variable (`variable`), fitted by
    a quadratic Poisson GLM (ter Braak's Gaussian response) or a GAM
    (`model`), with a confidence band from the model on the link scale,
    for the `species` best-fitted species, as panels or overlaid
    (`layout`);

  - `"scree"`: variation explained by each axis, with the broken-stick
    expectation (`n_axes` axes);

  - `"shepard"`: Shepard diagram of an NMDS with stress and R squared;

  - `"tvalue"`: which species increase or decrease with one site
    variable (`variable`), the question of CANOCO's t-value biplot:
    species arrows coloured by an exact t-test of their coefficient in a
    regression of each (transformed) species on all site variables. Van
    Dobben circles are not drawn, as they only approximate these tests
    under one scaling.

  - `"vandobben"`: CANOCO's t-value biplot with Van Dobben circles for
    one numeric site variable (`variable`): species and variables placed
    by a rank-2 approximation of the matrix of t-values of regression
    coefficients; the dashed circles mark, approximately, species with a
    significant positive (red) or negative (blue) coefficient, and the
    colours give the exact t-tests;

  - `"stability"`: how robust each site's position is: 95% ellipses of
    `nboot` bootstrap ordinations (species resampled), rotated onto the
    original by Procrustes analysis (unconstrained methods).

- variable, axis, model, layout, n_axes, nboot:

  Options of `type` (see above).

- inset:

  For the biplot, a small diagnostic panel in a corner: `"scree"`
  (variance per axis) or `"shepard"` (NMDS fit).

- ...:

  Not used.

## Value

A ggplot object.

## Details

Groups of sites can be summarised with ellipses, convex hulls or
spiders. Ellipses follow
[`vegan::ordiellipse()`](https://vegandevs.github.io/vegan/reference/ordihull.html):
`"sd"` covers one standard deviation of the points, `"ci"` the region
expected to hold `level` of the points, and `"se"` a `level` confidence
region for the group centroid.

How to read the lines:

- red arrows from the origin: species (linear methods only);

- dark arrows from the origin: quantitative environmental variables;

- dark triangles: centroids of factor levels (for example years);

- coloured outlines: ellipses or convex hulls around groups of sites,
  and, with `spider = TRUE`, lines from each group centroid to its
  sites;

- faint dotted grey lines: label leaders, joining a label that had to be
  moved to avoid overlap to its point. They carry no information.

Every option is an argument, and the result is an ordinary ggplot that
can be changed further with `+`.

## References

ter Braak, C. J. F. and Smilauer, P. (2012). Canoco reference manual and
user's guide: software for ordination (version 5.0). Microcomputer
Power, Ithaca, USA.

## Examples

``` r
library(ggplot2)
data("dune", "dune.env", package = "vegan")
d <- community_long(cbind(site = rownames(dune), dune.env, dune),
  cols = dplyr::all_of(names(dune))
)

# RDA triplot of the dune meadows: A1 horizon as an arrow, management
# types as centroids with one-SD ellipses
ord <- ord_fit(d,
  abundance = abundance, method = "rda", transform = "hellinger",
  formula = ~ A1 + Management
)
autoplot(ord, colour = Management, ellipse = "sd")


# Which species respond to the A1 horizon? Van Dobben circles
autoplot(ord, type = "vandobben", variable = "A1")


# NMDS with the A1 horizon as contours and a Shepard inset
nmds <- ord_fit(d, abundance = abundance, method = "nmds", formula = ~A1)
autoplot(nmds, surface = A1, inset = "shepard")
```
