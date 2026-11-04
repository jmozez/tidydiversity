test_that("beta_hill reproduces iNEXT.beta3D (TD, abundance, coverage)", {
  skip_on_cran()
  skip_if_not_installed("iNEXT.beta3D")
  e <- new.env()
  utils::data("Brazil_rainforests", package = "iNEXT.beta3D", envir = e)
  dat <- e$Brazil_rainforests
  long <- do.call(rbind, lapply(names(dat), function(reg) {
    m <- dat[[reg]]
    data.frame(region = reg, site = rep(colnames(m), each = nrow(m)),
               species = rep(rownames(m), ncol(m)), n = as.vector(m))
  }))
  long <- long[long$n > 0, ]
  ours <- beta_hill(long, abundance = n, coverage = c(0.9, 0.95),
                    .by = region)
  ref <- iNEXT.beta3D::iNEXTbeta3D(
    dat,
    diversity = "TD", datatype = "abundance", base = "coverage",
    level = c(0.9, 0.95), nboot = 0
  )
  for (reg in names(dat)) {
    o <- ours[ours$region == reg, ]
    o <- o[order(o$q, o$coverage), ]
    r <- ref[[reg]]
    key <- function(x) order(x$Order.q, x$SC)
    expect_equal(o$gamma, r$gamma$Gamma[key(r$gamma)], tolerance = 1e-8)
    expect_equal(o$alpha, r$alpha$Alpha[key(r$alpha)], tolerance = 1e-8)
    expect_equal(o$beta, r$beta$Beta[key(r$beta)], tolerance = 1e-8)
    expect_equal(o$dis_sorensen, r$`1-C`$Dissimilarity[key(r$`1-C`)],
                 tolerance = 1e-8)
    expect_equal(o$dis_jaccard, r$`1-U`$Dissimilarity[key(r$`1-U`)],
                 tolerance = 1e-8)
    expect_equal(o$dis_turnover_sorensen,
                 r$`1-V`$Dissimilarity[key(r$`1-V`)], tolerance = 1e-8)
    expect_equal(o$dis_turnover_jaccard,
                 r$`1-S`$Dissimilarity[key(r$`1-S`)], tolerance = 1e-8)
  }
})

test_that("beta_hill defaults, bounds and errors", {
  b <- beta_hill(png_ants, .by = season)
  expect_equal(length(unique(b$coverage)), 1)
  expect_true(all(b$beta >= 1 & b$beta <= b$n_sites))
  dis <- as.matrix(b[grep("^dis_", names(b))])
  expect_true(all(dis >= -1e-12 & dis <= 1 + 1e-12))
  expect_error(beta_hill(png_ants, coverage = 1.5), "coverage")
  one <- png_ants[png_ants$site == png_ants$site[1], ]
  expect_error(beta_hill(one), "two sites")
})
