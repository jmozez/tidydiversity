# Trait dissimilarity between species

Computes functional dissimilarity between species from traits of any
type (numeric, ordinal, categorical, binary, with missing values).
`"gower"` uses Gower distance with Podani's extension
([`FD::gowdis()`](https://rdrr.io/pkg/FD/man/gowdis.html)); `"gawdis"`
uses [`gawdis::gawdis()`](https://rdrr.io/pkg/gawdis/man/gawdis.html),
which weights traits so that each contributes equally to the
dissimilarity, an improvement on Gower when trait types are mixed (de
Bello et al. 2021).

## Usage

``` r
trait_dist(
  traits,
  species = species,
  cols = tidyselect::everything(),
  method = c("gower", "gawdis"),
  groups = NULL,
  ...
)
```

## Arguments

- traits:

  A data frame of traits, one row per species.

- species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column of species names.

- cols:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Trait columns; all other columns by default.

- method:

  `"gower"` or `"gawdis"`.

- groups:

  For `"gawdis"`, an integer vector giving a group to each trait column,
  so that traits measuring the same thing (e.g. fuzzy-coded life forms)
  count as one.

- ...:

  Passed to
  [`gawdis::gawdis()`](https://rdrr.io/pkg/gawdis/man/gawdis.html).

## Value

A `dist` object labelled with species names, usable as `dist` in
[`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md)
and other FD functions.

## References

de Bello, F. et al. (2021). Towards a more balanced combination of
multiple traits when computing functional differences between species.
*Methods in Ecology and Evolution*, 12, 443-448.
[doi:10.1111/2041-210X.13537](https://doi.org/10.1111/2041-210X.13537)

## Examples

``` r
data(aravo, package = "ade4")
tr <- data.frame(species = rownames(aravo$traits), aravo$traits)
d <- trait_dist(tr)
as.matrix(d)[1:3, 1:3]
#>           Agro.rupe Alop.alpi Anth.nipp
#> Agro.rupe 0.0000000 0.1543923 0.1582251
#> Alop.alpi 0.1543923 0.0000000 0.1461747
#> Anth.nipp 0.1582251 0.1461747 0.0000000
```
