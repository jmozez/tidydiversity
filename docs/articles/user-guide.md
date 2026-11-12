# User guide

This guide explains how to use tidydiversity **and** what its results
mean. Each chapter follows the same plan:

1.  **The concept**: the question, the theory and its key formula, with
    the original references.
2.  **Code** to copy into RStudio, run on real, openly licensed field
    data shipped with the package.
3.  **Figures and tables** made by that code.
4.  **How to interpret them**, including what they do not show.
5.  **How to report them**: a model paragraph for a paper, with the
    numbers filled in from the analysis.

| Chapter                                                                                                             | You will learn                                                                                                           | Main functions                                                                                                                                                                                                                                                                                                                                |
|---------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [1. Install, run and prepare your data](https://tidydiversity.in4metrix.dev/articles/guide-01-install.md)           | Set up R and RStudio; the tidy data format; abundance and incidence data; converting spreadsheets                        | [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md)                                                                                                                                                                                                                                                                     |
| [2. Hill numbers, completeness and coverage](https://tidydiversity.in4metrix.dev/articles/guide-02-hill-numbers.md) | What diversity is; orders q = 0, 1, 2; diversity profiles; sample coverage; completeness; Chao1 and asymptotic estimates | [`div_hill()`](https://tidydiversity.in4metrix.dev/reference/div_hill.md), [`div_coverage()`](https://tidydiversity.in4metrix.dev/reference/div_coverage.md), [`div_completeness()`](https://tidydiversity.in4metrix.dev/reference/div_completeness.md), [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md)    |
| [3. Fair comparisons](https://tidydiversity.in4metrix.dev/articles/guide-03-fair-comparisons.md)                    | Rarefaction and extrapolation; size- versus coverage-based standardisation; reading confidence intervals                 | [`div_rarefy()`](https://tidydiversity.in4metrix.dev/reference/div_rarefy.md), [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md)                                                                                                                                                                        |
| [4. Beta diversity](https://tidydiversity.in4metrix.dev/articles/guide-04-beta.md)                                  | Gamma = alpha × beta; dissimilarities; turnover versus nestedness; distance decay                                        | [`beta_hill()`](https://tidydiversity.in4metrix.dev/reference/beta_hill.md), [`beta_pair()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md), [`beta_multi()`](https://tidydiversity.in4metrix.dev/reference/beta_pair.md), [`beta_decay()`](https://tidydiversity.in4metrix.dev/reference/beta_decay.md)                         |
| [5. Community composition](https://tidydiversity.in4metrix.dev/articles/guide-05-composition.md)                    | Ordination and how to read biplots; PERMANOVA; dispersion; indicator species                                             | [`ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.md), [`beta_permanova()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md), [`beta_dispersion()`](https://tidydiversity.in4metrix.dev/reference/beta_permanova.md), [`beta_indicator()`](https://tidydiversity.in4metrix.dev/reference/beta_indicator.md) |
| [6. Functional and phylogenetic diversity](https://tidydiversity.in4metrix.dev/articles/guide-06-dimensions.md)     | TD, PD and FD on one Hill-number scale; functional redundancy; choosing tau                                              | [`div_estimate()`](https://tidydiversity.in4metrix.dev/reference/div_estimate.md), [`div_standardise()`](https://tidydiversity.in4metrix.dev/reference/div_standardise.md) with `type`                                                                                                                                                        |

**Where to start.** New to R: Chapters 1 and 2. Comparing sites or
treatments: Chapter 3 is essential. Comparing species lists: Chapters 4
and 5. Traits or phylogenies: Chapter 6.

**Going further.** The
[tutorials](https://tidydiversity.in4metrix.dev/articles/tutorials.md)
apply these methods to ants, frogs, butterflies, insects, mammals, birds
and trees; the
[Reference](https://tidydiversity.in4metrix.dev/reference/index.md)
lists every function. To put diversity on a map, use the companion
package [tidymapr](https://tidymapr.in4metrix.dev), whose [user
guide](https://tidymapr.in4metrix.dev/articles/user-guide.html) covers
mapping and spatial analysis.

**How to cite.** Run `citation("tidydiversity")` in R.
