# Alpine plant communities with traits (aravo) in long format

Converts the `aravo` data of the ade4 package (Choler 2005) into the
long format used by tidydiversity: 82 alpine plant species in 75 sites
in the Aravo valley (French Alps), with 6 site variables (including
snowmelt date, `Snow`, and physical disturbance, `PhysD`) and 8
functional traits. The data are loaded from ade4, not copied into
tidydiversity.

## Usage

``` r
data_aravo()
```

## Value

A list with `community` (a tibble with `site`, `species`, `cover`
(abundance class 0-5) and the site variables) and `traits` (a tibble
with `species` and the 8 traits).

## References

Choler, P. (2005). Consistent shifts in Alpine plant traits along a
mesotopographical gradient. *Arctic, Antarctic, and Alpine Research*,
37, 444-453.
[doi:10.1657/1523-0430(2005)037\[0444:CSIAPT\]2.0.CO;2](https://doi.org/10.1657/1523-0430%282005%29037%5B0444%3ACSIAPT%5D2.0.CO%3B2)

## Examples

``` r
aravo <- data_aravo()
aravo$community
#> # A tibble: 1,288 x 9
#>    site  species   cover Aspect Slope Form  PhysD ZoogD  Snow
#>    <chr> <chr>     <int>  <int> <int> <fct> <int> <fct> <int>
#>  1 AR26  Agro.rupe     3      5     0 3        20 no      140
#>  2 AR22  Agro.rupe     2      5    10 3        70 no      160
#>  3 AR28  Agro.rupe     3      1     5 3        60 no      150
#>  4 AR01  Agro.rupe     1      9    30 3        30 no      140
#>  5 AR23  Agro.rupe     2      5    10 3        20 some    140
#>  6 AR08  Agro.rupe     3      8    20 3        60 some    160
#>  7 AR12  Agro.rupe     2      9     5 3        40 no      150
#>  8 AR61  Agro.rupe     3      8    15 4        10 no      150
#>  9 AR49  Agro.rupe     2      5     2 1        65 no      150
#> 10 AR50  Agro.rupe     1      5     0 1        40 no      160
#> # i 1,278 more rows
aravo$traits
#> # A tibble: 82 x 9
#>    species   Height Spread Angle  Area Thick   SLA N_mass  Seed
#>    <chr>      <dbl>  <int> <int> <dbl> <dbl> <dbl>  <dbl> <dbl>
#>  1 Agro.rupe      6     10    80   60   0.12   8.1   219.  0.08
#>  2 Alop.alpi      5     20    20  191.  0.2   15.1   204.  0.21
#>  3 Anth.nipp     15      5    50  280   0.08  18     220.  0.54
#>  4 Heli.sede      0     30    80  600   0.2   10.6   233.  1.72
#>  5 Aven.vers     12     30    60  420   0.14  12.5   156.  1.17
#>  6 Care.rosa     30     20    80  180   0.4    6.5   209.  1.68
#>  7 Care.foet     12     40    45  280   0.14  19     397.  0.23
#>  8 Care.parv     25     10    80  520   0.2   13.7   237.  0.61
#>  9 Care.rupe      9      5    70   75   0.2    8.8   181.  0.64
#> 10 Care.semp     20     20    50  600   0.2   11.5   183.  0.83
#> # i 72 more rows
```
