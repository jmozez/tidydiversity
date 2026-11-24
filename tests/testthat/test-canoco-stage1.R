dune_ord <- function(...) {
  d <- community_long(dune_species, cols = -site)
  ord_fit(d, abundance = abundance, env = dune_env, permutations = 0, ...)
}

test_that("ord_design() builds the permute design CANOCO would use", {
  skip_if_not_installed("vegan")
  env <- as.data.frame(dune_env)
  h <- td_how(ord_design(blocks = "Management"), env, 99)
  expect_s3_class(h, "how")
  expect_equal(as.character(permute::getBlocks(h)), as.character(env$Management))
  s <- td_how(ord_design(within = "series"), env, 99)
  expect_identical(permute::getType(s, which = "within"), "series")
  g <- td_how(ord_design(within = "grid", nrow = 4, ncol = 5), env, 99)
  expect_identical(permute::getType(g, which = "within"), "grid")
  sp <- td_how(ord_design(plots = "Management", plots_type = "free", within = "none"), env, 99)
  expect_identical(permute::getType(sp, which = "plots"), "free")
  expect_error(ord_design(within = "grid"), "nrow")
  expect_error(td_how(ord_design(blocks = "nope"), env, 9), "nope")
})

test_that("a blocked test never shuffles sites between blocks", {
  skip_if_not_installed("vegan")
  env <- as.data.frame(dune_env)
  h <- td_how(ord_design(blocks = "Management"), env, 99)
  set.seed(1)
  p <- permute::shuffleSet(20, 50, control = h)
  same <- apply(p, 1, function(i) all(env$Management[i] == env$Management))
  expect_true(all(same))
  o <- dune_ord(method = "rda", formula = ~ A1)
  set.seed(2)
  t <- ord_test(o, permutations = 99, design = ord_design(blocks = "Management"))
  set.seed(2)
  ref <- vegan::anova.cca(o$fit, permutations = h)
  expect_equal(t$p.value[1], ref$`Pr(>F)`[1])
})

test_that("ord_effects() gives CANOCO's simple and conditional effects", {
  skip_if_not_installed("vegan")
  data("varespec", "varechem", package = "vegan")
  v <- community_long(vare_species, cols = -site)
  o <- ord_fit(v, abundance = abundance, method = "cca", formula = ~ Al + P + K,
               env = vare_env, permutations = 0)
  e <- ord_effects(o, permutations = 99)
  expect_setequal(unique(e$effect), c("simple", "conditional"))
  al <- vegan::cca(varespec ~ Al, data = varechem)
  s <- e[e$effect == "simple" & e$term == "Al", ]
  expect_equal(s$explained, al$CCA$tot.chi, tolerance = 1e-8)
  expect_equal(s$explained_pct, 100 * al$CCA$tot.chi / al$tot.chi, tolerance = 1e-8)
  cnd <- e[e$effect == "conditional", ]
  expect_equal(sum(cnd$explained), o$fit$CCA$tot.chi, tolerance = 1e-8)
  expect_true(all(cnd$p.adjusted >= cnd$p.value))
})

test_that("ord_select() reports adjusted p-values", {
  skip_if_not_installed("vegan")
  v <- community_long(vare_species, cols = -site)
  set.seed(1)
  s <- ord_select(v, abundance = abundance, formula = ~ Al + P + K + N + Baresoil,
                  env = vare_env, permutations = 99, adjust = "holm")
  expect_true("p.adjusted" %in% names(s))
  if (nrow(s)) {
    expect_equal(s$p.adjusted, stats::p.adjust(s$p.value, "holm", n = 5))
  }
})

test_that("downweighting matches vegan and species fit matches goodness()", {
  skip_if_not_installed("vegan")
  data("dune", package = "vegan")
  o <- dune_ord(method = "ca", downweight = TRUE)
  ref <- vegan::cca(vegan::downweight(as.matrix(dune)))
  expect_equal(o$fit$CA$eig, ref$CA$eig, tolerance = 1e-8)
  expect_error(dune_ord(method = "pca", downweight = TRUE), "CA, DCA and CCA")

  f <- ord_species_fit(o, axes = 2)
  g <- vegan::goodness(o$fit, display = "species", model = "CA", choices = 1:2)
  expect_equal(f$fit_pct, unname(100 * g[, 2]), tolerance = 1e-8)
  p <- ggplot2::autoplot(o, species = Inf, species_fit = 50)
  expect_s3_class(p, "ggplot")
})
