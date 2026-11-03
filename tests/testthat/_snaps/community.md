# community print header is informative

    Code
      as_community(toy())
    Output
      # A community: 2 sites, 9 species, 34 individuals
         site  species abundance
         <chr> <chr>       <dbl>
       1 a     s1             10
       2 a     s2              5
       3 a     s3              3
       4 a     s4              2
       5 a     s5              1
       6 a     s6              1
       7 b     s1              4
       8 b     s2              4
       9 b     s7              2
      10 b     s8              1
      11 b     s9              1

# input errors are informative

    Code
      as_community(1:3)
    Condition
      Error in `as_community()`:
      ! `data` must be a data frame, not an integer vector.
    Code
      as_community(toy(), site = c(site, species))
    Condition
      Error in `as_community()`:
      ! `site` must select exactly one column, not 2.
    Code
      as_community(toy(), abundance = species)
    Condition
      Error in `as_community()`:
      ! Column species must be numeric, not a character vector.
    Code
      as_community(dplyr::mutate(toy(), abundance = -1))
    Condition
      Error in `as_community()`:
      ! Column abundance must contain non-negative, finite values.
      x Problem at rows 1, 2, 3, 4, and 5.
    Code
      div_estimate(dplyr::mutate(toy(), abundance = 1.5))
    Condition
      Error in `div_estimate()`:
      ! Column abundance must contain whole-number counts.
      i Estimators based on sampling theory need counts of individuals.
    Code
      as_community(dplyr::group_by(toy(), site), .by = species)
    Condition
      Error in `as_community()`:
      ! Can't supply `.by` when `data` is a grouped data frame.
    Code
      div_estimate(toy(), q = 3)
    Condition
      Error in `div_estimate()`:
      ! `q` must contain only 0, 1 or 2.
      i Estimators for other orders are not yet available.
    Code
      div_standardise(toy(), coverage = 0.9, size = 10)
    Condition
      Error in `div_standardise()`:
      ! Supply only one of `coverage` or `size`.

