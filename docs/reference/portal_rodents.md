# Rodent captures at the Portal Project, Arizona

Real field data: annual counts of rodent captures on the 24 experimental
plots of the Portal Project, a long-term study in the Chihuahuan Desert
near Portal, Arizona, USA, from 2016 to 2019. Since 2015 plots have been
unmanipulated controls, kangaroo rat (*Dipodomys*) exclosures, or
removals of all rodents. Only rodent species that are census targets and
identified to species are kept. Each plot and year is one site.

## Usage

``` r
portal_rodents
```

## Format

A tibble with one row per site and species captured, and seven columns:

- site:

  Site identifier, plot and year, such as `"P01-2016"`.

- plot:

  Plot number, 1 to 24.

- year:

  Census year.

- treatment:

  Experimental treatment: `control`, `krat_exclosure` or `removal`.

- species:

  Two-letter species code.

- scientific_name:

  Scientific name.

- abundance:

  Number of captures in the year.

## Source

PortalData, Weecology, <https://github.com/weecology/PortalData>,
released under the CC0 1.0 public domain dedication. Built by
`data-raw/portal_rodents.R` in the package source.

## References

Ernest, S. K. M., Yenni, G. M., Allington, G., Bledsoe, E. K.,
Christensen, E. M., Diaz, R. M. et al. (2018). The Portal Project: a
long-term study of a Chihuahuan desert ecosystem. bioRxiv.
[doi:10.1101/332783](https://doi.org/10.1101/332783)

## Examples

``` r
portal_rodents
#> # A tibble: 491 × 7
#>    site      plot  year treatment species scientific_name           abundance
#>    <chr>    <int> <int> <fct>     <chr>   <chr>                         <int>
#>  1 P01-2016     1  2016 removal   PM      Peromyscus maniculatus            9
#>  2 P01-2016     1  2016 removal   PE      Peromyscus eremicus               8
#>  3 P01-2016     1  2016 removal   RM      Reithrodontomys megalotis         6
#>  4 P01-2016     1  2016 removal   PP      Chaetodipus penicillatus          5
#>  5 P01-2016     1  2016 removal   PL      Peromyscus leucopus               1
#>  6 P01-2017     1  2017 removal   PP      Chaetodipus penicillatus         16
#>  7 P01-2017     1  2017 removal   OT      Onychomys torridus                9
#>  8 P01-2017     1  2017 removal   PL      Peromyscus leucopus               8
#>  9 P01-2017     1  2017 removal   PE      Peromyscus eremicus               6
#> 10 P01-2017     1  2017 removal   RM      Reithrodontomys megalotis         5
#> # ℹ 481 more rows
div_hill(portal_rodents, q = 0, .by = c(treatment, year))
#> # A tibble: 96 × 6
#>    treatment       year site         q     n diversity
#>    <fct>          <int> <chr>    <dbl> <int>     <dbl>
#>  1 removal         2016 P01-2016     0    29         5
#>  2 removal         2017 P01-2017     0    54        10
#>  3 removal         2018 P01-2018     0    35         5
#>  4 removal         2019 P01-2019     0     8         2
#>  5 krat_exclosure  2016 P02-2016     0    81         6
#>  6 krat_exclosure  2017 P02-2017     0    84         8
#>  7 krat_exclosure  2018 P02-2018     0    41         3
#>  8 krat_exclosure  2019 P02-2019     0    70         4
#>  9 krat_exclosure  2016 P03-2016     0    79         8
#> 10 krat_exclosure  2017 P03-2017     0    66         8
#> # ℹ 86 more rows
```
