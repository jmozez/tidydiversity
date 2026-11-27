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
#>    treatment  year site         q     n diversity
#>    <fct>     <int> <chr>    <dbl> <int>     <dbl>
#>  1 control    2016 P04-2016     0    92         8
#>  2 control    2016 P05-2016     0   120         8
#>  3 control    2016 P06-2016     0    60         7
#>  4 control    2016 P07-2016     0   107         6
#>  5 control    2016 P11-2016     0    73         4
#>  6 control    2016 P13-2016     0    74         7
#>  7 control    2016 P14-2016     0    98         6
#>  8 control    2016 P17-2016     0   111         7
#>  9 control    2016 P18-2016     0    66         7
#> 10 control    2016 P24-2016     0    72         8
#> # ℹ 86 more rows
```
