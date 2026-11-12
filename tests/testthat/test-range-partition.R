test_that("range_partition equals vegan::varpart on the same predictors", {
  skip_if_not_installed("vegan")
  set.seed(1)
  m <- range_mde(png_frogs, gradient = elevation, nsim = 99)
  p <- range_partition(m, ~elevation)
  d <- tibble::as_tibble(unclass(m))
  v <- vegan::varpart(d$observed, d$expected, d$elevation)$part$indfract$Adj.R.square
  expect_equal(p$adj_r2, v, tolerance = 1e-10)
  expect_equal(sum(p$adj_r2), 1, tolerance = 1e-10)
  expect_true(all(p$p_value[1:2] > 0 & p$p_value[1:2] <= 1))
})

test_that("range_partition works by group and with site data", {
  set.seed(1)
  m <- range_mde(png_ants, gradient = elevation, nsim = 49, .by = season)
  p <- range_partition(m, ~elevation)
  expect_equal(nrow(p), 8)
  sites <- dplyr::distinct(png_ants, site, elevation) |>
    dplyr::mutate(temp = 27 - elevation / 180)
  q <- range_partition(m, ~temp, data = dplyr::select(sites, site, temp))
  expect_equal(q$adj_r2, p$adj_r2, tolerance = 1e-10)
  expect_error(range_partition(m, ~rain), "not found")
  expect_error(range_partition(png_ants, ~elevation), "range_mde")
})
