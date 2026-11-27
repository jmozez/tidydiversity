# Co-correspondence analysis

CANOCO's co-correspondence analysis (ter Braak and Schaffers 2004;
[`cocorresp::coca()`](https://gavinsimpson.github.io/cocorresp/reference/coca.html)):
relates two communities sampled at the same sites, such as plants and
insects. The *predictive* form explains one community (`response`) from
the other (`predictor`); the *symmetric* form finds the axes the two
share.

## Usage

``` r
ord_coca(
  response,
  predictor,
  site = site,
  species = species,
  abundance = NULL,
  method = c("predictive", "symmetric"),
  axes = 2
)
```

## Arguments

- response, predictor:

  Long community data for the two communities.

- site, species, abundance:

  Columns, the same in both data sets.

- method:

  `"predictive"` or `"symmetric"`.

- axes:

  Number of axes for the predictive form.

## Value

A list of class `td_coca`: `axes` (the variance of the response
community explained, predictive; or the eigenvalues, symmetric), `sites`
(site scores of both communities) and `fit`.

## References

ter Braak, C. J. F. and Schaffers, A. P. (2004). Co-correspondence
analysis: a new ordination method to relate two community compositions.
*Ecology*, 85, 834-846.
[doi:10.1890/03-0021](https://doi.org/10.1890/03-0021)
