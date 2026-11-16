# Combine functional and phylogenetic distances

Combines a functional and a phylogenetic dissimilarity into one, as
`sqrt(w * F^2 + (1 - w) * P^2)` after scaling each to a maximum of 1
(the approach of Cadotte et al. 2013 and de Bello et al. 2017). Only
species present in both are kept.

## Usage

``` r
phylo_combine_dist(functional, phylogenetic, weight = 0.5)
```

## Arguments

- functional, phylogenetic:

  `dist` objects labelled by species.

- weight:

  Weight `w` of the functional part, between 0 and 1.

## Value

A `dist` object.

## References

Cadotte, M. W. et al. (2013). The ecology of differences: assessing
community assembly with trait and evolutionary distances. *Ecology
Letters*, 16, 1234-1244.
[doi:10.1111/ele.12161](https://doi.org/10.1111/ele.12161)
