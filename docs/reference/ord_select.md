# Forward selection of explanatory variables

Selects site variables for RDA (or CCA, db-RDA) by forward selection
with the double stopping criterion of Blanchet et al. (2008): a variable
enters only if it is significant *and* the adjusted \\R^2\\ of the model
stays below that of the full model. Uses
[`vegan::ordiR2step()`](https://rdrr.io/pkg/vegan/man/ordistep.html).

## Usage

``` r
ord_select(
  data,
  site = site,
  species = species,
  abundance = NULL,
  formula,
  env = NULL,
  method = c("rda", "cca", "dbrda"),
  transform = NULL,
  distance = "bray",
  alpha = 0.05,
  permutations = 999
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

- formula:

  One-sided formula of all candidate site variables.

- env:

  A data frame of site variables with a column named like the site
  column. By default, site variables are taken from `data`: every column
  that is constant within each site.

- method:

  `"rda"`, `"cca"` or `"dbrda"`.

- transform:

  Transformation of the community matrix before the analysis:
  `"hellinger"` (the default for PCA and RDA, which otherwise overweight
  abundant species; Legendre and Gallagher 2001), `"chord"`, `"log"`
  (log(x) + 1 for x \> 0), `"sqrt"`, `"pa"` (presence-absence) or
  `"none"` (the default for the other methods).

- distance:

  Dissimilarity for `"pcoa"`, `"nmds"` and `"dbrda"`, passed to
  [`vegan::vegdist()`](https://rdrr.io/pkg/vegan/man/vegdist.html), such
  as `"bray"` (the default) or `"jaccard"`.

- alpha:

  Significance level for entry.

- permutations:

  Number of permutations for the tests of passive variables.

## Value

A tibble with one row per selected step: `step`, `term`, `adj_r2`
(cumulative), `statistic` and `p.value`, and the adjusted \\R^2\\ of the
full model as attribute `"adj_r2_full"`.

## References

Blanchet, F. G., Legendre, P. and Borcard, D. (2008). Forward selection
of explanatory variables. *Ecology*, 89, 2623-2632.
[doi:10.1890/07-0986.1](https://doi.org/10.1890/07-0986.1)

## Examples

``` r
ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
set.seed(1)
ord_select(ants, site = unit, formula = ~ elevation + season,
           permutations = 199)
#> # A tibble: 1 × 5
#>    step term      adj_r2 statistic p.value
#>   <int> <chr>      <dbl>     <dbl>   <dbl>
#> 1     1 elevation  0.101      3.13   0.005
```
