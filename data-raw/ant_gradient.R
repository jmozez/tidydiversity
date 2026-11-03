# Simulated (synthetic) ant counts along two elevational transects.
# These are not field data. They exist to demonstrate tidydiversity.

set.seed(20261103)

n_species <- 40
elevations <- seq(200, 1600, by = 200)
transects <- c("north", "south")

optimum <- runif(n_species, 0, 1800)
breadth <- runif(n_species, 150, 500)
peak <- exp(rnorm(n_species, mean = 1.6, sd = 1.1))

rows <- list()
for (tr in transects) {
  shift <- if (tr == "north") 0 else 100
  for (el in elevations) {
    mu <- peak * exp(-((el + shift - optimum)^2) / (2 * breadth^2))
    mu <- mu * (1.4 - el / 2000)
    count <- rnbinom(n_species, mu = mu, size = 0.8)
    keep <- count > 0
    rows[[length(rows) + 1]] <- data.frame(
      transect = tr,
      site = sprintf("%s_%04d", substr(tr, 1, 1), el),
      elevation = el,
      species = sprintf("sp%02d", seq_len(n_species))[keep],
      abundance = as.integer(count[keep])
    )
  }
}

ant_gradient <- tibble::as_tibble(do.call(rbind, rows))

usethis::use_data(ant_gradient, overwrite = TRUE)
