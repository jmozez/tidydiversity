butterflies <- function() {
  b <- wanang_butterflies
  b$year <- factor(paste("Year", b$year))
  b
}

vegan_inputs <- function(b) {
  y <- as.matrix(stats::xtabs(abundance ~ site + species, b))
  class(y) <- "matrix"
  env <- unique(as.data.frame(b[c("site", "year", "month")]))
  env <- env[match(rownames(y), env$site), ]
  list(y = y, env = env)
}

same_scores <- function(ord, ref, display, scaling) {
  tab <- if (display == "sites") ord$sites else ord$species
  ours <- as.matrix(tab[c("axis1", "axis2")])
  theirs <- vegan::scores(ref, display = display, choices = 1:2, scaling = scaling)
  theirs <- theirs[match(tab[[1]], rownames(theirs)), , drop = FALSE]
  expect_equal(unname(ours), unname(theirs), tolerance = 1e-8)
}

test_that("constrained ordinations reproduce vegan", {
  skip_if_not_installed("vegan")
  b <- butterflies()
  v <- vegan_inputs(b)
  h <- vegan::decostand(v$y, "hellinger")
  rda <- ord_fit(b, method = "rda", formula = ~ year + month)
  ref <- vegan::rda(h ~ year + month, v$env)
  same_scores(rda, ref, "sites", 2)
  same_scores(rda, ref, "species", 2)
  expect_equal(glance(rda)$constrained, ref$CCA$tot.chi / ref$tot.chi)
  expect_setequal(rda$centroids$level, c("Year 1", "Year 2", "Year 3"))
  expect_equal(rda$vectors$term, "month")

  cca <- ord_fit(b, method = "cca", formula = ~ year + month, scaling = "sites")
  same_scores(cca, vegan::cca(v$y ~ year + month, v$env), "sites", 1)
  db <- ord_fit(b, method = "dbrda", formula = ~year)
  same_scores(db, vegan::capscale(v$y ~ year, v$env, distance = "bray"), "sites", 2)
})

test_that("unconstrained ordinations reproduce vegan", {
  skip_if_not_installed("vegan")
  b <- butterflies()
  v <- vegan_inputs(b)
  pca <- ord_fit(b, method = "pca", scaling = "symmetric")
  same_scores(pca, vegan::rda(vegan::decostand(v$y, "hellinger")), "sites", 3)
  ca <- ord_fit(b, method = "ca")
  same_scores(ca, vegan::cca(v$y), "species", 2)
  pcoa <- ord_fit(b, method = "pcoa", distance = "jaccard")
  same_scores(pcoa, vegan::capscale(v$y ~ 1, distance = "jaccard"), "sites", 2)
  dca <- ord_fit(b, method = "dca")
  ref <- vegan::scores(vegan::decorana(v$y), display = "sites", choices = 1:2)
  expect_equal(
    unname(as.matrix(dca$sites[c("axis1", "axis2")])),
    unname(ref[dca$sites$site, ]),
    tolerance = 1e-8
  )
  expect_equal(sum(pca$axes$explained > 0), nrow(pca$axes))
})

test_that("NMDS and passive variables work", {
  skip_if_not_installed("vegan")
  set.seed(1)
  nmds <- ord_fit(butterflies(), method = "nmds", formula = ~ month + year)
  expect_true(is.finite(nmds$stress) && nmds$stress < 0.3)
  expect_equal(nmds$vectors$term, "month")
  expect_named(nmds$envfit, c("term", "type", "r2", "p.value", "axes", "permutations", "exact"))
  expect_true(all(nmds$envfit$p.value > 0 & nmds$envfit$p.value <= 1))
  expect_equal(glance(nmds)$method, "nmds")
  expect_s3_class(tidy(nmds, "envfit"), "tbl_df")
})

test_that("site variables are found automatically or from env", {
  skip_if_not_installed("vegan")
  ord <- ord_fit(png_frogs, method = "cca", formula = ~elevation)
  expect_true("elevation" %in% names(ord$sites))
  env <- data.frame(site = unique(png_frogs$site), zone = rep(c("low", "high"), each = 4))
  ord2 <- ord_fit(png_frogs, method = "rda", formula = ~zone, env = env)
  expect_setequal(ord2$centroids$level, c("high", "low"))
  expect_error(ord_fit(png_frogs, method = "rda"), "formula")
  expect_error(ord_fit(png_frogs, method = "rda", formula = ~nothing), "nothing")
  expect_error(ord_test(ord_fit(png_frogs, method = "ca")), "constrained")
})

test_that("permutation tests are tidy", {
  skip_if_not_installed("vegan")
  set.seed(1)
  ord <- ord_fit(butterflies(), method = "rda", formula = ~ year + month)
  t1 <- ord_test(ord, permutations = 99)
  expect_named(t1, c("term", "df", "variance", "statistic", "p.value"))
  t2 <- ord_test(ord, by = "terms", permutations = 99)
  expect_equal(t2$term, c("year", "month", "Residual"))
  cca <- ord_fit(butterflies(), method = "cca", formula = ~month)
  expect_true("chi_square" %in% names(ord_test(cca, permutations = 99)))
})

test_that("ordination plots render without warnings", {
  skip_if_not_installed("vegan")
  skip_if_not_installed("ggplot2")
  set.seed(1)
  b <- butterflies()
  rda <- ord_fit(b, method = "rda", formula = ~ year + month)
  nmds <- ord_fit(b, method = "nmds", formula = ~month)
  ca <- ord_fit(png_frogs, method = "ca", formula = ~elevation)
  plots <- list(
    ggplot2::autoplot(rda, colour = year, ellipse = "sd"),
    ggplot2::autoplot(rda, colour = year, ellipse = "se", hull = TRUE, spider = TRUE),
    ggplot2::autoplot(nmds, colour = month, group = year, ellipse = "ci"),
    ggplot2::autoplot(ca, colour = elevation, site_labels = TRUE, species = Inf),
    ggplot2::autoplot(rda, axes = c(1, 3), species = 0, arrows = FALSE)
  )
  for (p in plots) {
    expect_s3_class(p, "ggplot")
    expect_no_warning(ggplot2::ggplotGrob(p))
  }
  expect_error(ggplot2::autoplot(rda, ellipse = "sd"), "groups")
  expect_error(ggplot2::autoplot(rda, axes = c(1, 9)), "axes")
})

test_that("groups too small for ellipses or hulls are skipped", {
  skip_if_not_installed("vegan")
  skip_if_not_installed("ggplot2")
  ord <- ord_fit(png_frogs, method = "ca", formula = ~elevation)
  env_pairs <- ord$sites
  env_pairs$pair <- rep(c("a", "b", "c", "d"), each = 2)
  ord$sites <- env_pairs
  expect_warning(
    p <- ggplot2::autoplot(ord, colour = pair, ellipse = "sd", hull = TRUE),
    "3 or more"
  )
  expect_no_warning(ggplot2::ggplotGrob(p))
})
