abu_ex <- c(rep(1, 12), rep(2, 5), 3, 3, 4, 5, 8, 12, 15, 30)
inc_ex <- c(rep(1, 10), rep(2, 6), rep(3, 3), 4, 5, 7, 9, 12, 15)

test_that("abundance richness estimators equal SpadeR", {
  skip_if_not_installed("SpadeR")
  ns <- asNamespace("SpadeR")
  r <- richness_abu(abu_ex, 10)
  ref <- c(
    chao1 = ns$SpecAbunChao1(abu_ex, k = 10, conf = 0.95)[1, 1],
    chao1_bc = ns$SpecAbunChao1bc(abu_ex, k = 10, conf = 0.95)[1, 1],
    ichao1 = ns$SpecAbuniChao1(abu_ex, k = 10, conf = 0.95)[1, 1],
    ace = ns$SpecAbunAce(abu_ex, k = 10, conf = 0.95)[1, 1],
    ace1 = ns$SpecAbunAce1(abu_ex, k = 10, conf = 0.95)[1, 1],
    jack1 = ns$SpecAbunJack1(abu_ex, k = 10, conf = 0.95)[1, 1],
    jack2 = ns$SpecAbunJack2(abu_ex, k = 10, conf = 0.95)[1, 1]
  )
  expect_equal(r[names(ref)], ref, tolerance = 1e-10)
})

test_that("ACE and Chao1-bc equal vegan::estimateR", {
  skip_if_not_installed("vegan")
  v <- vegan::estimateR(abu_ex)
  r <- richness_abu(abu_ex, 10)
  expect_equal(unname(r["ace"]), unname(v["S.ACE"]), tolerance = 1e-10)
})

test_that("incidence richness estimators equal SpadeR", {
  skip_if_not_installed("SpadeR")
  ns <- asNamespace("SpadeR")
  y <- c(20, inc_ex)
  r <- richness_inc(inc_ex, 20, 10)
  ref <- c(
    chao2 = ns$SpecInciChao2(y, k = 10, conf = 0.95)[1, 1],
    chao2_bc = ns$SpecInciChao2bc(y, k = 10, conf = 0.95)[1, 1],
    ichao2 = ns$SpecInciiChao2(y, k = 10, conf = 0.95)[1, 1],
    ice = ns$SpecInciModelh(y, k = 10, conf = 0.95)[1, 1],
    ice1 = ns$SpecInciModelh1(y, k = 10, conf = 0.95)[1, 1],
    jack1 = ns$SpecInciJack1(y, k = 10, conf = 0.95)[1, 1],
    jack2 = ns$SpecInciJack2(y, k = 10, conf = 0.95)[1, 1]
  )
  expect_equal(r[names(ref)], ref, tolerance = 1e-10)
})

test_that("incidence estimators equal vegan::specpool", {
  skip_if_not_installed("vegan")
  set.seed(4)
  m <- matrix(stats::rbinom(25 * 40, 1, stats::rbeta(40, 0.3, 2)), 25, 40, byrow = TRUE)
  m <- m[, colSums(m) > 0]
  v <- vegan::specpool(m)
  r <- richness_inc(colSums(m), nrow(m), 10)
  expect_equal(unname(r[c("jack1", "jack2", "bootstrap")]),
    unname(unlist(v[c("jack1", "jack2", "boot")])),
    tolerance = 1e-10
  )
  expect_equal(unname(r["chao2"]), v$chao, tolerance = 1e-10)
})

test_that("div_richness returns every estimator with intervals", {
  set.seed(1)
  r <- div_richness(png_ants, .by = season, nboot = 20)
  expect_s3_class(r, "td_richness")
  expect_setequal(unique(r$estimator), richness_abu_names)
  expect_true(all(r$estimate >= r$observed, na.rm = TRUE))
  expect_true(all(r$lower <= r$estimate & r$estimate <= r$upper, na.rm = TRUE))
  inc <- div_richness(png_ants, unit = bait, n_units = baits, .by = season, nboot = 0)
  expect_setequal(unique(inc$estimator), richness_inc_names)
  expect_true(all(is.na(inc$se)))
  expect_false(anyNA(inc$estimate))
  ch2 <- dplyr::filter(inc, estimator == "chao2")
  de2 <- div_estimate(png_ants, unit = bait, n_units = baits, .by = season, q = 0, nboot = 0)
  expect_equal(ch2$estimate, de2$estimate, tolerance = 1e-10)
  # q = 0 estimate of div_estimate is Chao1/Chao2
  ch <- dplyr::filter(r, estimator == "chao1")
  de <- dplyr::filter(div_estimate(png_ants, .by = season, q = 0, nboot = 0))
  expect_equal(ch$estimate, de$estimate, tolerance = 1e-10)
  expect_error(div_richness(png_ants, estimator = "chao2"), "abundance")
})

test_that("Fisher's alpha equals vegan::fisher.alpha", {
  skip_if_not_installed("vegan")
  f <- div_fisher_alpha(png_ants, .by = season)
  key <- paste(png_ants$season, png_ants$site)
  tab <- unclass(table(key, png_ants$species))
  ref <- vegan::fisher.alpha(tab)
  expect_equal(f$alpha, unname(ref[paste(f$season, f$site)]), tolerance = 1e-6)
})

test_that("shared species estimators equal SpadeR", {
  skip_if_not_installed("SpadeR")
  ns <- asNamespace("SpadeR")
  set.seed(3)
  for (r in 1:5) {
    x1 <- stats::rnbinom(80, mu = 2, size = 0.4)
    x2 <- stats::rnbinom(80, mu = 2, size = 0.4)
    expect_equal(chao_shared(x1, x2, sum(x1), sum(x2)), ns$Chao1_sharedEstFun(x1, x2))
    y1 <- pmin(stats::rpois(80, 1.2), 12)
    y2 <- pmin(stats::rpois(80, 1), 15)
    expect_equal(
      chao_shared(y1, y2, 12, 15, incidence = TRUE),
      ns$Chao2_sharedEstFun(c(12, y1), c(15, y2))
    )
  }
})

test_that("Chao similarity equals SpadeR and vegan", {
  skip_if_not_installed("vegan")
  set.seed(5)
  x1 <- stats::rnbinom(60, mu = 3, size = 0.5)
  x2 <- stats::rnbinom(60, mu = 3, size = 0.5)
  uv <- chao_uv(x1, x2, sum(x1), sum(x2))
  j <- uv[1] * uv[2] / (sum(uv) - prod(uv))
  expect_equal(j, 1 - as.vector(vegan::vegdist(rbind(x1, x2), "chao")), tolerance = 1e-10)
})

test_that("beta_shared and beta_chao work on tidy data", {
  s <- beta_shared(png_ants, .by = season)
  expect_equal(nrow(s), 20)
  expect_true(all(s$estimate >= s$observed))
  si <- beta_shared(png_ants, unit = bait, n_units = baits, .by = season)
  expect_true(all(si$estimate >= si$observed))
  b <- beta_chao(png_ants, .by = season)
  expect_true(all(b$chao_jaccard >= 0 & b$chao_jaccard <= 1))
  expect_true(all(b$chao_sorensen >= b$chao_jaccard - 1e-12))
  # Classic Sørensen equals 1 - total dissimilarity of beta_pair()
  p <- beta_pair(png_ants, .by = season)
  expect_equal(b$sorensen, 1 - p$total, tolerance = 1e-12)
  expect_error(beta_shared(dplyr::filter(png_ants, site == "MW0200")), "two sites")
})
