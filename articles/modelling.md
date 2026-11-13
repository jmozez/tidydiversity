# Modelling diversity against covariates

Diversity estimates are often the response in a model of environmental
drivers. Two things matter: the estimates should be comparable (equal
coverage or asymptotic), and their uncertainty should carry through to
the model. tidydiversity results are tidy tibbles, so this takes a few
lines.

## The concept

A diversity estimate is not a measurement like temperature: it is itself
an estimate, with a standard error that depends on how well the site was
sampled. Two consequences follow when diversity becomes the response in
a regression:

1.  **Compare like with like.** Observed richness grows with sampling
    effort, so a model of raw counts partly models effort. Use estimates
    standardised to equal coverage
    ([`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md))
    or asymptotic estimates (Chapter 3 of the [user
    guide](https://tidydiversity.in4metrix.dev/articles/guide-03-fair-comparisons.md)).
2.  **Carry the uncertainty.** A site with a wide confidence interval
    should influence the fit less than a precisely estimated one. Either
    weight each estimate by the inverse of its variance, or refit the
    model to many bootstrap replicates of the estimates and look at the
    spread of the coefficients.

With few sites, as here (5 elevations x 2 seasons = 10 estimates), keep
models simple: every extra term costs a degree of freedom you cannot
spare.

``` r

library(tidydiversity)
library(dplyr)
library(ggplot2)
set.seed(2026)
sites <- distinct(png_ants, site, elevation)
```

## Model-ready estimates

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) renames
columns to the broom conventions and adds an inverse-variance `weight`;
[`add_site_data()`](https://tidydiversity.in4metrix.dev/reference/tidy-tidydiversity.md)
joins covariates that are constant within each site.

``` r

est <- div_standardise(png_ants,
  q = c(0, 1, 2), .by = season,
  nboot = 200
) |>
  tidy() |>
  add_site_data(sites)
est
#> # A tibble: 30 × 13
#>    season site       q     m method  target coverage estimate std.error conf.low
#>    <chr>  <chr>  <dbl> <dbl> <chr>    <dbl>    <dbl>    <dbl>     <dbl>    <dbl>
#>  1 dry    MW0200     0 11.6  rarefa…  0.565    0.565     7.96     0.489     7.00
#>  2 dry    MW0200     1 11.6  rarefa…  0.565    0.565     7.10     0.549     6.02
#>  3 dry    MW0200     2 11.6  rarefa…  0.565    0.565     6.24     0.563     5.13
#>  4 dry    MW0700     0 46.0  extrap…  0.565    0.565    26.0      4.48     17.2 
#>  5 dry    MW0700     1 46.0  extrap…  0.565    0.565    17.9      4.86      8.33
#>  6 dry    MW0700     2 46.0  extrap…  0.565    0.565    10.5      4.48      1.72
#>  7 dry    MW1200     0 11.0  rarefa…  0.565    0.565     7.17     0.720     5.76
#>  8 dry    MW1200     1 11.0  rarefa…  0.565    0.565     6.09     0.874     4.38
#>  9 dry    MW1200     2 11.0  rarefa…  0.565    0.565     5.04     0.939     3.20
#> 10 dry    MW1700     0  3.07 rarefa…  0.565    0.565     2.32     0.196     1.94
#> # ℹ 20 more rows
#> # ℹ 3 more variables: conf.high <dbl>, weight <dbl>, elevation <int>
```

**How to read it.** One row per site, season and order `q`. `estimate`
is the standardised diversity in effective numbers of species,
`conf.low` and `conf.high` its 95% interval, `method` whether the site
was interpolated (`rarefaction`) or extrapolated to reach the common
coverage `coverage`, and `weight` = 1 / standard error². Extrapolated
estimates have wider intervals and therefore smaller weights.

## Approaches

- Weighted lm
- Mixed model
- GAM
- Count model for richness

Inverse-variance weights give less influence to imprecise estimates.

``` r

# A site with one species has a zero standard error and no weight
shannon <- filter(est, q == 1, !is.na(weight))
fit_lm <- lm(estimate ~ elevation + I(elevation^2) + season,
  data = shannon, weights = weight
)
broom::tidy(fit_lm, conf.int = TRUE)
#> # A tibble: 4 × 7
#>   term              estimate  std.error statistic p.value    conf.low  conf.high
#>   <chr>                <dbl>      <dbl>     <dbl>   <dbl>       <dbl>      <dbl>
#> 1 (Intercept)     8.58       2.15           4.00  0.00713  3.33          1.38e+1
#> 2 elevation      -0.00556    0.00370       -1.50  0.183   -0.0146        3.49e-3
#> 3 I(elevation^2)  0.00000118 0.00000153     0.771 0.470   -0.00000256    4.91e-6
#> 4 seasonwet       2.36       1.66           1.42  0.207   -1.72          6.43e+0
```

**Interpretation.** No term is significant: with 10 estimates and four
parameters, the quadratic model has too little information to separate
the linear and curved parts of the elevation effect, and their
confidence intervals are wide. This is a typical small-sample result,
not evidence of no effect: the simpler models below detect the decline.

Each elevation band was sampled in both seasons, so sites are repeated.
Add a random effect for site with **lme4** (or **glmmTMB**, which takes
the same formula).

``` r

fit_mm <- lme4::lmer(estimate ~ elevation + season + (1 | site),
  data = shannon, weights = weight / mean(weight)
)
summary(fit_mm)$coefficients
#>                Estimate  Std. Error   t value
#> (Intercept)  8.33673288 1.902635111  4.381677
#> elevation   -0.00289298 0.001164097 -2.485171
#> seasonwet    2.08097724 1.339036276  1.554086
```

**Interpretation.** Accounting for the pairing of seasons within sites,
Shannon diversity declines with elevation (t = -2.4): about 0.29
effective species per 100 m. lme4 gives no p-values by design; use the
confidence interval (`confint(fit_mm)`) or the **lmerTest** package.

**mgcv** fits a smooth response along the gradient.

``` r

fit_gam <- mgcv::gam(estimate ~ s(elevation, k = 4) + season,
  data = shannon, weights = weight / mean(weight), method = "REML"
)
summary(fit_gam)$s.table
#>                   edf   Ref.df        F   p-value
#> s(elevation) 1.000083 1.000166 9.140877 0.0192844
# edf near 1 means the smooth is a straight line
grid <- tidyr::expand_grid(
  elevation = seq(200, 2200, by = 20),
  season = c("wet", "dry")
)
pred <- predict(fit_gam, grid, se.fit = TRUE)
grid$fit <- pred$fit
grid$se <- pred$se.fit
ggplot(grid, aes(elevation, fit, colour = season, fill = season)) +
  geom_ribbon(aes(ymin = fit - 1.96 * se, ymax = fit + 1.96 * se),
    alpha = 0.2, colour = NA
  ) +
  geom_line() +
  geom_pointrange(aes(y = estimate, ymin = conf.low, ymax = conf.high),
    data = shannon
  ) +
  scale_colour_tidydiversity() +
  scale_fill_tidydiversity() +
  labs(
    x = "Elevation (m)",
    y = "Shannon diversity (effective number of species)",
    colour = NULL, fill = NULL
  ) +
  theme_tidydiversity()
```

![GAM smooth of Shannon diversity along
elevation](modelling_files/figure-html/gam-1.png)

**Interpretation.** The effective degrees of freedom of the smooth (edf
= 1.0) say the GAM chose a straight line: there is no evidence of a
mid-elevation peak, a pattern often reported for ants. The decline is
significant (*P* = 0.02). The points with error bars are the estimates
themselves; the wide bars of the extrapolated sites show why weighting
matters.

Observed richness is a count, but it depends on sampling effort. Model
standardised richness with a Gamma GLM (positive, continuous), or
observed richness with a Poisson GLM and log sample size as an offset.

``` r

rich <- filter(est, q == 0, !is.na(weight))
broom::tidy(glm(estimate ~ elevation + season,
  data = rich,
  family = Gamma(link = "log"), weights = weight / mean(weight)
))
#> # A tibble: 3 × 5
#>   term         estimate std.error statistic p.value
#>   <chr>           <dbl>     <dbl>     <dbl>   <dbl>
#> 1 (Intercept)  2.11      0.430         4.91 0.00174
#> 2 elevation   -0.000597  0.000253     -2.36 0.0504 
#> 3 seasonwet    0.809     0.487         1.66 0.140
obs <- div_hill(png_ants, q = 0, .by = season) |> add_site_data(sites)
broom::tidy(glm(diversity ~ elevation + season + offset(log(n)),
  data = obs, family = poisson
))
#> # A tibble: 3 × 5
#>   term          estimate std.error statistic    p.value
#>   <chr>            <dbl>     <dbl>     <dbl>      <dbl>
#> 1 (Intercept) -0.874      0.181       -4.81  0.00000148
#> 2 elevation    0.0000230  0.000131     0.175 0.861     
#> 3 seasonwet   -0.197      0.173       -1.14  0.256
```

**Interpretation.** Coefficients of a log-link model are on the log
scale: the Gamma GLM slope of -6^{-4} per metre means standardised
richness falls by about 6% per 100 m (exp(100 x slope)), close to
significance (*P* = 0.054). The Poisson model with an effort offset
finds no trend: observed richness per record does not change with
elevation, a reminder that the two models answer different questions.

## Propagating uncertainty with bootstrap draws

Weights use only the standard error.
[`div_boot()`](https://tidydiversity.in4metrix.dev/reference/div_boot.md)
returns the bootstrap replicates themselves, so the whole model can be
refitted to each replicate and the spread of the coefficients includes
the estimation uncertainty in the response.

``` r

draws <- div_boot(png_ants,
  q = 1, type = "standardised", .by = season,
  coverage = 0.9, nboot = 200
) |>
  add_site_data(sites)
draws
#> # A tibble: 2,000 × 7
#>    season site       q     m .draw diversity elevation
#>    <chr>  <chr>  <dbl> <dbl> <int>     <dbl>     <int>
#>  1 dry    MW0200     1  47.5     1     12.4        200
#>  2 dry    MW0200     1  47.5     2      9.23       200
#>  3 dry    MW0200     1  47.5     3     10.8        200
#>  4 dry    MW0200     1  47.5     4     10.5        200
#>  5 dry    MW0200     1  47.5     5     10.9        200
#>  6 dry    MW0200     1  47.5     6     12.1        200
#>  7 dry    MW0200     1  47.5     7      9.03       200
#>  8 dry    MW0200     1  47.5     8     12.2        200
#>  9 dry    MW0200     1  47.5     9     11.8        200
#> 10 dry    MW0200     1  47.5    10     12.5        200
#> # ℹ 1,990 more rows

slopes <- draws |>
  group_by(.draw) |>
  group_modify(\(d, key) {
    broom::tidy(lm(diversity ~ elevation + season, data = d))
  }) |>
  ungroup() |>
  filter(term == "elevation")
quantile(slopes$estimate, c(0.025, 0.5, 0.975))
#>         2.5%          50%        97.5% 
#> -0.011822337 -0.007632935 -0.005015648
```

**How to read it.** Each of the 200 bootstrap replicates gives one
slope; their 2.5% and 97.5% quantiles form a 95% interval that includes
the uncertainty of the diversity estimates as well as the residual
scatter. Shannon diversity at 90% coverage falls by 0.76 effective
species per 100 m (95% interval 0.5 to 1.18), and the interval excludes
zero.

``` r

ggplot(slopes, aes(estimate * 100)) +
  geom_histogram(bins = 30, fill = plot_palette(1)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(x = "Change in Shannon diversity per 100 m", y = "Bootstrap draws") +
  theme_tidydiversity()
```

![Bootstrap distribution of the elevation
slope](modelling_files/figure-html/boot-plot-1.png)

## Beta diversity

### Distance decay

[`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md)
gives one row per pair of sites with the distance along one or more
gradients. Several columns give Euclidean distance.

``` r

decay <- beta_decay(png_ants, elevation, .by = season)
broom::tidy(lm(turnover ~ distance + season, data = decay))
#> # A tibble: 3 × 5
#>   term         estimate std.error statistic      p.value
#>   <chr>           <dbl>     <dbl>     <dbl>        <dbl>
#> 1 (Intercept)  0.664    0.0723        9.18  0.0000000531
#> 2 distance     0.000168 0.0000590     2.85  0.0110      
#> 3 seasonwet   -0.0149   0.0590       -0.252 0.804
```

**How to read it.** Turnover (species replacement) between two sites
increases by about 0.017 per 100 m of elevation difference: communities
further apart on the mountain share fewer species. The p-values of this
lm are too small, because each site appears in several pairs.

Pairs are not independent, so test the relationship with a Mantel test
rather than the lm p-values.

``` r

wet <- filter(png_ants, season == "wet")
d_beta <- beta_dist(beta_pair(wet), "turnover")
d_elev <- dist(distinct(wet, site, elevation)$elevation)
vegan::mantel(d_beta, d_elev, permutations = 999)
#> 'nperm' >= set of all permutations: complete enumeration.
#> Set of permutations < 'minperm'. Generating entire set.
#> 
#> Mantel statistic based on Pearson's product-moment correlation 
#> 
#> Call:
#> vegan::mantel(xdis = d_beta, ydis = d_elev, permutations = 999) 
#> 
#> Mantel statistic r: 0.8064 
#>       Significance: 0.016667 
#> 
#> Upper quantiles of permutations (null model):
#>   90%   95% 97.5%   99% 
#> 0.443 0.515 0.522 0.655 
#> Permutation: free
#> Number of permutations: 119
```

**Interpretation.** The Mantel correlation between turnover and
elevation difference is strong (r = 0.81). With five sites there are
only 5! = 120 distinct permutations, so the smallest possible p-value is
1/120 ≈ 0.008; *P* = 0.017 is close to that floor. Few sites limit the
power of any test of beta diversity, however strong the pattern.

### PERMANOVA and ordination

``` r

# One sampling unit per elevation band and season
units <- mutate(png_ants, unit = paste(site, season))
bray <- beta_dist(beta_pair(units, site = unit, index = "bray"))
unit_data <- distinct(units, unit, site, season, elevation)
unit_data <- unit_data[match(labels(bray), unit_data$unit), ]
vegan::adonis2(bray ~ elevation + season,
  data = unit_data,
  permutations = 999
)
#> Permutation test for adonis under reduced model
#> Permutation: free
#> Number of permutations: 999
#> 
#> vegan::adonis2(formula = bray ~ elevation + season, data = unit_data, permutations = 999)
#>          Df SumOfSqs      R2      F Pr(>F)  
#> Model     2   1.1156 0.30648 1.5467  0.067 .
#> Residual  7   2.5244 0.69352                
#> Total     9   3.6400 1.00000                
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

**Interpretation.** Elevation explains 23% of the variation in
composition between the ten site-season units (*P* = 0.008); season,
added after elevation, explains 7% and is not significant. The
[composition
tests](https://tidydiversity.in4metrix.dev/articles/composition-tests.md)
article shows how restricting permutations within sites reveals the
season effect.

``` r

nmds <- vegan::metaMDS(bray, trace = FALSE)
bind_cols(unit_data, as.data.frame(vegan::scores(nmds))) |>
  mutate(elevation = factor(elevation)) |>
  ggplot(aes(NMDS1, NMDS2, colour = elevation, shape = season)) +
  geom_point(size = 3) +
  scale_colour_tidydiversity() +
  coord_equal() +
  labs(colour = "Elevation (m)", shape = NULL) +
  theme_tidydiversity(legend_position = "right")
```

![NMDS ordination of sites coloured by
elevation](modelling_files/figure-html/nmds-1.png)

**Interpretation.** Sites are ordered by elevation along the first NMDS
axis, and the dry- and wet-season samples of each site lie close
together: elevation, not season, structures the ant communities.

## How to report it

> Shannon diversity (Hill number of order 1) was standardised to 90%
> sample coverage with tidydiversity (Chao et al. 2014). To propagate
> estimation uncertainty, a linear model of diversity against elevation
> and season was refitted to each of 200 bootstrap replicates of the
> estimates. Diversity declined by 0.76 effective species per 100 m (95%
> bootstrap interval 0.5-1.18). Compositional turnover was correlated
> with elevation difference (Mantel r = 0.81, *P* = 0.017).

## References

Chao, A. et al. (2014). Rarefaction and extrapolation with Hill numbers:
a framework for sampling and estimation in species diversity studies.
*Ecological Monographs*, 84, 45-67.
