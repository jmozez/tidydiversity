wet <- png_ants[png_ants$season == "wet", ]
wide_wet <- function() {
  comm_prep(wet, rlang::quo(site), rlang::quo(species), rlang::quo(workers),
            NULL, NULL, "none")$y
}

test_that("beta_hill_pair() reproduces classic indices", {
  skip_if_not_installed("vegan")
  h <- beta_hill_pair(wet, abundance = workers)
  y <- wide_wet()
  ix <- cbind(h$site_1, h$site_2)
  q0 <- h$q == 0
  q2 <- h$q == 2
  sor <- as.matrix(vegan::vegdist(y, "bray", binary = TRUE))
  jac <- as.matrix(vegan::vegdist(y, "jaccard", binary = TRUE))
  mh <- as.matrix(vegan::vegdist(y / rowSums(y), "horn"))
  expect_equal(h$dis_sorensen[q0], sor[ix[q0, ]])
  expect_equal(h$dis_jaccard[q0], jac[ix[q0, ]])
  expect_equal(h$dis_sorensen[q2], mh[ix[q2, ]])
  # For two sites beta lies between 1 and 2 and V = C at q = 0.
  expect_true(all(h$beta >= 1 - 1e-9 & h$beta <= 2 + 1e-9))
  expect_equal(h$dis_turnover_sorensen[q0], h$dis_sorensen[q0])
})

test_that("beta_hill_pair() weighting, groups and q = 1", {
  eq <- beta_hill_pair(wet, abundance = workers, q = 1)
  sz <- beta_hill_pair(wet, abundance = workers, q = 1, weight = "size")
  expect_false(isTRUE(all.equal(eq$dis_sorensen, sz$dis_sorensen)))
  expect_equal(eq$dis_sorensen, log(eq$beta) / log(2))
  expect_equal(eq$dis_sorensen, eq$dis_jaccard)
  g <- beta_hill_pair(png_ants, abundance = workers, q = 2, .by = season)
  expect_s3_class(g, "td_beta_hill_pair")
  expect_setequal(unique(g$season), c("dry", "wet"))
  expect_error(beta_hill_pair(wet, q = -1), "non-negative")
})

test_that("beta_dist() and autoplot() handle beta_hill_pair()", {
  h <- beta_hill_pair(wet, abundance = workers)
  d <- beta_dist(h, q = 2)
  expect_s3_class(d, "dist")
  expect_equal(attr(d, "Size"), 5)
  expect_error(beta_dist(h), "several orders")
  expect_error(beta_dist(h, "total", q = 2), "must be one of")
  p <- ggplot2::autoplot(h, component = "dis_jaccard")
  expect_s3_class(p, "ggplot")
  expect_s3_class(p, "td_gg")
})
