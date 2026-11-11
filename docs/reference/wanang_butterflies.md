# Butterflies in the Wanang forest dynamics plot, Papua New Guinea

Real field data: butterflies counted on 36 sampling days, three days a
month over 12 months spread across three years, in the Wanang 50 ha
forest dynamics plot, Papua New Guinea (Luk et al. 2019). Each sampling
day is one site, which makes the data suited to sample-based
accumulation and to partitioning diversity across days, months and
years. Only the Wanang part of the published multi-site dataset is
included.

## Usage

``` r
wanang_butterflies
```

## Format

A tibble with one row per day and species recorded, and six columns:

- site:

  Sampling day, `"day01"` to `"day36"`.

- day:

  Sampling day number, 1 to 36.

- month:

  Sampling month, 1 to 12, in order of sampling.

- year:

  Sampling year, 1 to 3, in order of sampling.

- species:

  Butterfly species.

- abundance:

  Number of individuals counted.

## Source

Luk, C.-L., Basset, Y., Kongnoo, P., Hau, B. C. H. and Bonebrake, T. C.
(2019). Data from: Inter-annual monitoring improves diversity estimation
of tropical butterfly assemblages. Dryad.
[doi:10.5061/dryad.j35fq7r](https://doi.org/10.5061/dryad.j35fq7r) ,
released under CC0 1.0. Built by `data-raw/wanang_butterflies.R`.

## References

Luk, C.-L., Basset, Y., Kongnoo, P., Hau, B. C. H. and Bonebrake, T. C.
(2019). Inter-annual monitoring improves diversity estimation of
tropical butterfly assemblages. *Biotropica*, 51, 519-528.
[doi:10.1111/btp.12671](https://doi.org/10.1111/btp.12671)

## Examples

``` r
wanang_butterflies
#> # A tibble: 2,020 x 6
#>    site    day month  year species               abundance
#>    <chr> <int> <int> <int> <chr>                     <int>
#>  1 day01     1     1     1 Apaturina erminea             4
#>  2 day01     1     1     1 Appias celestina              2
#>  3 day01     1     1     1 Cirrochroa regina            14
#>  4 day01     1     1     1 Cyrestis acilia               1
#>  5 day01     1     1     1 Danis danis                  41
#>  6 day01     1     1     1 Danis glaucopis               1
#>  7 day01     1     1     1 Danis regalis                34
#>  8 day01     1     1     1 Dicallaneura decorata         2
#>  9 day01     1     1     1 Elodina hypatia               5
#> 10 day01     1     1     1 Elymnias cybele               6
#> # i 2,010 more rows
div_hill(wanang_butterflies, q = 0, .by = year) |> head()
#> # A tibble: 6 x 5
#>    year site      q     n diversity
#>   <int> <chr> <dbl> <int>     <dbl>
#> 1     1 day01     0   197        30
#> 2     1 day02     0   192        33
#> 3     1 day03     0   171        33
#> 4     1 day04     0   341        41
#> 5     1 day05     0   299        36
#> 6     1 day06     0   399        37
```
