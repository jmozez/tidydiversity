# Phylogenetic signal of traits

Measures how strongly closely related species resemble each other in
each trait, with Blomberg's K (Blomberg et al. 2003) or Pagel's lambda
(Pagel 1999), using
[`phytools::phylosig()`](https://rdrr.io/pkg/phytools/man/phylosig.html).
K = 1 and lambda = 1 match Brownian-motion evolution; values near 0 mean
no phylogenetic signal.

## Usage

``` r
phylo_signal(
  traits,
  tree,
  species = species,
  cols = tidyselect::everything(),
  method = c("K", "lambda"),
  nsim = 999
)
```

## Arguments

- traits:

  A data frame with a species column and numeric traits.

- tree:

  A phylogeny of class `phylo` (ape); tip labels must match species
  names.

- species:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  The species column of `traits`.

- cols:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Numeric trait columns.

- method:

  `"K"` or `"lambda"`.

- nsim:

  Number of randomisations for the test of K.

## Value

A tibble with `trait`, `method`, `n_species` (with data and in the
tree), `statistic` and `p.value` (randomisation test for K,
likelihood-ratio test against lambda = 0 for lambda).

## References

Blomberg, S. P., Garland, T. and Ives, A. R. (2003). Testing for
phylogenetic signal in comparative data: behavioral traits are more
labile. *Evolution*, 57, 717-745.
[doi:10.1111/j.0014-3820.2003.tb00285.x](https://doi.org/10.1111/j.0014-3820.2003.tb00285.x)

Pagel, M. (1999). Inferring the historical patterns of biological
evolution. *Nature*, 401, 877-884.
[doi:10.1038/44766](https://doi.org/10.1038/44766)
