# Synthetic elevational gradient: 7 sites given in shuffled order
gradient_fixture <- function() {
  set.seed(42)
  elev <- c(1200, 200, 3200, 700, 2700, 1700, 2200)
  sites <- data.frame(site = paste0("e", elev), elevation = elev)
  sites$moisture <- 50 - elev / 100 + c(3, -2, 1, 4, -3, 0, 2)
  d <- do.call(rbind, lapply(seq_along(elev), function(i) {
    opt <- seq(100, 3300, length.out = 14)
    data.frame(
      site = sites$site[i], species = sprintf("sp%02d", 1:14),
      n = stats::rpois(14, 8 * exp(-(opt - elev[i])^2 / 6e5))
    )
  }))
  merge(d, sites)[sample(nrow(d)), ]
}

test_that("outputs follow a stable site order, not input order", {
  d <- gradient_fixture()
  want <- paste0("e", c(200, 700, 1200, 1700, 2200, 2700, 3200))
  expect_equal(div_hill(d, abundance = n, q = 0)$site, want)
  expect_equal(div_coverage(d, abundance = n)$site, want)
  skip_if_not_installed("vegan")
  o <- ord_fit(d, abundance = n, method = "pca", formula = ~elevation)
  expect_equal(o$sites$site, want)
  # Environmental values travel with their site, never by position
  expect_equal(o$sites$elevation, c(200, 700, 1200, 1700, 2200, 2700, 3200))
  d$site <- factor(d$site, levels = rev(want))
  expect_equal(as.character(div_hill(d, abundance = n, q = 0)$site), rev(want))
})

test_that("ord_fit tests passive variables on the plotted axes, exactly", {
  skip_if_not_installed("vegan")
  skip_if_not_installed("permute")
  d <- gradient_fixture()
  o <- ord_fit(d,
    abundance = n, method = "pca", formula = ~ elevation + moisture,
    permutations = "exact"
  )
  y <- vegan::decostand(
    as.matrix(stats::xtabs(n ~ site + species, d))[o$sites$site, ], "hellinger"
  )
  env <- o$sites[c("elevation", "moisture")]
  ref <- suppressMessages(vegan::envfit(vegan::rda(y), as.data.frame(env),
    choices = 1:2, permutations = permute::how(complete = TRUE, maxperm = 6000)
  ))
  expect_equal(o$envfit$r2, unname(ref$vectors$r), tolerance = 1e-10)
  expect_equal(o$envfit$p.value, unname(ref$vectors$pvals), tolerance = 1e-12)
  expect_equal(unique(o$envfit$axes), "1, 2")
  expect_true(all(o$envfit$exact))
  expect_equal(unique(o$envfit$permutations), factorial(7) - 1)
  three <- ord_fit(d, abundance = n, method = "pca", formula = ~elevation, choices = 1:3, seed = 1)
  expect_equal(unique(three$envfit$axes), "1, 2, 3")
  expect_error(ord_fit(d, abundance = n, formula = ~elevation, choices = 0), "axis")
})

test_that("div_standardise reports and explains its target coverage", {
  d <- gradient_fixture()
  a <- suppressWarnings(div_standardise(d, abundance = n, q = 0, nboot = 0))
  expect_true("target" %in% names(a))
  expect_equal(length(unique(a$target)), 1)
  b <- suppressWarnings(div_standardise(d, abundance = n, q = 0, nboot = 0, level = "min_observed"))
  obs <- div_coverage(d, abundance = n)$coverage
  expect_equal(unique(b$target), min(obs), tolerance = 1e-10)
  # A site that cannot reach the target is flagged, not silently lowered
  one <- data.frame(
    site = rep(c("a", "b"), c(3, 4)),
    species = c("x", "y", "z", "x", "y", "z", "w"), n = c(20, 15, 10, 30, 1, 5, 5)
  )
  expect_warning(
    div_standardise(one, abundance = n, q = 0, nboot = 0, coverage = 0.999),
    "cannot reach"
  )
  skip_if_not_installed("iNEXT")
  lst <- split(d$n[d$n > 0], d$site[d$n > 0])
  ref <- suppressWarnings(iNEXT::estimateD(lst,
    datatype = "abundance", base = "coverage",
    level = unique(b$target), nboot = 0
  ))
  ref <- ref[ref$Order.q == 0, ]
  expect_equal(b$diversity, ref$qD[match(b$site, ref$Assemblage)], tolerance = 1e-6)
})

