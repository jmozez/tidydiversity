# Variation partitioning

Partitions the variation in community composition among two to four
groups of explanatory variables with adjusted \\R^2\\ (Borcard et al.
1992; Peres-Neto et al. 2006), using
[`vegan::varpart()`](https://rdrr.io/pkg/vegan/man/varpart.html).
Fractions that are testable (the unique fraction of each group) are
tested by permutation with partial RDA.

## Usage

``` r
ord_varpart(
  data,
  ...,
  site = site,
  species = species,
  abundance = NULL,
  env = NULL,
  transform = "hellinger",
  permutations = 999
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- ...:

  Two to four one-sided formulas of site variables, named by group, e.g.
  `climate = ~ elevation, time = ~ season`.

- site, species:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://rdrr.io/pkg/dplyr/man/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- transform:

  Transformation before RDA; Hellinger by default.

- permutations:

  Number of permutations for the tests of passive variables.

## Value

A tibble of fractions with columns `fraction`, `label` (e.g.
`"[a] climate only"`), `adj_r2`, `testable` and `p.value`.

## References

Borcard, D., Legendre, P. and Drapeau, P. (1992). Partialling out the
spatial component of ecological variation. *Ecology*, 73, 1045-1055.
[doi:10.2307/1940179](https://doi.org/10.2307/1940179)

Peres-Neto, P. R. et al. (2006). Variation partitioning of species data
matrices: estimation and comparison of fractions. *Ecology*, 87,
2614-2625.
[doi:10.1890/0012-9658(2006)87\[2614:VPOSDM\]2.0.CO;2](https://doi.org/10.1890/0012-9658%282006%2987%5B2614%3AVPOSDM%5D2.0.CO%3B2)

## Examples

``` r
ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
set.seed(1)
ord_varpart(ants, site = unit,
            elevation = ~elevation, season = ~season,
            permutations = 199)
#> # A tibble: 4 x 5
#>   fraction        label                       adj_r2 testable p.value
#>   <chr>           <chr>                        <dbl> <lgl>      <dbl>
#> 1 [a] = X1|X2     elevation only             0.107   TRUE       0.005
#> 2 [b] = X2|X1     season only                0.0127  TRUE       0.175
#> 3 [c]             shared elevation & season -0.00631 FALSE     NA    
#> 4 [d] = Residuals residual                   0.886   FALSE     NA    
```
