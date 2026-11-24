test_that("log-ratio transform double-centres log(y + 1)", {
  skip_if_not_installed("vegan")
  d <- community_long(dune_species, cols = -site)
  o <- ord_fit(d, abundance = abundance, method = "pca", transform = "logratio")
  z <- log1p(as.matrix(dune_species[-1]))
  z <- sweep(sweep(z, 1, rowMeans(z)), 2, colMeans(z)) + mean(z)
  expect_equal(unname(rowMeans(o$analysed)), rep(0, 20), tolerance = 1e-10)
  expect_equal(unname(o$fit$CA$eig), unname(vegan::rda(z)$CA$eig), tolerance = 1e-8)
})

test_that("supplementary sites land where vegan puts them", {
  skip_if_not_installed("vegan")
  d <- community_long(dune_species, cols = -site)
  ref <- d[d$site %in% as.character(1:15), ]
  new <- d[d$site %in% as.character(16:20), ]
  o <- ord_fit(ref, abundance = abundance, method = "ca")
  p <- ord_predict(o, new, abundance = abundance)
  y <- as.matrix(dune_species[16:20, -1])
  rownames(y) <- dune_species$site[16:20]
  y <- y[, colnames(o$community)]
  vp <- predict(o$fit, newdata = y, type = "wa", rank = 2, scaling = 2)
  expect_equal(unname(as.matrix(p[c("axis1", "axis2")])), unname(vp[p$site, ]), tolerance = 1e-8)
  # a site in the analysis is placed on its own score
  o2 <- ord_fit(d, abundance = abundance, method = "ca")
  p2 <- ord_predict(o2, d[d$site == "1", ], abundance = abundance)
  expect_equal(p2$axis1, o2$sites$axis1[o2$sites$site == "1"], tolerance = 1e-8)
})

test_that("CVA separates groups and tests the separation", {
  skip_if_not_installed("MASS")
  v <- community_long(vare_species, cols = -site)
  v <- v[v$species %in% c("Cladstel", "Cladrang", "Pleuschr", "Vaccviti", "Empenigr"), ]
  env <- vare_env
  env$humus <- ifelse(env$Humdepth > stats::median(env$Humdepth), "deep", "shallow")
  set.seed(1)
  cv <- ord_cva(v, abundance = abundance, group = "humus", env = env, permutations = 99)
  expect_s3_class(cv, "td_cva")
  expect_equal(nrow(cv$sites), 24)
  expect_true(cv$test$p.value > 0 && cv$test$p.value <= 1)
  y <- as.matrix(vare_species[c("Cladstel", "Cladrang", "Pleuschr", "Vaccviti", "Empenigr")])
  g <- factor(env$humus)
  ref <- stats::cancor(y, stats::model.matrix(~g)[, -1, drop = FALSE])$cor
  expect_equal(cv$test$statistic, sum(ref^2), tolerance = 1e-8)
  expect_error(
    ord_cva(community_long(vare_species, cols = -site), abundance = abundance,
            group = "humus", env = env),
    "fewer species"
  )
})

test_that("dc-CA matches douconca", {
  skip_if_not_installed("douconca")
  a <- data_aravo()
  r <- trait_dcca(a$community, abundance = cover, traits = a$traits,
                  trait_formula = ~ Height + SLA, env_formula = ~ Snow + PhysD,
                  permutations = 19)
  expect_s3_class(r, "td_dcca")
  expect_equal(r$test$level, c("sites", "species", "max"))
  expect_equal(r$test$p.value[3], max(r$test$p.value[1:2]))
  expect_true(all(r$axes$eigenvalue > 0))
})

test_that("RLQ runs and reports the combined test", {
  skip_if_not_installed("ade4")
  a <- data_aravo()
  set.seed(1)
  r <- trait_rlq(a$community, abundance = cover, traits = a$traits,
                 env_vars = c("Snow", "PhysD"), trait_vars = c("Height", "SLA"),
                 permutations = 49)
  expect_s3_class(r, "td_rlq")
  expect_equal(r$test$p.value[3], max(r$test$p.value[1:2]))
  expect_setequal(r$trait_scores$trait, c("Height", "SLA"))
})

test_that("co-correspondence analysis relates two communities", {
  skip_if_not_installed("cocorresp")
  d <- community_long(dune_species, cols = -site)
  half <- unique(d$species)[1:15]
  a <- d[d$species %in% half, ]
  b <- d[!d$species %in% half, ]
  p <- ord_coca(a, b, abundance = abundance, method = "predictive", axes = 2)
  expect_s3_class(p, "td_coca")
  expect_equal(nrow(p$axes), 2)
  s <- ord_coca(a, b, abundance = abundance, method = "symmetric")
  expect_true(all(s$axes$eigenvalue >= 0))
})
