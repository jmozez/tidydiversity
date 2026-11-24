test_that("species-environment pairs match vegan and link by site", {
  skip_if_not_installed("vegan")
  data("dune", "dune.env", "varespec", "varechem", package = "vegan")
  expect_equal(as.matrix(dune_species[-1]), as.matrix(dune), ignore_attr = TRUE)
  expect_identical(dune_species$site, rownames(dune))
  expect_identical(dune_env$site, dune_species$site)
  expect_equal(as.data.frame(dune_env[-1]), dune.env, ignore_attr = TRUE)
  expect_equal(as.matrix(vare_species[-1]), as.matrix(varespec), ignore_attr = TRUE)
  expect_identical(vare_env$site, vare_species$site)
  expect_equal(as.data.frame(vare_env[-1]), varechem, ignore_attr = TRUE)
})

test_that("a pair gives the same ordination as vegan", {
  skip_if_not_installed("vegan")
  data("varespec", "varechem", package = "vegan")
  v <- community_long(vare_species, cols = -site)
  o <- ord_fit(v,
    abundance = abundance, method = "cca", formula = ~ Al + P + K,
    env = vare_env, transform = "none", permutations = 0
  )
  ref <- vegan::cca(varespec ~ Al + P + K, data = varechem)
  expect_equal(o$fit$CCA$tot.chi, ref$CCA$tot.chi, tolerance = 1e-8)

  a <- ord_advise(v, abundance = abundance, formula = ~ Al + P + K, env = vare_env)
  expect_identical(a$question, "explain")
  expect_error(
    ord_advise(v, abundance = abundance, env = rbind(vare_env, vare_env)),
    "one row per site"
  )
})
