# Validate projected range shifts against resurveys (hindcasting)

A range-shift model earns trust when it predicts shifts that have
already happened. `range_shift_validate()` compares the shifts observed
between a historical survey and a resurvey
([`range_shift_resurvey()`](https://tidydiversity.in4metrix.dev/reference/range_shift_resurvey.md))
with the shifts a model predicted for the same species and period, run
from the climate of the first survey to that of the second
(hindcasting).

For each measure (lower edge, upper edge, midpoint, optimum) it reports:

- `bias`: mean of predicted minus observed shift (m);

- `mae`, `rmse`: mean absolute and root mean square error (m);

- `r`, `rho`: Pearson and Spearman correlation across species;

- `slope`: calibration slope of observed on predicted (1 is ideal; below
  1, the model overstates differences between species);

- `direction`: share of species whose shift has the predicted sign;

- `tracking`: mean observed shift divided by mean predicted shift, the
  share of the expected shift that species realised (1 = full tracking;
  below 1, a lag), with a bootstrap interval resampling species.

`range_shift_expected()` gives the simplest prediction, the isotherm
shift \\\Delta T / \gamma\\ for warming \\\Delta T\\ and lapse rate
\\\gamma\\ (Colwell et al. 2008; Freeman and Freeman 2014). It is the
baseline any model must beat.

## Usage

``` r
range_shift_validate(
  observed,
  predicted,
  drop_truncated = TRUE,
  nboot = 999,
  conf = 0.95,
  seed = NULL
)

range_shift_expected(warming, lapse_rate)
```

## Arguments

- observed:

  Result of
  [`range_shift_resurvey()`](https://tidydiversity.in4metrix.dev/reference/range_shift_resurvey.md),
  or a data frame with `species` and observed `shift_*` columns.

- predicted:

  Data frame with `species` and predicted shifts, in columns named like
  those of `observed` (`shift_lower`, `shift_upper`, `shift_midpoint`,
  `shift_optimum`), or a single column `shift` used for every measure.

- drop_truncated:

  Leave out edges truncated at the ends of the sampled gradient (needs
  the `truncated_*` columns of `observed`).

- nboot:

  Bootstrap resamples for the tracking interval.

- conf:

  Confidence level.

- seed:

  Optional random seed.

- warming:

  Warming in degrees C between the surveys (or scenarios).

- lapse_rate:

  Temperature lapse rate in degrees C per km.

## Value

`range_shift_validate()`: a tibble with one row per measure.

`range_shift_expected()`: the expected upslope shift in metres.

## References

Colwell, R. K., Brehm, G., Cardelús, C. L., Gilman, A. C. and Longino,
J. T. (2008). Global warming, elevational range shifts, and lowland
biotic attrition in the wet tropics. Science, 322, 258-261.

Freeman, B. G. and Class Freeman, A. M. (2014). Rapid upslope shifts in
New Guinean birds illustrate strong distributional responses of tropical
montane species to global warming. PNAS, 111, 4490-4494.

## Examples

``` r
# Virtual resurvey: species realise 60% of a 200 m expected shift
before <- png_frogs
after <- png_frogs
after$elevation <- after$elevation + 120
obs <- range_shift_resurvey(before, after, gradient = elevation, abundance = abundance)
pred <- data.frame(species = obs$species, shift = range_shift_expected(1, 5))
range_shift_validate(obs, pred, nboot = 199, seed = 1)
#> # A tibble: 4 × 14
#>   measure     n observed predicted  bias   mae  rmse     r   rho slope direction
#>   <chr>   <int>    <dbl>     <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>     <dbl>
#> 1 lower      42      120       200    80    80    80    NA    NA    NA         1
#> 2 upper      53      120       200    80    80    80    NA    NA    NA         1
#> 3 midpoi…    55      120       200    80    80    80    NA    NA    NA         1
#> 4 optimum    55      120       200    80    80    80    NA    NA    NA         1
#> # ℹ 3 more variables: tracking <dbl>, tracking_lower <dbl>,
#> #   tracking_upper <dbl>
```
