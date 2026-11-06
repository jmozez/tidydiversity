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

test_that("beta_hill sorts and de-duplicates q", {
  b <- beta_hill(png_ants, .by = season, q = c(2, 0, 0))
  expect_equal(nrow(b), 4)
  expect_equal(b$q[b$season == "dry"], c(0, 2))
})

bh_ref_compare <- function(ours, ref, tol = 1e-8) {
  for (reg in names(ref)) {
    o <- ours[ours$region == reg, ]
    o <- o[order(o$q, o$coverage), ]
    r <- ref[[reg]]
    key <- function(x) order(x$Order.q, x$SC)
    expect_equal(o$gamma, r$gamma$Gamma[key(r$gamma)], tolerance = tol)
    expect_equal(o$alpha, r$alpha$Alpha[key(r$alpha)], tolerance = tol)
    expect_equal(o$beta, r$beta$Beta[key(r$beta)], tolerance = tol)
    expect_equal(o$dis_jaccard, r$`1-U`$Dissimilarity[key(r$`1-U`)],
      tolerance = tol
    )
  }
}

bh_brazil <- function() {
  e <- new.env()
  utils::data("Brazil_rainforests", "Brazil_tree", "Brazil_distM",
    package = "iNEXT.beta3D", envir = e
  )
  dat <- e$Brazil_rainforests
  long <- do.call(rbind, lapply(names(dat), function(reg) {
    m <- dat[[reg]]
    data.frame(
      region = reg, site = rep(colnames(m), each = nrow(m)),
      species = rep(rownames(m), ncol(m)), n = as.vector(m)
    )
  }))
  list(
    dat = dat, long = long[long$n > 0, ], tree = e$Brazil_tree,
    dist = as.matrix(e$Brazil_distM)
  )
}

bh_forests <- function() {
  e <- new.env()
  utils::data("Second_growth_forests", package = "iNEXT.beta3D", envir = e)
  sg <- e$Second_growth_forests
  long <- do.call(rbind, lapply(names(sg), function(reg) {
    do.call(rbind, lapply(names(sg[[reg]]), function(s) {
      m <- sg[[reg]][[s]]
      w <- which(m > 0, arr.ind = TRUE)
      data.frame(
        region = reg, site = s, species = rownames(m)[w[, 1]],
        plot = colnames(m)[w[, 2]], n_plots = ncol(m)
      )
    }))
  }))
  list(dat = sg, long = long)
}

test_that("beta_hill reproduces iNEXT.beta3D for PD and FD", {
  skip_on_cran()
  skip_if_not_installed("iNEXT.beta3D")
  skip_if_not_installed("ape")
  b <- bh_brazil()
  lv <- c(0.9, 0.95)
  ours <- beta_hill(b$long,
    abundance = n, coverage = lv, type = "PD",
    tree = b$tree, .by = region
  )
  ref <- suppressMessages(iNEXT.beta3D::iNEXTbeta3D(b$dat,
    diversity = "PD", level = lv, nboot = 0, PDtree = b$tree
  ))
  bh_ref_compare(ours, ref)
  ours <- beta_hill(b$long,
    abundance = n, coverage = lv, type = "FD",
    distance = b$dist, tau = 0.3, .by = region
  )
  ref <- iNEXT.beta3D::iNEXTbeta3D(b$dat,
    diversity = "FD", level = lv, nboot = 0, FDdistM = b$dist,
    FDtype = "tau_value", FDtau = 0.3
  )
  bh_ref_compare(ours, ref)
  ours <- beta_hill(b$long,
    abundance = n, coverage = lv, type = "FD",
    distance = b$dist, tau = "auc", .by = region
  )
  ref <- iNEXT.beta3D::iNEXTbeta3D(b$dat,
    diversity = "FD", level = lv, nboot = 0, FDdistM = b$dist,
    FDtype = "AUC"
  )
  bh_ref_compare(ours, ref)
})

test_that("beta_hill reproduces iNEXT.beta3D for incidence data", {
  skip_on_cran()
  skip_if_not_installed("iNEXT.beta3D")
  skip_if_not_installed("ape")
  f <- bh_forests()
  lv <- c(0.9, 0.95)
  ours <- beta_hill(f$long,
    unit = plot, n_units = n_plots, coverage = lv,
    .by = region
  )
  ref <- iNEXT.beta3D::iNEXTbeta3D(f$dat,
    diversity = "TD", datatype = "incidence_raw", level = lv, nboot = 0
  )
  bh_ref_compare(ours, ref)
  spp <- sort(unique(f$long$species))
  set.seed(7)
  tree <- ape::rcoal(length(spp), tip.label = spp)
  ours <- beta_hill(f$long,
    unit = plot, n_units = n_plots, coverage = lv,
    type = "PD", tree = tree, .by = region
  )
  # iNEXT.beta3D fails on several regions here, so run it one at a time
  for (reg in names(f$dat)) {
    ref <- suppressMessages(iNEXT.beta3D::iNEXTbeta3D(f$dat[reg],
      diversity = "PD", datatype = "incidence_raw", level = lv,
      nboot = 0, PDtree = tree
    ))
    bh_ref_compare(ours, ref)
  }
  dist <- as.matrix(stats::dist(matrix(stats::runif(2 * length(spp)), ncol = 2)))
  dist <- dist / max(dist)
  dimnames(dist) <- list(spp, spp)
  ours <- beta_hill(f$long,
    unit = plot, n_units = n_plots, coverage = lv,
    type = "FD", distance = dist, tau = 0.2, .by = region
  )
  ref <- iNEXT.beta3D::iNEXTbeta3D(f$dat,
    diversity = "FD", datatype = "incidence_raw", level = lv, nboot = 0,
    FDdistM = dist, FDtype = "tau_value", FDtau = 0.2
  )
  bh_ref_compare(ours, ref)
})

test_that("beta_hill bootstrap intervals bracket the estimates", {
  set.seed(1)
  b <- beta_hill(png_ants, .by = season, coverage = 0.9, nboot = 10)
  expect_true(all(b$beta_lower <= b$beta & b$beta <= b$beta_upper))
  expect_true(all(b$gamma_upper > b$gamma_lower))
  expect_false("beta_lower" %in% names(beta_hill(png_ants, .by = season)))
})

test_that("beta_hill incidence needs units shared across sites", {
  expect_error(
    beta_hill(png_ants, unit = bait, n_units = baits, .by = season),
    "same sampling units"
  )
})

test_that("autoplot draws beta_hill results", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  b <- beta_hill(png_ants, coverage = 0.9, nboot = 5, .by = season)
  p <- ggplot2::autoplot(b)
  expect_s3_class(p, "ggplot")
  expect_true(any(vapply(p$layers, function(l) {
    inherits(l$geom, "GeomErrorbar")
  }, logical(1))))
  d <- ggplot2::autoplot(beta_hill(png_ants, coverage = c(0.8, 0.9), .by = season),
    what = "dissimilarity"
  )
  expect_s3_class(d, "ggplot")
  expect_silent(ggplot2::ggplot_build(d))
})

test_that("beta_hill intervals stay within each quantity's range", {
  set.seed(2)
  b <- beta_hill(png_ants, coverage = 0.9, nboot = 10, .by = season)
  dis <- unlist(b[grep("^dis_.*_(lower|upper)$", names(b))])
  expect_true(all(dis >= 0 & dis <= 1))
  expect_true(all(b$beta_lower >= 1 & b$beta_upper <= b$n_sites))
})
