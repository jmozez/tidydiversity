toy <- tibble::tibble(
  site = c("a", "c", "a", "b", "c", "d", "e", "e"),
  elevation = c(100, 300, 100, 200, 300, 400, 500, 500),
  species = c("x", "x", "y", "y", "y", "y", "y", "z")
)

test_that("range_through fills gaps between the extremes only", {
  rt <- range_through(toy, gradient = elevation)
  x <- rt[rt$species == "x", ]
  expect_equal(x$site, c("a", "b", "c"))
  expect_equal(x$interpolated, c(FALSE, TRUE, FALSE))
  expect_equal(sum(rt$species == "y"), 5)
  expect_equal(sum(rt$species == "z"), 1)
  expect_equal(sum(rt$interpolated), 1)
})

test_that("uniform expectation is exact and matches simulation", {
  size <- c(1, 2, 3, 5, 8)
  e <- mde_expected_uniform(size, 8)
  # a range of the full domain covers every site; total = sum of sizes
  expect_equal(sum(e), sum(size))
  expect_equal(mde_expected_uniform(8, 8), rep(1, 8))
  expect_equal(mde_expected_uniform(1, 4), rep(0.25, 4))
  set.seed(1)
  s <- mde_simulate(size, 8, 20000, "uniform")
  expect_equal(rowMeans(s), e, tolerance = 0.02)
  expect_equal(e, rev(e))
})

test_that("spreading-dye model matches rangemodelR", {
  skip_if_not_installed("rangemodelR")
  g <- mde_prepare(
    png_frogs, rlang::quo(elevation), rlang::quo(site),
    rlang::quo(species), rlang::quo(NULL)
  )
  o <- mde_occupancy(g$groups[[1]])
  m <- mde_fill(o$mat)
  set.seed(2)
  ours <- rowMeans(mde_simulate(colSums(m), nrow(m), 10000, "spread"))
  mm <- m * 1
  rownames(mm) <- o$sites
  set.seed(3)
  ref <- rangemodelR::rangemod1d(mm, cohesion = TRUE, reps = 4000)$mod.rich
  expect_equal(ours, ref, tolerance = 0.02)
})

test_that("range_mde returns observed, expected and limits", {
  set.seed(1)
  r <- range_mde(png_frogs, gradient = elevation, nsim = 199)
  expect_s3_class(r, "td_mde")
  expect_equal(r$elevation, sort(unique(png_frogs$elevation)))
  expect_true(all(r$lower <= r$upper))
  expect_true(all(r$outside %in% c("above", "below", "within")))
  f <- glance(r)
  expect_equal(nrow(f), 1)
  expect_true(f$p_value > 0 && f$p_value <= 1)
  sp <- range_mde(png_frogs, gradient = elevation, model = "spread", nsim = 99)
  expect_equal(sum(sp$expected), sum(r$expected), tolerance = 1e-8)
  by <- range_mde(png_ants, gradient = elevation, nsim = 49, .by = season)
  expect_equal(nrow(glance(by)), 2)
  expect_error(range_mde(png_frogs), "gradient")
  bad <- png_frogs
  bad$elevation[1] <- bad$elevation[1] + 1
  expect_error(range_mde(bad, gradient = elevation), "single")
})

test_that("autoplot draws the null model", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  r <- range_mde(png_frogs, gradient = elevation, nsim = 49)
  expect_s3_class(ggplot2::autoplot(r), "ggplot")
})
