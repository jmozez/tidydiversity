resurvey_fixture <- function(shift = 100) {
  before <- data.frame(
    site = rep(c("a", "b", "c", "d", "e"), each = 3),
    elevation = rep(c(500, 1000, 1500, 2000, 2500), each = 3),
    species = rep(c("x", "y", "z"), 5),
    n = c(5, 0, 0, 4, 2, 0, 0, 6, 1, 0, 3, 4, 0, 0, 2)
  )
  after <- before
  after$elevation <- after$elevation + shift
  list(before = before, after = after)
}

test_that("range_edges gives edges, breadth, optimum and truncation", {
  f <- resurvey_fixture()
  e <- range_edges(f$before, gradient = elevation, abundance = n)
  x <- e[e$species == "x", ]
  expect_equal(c(x$lower, x$upper, x$breadth), c(500, 1000, 500))
  expect_equal(x$optimum, (500 * 5 + 1000 * 4) / 9)
  expect_true(x$truncated_lower)
  expect_false(x$truncated_upper)
  z <- e[e$species == "z", ]
  expect_true(z$truncated_upper)
  # Incidence only: no optimum
  expect_true(all(is.na(range_edges(f$before, gradient = elevation)$optimum)))
  expect_error(range_edges(transform(f$before, elevation = "a"), gradient = elevation), "numeric")
})

test_that("a uniform 100 m upslope move is recovered exactly", {
  f <- resurvey_fixture(100)
  s <- range_shift_resurvey(f$before, f$after, gradient = elevation, abundance = n)
  expect_true(all(s$status == "both"))
  expect_equal(s$shift_lower, rep(100, 3))
  expect_equal(s$shift_optimum, rep(100, 3))
  expect_equal(s$change_breadth, rep(0, 3))
  t <- range_shift_test(s, nboot = 99, seed = 1, drop_truncated = FALSE)
  expect_equal(t$mean, rep(100, 4))
  expect_equal(t$n_up, rep(3L, 4))
})

test_that("lost and new species are listed, and the sign test is exact", {
  f <- resurvey_fixture(0)
  f$after <- f$after[f$after$species != "x", ]
  f$after <- rbind(f$after, data.frame(site = "e", elevation = 2500, species = "w", n = 1))
  s <- range_shift_resurvey(f$before, f$after, gradient = elevation, abundance = n)
  expect_equal(s$status[s$species == "x"], "lost")
  expect_equal(s$status[s$species == "w"], "new")
  # png_frogs moved up 50 m: 25 of 25 up gives p = 2 * 0.5^25
  b <- png_frogs
  a <- png_frogs
  a$elevation <- a$elevation + 50
  t <- range_shift_test(range_shift_resurvey(b, a, gradient = elevation), nboot = 49, seed = 1)
  mid <- t[t$measure == "midpoint", ]
  expect_equal(mid$p_sign, stats::binom.test(mid$n, mid$n)$p.value)
  expect_error(range_shift_test(data.frame()), "range_shift_resurvey")
})
