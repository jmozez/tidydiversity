# Range shifts between two surveys of the same gradient

`range_shift_resurvey()` compares species' ranges in a historical survey
and a resurvey of the same gradient (for example the same elevational
transect decades apart; Moritz et al. 2008; Freeman and Freeman 2014).
For each species found in both surveys it gives the shift of the lower
edge, the upper edge, the midpoint and the abundance-weighted optimum,
and the change in breadth; species found in only one survey are listed
as `"lost"` or `"new"`.

`range_shift_test()` asks whether species shifted on average. Species
share a gradient and survey design, but their shifts are treated as the
units of replication, as in published resurveys: it gives the mean shift
of each measure, a bootstrap confidence interval resampling species, and
an exact two-sided sign test of whether more species moved up than down.
Shifts of edges at the end of the sampled gradient are unreliable, so by
default edges flagged as truncated in either survey are left out of the
test of that edge.

## Usage

``` r
range_shift_resurvey(
  before,
  after,
  gradient,
  site = site,
  species = species,
  abundance = NULL
)

range_shift_test(
  x,
  nboot = 999,
  conf = 0.95,
  drop_truncated = TRUE,
  seed = NULL
)
```

## Arguments

- before, after:

  Long-format data of the two surveys, with the same columns.

- gradient:

  Column giving the position of each site on the gradient, such as
  elevation in metres.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- x:

  Result of `range_shift_resurvey()`.

- nboot:

  Number of bootstrap resamples of species.

- conf:

  Confidence level.

- drop_truncated:

  Leave out edges truncated at the ends of the sampled gradient?

- seed:

  Optional random seed.

## Value

`range_shift_resurvey()`: a tibble with one row per species: `species`,
`status` (`"both"`, `"lost"`, `"new"`), the edges in both surveys
(`lower_before`, `lower_after`, ...), the shifts (`shift_lower`,
`shift_upper`, `shift_midpoint`, `shift_optimum`, `change_breadth`) and
`truncated` (an edge truncated in either survey).

`range_shift_test()`: a tibble with one row per measure: `measure`, `n`
(species), `mean`, `lower`, `upper` (bootstrap interval), `n_up`,
`n_down`, `p_sign` (exact sign test).

## References

Freeman, B. G. and Class Freeman, A. M. (2014). Rapid upslope shifts in
New Guinean birds illustrate strong distributional responses of tropical
montane species to global warming. PNAS, 111, 4490-4494.

Moritz, C. et al. (2008). Impact of a century of climate change on
small-mammal communities in Yosemite National Park, USA. Science, 322,
261-264.

## Examples

``` r
# Two virtual surveys: every species moves 100 m upslope
before <- png_frogs
after <- png_frogs
after$elevation <- after$elevation + 100
shifts <- range_shift_resurvey(before, after,
  gradient = elevation, abundance = abundance
)
range_shift_test(shifts, nboot = 199, seed = 1)
#> # A tibble: 4 × 8
#>   measure      n  mean lower upper  n_up n_down   p_sign
#>   <chr>    <int> <dbl> <dbl> <dbl> <int>  <int>    <dbl>
#> 1 lower       42   100   100   100    42      0 4.55e-13
#> 2 upper       53   100   100   100    53      0 2.22e-16
#> 3 midpoint    55   100   100   100    55      0 5.55e-17
#> 4 optimum     55   100   100   100    55      0 5.55e-17
```
