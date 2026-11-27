dry <- png_ants[png_ants$season == "dry", ]

# Reference values from adespatial::beta.div(method = "hellinger") 0.8-0.
test_that("LCBD and SCBD match adespatial::beta.div()", {
  r <- beta_lcbd(dry, nperm = 0)
  expect_s3_class(r, "td_lcbd")
  expect_equal(sum(r$lcbd), 1)
  expect_equal(
    r$lcbd,
    c(0.181258605, 0.1675548126, 0.1840055003, 0.2339135752, 0.2332675069),
    tolerance = 1e-8
  )
  expect_equal(r$ss_total[1], 3.490990404, tolerance = 1e-8)
  expect_equal(r$bd_total[1], 0.8727476011, tolerance = 1e-8)
  s <- beta_scbd(dry)
  expect_equal(sum(s$scbd), 1)
  expect_equal(s$species[1:3], c("phei_057", "prol_004", "phei_019"))
  expect_equal(
    s$scbd[1:3], c(0.1078406253, 0.0705111781, 0.05942849751),
    tolerance = 1e-8
  )
})

test_that("LCBD permutation test gives valid p-values", {
  set.seed(1)
  r <- beta_lcbd(png_ants, .by = season, nperm = 49)
  expect_true(all(r$p_value > 0 & r$p_value <= 1))
  expect_true(all(r$p_adjusted >= r$p_value))
  expect_error(beta_lcbd(dry[dry$site %in% unique(dry$site)[1:2], ]), "three")
})

test_that("zeta diversity equals brute-force enumeration", {
  w <- tidyr_free_wide(dry) > 0
  z <- beta_zeta(dry)
  brute <- vapply(1:3, function(i) {
    mean(apply(utils::combn(nrow(w), i), 2, function(s) {
      sum(colSums(w[s, , drop = FALSE]) == i)
    }))
  }, 1)
  expect_equal(z$zeta[1:3], brute)
  expect_equal(z$zeta[1], mean(rowSums(w)))
  expect_equal(z$zeta_simpson[1], 1)
  g <- glance(beta_zeta(png_ants, .by = season))
  expect_equal(nrow(g), 4)
  expect_setequal(g$season, c("dry", "wet"))
  expect_error(beta_zeta(dry, orders = 99), "exceed")
})

test_that("Raup-Crick is bounded and agrees with vegan", {
  skip_if_not_installed("vegan")
  set.seed(1)
  r <- beta_raup_crick(dry, nsim = 499)
  expect_true(all(abs(r$raup_crick) <= 1))
  w <- tidyr_free_wide(dry) > 0
  set.seed(1)
  v_hi <- as.vector(vegan::raupcrick(w * 1, nsimul = 499))
  set.seed(1)
  v_lo <- as.vector(vegan::raupcrick(w * 1, nsimul = 499, chase = TRUE))
  expect_gt(stats::cor(v_hi, r$probability), 0.8)
  expect_true(mean(r$probability <= v_hi + 0.1 & r$probability >= v_lo - 0.1) > 0.9)
})

# Reference values from adespatial::TBI(method = "%difference").
test_that("TBI matches adespatial::TBI()", {
  s <- portal_rodents[portal_rodents$year %in% c(2016, 2019), ]
  r <- beta_tbi(s, time = year, site = plot, nperm = 0)
  expect_s3_class(r, "td_tbi")
  expect_equal(r$losses + r$gains, r$tbi)
  expect_equal(r$tbi, c(
    0.6756756757, 0.1523178808, 0.4867256637, 0.3290322581, 0.3953488372,
    0.2745098039, 0.2934782609, 0.203125, 0.3333333333, 1, 0.537037037,
    0.6888888889, 0.5238095238, 0.2738095238, 0.2777777778, 0.7222222222,
    0.4152046784, 0.375, 0.3333333333, 0.3157894737, 0.3333333333,
    0.625, 0.8536585366, 0.3109243697
  ), tolerance = 1e-8)
  expect_equal(r$losses[1:5], c(
    0.6216216216, 0.1125827815, 0.4424778761, 0.2580645161, 0.3953488372
  ), tolerance = 1e-8)
  set.seed(3)
  rs <- beta_tbi(s, time = year, site = plot, index = "sorensen", nperm = 19)
  expect_true(all(rs$p_value > 0 & rs$p_value <= 1))
  expect_error(
    beta_tbi(portal_rodents, time = year, site = plot),
    "exactly two"
  )
})
