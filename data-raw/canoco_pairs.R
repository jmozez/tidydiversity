# Two classic species-environment pairs in the layout CANOCO uses: a species
# table (one row per site, one column per species) and an environment table
# (one row per site), linked by `site`. Taken unchanged from vegan, which
# documents their sources.
library(vegan)
data("dune", "dune.env", "varespec", "varechem", package = "vegan")

as_pair <- function(spe, env) {
  site <- rownames(spe)
  stopifnot(identical(site, rownames(env)))
  list(
    species = tibble::as_tibble(cbind(site = site, spe)),
    env = tibble::as_tibble(cbind(site = site, env))
  )
}

d <- as_pair(dune, dune.env)
dune_species <- d$species
dune_env <- d$env
v <- as_pair(varespec, varechem)
vare_species <- v$species
vare_env <- v$env

usethis::use_data(dune_species, dune_env, vare_species, vare_env, overwrite = TRUE)
