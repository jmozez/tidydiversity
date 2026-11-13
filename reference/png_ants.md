# Ants at nutrient baits along Mt Wilhelm, Papua New Guinea

Real field data: ground-foraging ants recorded at experimental nutrient
baits along the Mt Wilhelm elevational gradient in Papua New Guinea,
from 200 to 3700 m, in the dry and the wet season (Moses et al. 2023).
Baits offering six nutrient types were placed along transects at eight
elevations 500 m apart. Ants were found up to 2200 m in both seasons and
at 2700 m only once, in the dry season (one species at three baits);
that record is left out so both seasons cover the same five elevations
(200 to 2200 m) and can be compared directly. Each row is one species
recorded at one bait. Only the Papua New Guinea part of the published
cross-continental dataset is included, with the lead author's
permission.

## Usage

``` r
png_ants
```

## Format

A tibble with one row per bait and ant species, and 12 columns:

- site:

  Elevation band, such as `"MW0200"` for 200 m.

- elevation:

  Elevation band in metres.

- season:

  Sampling season, `"dry"` or `"wet"`.

- transect:

  Transect number within the elevation band.

- bait:

  Bait identifier: the sampling unit for incidence-based estimates
  (`unit = bait`).

- baits:

  Number of baits set at that elevation and season, including baits no
  ant visited (`n_units = baits`).

- bait_type:

  Nutrient offered: `h2o`, `nacl`, `cho` (sucrose), `amino_acid`,
  `cho_amino_acid` or `lipid`.

- species:

  Ant morphospecies code.

- genus, subfamily:

  Ant genus and subfamily.

- guild:

  Trophic guild.

- workers:

  Number of workers at the bait.

## Source

Mottl, O., Moses, J. and Klimes, P. (2023). Data and code for "Nutrient
use by tropical ant communities varies among three extensive elevational
gradients: a cross-continental comparison". Zenodo.
[doi:10.5281/zenodo.8191946](https://doi.org/10.5281/zenodo.8191946)
(open access). Built by `data-raw/png_ants.R` in the package source.

## Details

Because ants recruit to baits, worker counts measure activity rather
than independent individuals. tidydiversity therefore counts each row
(one species at one bait) as one occurrence when no `abundance` column
is given, which is the default here: diversity is estimated from the
number of baits at which each species was recorded.

## References

Moses, J., Peters, M. K., Tiede, Y., Mottl, O., Donoso, D. A., Farwig,
N., Fayle, T. M., Novotny, V., Sanders, N. J. and Klimes, P. (2023).
Nutrient use by tropical ant communities varies among three extensive
elevational gradients: a cross-continental comparison. *Global Ecology
and Biogeography*, 32, 2212-2229.
[doi:10.1111/geb.13757](https://doi.org/10.1111/geb.13757)

## Examples

``` r
png_ants
#> # A tibble: 369 × 12
#>    site  elevation season transect bait  baits bait_type species genus subfamily
#>    <chr>     <int> <chr>     <int> <chr> <int> <chr>     <chr>   <chr> <chr>    
#>  1 MW02…       200 dry           1 200_…    60 cho       lepm_0… Lept… Dolichod…
#>  2 MW02…       200 dry           1 200_…    60 cho       mono_0… Mono… Myrmicin…
#>  3 MW02…       200 dry           1 200_…    60 lipid     phei_0… Phei… Myrmicin…
#>  4 MW02…       200 dry           1 200_…    60 lipid     tetr_0… Tetr… Myrmicin…
#>  5 MW02…       200 dry           1 200_…    60 amino_ac… crem_0… Crem… Myrmicin…
#>  6 MW02…       200 dry           1 200_…    60 cho_amin… crem_0… Crem… Myrmicin…
#>  7 MW02…       200 dry           1 200_…    60 lipid     crem_0… Crem… Myrmicin…
#>  8 MW02…       200 dry           1 200_…    60 cho       crem_0… Crem… Myrmicin…
#>  9 MW02…       200 dry           1 200_…    60 cho_amin… rhyt_0… Rhyt… Ectatomm…
#> 10 MW02…       200 dry           1 200_…    60 cho       crem_0… Crem… Myrmicin…
#> # ℹ 359 more rows
#> # ℹ 2 more variables: guild <chr>, workers <int>
div_hill(png_ants, q = 0, .by = season)
#> # A tibble: 10 × 5
#>    season site       q     n diversity
#>    <chr>  <chr>  <dbl> <dbl>     <dbl>
#>  1 dry    MW0200     0    47        16
#>  2 dry    MW0700     0    23        15
#>  3 dry    MW1200     0    29        13
#>  4 dry    MW1700     0    17         5
#>  5 dry    MW2200     0    13         6
#>  6 wet    MW0200     0    76        21
#>  7 wet    MW0700     0    58        28
#>  8 wet    MW1200     0    57        20
#>  9 wet    MW1700     0    34        10
#> 10 wet    MW2200     0    15         5

# Incidence-based: baits as sampling units, including empty baits
div_estimate(png_ants, unit = bait, n_units = baits, .by = season, nboot = 0)
#> # A tibble: 30 × 8
#>    season site       q observed estimate    se lower upper
#>    <chr>  <chr>  <dbl>    <dbl>    <dbl> <dbl> <dbl> <dbl>
#>  1 dry    MW0200     0    16       18.5     NA    NA    NA
#>  2 dry    MW0200     1    12.3     15.2     NA    NA    NA
#>  3 dry    MW0200     2     9.91    12.3     NA    NA    NA
#>  4 dry    MW0700     0    15       85.8     NA    NA    NA
#>  5 dry    MW0700     1    11.8     39.2     NA    NA    NA
#>  6 dry    MW0700     2     8.67    13.7     NA    NA    NA
#>  7 dry    MW1200     0    13       21.0     NA    NA    NA
#>  8 dry    MW1200     1     9.37    14.0     NA    NA    NA
#>  9 dry    MW1200     2     6.73     8.61    NA    NA    NA
#> 10 dry    MW1700     0     5        5.25    NA    NA    NA
#> # ℹ 20 more rows
```
