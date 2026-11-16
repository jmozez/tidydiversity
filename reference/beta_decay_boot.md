# Bootstrap confidence interval for a distance-decay slope

`beta_decay_boot()` estimates the slope of dissimilarity against
distance (from
[`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md))
and its bootstrap confidence interval. Because pairs of sites share
sites and are not independent, sites, not pairs, are resampled: each
replicate draws the sites with replacement and refits the slope on every
pair of distinct drawn sites. Compare the slopes of two transects (or
taxa) by whether their intervals overlap, or by the interval of their
difference (`compare`).

## Usage

``` r
beta_decay_boot(
  decay,
  component = c("total", "turnover", "nestedness"),
  nboot = 999,
  conf = 0.95,
  group = NULL,
  per = 1,
  seed = NULL
)
```

## Arguments

- decay:

  A
  [`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md)
  result.

- component:

  Dissimilarity column: `"total"` (default), `"turnover"` or
  `"nestedness"`.

- nboot:

  Number of bootstrap replicates.

- conf:

  Confidence level.

- group:

  Optional column of `decay` identifying transects or taxa; slopes are
  estimated within each, and with exactly two groups their difference is
  added.

- per:

  Scale the slope to dissimilarity per `per` distance units (for example
  1000 for per km when distance is in metres).

- seed:

  Optional random seed.

## Value

A tibble with `group` (if given), `slope`, `lower`, `upper`, `n_sites`
and `nboot`; with two groups an extra row `difference`.

## Examples

``` r
d <- beta_decay(png_frogs, elevation)
beta_decay_boot(d, nboot = 200, per = 1000, seed = 1)
#> # A tibble: 1 × 5
#>   slope  lower upper n_sites nboot
#>   <dbl>  <dbl> <dbl>   <int> <int>
#> 1 0.154 0.0724 0.468       8   200
```
