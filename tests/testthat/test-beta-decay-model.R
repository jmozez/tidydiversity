decay_mats <- function(d) {
  labs <- unique(c(d$site_1, d$site_2))
  i <- match(d$site_1, labs)
  j <- match(d$site_2, labs)
  s <- matrix(0, length(labs), length(labs))
  g <- s
  s[cbind(i, j)] <- 1 - d$total
  s[cbind(j, i)] <- 1 - d$total
  g[cbind(i, j)] <- d$distance
  g[cbind(j, i)] <- d$distance
  list(s = stats::as.dist(s), g = stats::as.dist(g))
}

test_that("beta_decay_model() matches betapart::decay.model()", {
  skip_if_not_installed("betapart")
  skip_if_not_installed("minpack.lm")
  d <- beta_decay(png_ants, gradient = elevation, .by = season)
  wet <- d[d$season == "wet", ]
  m <- decay_mats(wet)
  for (mt in c("exponential", "power")) {
    ref <- betapart::decay.model(m$s, m$g, model.type = mt, perm = 2)
    ours <- beta_decay_model(wet, model = mt, permutations = 0)
    expect_equal(ours$a, unname(ref$first.parameter), tolerance = 1e-4)
    expect_equal(ours$b, unname(-ref$second.parameter), tolerance = 1e-4)
    expect_equal(ours$pseudo_r2, ref$pseudo.r.squared, tolerance = 1e-5)
    expect_equal(ours$aic, ref$aic, tolerance = 1e-4)
  }
})

test_that("beta_decay_model() fits each group and tests by permutation", {
  d <- beta_decay(png_frogs, gradient = elevation, abundance = abundance)
  set.seed(2)
  out <- beta_decay_model(d, permutations = 99)
  expect_equal(nrow(out), 1)
  expect_gt(out$b, 0)
  expect_gte(out$p.value, 1 / 100)
  expect_lte(out$p.value, 1)
  expect_lt(out$p.value, 0.05)
  expect_equal(out$half_distance, log(2) / out$b)
  g <- beta_decay_model(beta_decay(png_ants, elevation, .by = season),
                        component = "turnover", permutations = 0)
  expect_equal(g$season, c("dry", "wet"))
  expect_true(all(is.na(g$p.value)))
  expect_error(beta_decay_model(png_ants), "beta_decay")
})
