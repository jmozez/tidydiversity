# 1. Install, run and prepare your data

This chapter takes you from an empty computer to a first diversity
estimate. No previous R experience is needed.

## What you need

| Software | What it is | Where to get it |
|----|----|----|
| **R** (4.1 or newer) | The language that runs the analysis | <https://cran.r-project.org> |
| **RStudio Desktop** | The program you type and run code in | <https://posit.co/download/rstudio-desktop/> |
| **Build tools** | Only to build tidydiversity from source (option 2) | See below |

The quickest way is a ready-built binary from r-universe (option 1
below): nothing to compile. To build the development version from source
instead (option 2), your computer compiles it once, which needs:

| Operating system | Install once |
|----|----|
| **Windows** | **Rtools** for your R version: <https://cran.r-project.org/bin/windows/Rtools/> |
| **macOS** | In the Terminal app: `xcode-select --install` |
| **Linux** | `sudo apt install build-essential` (Ubuntu, Debian) or `sudo dnf install gcc-c++` (Fedora) |

## Install tidydiversity

In RStudio’s **Console** (bottom left):

**Option 1 (recommended): a ready-built binary from r-universe.** Works
on Windows, macOS and Linux, with no compiler:

``` r

install.packages("tidydiversity",
  repos = c("https://jmozez.r-universe.dev", "https://cloud.r-project.org"))
```

**Option 2: build the development version from GitHub source** (needs
the build tools above):

``` r

install.packages("pak")
pak::pak("jmozez/tidydiversity")
```

Then add the packages used throughout this guide:

``` r

install.packages(c("vegan", "ggplot2", "dplyr"))
```

Then check:

``` r

library(tidydiversity)
packageVersion("tidydiversity")
#> [1] '0.3.0'
```

For maps of diversity, add the companion package
[tidymapr](https://tidymapr.in4metrix.dev) the same way:
`install.packages("tidymapr", repos = c("https://jmozez.r-universe.dev", "https://cloud.r-project.org"))`.

## Work in an RStudio project

**File → New Project → New Directory**, then make `data/`, `R/` and
`figures/` folders inside it. Write code in a script (**File → New File
→ R Script**) and run a line with **Ctrl + Enter** (**Cmd + Enter** on a
Mac). The [tidymapr
guide](https://tidymapr.in4metrix.dev/articles/guide-01-install.html)
explains projects in more detail.

## The tidy data format

Every tidydiversity function takes **one row per species record** in a
long table, not a species-by-site matrix:

| Column | Meaning | Argument |
|----|----|----|
| `site` | Where (or when, or which treatment) the sample is from | `site =` |
| `species` | Species name or morphospecies code | `species =` |
| `n` | Number of individuals (abundance data) | `abundance =` |
| `unit` | The trap, bait, plot or day it was detected in (incidence data) | `unit =` |

The example data are ants at nutrient baits along the Mt Wilhelm
elevational gradient in Papua New Guinea (Mottl, Moses and Klimes 2023):

``` r

png_ants |>
  dplyr::select(site, elevation, season, bait, species) |>
  head()
#> # A tibble: 6 × 5
#>   site   elevation season bait           species 
#>   <chr>      <int> <chr>  <chr>          <chr>   
#> 1 MW0200       200 dry    200_fp_h_004_a lepm_001
#> 2 MW0200       200 dry    200_fp_h_004_a mono_002
#> 3 MW0200       200 dry    200_fp_h_005_a phei_008
#> 4 MW0200       200 dry    200_fp_h_005_a tetr_003
#> 5 MW0200       200 dry    200_fp_h_006_a crem_003
#> 6 MW0200       200 dry    200_fp_h_007_a crem_003
```

Each row is one species found at one bait, so the data are **incidence**
records: the sampling unit is the bait. Without an `abundance` column,
tidydiversity counts rows.

### Abundance or incidence?

| Your data record | Type | Example | Use |
|----|----|----|----|
| How many individuals of each species | **Abundance** | Trees in a plot, birds counted on a transect | `abundance = n` |
| Which species were present in each sampling unit | **Incidence** | Species per pitfall trap, bait, camera-day | `unit = trap, n_units = traps_set` |

Incidence data are often more reliable for social insects, clonal plants
or animals that cannot be counted individually. The estimators differ,
so tell tidydiversity which you have (Chapter 2).

### From a spreadsheet matrix to tidy

Field data are often a matrix with species in rows and sites in columns.
Convert it once:

``` r

wide <- data.frame(
  species = c("Pheidole sp1", "Pheidole sp2", "Tetramorium sp1"),
  Lowland = c(12, 0, 4),
  Montane = c(3, 7, 0)
)
tidy <- tidyr::pivot_longer(wide, -species, names_to = "site", values_to = "n") |>
  dplyr::filter(n > 0)
tidy
#> # A tibble: 4 × 3
#>   species         site        n
#>   <chr>           <chr>   <dbl>
#> 1 Pheidole sp1    Lowland    12
#> 2 Pheidole sp1    Montane     3
#> 3 Pheidole sp2    Montane     7
#> 4 Tetramorium sp1 Lowland     4
```

From Excel: `wide <- readxl::read_excel("data/ants.xlsx")`, then the
same two lines.

## A first analysis

``` r

div_hill(png_ants, q = 0:2, .by = season)
#> # A tibble: 30 × 5
#>    season site       q     n diversity
#>    <chr>  <chr>  <int> <dbl>     <dbl>
#>  1 dry    MW0200     0    47     16   
#>  2 dry    MW0200     1    47     12.3 
#>  3 dry    MW0200     2    47      9.91
#>  4 dry    MW0700     0    23     15   
#>  5 dry    MW0700     1    23     11.8 
#>  6 dry    MW0700     2    23      8.67
#>  7 dry    MW1200     0    29     13   
#>  8 dry    MW1200     1    29      9.37
#>  9 dry    MW1200     2    29      6.73
#> 10 dry    MW1700     0    17      5   
#> # ℹ 20 more rows
```

**What this means.** For each site and season, `diversity` is the
**effective number of species** of order `q` (Chapter 2): with `q = 0`
the number of species, with larger `q` the number of *common* species.
These are **observed** values; Chapters 2 and 3 show why observed values
from different samples should not be compared directly, and what to do
instead.

## Troubleshooting

| Message | Cause | Fix |
|----|----|----|
| `Could not find tools necessary to compile` | Building from source (option 2) without build tools | Use option 1 (r-universe binary), or install the build tools and restart RStudio |
| `Can't subset columns that don't exist` | Column name differs from `site`, `species` | Name them: `div_hill(data, site = plot, species = taxon)` |
| `abundance must be numeric` | Counts stored as text (e.g. “12”) | `data$n <- as.numeric(data$n)` |
| Diversity is the same for q = 0, 1 and 2 | Each row is a species total but `abundance` was not given, so every species counts once | Add `abundance = n` |
| Zero counts treated as present | Matrix converted without removing zeros | `filter(n > 0)` after `pivot_longer()` |

## Next

Chapter 2, [Hill numbers, completeness and
coverage](https://tidydiversity.in4metrix.dev/articles/guide-02-hill-numbers.md),
explains what these numbers mean and how complete your sampling is.
