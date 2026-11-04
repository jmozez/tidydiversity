test_that("beta_pair() matches betapart", {
  skip_if_not_installed("betapart")
  sub <- png_ants[png_ants$season == "dry", ]
  wide <- community_wide(sub)
  mat <- as.matrix(wide[-1]) > 0
  rownames(mat) <- wide$site
  for (index in c("sorensen", "jaccard")) {
    ref <- betapart::beta.pair(mat * 1, index.family = index)
    mine <- beta_pair(sub, index = index)
    lt <- function(d) as.matrix(d)[lower.tri(as.matrix(d))]
    expect_equal(mine$turnover, lt(ref[[1]]))
    expect_equal(mine$nestedness, lt(ref[[2]]))
    expect_equal(mine$total, lt(ref[[3]]))
  }
})

test_that("beta_multi() matches betapart", {
  skip_if_not_installed("betapart")
  for (tr in c("wet", "dry")) {
    sub <- png_ants[png_ants$season == tr, ]
    wide <- community_wide(sub)
    mat <- (as.matrix(wide[-1]) > 0) * 1
    for (index in c("sorensen", "jaccard")) {
      ref <- unlist(betapart::beta.multi(mat, index.family = index))
      mine <- beta_multi(sub, index = index)
      expect_equal(
        c(mine$turnover, mine$nestedness, mine$total),
        unname(ref)
      )
    }
  }
})

test_that("beta_decay() adds gradient distances", {
  out <- beta_decay(png_ants, elevation, .by = season)
  expect_s3_class(out, "td_beta_decay")
  n_sites <- tapply(png_ants$site, png_ants$season, function(s) length(unique(s)))
  expect_equal(nrow(out), sum(choose(n_sites, 2)))
  expect_equal(out$distance, abs(out$gradient_2 - out$gradient_1))
  expect_true(all(out$turnover + out$nestedness - out$total < 1e-12))
})

test_that("beta errors are informative", {
  expect_snapshot(error = TRUE, {
    beta_pair(toy()[toy()$site == "a", ])
    beta_pair(toy(), index = "chao")
    beta_decay(toy(), gradient = abundance)
  })
})
