# Phylogenetic distances between species

Cophenetic (patristic) distances from a phylogeny, scaled to a maximum
of 1 by default. Use them as `dist` in
[`trait_rao()`](https://tidydiversity.in4metrix.dev/reference/trait_rao.md),
[`trait_ses()`](https://tidydiversity.in4metrix.dev/reference/trait_ses.md)
or
[`trait_fd_indices()`](https://tidydiversity.in4metrix.dev/reference/trait_fd_indices.md)
to measure phylogenetic instead of functional diversity, or combine them
with trait distances in
[`phylo_combine_dist()`](https://tidydiversity.in4metrix.dev/reference/phylo_combine_dist.md).

## Usage

``` r
phylo_dist(tree, scale = TRUE)
```

## Arguments

- tree:

  A phylogeny of class `phylo` (ape); tip labels must match species
  names.

- scale:

  Scale distances to a maximum of 1?

## Value

A `dist` object labelled by tip labels.