test_that("model_count prints a readable call", {
  m <- model_count(data.frame(r = c(3, 5, 4, 2, 1), e = 1:5), r ~ poly(e, 2))
  out <- paste(utils::capture.output(print(m)), collapse = " ")
  expect_match(out, "glm(formula = r ~ poly(e, 2), family = poisson", fixed = TRUE)
  expect_false(grepl("function", out, fixed = TRUE))
})

test_that("beta_mantel equals vegan::mantel, with exact and one-sided p", {
  skip_if_not_installed("vegan")
  skip_if_not_installed("permute")
  d <- gradient_fixture()
  bd <- beta_dist(beta_pair(d, abundance = n, index = "bray"))
  elev <- stats::setNames(
    c(200, 700, 1200, 1700, 2200, 2700, 3200),
    paste0("e", c(200, 700, 1200, 1700, 2200, 2700, 3200))
  )
  m <- beta_mantel(bd, elev, permutations = "exact")
  ref <- suppressMessages(vegan::mantel(bd, stats::dist(elev[attr(bd, "Labels")]),
    method = "spearman", permutations = permute::how(complete = TRUE, maxperm = 6000)
  ))
  expect_equal(m$statistic, unname(ref$statistic))
  expect_equal(m$p.value, ref$signif, tolerance = 1e-12)
  expect_true(m$exact)
  sim <- 1 - as.matrix(bd)
  low <- beta_mantel(stats::as.dist(sim), elev, permutations = "exact", alternative = "less")
  expect_lt(low$statistic, 0)
  expect_equal(low$p.value, m$p.value, tolerance = 1e-12)
  pm <- beta_mantel(bd, elev, z = elev^2, permutations = 199, seed = 1)
  expect_true(pm$partial)
  expect_error(beta_mantel(bd, 1:3), "sites")
})

test_that("beta_turnover_counts matches betapart and handles empty sites", {
  d <- gradient_fixture()
  tc <- beta_turnover_counts(d, abundance = n, order_by = elevation)
  expect_equal(nrow(tc), 6)
  expect_equal(tc$site_1[1], "e200")
  expect_equal(tc$sorensen, tc$turnover + tc$nestedness)
  expect_equal(tc$s_1 - tc$shared, tc$lost)
  skip_if_not_installed("betapart")
  m <- as.matrix(stats::xtabs(n ~ site + species, d))
  for (k in seq_len(nrow(tc))) {
    sub <- m[c(tc$site_1[k], tc$site_2[k]), ]
    bp <- betapart::beta.pair((sub > 0) * 1, "sorensen")
    expect_equal(tc$turnover[k], as.numeric(bp$beta.sim))
    expect_equal(tc$nestedness[k], as.numeric(bp$beta.sne))
    ba <- betapart::beta.pair.abund(sub, "bray")
    expect_equal(tc$balanced[k], as.numeric(ba$beta.bray.bal))
    expect_equal(tc$gradient[k], as.numeric(ba$beta.bray.gra))
  }
  empty <- rbind(d, data.frame(
    site = "e3700", species = "sp01", n = 0,
    elevation = 3700, moisture = 13
  ))
  expect_warning(
    e <- beta_turnover_counts(empty, abundance = n, order_by = elevation),
    "no species"
  )
  last <- e[e$site_2 == "e3700", ]
  expect_equal(last$gained, 0)
  expect_equal(last$shared, 0)
  expect_true(is.na(last$turnover))
  all <- beta_turnover_counts(d, pairs = "all")
  expect_equal(nrow(all), 21)
})

test_that("beta_decay_boot gives the lm slope and a bootstrap interval", {
  d <- beta_decay(png_frogs, elevation)
  b <- beta_decay_boot(d, nboot = 199, per = 1000, seed = 1)
  ref <- stats::coef(stats::lm(total ~ distance, data = d))[[2]] * 1000
  expect_equal(b$slope, ref)
  expect_lt(b$lower, b$slope)
  expect_gt(b$upper, b$slope)
  two <- rbind(transform(d, tr = "a"), transform(d, tr = "b"))
  t2 <- beta_decay_boot(two, nboot = 99, group = tr, seed = 1)
  expect_equal(nrow(t2), 3)
  expect_equal(t2$slope[3], 0, tolerance = 1e-12)
  expect_error(beta_decay_boot(png_frogs), "beta_decay")
})
