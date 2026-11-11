# Hill number features in a recipe

`step_hill()` is a [recipes](https://recipes.tidymodels.org) step that
replaces wide species columns (one column per species, abundance or
incidence values) with Hill numbers of chosen orders, so community
diversity can be used as a predictor in tidymodels workflows.

## Usage

``` r
step_hill(
  recipe,
  ...,
  q = c(0, 1, 2),
  prefix = "hill_q",
  keep_original_cols = FALSE,
  role = "predictor",
  trained = FALSE,
  columns = NULL,
  skip = FALSE,
  id = NULL
)
```

## Arguments

- recipe:

  A recipe.

- ...:

  Selectors for the species columns.

- q:

  Orders of diversity; one output column per order, named `prefix` +
  `q`.

- prefix:

  Prefix for the new columns.

- keep_original_cols:

  Keep the species columns?

- role, trained, columns, skip, id:

  Standard recipe step arguments.

## Value

An updated recipe.

## Examples

``` r
wide <- data.frame(elev = c(200, 700, 1200),
                   sp1 = c(5, 0, 2), sp2 = c(1, 3, 0), sp3 = c(2, 2, 2))
recipes::recipe(elev ~ ., data = wide) |>
  step_hill(dplyr::starts_with("sp"), q = c(0, 2)) |>
  recipes::prep() |>
  recipes::bake(new_data = NULL)
#> # A tibble: 3 x 3
#>    elev hill_q0 hill_q2
#>   <dbl>   <dbl>   <dbl>
#> 1   200       3    2.13
#> 2   700       2    1.92
#> 3  1200       2    2   
```
