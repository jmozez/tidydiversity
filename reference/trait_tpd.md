# Functional diversity from trait probability densities

The trait probability density (TPD) approach (Carmona et al. 2016, 2019)
describes each species by the probability density of its trait values,
estimated from individual measurements, so intraspecific variability is
part of every index. Community TPDs are the abundance-weighted sums of
species TPDs. From them, `trait_tpd()` returns functional richness,
evenness and divergence
([`TPD::REND()`](https://rdrr.io/pkg/TPD/man/REND.html)) and functional
redundancy
([`TPD::redundancy()`](https://rdrr.io/pkg/TPD/man/redundancy.html)) per
site, and `trait_tpd_dissim()` returns pairwise functional dissimilarity
between sites, split into shared and non-shared parts
([`TPD::dissim()`](https://rdrr.io/pkg/TPD/man/dissim.html)).

## Usage

``` r
trait_tpd(
  data,
  traits,
  site = site,
  species = species,
  abundance = NULL,
  cols,
  alpha = 0.95,
  n_divisions = NULL
)

trait_tpd_dissim(
  data,
  traits,
  site = site,
  species = species,
  abundance = NULL,
  cols,
  alpha = 0.95,
  n_divisions = NULL
)
```

## Arguments

- data:

  A data frame in long format, with one row per record.

- traits:

  A data frame with one row per measured individual: a species column
  (named as in `data`) and one to four numeric trait columns. Traits are
  often log-transformed first.

- site, species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding site identifiers and the column holding species
  names.

- abundance:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The column holding counts. If `NULL` (the default), a column called
  `abundance` is used when present, otherwise every row counts as one
  individual.

- cols:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The trait columns (one to four).

- alpha:

  Proportion of the probability density kept for each species (removes
  outliers).

- n_divisions:

  Number of grid divisions per trait axis; defaults to those of
  [`TPD::TPDs()`](https://rdrr.io/pkg/TPD/man/TPDs.html).

## Value

`trait_tpd()`: a tibble with the site column, `FRic`, `FEve`, `FDiv` and
`redundancy`. `trait_tpd_dissim()`: a tibble of site pairs with
`dissimilarity`, its parts due to shared (`p_shared`) and non-shared
(`p_nonshared`) trait space.

## References

Carmona, C. P. et al. (2016). Traits without borders: integrating
functional diversity across scales. *Trends in Ecology & Evolution*, 31,
382-394.
[doi:10.1016/j.tree.2016.02.003](https://doi.org/10.1016/j.tree.2016.02.003)

Carmona, C. P. et al. (2019). Trait probability density (TPD): measuring
functional diversity across scales based on TPD with R. *Ecology*, 100,
e02876. [doi:10.1002/ecy.2876](https://doi.org/10.1002/ecy.2876)
