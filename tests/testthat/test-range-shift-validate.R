test_that("expected isotherm shift is warming over lapse rate", {
  expect_equal(range_shift_expected(1.8, 4.84), 1000 * 1.8 / 4.84)
  expect_equal(range_shift_expected(c(1, 2), 5), c(200, 400))
  expect_error(range_shift_expected(1, 0), "positive")
})

test_that("a perfect model scores perfectly; a lagging species tracks partially", {
  set.seed(1)
  sp <- paste0("sp", 1:30)
  truth <- stats::rnorm(30, 150, 60)
  obs <- data.frame(species = sp, shift_midpoint = truth, shift_optimum = truth)
  pred <- data.frame(species = sp, shift_midpoint = truth, shift_optimum = truth)
  v <- range_shift_validate(obs, pred,
    nboot = 99, seed = 1
  )
  expect_equal(v$bias, c(0, 0))
  expect_equal(v$r, c(1, 1))
  expect_equal(v$slope, c(1, 1))
  expect_equal(v$tracking, c(1, 1))
  # Species realise half of a uniform expected shift of 300 m
  half <- data.frame(species = sp, shift_midpoint = 150 + stats::rnorm(30, 0, 20))
  vh <- range_shift_validate(half, data.frame(species = sp, shift = 300), nboot = 199, seed = 1)
  expect_equal(vh$tracking, mean(half$shift_midpoint) / 300)
  expect_lt(vh$tracking_lower, 0.5)
  expect_gt(vh$tracking_upper, 0.5)
  expect_true(is.na(vh$r))
  expect_equal(vh$direction, 1)
})

test_that("works on range_shift_resurvey() output and drops truncated edges", {
  b <- png_frogs
  a <- png_frogs
  a$elevation <- a$elevation + 100
  obs <- range_shift_resurvey(b, a, gradient = elevation, abundance = abundance)
  pred <- data.frame(species = obs$species, shift = 100)
  v <- range_shift_validate(obs, pred, nboot = 49, seed = 1)
  expect_setequal(v$measure, c("lower", "upper", "midpoint", "optimum"))
  expect_equal(v$bias, rep(0, 4))
  expect_lt(v$n[v$measure == "lower"], v$n[v$measure == "midpoint"])
  expect_error(range_shift_validate(obs, data.frame(x = 1)), "species")
})
