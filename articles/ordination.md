# Ordination: biplots and triplots

[`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md)
fits every common ordination to long community data and returns tidy
scores;
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws publication-quality biplots and triplots in the style of CANOCO.
The ordinations are computed by the
[vegan](https://CRAN.R-project.org/package=vegan) package, so the
results are identical to vegan’s (this is checked in the test suite).

``` r

library(tidydiversity)
library(dplyr)
library(ggplot2)
set.seed(2026)
```

## The concept

A community table has one column per species, so with 189 butterfly
species every sampling day is a point in 189 dimensions. **Ordination**
squeezes that into two or three axes that keep as much of the
differences between samples as possible: samples close together in the
diagram have similar species composition, samples far apart differ.

There are two families:

| Family | Question | Axes are |
|----|----|----|
| **Unconstrained** (PCA, CA, DCA, PCoA, NMDS) | What are the main patterns in composition, whatever causes them? | The strongest gradients in the species data |
| **Constrained** or canonical (RDA, CCA, db-RDA) | How much of the composition do *my* variables explain, and is it more than chance? | Combinations of the explanatory variables, chosen to explain the most composition |

Use an unconstrained method to explore and a constrained one to test a
hypothesis. Comparing the two tells you whether your variables capture
the main pattern or only a small part of it.

## Choosing a method

| Question | Method | `method =` |
|----|----|----|
| Main gradients in composition, short gradients | Principal components analysis | `"pca"` |
| Main gradients, long gradients (species turn over) | Correspondence analysis, detrended CA | `"ca"`, `"dca"` |
| Main gradients from any dissimilarity | Principal coordinates analysis, NMDS | `"pcoa"`, `"nmds"` |
| How much composition do my variables explain? | Redundancy analysis | `"rda"` |
| The same, for long gradients | Canonical correspondence analysis | `"cca"` |
| The same, for any dissimilarity | Distance-based RDA | `"dbrda"` |

A first DCA axis longer than about 4 standard deviation units suggests
long gradients, where the unimodal methods (CA, CCA) fit better than the
linear ones (PCA, RDA). PCA and RDA use the Hellinger transformation by
default (Legendre and Gallagher 2001); change it with `transform`.

## Reading the diagrams

| Element | Meaning |
|----|----|
| Points | Sites (coloured by a site variable) |
| Red arrows from the origin | Species, in linear methods (PCA, RDA, PCoA, db-RDA): the direction in which each species increases |
| Red crosses | Species optima, in unimodal methods (CA, CCA, DCA) and NMDS |
| Dark arrows from the origin | Quantitative environmental variables; in NMDS and PCA they are fitted afterwards (passive) |
| Dark triangles | Centroids of factor levels, such as years |
| Ellipses, hulls, spiders | Spread of each group of sites |
| Faint dotted grey lines | Label leaders only: they join a label that was moved to avoid overlap to its point |

## Constrained ordination: butterflies at Wanang

`wanang_butterflies` holds butterfly counts on 36 days over three years.
Does the community differ between years and change through the months?
Site variables (here `year` and `month`) are taken from the data
automatically, because they are constant within each day.

``` r

butterflies <- mutate(wanang_butterflies, year = factor(paste("Year", year)))
rda <- ord_fit(butterflies, method = "rda", formula = ~ year + month)
rda
#> RDA of 36 sites and 189 species
#> Transformation: hellinger
#> Variation explained: RDA1 13.1%, RDA2 6.4%, RDA3 4.1%
#> Constrained: 23.6% of the total
```

Permutation tests of the whole model and of each term:

``` r

ord_test(rda)
#> # A tibble: 2 × 5
#>   term        df variance statistic p.value
#>   <chr>    <dbl>    <dbl>     <dbl>   <dbl>
#> 1 Model        3   0.0521      3.29   0.001
#> 2 Residual    32   0.169      NA     NA
ord_test(rda, by = "terms")
#> # A tibble: 3 × 5
#>   term        df variance statistic p.value
#>   <chr>    <dbl>    <dbl>     <dbl>   <dbl>
#> 1 year         2   0.0336      3.18   0.001
#> 2 month        1   0.0185      3.51   0.001
#> 3 Residual    32   0.169      NA     NA
```

**How to read it.** The printout says the year and month together
explain 23.6% of the variation in butterfly composition (the
*constrained* fraction); the rest is variation among days that these
variables do not account for. A constrained fraction of 10-30% is
typical for community data: species respond to many things at once, and
counts of rare species are noisy.

The permutation test shuffles the days many times and refits the model;
the p-value is the proportion of shuffles that explain as much as the
real data. Both terms are significant on their own: years differ in
composition, and composition shifts steadily through the months
(seasonality), independently of year. Use `by = "terms"` for sequential
tests (each term after those before it) or `by = "margin"` for the
unique effect of each term after all others.

A triplot shows the days (points), the species with the strongest
responses (red arrows), the month gradient (blue arrow) and the year
centroids (triangles). Ellipses cover one standard deviation of the days
in each year.

``` r

autoplot(rda, colour = year, ellipse = "sd", species = 10)
```

![RDA triplot of butterfly days coloured by year, with ellipses, species
arrows, the month arrow and year
centroids.](ordination_files/figure-html/rda-plot-1.png)

**Interpretation.** Days of the same year cluster, and the year ellipses
overlap only partly: the community changed between years. The month
arrow points along the direction in which days late in the season lie; a
species arrow pointing the same way is more abundant late in the season,
one pointing the opposite way early in the season. The angle between two
arrows approximates their correlation (small angle = positive, right
angle = none, opposite = negative). Read species only from their arrow
direction, not from their nearest site.

## Unconstrained ordination with passive variables

NMDS summarises composition without reference to the variables; adding a
formula fits them passively afterwards (\[vegan::envfit()\]), as
supplementary variables in CANOCO.

``` r

nmds <- ord_fit(butterflies, method = "nmds", formula = ~ month + year)
tidy(nmds, "envfit")
#> # A tibble: 2 × 7
#>   term  type      r2 p.value axes  permutations exact
#>   <chr> <chr>  <dbl>   <dbl> <chr>        <dbl> <lgl>
#> 1 month vector 0.198   0.034 1, 2           999 FALSE
#> 2 year  factor 0.185   0.01  1, 2           999 FALSE
```

**How to read it.** `r2` is the proportion of variation in the NMDS
configuration explained by each variable, and `p.value` comes from a
permutation test. Month and year each explain about a fifth of the
pattern, and both are significant: the main pattern in composition,
found *without* reference to these variables, still lines up with them.
That is stronger evidence than a constrained analysis alone, which
always finds *some* pattern along the variables it is given.

``` r

autoplot(nmds, colour = month, group = year, hull = TRUE, species = 8)
```

![NMDS of butterfly days coloured by month, with convex hulls around
years.](ordination_files/figure-html/nmds-plot-1.png)

## Frogs along Mt Wilhelm

Frog communities turn over almost completely along the elevational
gradient, so a unimodal method suits them. CCA constrained by elevation:

``` r

cca <- ord_fit(png_frogs, method = "cca", formula = ~elevation)
ord_test(cca)
#> # A tibble: 2 × 5
#>   term        df chi_square statistic p.value
#>   <chr>    <dbl>      <dbl>     <dbl>   <dbl>
#> 1 Model        1      0.959      1.44   0.001
#> 2 Residual     6      4.00      NA     NA
```

**Interpretation.** Elevation alone explains about a fifth of frog
composition (model chi-square 0.96 of a total of 4.96), a large share
for a single variable, and the test is significant even with only eight
sites. In the triplot the sites are ordered along the elevation arrow,
and the species crosses mark each species’ optimum: lowland species at
one end, montane species at the other, with almost no species shared
between the ends. That is complete turnover, which is why a unimodal
method (CCA) was chosen.

``` r

autoplot(cca, colour = elevation, site_labels = TRUE, species = 12)
```

![CCA triplot of frog communities at eight elevations on Mt Wilhelm,
sites coloured by elevation, with the elevation
arrow.](ordination_files/figure-html/frogs-plot-1.png)

## Which geometry for which kind of variable

An ordination diagram follows the same rules as any map or chart: the
geometry and the visual variable depend on the type of data (Bertin
1967; ter Braak and Smilauer 2012; Oksanen et al.):

| What | Data type | Drawn as | In [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) |
|----|----|----|----|
| Sites, species | objects | points (or labels) | always |
| Groups of sites (habitat, season, elevation band) | factor | symbols and colours per class; centroids, ellipses, hulls, spiders | `colour`, `shape`, `group`, `ellipse`, `hull`, `spider` |
| Explanatory variable, linear | continuous | arrow: direction of steepest increase, length proportional to the correlation ([`vegan::envfit()`](https://vegandevs.github.io/vegan/reference/envfit.html)) | `formula` in [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md) |
| Explanatory variable, non-linear | continuous | contour lines of a fitted surface ([`vegan::ordisurf()`](https://vegandevs.github.io/vegan/reference/ordisurf.html)) | `surface` |
| A quantity at each site | continuous | symbol size (attribute plot, CANOCO) | `size` |

A continuous variable is a gradient, so it is drawn with lines (an arrow
or contours) or by symbol size, never by colouring the points on a
continuous colour bar. The same variable can be either kind, depending
on the question. Elevation, for example, is continuous when you ask how
composition changes along the gradient, and categorical when the sites
are a few elevation bands or when elevation simply identifies each site.
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
treats a numeric `colour` or `shape` as classes (one per value up to
eight, otherwise up to six classes), so give it a factor when you mean
categories, and use `formula`, `surface` or `size` when you mean a
gradient.

``` r

frog_pca <- ord_fit(png_frogs,
  abundance = abundance, method = "pca",
  transform = "hellinger", formula = ~elevation
)
# Elevation as categories: one symbol and colour per site elevation
p1 <- autoplot(frog_pca, colour = elevation, species = 0, arrows = FALSE) +
  ggplot2::labs(title = "Elevation as categories")
# Elevation as a gradient: fitted arrow and contours of a trend surface
p2 <- autoplot(frog_pca, surface = elevation, species = 0) +
  ggplot2::labs(title = "Elevation as a gradient")
plot_panel(p1, p2)
#> Ignoring unknown labels:
#> • colour : "elevation"
```

![Two PCA diagrams of frogs on Mt Wilhelm: elevation as classes, and as
a fitted vector with
contours](ordination_files/figure-html/geometry-1.png)

## Customising the plot

Every option is an argument, and the result is an ordinary ggplot:

- `axes = c(1, 3)` plots other axes.
- `species` sets how many species to show (the best represented); `0`
  hides them.
- `ellipse = "sd"`, `"ci"` (a `level` region for the points) or `"se"`
  (a `level` confidence region for the centroid); `hull = TRUE`;
  `spider = TRUE`.
- `site_labels = TRUE`, `arrows = FALSE`.
- `colour`, `shape` and `group` take site variables.

``` r

autoplot(rda, colour = year, shape = year, spider = TRUE, species = 0) +
  labs(title = "Butterfly communities at Wanang, by year") +
  theme(legend.position = "right")
```

![RDA of butterfly days with spiders joining each day to its year
centroid, a title and the legend at the
right.](ordination_files/figure-html/custom-1.png)

## Tidy scores for your own plots

``` r

tidy(rda, "sites")
#> # A tibble: 36 × 7
#>    site    axis1   axis2    axis3   day month year  
#>    <chr>   <dbl>   <dbl>    <dbl> <int> <int> <fct> 
#>  1 day01 -0.554  -0.0192 -0.548       1     1 Year 1
#>  2 day02 -0.585  -0.0395 -0.437       2     1 Year 1
#>  3 day03 -0.591  -0.0809 -0.531       3     1 Year 1
#>  4 day04 -0.423   0.167  -0.0389      4     2 Year 1
#>  5 day05 -0.337   0.0890 -0.00424     5     2 Year 1
#>  6 day06 -0.397   0.166   0.119       6     2 Year 1
#>  7 day07 -0.0705  0.466  -0.0135      7     3 Year 1
#>  8 day08 -0.139   0.396  -0.0547      8     3 Year 1
#>  9 day09 -0.150   0.361  -0.0338      9     3 Year 1
#> 10 day10  0.0778  0.443  -0.191      10     4 Year 1
#> # ℹ 26 more rows
tidy(rda, "axes")
#> # A tibble: 3 × 4
#>   axis  name  eigenvalue explained
#>   <chr> <chr>      <dbl>     <dbl>
#> 1 axis1 RDA1     0.0290     0.131 
#> 2 axis2 RDA2     0.0141     0.0637
#> 3 axis3 RDA3     0.00903    0.0409
glance(rda)
#> # A tibble: 1 × 8
#>   method n_sites n_species transform distance scaling stress constrained
#>   <chr>    <int>     <int> <chr>     <lgl>    <chr>    <dbl>       <dbl>
#> 1 rda         36       189 hellinger NA       species     NA       0.236
```

## How to report it

> Butterfly composition was related to year and month by redundancy
> analysis (RDA) of Hellinger-transformed counts (Legendre and Gallagher
> 2001), with tidydiversity and vegan. Year and month together explained
> 23.6% of the variation (permutation test, 999 permutations, *P* =
> 0.001); both terms were significant (Table S1). An NMDS with passively
> fitted variables showed the same pattern (Figure 2).

Report the method and transformation, the explained fraction, the test
and number of permutations, and give the table of terms as a supplement.

## References

Bertin, J. (1967). *Semiologie graphique*. Gauthier-Villars, Paris.
English translation (1983): *Semiology of Graphics*. University of
Wisconsin Press.

Legendre, P. and Gallagher, E. D. (2001). Ecologically meaningful
transformations for ordination of species data. *Oecologia*, 129,
271-280. <https://doi.org/10.1007/s004420100716>

ter Braak, C. J. F. and Smilauer, P. (2012). *Canoco reference manual
and user’s guide: software for ordination (version 5.0)*. Microcomputer
Power, Ithaca, USA.

Oksanen, J. et al. vegan: Community Ecology Package.
<https://CRAN.R-project.org/package=vegan>
