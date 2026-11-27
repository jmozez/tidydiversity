# Caterpillars reared from trees in primary and secondary forest at Wanang

Real field data: Lepidoptera larvae collected from the foliage of trees
in a primary and a secondary forest plot in the Wanang Conservation
Area, Madang Province, Papua New Guinea, between 2003 and 2009, and
reared to adults where possible by the New Guinea Binatang Research
Centre (Butterill and Redmond 2023). Each plot has five sampling units
(`WP1`-`WP5` in primary and `WS1`-`WS5` in secondary forest). Counts are
the number of individuals of each morphospecies reared from each host
plant species. Taxa are morphospecies codes identified to different
ranks (species, genus, family or order), so treat them as morphospecies,
not as named species. The host plant makes the data suited to
species-overlap diagrams
([`plot_venn()`](https://tidydiversity.in4metrix.dev/reference/plot_venn.md))
and host-use comparisons.

## Usage

``` r
wanang_caterpillars
```

## Format

A tibble with one row per sampling unit, host plant and morphospecies,
and eight columns:

- site:

  Forest type, `"primary"` or `"secondary"`.

- plot:

  Sampling unit, `"WP1"`-`"WP5"` and `"WS1"`-`"WS5"`.

- host:

  Host plant species (`NA` when not recorded).

- species:

  Morphospecies code (GBIF `taxonID`).

- scientific_name:

  Most precise name given for the morphospecies.

- rank:

  Rank of `scientific_name`.

- family:

  Lepidoptera family (`NA` when only identified to order).

- abundance:

  Number of individuals.

## Source

Butterill, P. and Redmond, C. (2023). Plot-based sampling and rearing of
adult lepidoptera from lowland rainforest in Wanang, Papua New Guinea.
Version 1.1. New Guinea Binatang Research Centre. Occurrence dataset,
GBIF. [doi:10.15468/7e96ht](https://doi.org/10.15468/7e96ht) , released
under CC BY 4.0 (<https://creativecommons.org/licenses/by/4.0/>): cite
this source when you use the data. Built from all 9,354 GBIF occurrence
records by `data-raw/wanang_caterpillars.R`.

## Examples

``` r
wanang_caterpillars
#> # A tibble: 3,504 × 8
#>    site    plot  host  species scientific_name            rank  family abundance
#>    <chr>   <chr> <chr> <chr>   <chr>                      <chr> <chr>      <int>
#>  1 primary WP1   NA    TORT151 Nolidae                    fami… Nolid…         9
#>  2 primary WP1   NA    TORT230 Tortricidae                fami… Tortr…         4
#>  3 primary WP1   NA    CHOR001 Brenthia Clemens, 1860     genus Chore…         2
#>  4 primary WP1   NA    TORT051 Homona phanaea Meyrick, 1… spec… Tortr…         2
#>  5 primary WP1   NA    TORT234 Tortricidae                fami… Tortr…         2
#>  6 primary WP1   NA    CHOR006 Choreutidae                fami… Chore…         1
#>  7 primary WP1   NA    CRAM134 Crambidae                  fami… Cramb…         1
#>  8 primary WP1   NA    ELAC001 Elachistidae               fami… Elach…         1
#>  9 primary WP1   NA    GELE013 Gelechiidae                fami… Gelec…         1
#> 10 primary WP1   NA    GEOM034 Symmacra solidaria ochrea… subs… Geome…         1
#> # ℹ 3,494 more rows
div_hill(wanang_caterpillars, site = plot, q = 0:2) |> head()
#> # A tibble: 6 × 4
#>   plot      q     n diversity
#>   <chr> <int> <int>     <dbl>
#> 1 WP1       0   810     246  
#> 2 WP1       1   810     143. 
#> 3 WP1       2   810      88.7
#> 4 WP2       0   741     208  
#> 5 WP2       1   741      95.1
#> 6 WP2       2   741      38.1
```
