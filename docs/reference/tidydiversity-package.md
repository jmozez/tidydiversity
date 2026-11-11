# tidydiversity: Taxonomic, Phylogenetic and Functional Diversity with Tidy Hill Numbers

Tidy, pipe-friendly tools for estimating taxonomic, phylogenetic and
functional diversity from long-format community data. All three
dimensions are expressed as Hill numbers of the same order q (effective
numbers of species), following Chao, Chiu and Jost (2014)
[doi:10.1146/annurev-ecolsys-120213-091540](https://doi.org/10.1146/annurev-ecolsys-120213-091540)
and Chao et al. (2019)
[doi:10.1002/ecm.1343](https://doi.org/10.1002/ecm.1343) . Computes
observed and asymptotic diversity, sample coverage, and size- and
coverage-based rarefaction and extrapolation following Chao et al.
(2014) [doi:10.1890/13-0133.1](https://doi.org/10.1890/13-0133.1) , and
partitions beta diversity into turnover and nestedness components
following Baselga (2010)
[doi:10.1111/j.1466-8238.2009.00490.x](https://doi.org/10.1111/j.1466-8238.2009.00490.x)
. Every function takes a data frame and returns a tibble, uses
data-masking for column arguments, and supports grouped data and the
'.by' argument.

## See also

Useful links:

- <https://tidydiversity.in4metrix.dev/>

- <https://github.com/jmozez/tidydiversity>

- <https://gitlab.com/jimmy.moses/tidydiversity>

- Report bugs at <https://github.com/jmozez/tidydiversity/issues>

## Author

**Maintainer**: Jimmy Moses <jimmy.moses@pnguot.ac.pg> \[copyright
holder\]

Authors:

- Jimmy Moses <jimmy.moses@pnguot.ac.pg> \[copyright holder\]
