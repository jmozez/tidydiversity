test_that("div_hill() gives richness, Shannon and Simpson", {
  out <- div_hill(toy(), q = c(0, 1, 2))
  x <- counts_of(toy(), "a")
  p <- x / sum(x)
  a <- out[out$site == "a", ]
  expect_equal(a$diversity, c(6, exp(-sum(p * log(p))), 1 / sum(p^2)))
  expect_equal(a$n, rep(22, 3))
})

test_that(".by and group_by() agree", {
  a <- div_hill(ant_gradient, .by = transect)
  b <- div_hill(dplyr::group_by(ant_gradient, transect))
  expect_equal(a, b)
  expect_named(a, c("transect", "site", "q", "n", "diversity"))
})

test_that("div_estimate() matches iNEXT asymptotic estimates", {
  skip_if_not_installed("iNEXT")
  for (s in unique(ant_gradient$site)[c(1, 6, 16)]) {
    x <- ant_gradient$abundance[ant_gradient$site == s]
    ref <- iNEXT::iNEXT(x, q = c(0, 1, 2), nboot = 0)$AsyEst
    mine <- div_estimate(ant_gradient[ant_gradient$site == s, ], nboot = 0)
    expect_equal(mine$estimate, unname(ref$Estimator), tolerance = 1e-8)
    expect_equal(mine$observed, unname(ref$Observed), tolerance = 1e-8)
  }
})

test_that("div_estimate() bootstrap gives intervals", {
  set.seed(1)
  out <- div_estimate(toy(), nboot = 20)
  expect_true(all(out$se >= 0))
  expect_true(all(out$lower <= out$estimate & out$estimate <= out$upper))
  expect_true(all(is.na(div_estimate(toy(), nboot = 0)$se)))
})

test_that("div_coverage() matches iNEXT", {
  skip_if_not_installed("iNEXT")
  out <- div_coverage(ant_gradient)
  ref <- iNEXT::DataInfo(
    split(ant_gradient$abundance, ant_gradient$site),
    datatype = "abundance"
  )
  expect_equal(out$coverage, ref$SC, tolerance = 1e-4)
  expect_equal(out$f1, ref$f1)
})
