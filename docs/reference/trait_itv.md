# Intra- and interspecific trait variability

Decomposes variation in community trait means into the part caused by
species turnover (interspecific) and the part caused by trait change
within species (intraspecific), following Leps et al. (2011). It
compares the *specific* average (CWM from site-specific species means)
with the *fixed* average (CWM from species means over all sites).

## Usage

``` r
trait_itv(
  data,
  traits,
  site = site,
  species = species,
  abundance = NULL,
  cols,
  formula = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- traits:

  A data frame of trait values measured per site: columns for site,
  species and the trait(s). Several rows per site and species
  (individuals) are averaged.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- cols:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  Trait columns of `traits`.

- formula:

  Optional one-sided formula of site variables. If given, the sums of
  squares are those explained by the formula; otherwise the total sums
  of squares are decomposed.

## Value

A tibble with one row per trait and component (`"turnover"`,
`"intraspecific"`, `"covariation"`, `"total"`), the sum of squares `ss`
and its share `prop` of the total.

## References

Leps, J. et al. (2011). Community trait response to environment:
disentangling species turnover vs intraspecific trait variability
effects. *Ecography*, 34, 856-863.
[doi:10.1111/j.1600-0587.2010.06904.x](https://doi.org/10.1111/j.1600-0587.2010.06904.x)
