# Evenness profiles

Computes the five classes of Hill-number evenness of Chao and Ricotta
(2019) for each site, either from the observed sample or from diversity
standardised to a common sample coverage, as in iNEXT.4steps.

## Usage

``` r
div_evenness(
  data,
  site = site,
  species = species,
  abundance = NULL,
  q = seq(0, 2, 0.2),
  class = c("E1", "E2", "E3", "E4", "E5"),
  method = c("estimated", "observed"),
  coverage = NULL,
  conf = 0.95,
  nboot = 50,
  .by = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- q:

  Orders of completeness, non-negative numbers. Defaults to a profile
  from 0 to 2.

- class:

  Evenness classes to return, any of `"E1"` to `"E5"`.

- method:

  `"estimated"` (the default) uses diversity standardised to `coverage`;
  `"observed"` uses the observed sample.

- coverage:

  Target coverage for `method = "estimated"`. Defaults to the lowest
  coverage that every site in a group reaches at twice its sample size.

- conf:

  Confidence level of the intervals.

- nboot:

  Number of bootstrap replicates. Use 0 to skip them.

- .by:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Optional grouping columns, kept in the output. Grouped data frames are
  also respected.

## Value

A `td_evenness` tibble with the grouping columns, the site column,
`class`, `q`, `evenness`, `se`, `lower` and `upper`, and `coverage` for
the estimated method.

## References

Chao, A. and Ricotta, C. (2019). Quantifying evenness and linking it to
diversity, beta diversity, and similarity. Ecology, 100, e02852.
[doi:10.1002/ecy.2852](https://doi.org/10.1002/ecy.2852)

Chao, A. et al. (2020). Quantifying sample completeness and comparing
diversities among assemblages. Ecological Research, 35, 292-314.
[doi:10.1111/1440-1703.12102](https://doi.org/10.1111/1440-1703.12102)

## Examples

``` r
div_evenness(png_ants, q = c(0, 1, 2), .by = season, nboot = 0)
#> # A tibble: 150 x 9
#>    season site   class     q evenness    se lower upper coverage
#>    <chr>  <chr>  <chr> <dbl>    <dbl> <dbl> <dbl> <dbl>    <dbl>
#>  1 dry    MW0200 E1        0    1        NA    NA    NA    0.565
#>  2 dry    MW0200 E1        1    0.945    NA    NA    NA    0.565
#>  3 dry    MW0200 E1        2    0.960    NA    NA    NA    0.565
#>  4 dry    MW0200 E2        0    1        NA    NA    NA    0.565
#>  5 dry    MW0200 E2        1    0.945    NA    NA    NA    0.565
#>  6 dry    MW0200 E2        2    0.752    NA    NA    NA    0.565
#>  7 dry    MW0200 E3        0    1        NA    NA    NA    0.565
#>  8 dry    MW0200 E3        1    0.876    NA    NA    NA    0.565
#>  9 dry    MW0200 E3        2    0.752    NA    NA    NA    0.565
#> 10 dry    MW0200 E4        0    1        NA    NA    NA    0.565
#> # i 140 more rows
```
