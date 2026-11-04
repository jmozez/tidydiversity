test_that("div_rarefy() matches iNEXT size-based curves", {
  skip_if_not_installed("iNEXT")
  x <- as.vector(table(png_ants$species[png_ants$site == "MW0700"]))
  n <- sum(x)
  m <- c(1, 10, 40, n - 1, n, n + 30, 2 * n)
  ref <- iNEXT::iNEXT(x, q = c(0, 1, 2), size = m, nboot = 0)
  ref <- ref$iNextEst$size_based
  ref <- ref[ref$m %in% m, ]
  ref <- ref[order(ref$Order.q, ref$m), ]
  mine <- div_rarefy(png_ants[png_ants$site == "MW0700", ], size = m)
  expect_equal(mine$m, ref$m)
  expect_equal(mine$diversity, ref$qD, tolerance = 1e-8)
  expect_equal(mine$coverage, ref$SC, tolerance = 1e-8)
  expect_equal(
    mine$method,
    c("rarefaction", "observed", "extrapolation")[
      match(ref$Method, c("Rarefaction", "Observed", "Extrapolation"))
    ]
  )
})

test_that("rarefaction reaches the observed values at m = n", {
  out <- div_rarefy(toy(), q = 0)
  obs <- out[out$method == "observed", ]
  expect_equal(obs$diversity, c(6, 5))
  expect_s3_class(out, "td_rarefy")
  expect_true(all(diff(out$diversity[out$site == "a"]) >= 0))
})

test_that("div_standardise() matches iNEXT::estimateD()", {
  skip_if_not_installed("iNEXT")
  sub <- png_ants[png_ants$season == "wet", ]
  lst <- lapply(split(sub$species, sub$site), function(s) as.vector(table(s)))
  for (lev in c(0.7, 0.85)) {
    ref <- suppressWarnings(
      iNEXT::estimateD(lst, base = "coverage", level = lev, nboot = 0)
    )
    ref <- ref[order(ref$Assemblage, ref$Order.q), ]
    mine <- suppressWarnings(
      div_standardise(sub, coverage = lev, nboot = 0)
    )
    expect_equal(mine$diversity, ref$qD, tolerance = 1e-6)
    expect_equal(mine$m, ref$m, tolerance = 1e-6)
  }
  ref <- iNEXT::estimateD(lst, base = "size", level = 80, nboot = 0)
  ref <- ref[order(ref$Assemblage, ref$Order.q), ]
  mine <- suppressWarnings(div_standardise(sub, size = 80, nboot = 0))
  expect_equal(mine$diversity, ref$qD, tolerance = 1e-8)
})

test_that("default coverage is the lowest C(2n) in each group", {
  out <- div_standardise(png_ants, .by = season, nboot = 0)
  # A site with a single species has coverage 1 at every size, so it cannot
  # be brought down to the common level; leave such sites out.
  unit <- paste(png_ants$season, png_ants$site)
  rich <- tapply(png_ants$species, unit, function(s) length(unique(s)))
  out <- out[rich[paste(out$season, out$site)] > 1, ]
  cov <- tapply(out$coverage, out$season, function(x) diff(range(x)))
  expect_true(all(cov < 1e-3))
})

test_that("bootstrap intervals are added on request", {
  set.seed(2)
  out <- div_rarefy(toy(), q = 0, size = c(5, 10, 15), nboot = 10)
  expect_false(anyNA(out$lower))
})
