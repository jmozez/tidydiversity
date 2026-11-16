# Argument names from vegan, betapart and indicspecies

test_that("method is accepted as vegan's name for distance", {
  skip_if_not_installed("vegan")
  ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
  set.seed(1)
  a <- beta_welch(ants, site = unit, group = season, distance = "jaccard", permutations = 19)
  set.seed(1)
  b <- beta_welch(ants, site = unit, group = season, method = "jaccard", permutations = 19)
  expect_equal(a, b)
  set.seed(1)
  d1 <- beta_dispersion(ants, site = unit, group = season, distance = "jaccard", permutations = 19)
  set.seed(1)
  d2 <- beta_dispersion(ants, site = unit, group = season, method = "jaccard", permutations = 19)
  expect_equal(d1$distance, d2$distance)
  expect_error(
    beta_welch(ants, site = unit, group = season, distance = "bray", method = "jaccard"),
    "not both"
  )
})

test_that("vegan's numeric scaling and by = NULL are understood", {
  skip_if_not_installed("vegan")
  o1 <- ord_fit(png_frogs, abundance = abundance, method = "pca", scaling = 1)
  o2 <- ord_fit(png_frogs, abundance = abundance, method = "pca", scaling = "sites")
  expect_equal(o1$sites, o2$sites)
  expect_identical(o1$scaling, "sites")
  r <- ord_fit(png_frogs, abundance = abundance, method = "cca", formula = ~elevation)
  set.seed(1)
  t1 <- ord_test(r, by = NULL, permutations = 49)
  set.seed(1)
  t2 <- ord_test(r, by = "model", permutations = 49)
  expect_equal(t1, t2)
})

test_that("model.type is accepted as betapart's name for model", {
  skip_if_not_installed("vegan")
  decay <- beta_decay(png_ants, gradient = elevation, .by = season)
  set.seed(1)
  a <- beta_decay_model(decay, model = "power", permutations = 19)
  set.seed(1)
  b <- beta_decay_model(decay, model.type = "pow", permutations = 19)
  expect_equal(a, b)
})

test_that("duleg is accepted as indicspecies' switch for combinations", {
  skip_if_not_installed("indicspecies")
  ants <- dplyr::mutate(png_ants,
    unit = paste(site, season, transect),
    zone = ifelse(elevation <= 700, "lowland", "montane")
  )
  set.seed(1)
  a <- beta_indicator(ants,
    site = unit, group = zone, combinations = FALSE, permutations = 49, alpha = 1
  )
  set.seed(1)
  b <- beta_indicator(ants, site = unit, group = zone, duleg = TRUE, permutations = 49, alpha = 1)
  expect_equal(a, b)
})
