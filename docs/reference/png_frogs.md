# Frogs along the Mt Wilhelm elevational gradient, Papua New Guinea

Real field data: 3390 frogs of 55 species recorded at eight sites from
200 to 3700 m on Mt Wilhelm, Papua New Guinea (Dahl et al. 2024).
Species not formally described carry a provisional name such as
`"Copiula sp 1"`.

## Usage

``` r
png_frogs
```

## Format

A tibble with one row per site and species recorded, and seven columns:

- site:

  Site, such as `"MW0200"` for 200 m.

- elevation:

  Elevation in metres.

- species:

  Species code.

- scientific_name:

  Scientific or provisional name.

- family:

  Frog family.

- reproduction:

  Reproductive mode, `"terrestrial"` (direct development) or
  `"aquatic"`.

- abundance:

  Number of individuals recorded.

## Source

Dahl, C., Richards, S. J., Basien, I., Mungkaje, A. J. and Novotny, V.
(2023). Data from: Local and regional diversity of frog communities
along an extensive rainforest elevation gradient in Papua New Guinea.
Dryad.
[doi:10.5061/dryad.3n5tb2rqf](https://doi.org/10.5061/dryad.3n5tb2rqf) ,
released under CC0 1.0. Built by `data-raw/png_frogs.R`.

## References

Dahl, C., Richards, S. J., Basien, I., Mungkaje, A. J. and Novotny, V.
(2024). Local and regional diversity of frog communities along an
extensive rainforest elevation gradient in Papua New Guinea.
*Biotropica*, 56, 90-97.
[doi:10.1111/btp.13283](https://doi.org/10.1111/btp.13283)

## Examples

``` r
png_frogs
#> # A tibble: 92 x 7
#>    site   elevation species scientific_name       family  reproduction abundance
#>    <chr>      <int> <chr>   <chr>                 <chr>   <chr>            <int>
#>  1 MW0200       200 FR01    Cornufer papuensis    Cerato~ terrestrial        253
#>  2 MW0200       200 FR23    Copiula sp 1          Microh~ terrestrial         29
#>  3 MW0200       200 FR28    Hylophorbus sp 7      Microh~ terrestrial         68
#>  4 MW0200       200 FR30    Mantophryne lateralis Microh~ terrestrial          1
#>  5 MW0200       200 FR32    Oreophryne hypsiops   Microh~ terrestrial         85
#>  6 MW0200       200 FR37    Xenorhina oxycephala  Microh~ terrestrial          8
#>  7 MW0200       200 FR40    Litoria arfakiana     Pelodr~ aquatic              2
#>  8 MW0200       200 FR46    Litoria mucro         Pelodr~ aquatic              4
#>  9 MW0200       200 FR50    Litoria thesaurensis  Pelodr~ aquatic             12
#> 10 MW0200       200 FR51    Papurana arfaki       Ranidae aquatic              9
#> # i 82 more rows
div_estimate(png_frogs, nboot = 0)
#> # A tibble: 24 x 7
#>    site       q observed estimate    se lower upper
#>    <chr>  <dbl>    <dbl>    <dbl> <dbl> <dbl> <dbl>
#>  1 MW0200     0    13       13.2     NA    NA    NA
#>  2 MW0200     1     4.99     5.05    NA    NA    NA
#>  3 MW0200     2     3.31     3.32    NA    NA    NA
#>  4 MW0700     0    13       13       NA    NA    NA
#>  5 MW0700     1     8.29     8.39    NA    NA    NA
#>  6 MW0700     2     6.40     6.47    NA    NA    NA
#>  7 MW1200     0    16       16.5     NA    NA    NA
#>  8 MW1200     1     9.40     9.54    NA    NA    NA
#>  9 MW1200     2     7.14     7.22    NA    NA    NA
#> 10 MW1700     0    18       18       NA    NA    NA
#> # i 14 more rows
```
