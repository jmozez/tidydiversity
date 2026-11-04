test_that("welch_wd equals Welch's F in one Euclidean dimension", {
  set.seed(3)
  x <- c(rnorm(6, 0, 1), rnorm(8, 1, 3), rnorm(5, 0.5, 0.5))
  grp <- factor(rep(c("a", "b", "c"), c(6, 8, 5)))
  d2 <- as.matrix(dist(x))^2
  ref <- stats::oneway.test(x ~ grp, var.equal = FALSE)$statistic
  expect_equal(welch_wd(d2, grp), unname(ref), tolerance = 1e-10)
  g2 <- droplevels(grp[grp != "c"])
  x2 <- x[grp != "c"]
  ref2 <- stats::oneway.test(x2 ~ g2, var.equal = FALSE)$statistic
  expect_equal(welch_wd(as.matrix(dist(x2))^2, g2), unname(ref2),
    tolerance = 1e-10
  )
})

test_that("beta_welch returns a one-row test", {
  skip_if_not_installed("vegan")
  ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
  set.seed(1)
  out <- beta_welch(ants, site = unit, group = season, permutations = 49)
  expect_named(out, c("statistic", "n_groups", "n_sites", "p.value"))
  expect_equal(nrow(out), 1)
  expect_equal(out$n_groups, 2)
  expect_true(out$p.value > 0 && out$p.value <= 1)
})

test_that("beta_welch needs two groups of two sites", {
  skip_if_not_installed("vegan")
  ants <- dplyr::mutate(png_ants,
    unit = paste(site, season, transect), one = "x"
  )
  expect_error(beta_welch(ants, site = unit, group = one), "two groups")
})
