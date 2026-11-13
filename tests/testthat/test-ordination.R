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

test_that("continuous site variables are drawn as lines or sizes, not colour bars", {
  skip_if_not_installed("ggplot2")
  o <- ord_fit(png_frogs, abundance = abundance, method = "pca", transform = "hellinger")
  # A linear trend surface of an exact plane is recovered exactly
  x <- o$sites$axis1
  y <- o$sites$axis2
  srf <- suppressWarnings(ord_surface(x, y, 2 * x + 3 * y))
  expect_equal(srf$model, "linear trend surface")
  expect_equal(srf$dev_expl, 1)
  expect_gt(nrow(srf$lines), 0)
  p <- ggplot2::autoplot(o, surface = elevation, size = elevation, species = 0)
  expect_s3_class(p, "ggplot")
  expect_match(p$labels$caption, "linear trend surface")
  scales <- vapply(p$scales$scales, function(s) class(s)[1], character(1))
  expect_false(any(grepl("ScaleContinuous", scales) & grepl("colour", scales)))
  expect_error(ggplot2::autoplot(o, surface = site), "numeric")
  # Numeric colour becomes classes (one per elevation)
  q <- ggplot2::autoplot(o, colour = elevation, species = 0)
  b <- ggplot2::ggplot_build(q)
  fills <- unlist(lapply(b$data, function(d) if ("fill" %in% names(d)) unique(d$fill)))
  expect_gte(length(unique(fills)), 8)
})

test_that("every ordination plot type draws", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  d <- png_frogs
  rich <- tapply(d$species[d$abundance > 0], d$site[d$abundance > 0], function(x) length(unique(x)))
  d$richness <- as.numeric(rich[d$site])
  o <- ord_fit(d, abundance = abundance, method = "pca", formula = ~ elevation + richness, seed = 1)
  expect_s3_class(ggplot2::autoplot(o, type = "gradient", path = elevation), "patchwork")
  r <- ggplot2::autoplot(o, type = "response", variable = "elevation", species = 4)
  expect_s3_class(r, "ggplot")
  b <- ggplot2::ggplot_build(r)
  rib <- b$data[[1]]
  expect_true(all(rib$ymin <= rib$ymax))
  expect_true(all(rib$ymin >= 0))
  expect_s3_class(ggplot2::autoplot(o, type = "response", axis = 1, layout = "overlay"), "ggplot")
  expect_s3_class(ggplot2::autoplot(o, type = "scree"), "ggplot")
  expect_s3_class(ggplot2::autoplot(o, type = "tvalue", variable = "elevation"), "ggplot")
  n <- ord_fit(d, abundance = abundance, method = "nmds", seed = 1)
  expect_s3_class(ggplot2::autoplot(n, type = "shepard"), "ggplot")
  expect_error(ggplot2::autoplot(n, type = "scree"), "eigenvalues")
  expect_error(ggplot2::autoplot(o, type = "shepard"), "NMDS")
})

test_that("response curves come from the GLM on the link scale", {
  o <- ord_fit(png_frogs, abundance = abundance, method = "pca")
  p <- ggplot2::autoplot(o, type = "response", axis = 1, species = 1)
  cur <- ggplot2::ggplot_build(p)$data[[2]]
  sp <- levels(p$data$species)[1]
  x <- o$sites$axis1
  y <- o$community[as.character(o$sites$site), sp]
  z <- (x - mean(x)) / stats::sd(x)
  g <- stats::glm(y ~ z + I(z^2), family = stats::poisson())
  nd <- data.frame(z = (cur$x - mean(x)) / stats::sd(x))
  expect_equal(cur$y, unname(stats::predict(g, nd, type = "response")), tolerance = 1e-6)
})

test_that("principal response curves match vegan and draw", {
  skip_if_not_installed("vegan")
  set.seed(1)
  p <- ord_prc(portal_rodents,
    treatment = treatment, time = year, abundance = abundance, permutations = 49
  )
  expect_s3_class(p, "td_prc")
  expect_true(all(p$curves$coefficient[p$curves$treatment == "control"] == 0))
  expect_equal(nrow(p$curves), 3 * 4)
  ref <- summary(p$fit)$coefficients
  got <- p$curves[p$curves$treatment == "removal", ]
  expect_equal(unname(got$coefficient), unname(ref["removal", ]))
  expect_s3_class(ggplot2::autoplot(p), "patchwork")
})

test_that("variation partitioning has a diagram", {
  skip_if_not_installed("vegan")
  a <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
  v <- suppressWarnings(ord_varpart(a,
    site = unit, abundance = workers,
    Elevation = ~elevation, Season = ~season, permutations = 49
  ))
  expect_s3_class(v, "td_varpart")
  expect_equal(attr(v, "sets"), c("Elevation", "Season"))
  expect_s3_class(ggplot2::autoplot(v), "ggplot")
})

test_that("Van Dobben, stability and inset diagrams build on the dune data", {
  skip_if_not_installed("vegan")
  skip_if_not_installed("patchwork")
  data("dune", package = "vegan", envir = environment())
  data("dune.env", package = "vegan", envir = environment())
  d <- community_long(cbind(site = rownames(dune), dune.env, dune),
    cols = dplyr::all_of(names(dune))
  )
  o <- ord_fit(d, abundance = abundance, method = "rda", formula = ~ A1 + Moisture + Management)
  p <- ggplot2::autoplot(o, type = "vandobben", variable = "A1")
  expect_s3_class(p, "ggplot")
  b <- ggplot2::ggplot_build(p)
  expect_true(any(grepl("Comapalu", unlist(lapply(b$data, function(x) x$label)))))
  expect_error(ggplot2::autoplot(o, type = "vandobben", variable = "nope"), "variable")
  u <- ord_fit(d, abundance = abundance, method = "pca")
  set.seed(1)
  s <- ggplot2::autoplot(u, type = "stability", nboot = 19)
  expect_s3_class(s, "ggplot")
  expect_error(ggplot2::autoplot(o, type = "stability", nboot = 5), "unconstrained")
  n <- ord_fit(d, abundance = abundance, method = "nmds")
  expect_s3_class(ggplot2::autoplot(n, inset = "shepard"), "patchwork")
})

test_that("ord_advise() follows the question and the gradient length", {
  skip_if_not_installed("vegan")
  data("dune", package = "vegan", envir = environment())
  data("dune.env", package = "vegan", envir = environment())
  d <- community_long(cbind(site = rownames(dune), dune.env, dune),
    cols = dplyr::all_of(names(dune))
  )
  a <- ord_advise(d, abundance = abundance)
  expect_s3_class(a, "td_ord_advice")
  expect_identical(a$question, "explore")
  expect_match(a$advice$recommendation[1], "Unconstrained")
  # gradient length equals vegan's DCA axis 1 on log(x + 1)
  y <- as.matrix(dune)
  ref <- diff(range(vegan::scores(vegan::decorana(log1p(y)), display = "sites", choices = 1)))
  expect_equal(a$gradient_length, unname(ref), tolerance = 1e-6)
  e <- ord_advise(d, abundance = abundance, formula = ~ A1 + Management)
  expect_identical(e$question, "explain")
  expect_match(e$advice$recommendation[1], "Constrained")
  g <- ord_advise(d, abundance = abundance, formula = ~Management)
  expect_identical(g$question, "groups")
  expect_true(any(grepl("beta_permanova", g$advice$code)))
  expect_output(print(e), NA)
})
