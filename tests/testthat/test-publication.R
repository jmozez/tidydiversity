test_that("autoplot options give customisable ggplots", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  curves <- div_rarefy(toy(), q = c(0, 1), knots = 10, nboot = 5)
  p <- ggplot2::autoplot(curves, palette = "grey", facet = FALSE,
    xlab = "Workers")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Workers")
  expect_s3_class(ggplot2::autoplot(curves, palette = c("red", "blue"),
    theme = NULL, ci = FALSE), "ggplot")
  expect_error(ggplot2::autoplot(curves, palette = 1), "palette")
  std <- div_standardise(ant_gradient, .by = transect, nboot = 5)
  expect_s3_class(std, "td_standardise")
  expect_s3_class(ggplot2::autoplot(std), "ggplot")
  expect_s3_class(theme_tidydiversity(grid = "none"), "theme")
  expect_length(td_palette(3), 3)
  expect_length(td_palette(12), 12)
  expect_length(td_palette(4, "grey"), 4)
})

test_that("div_table() formats estimates in APA style", {
  set.seed(1)
  est <- div_estimate(toy(), nboot = 10)
  tab <- div_table(est, digits = 1)
  expect_match(tab[["Estimate [95% CI]"]][1],
    "^[0-9]+\\.[0-9] \\[[0-9]+\\.[0-9], [0-9]+\\.[0-9]\\]$")
  wide <- div_table(est, wide = TRUE)
  expect_equal(nrow(wide), 2)
  expect_true("estimate (q = 0)" %in% names(wide))
  expect_match(div_table(est, ci_style = "pm")[[4]][1], "\u00b1")
  expect_s3_class(div_table(est, output = "kable"), "knitr_kable")
  skip_if_not_installed("flextable")
  expect_s3_class(div_table(est, output = "flextable"), "flextable")
  expect_s3_class(div_table(div_coverage(toy())), "tbl_df")
})

test_that("tidy() and add_site_data() give model-ready output", {
  set.seed(1)
  est <- div_estimate(ant_gradient, q = 0, nboot = 10)
  td <- generics::tidy(add_site_data(est, ant_gradient))
  expect_true(all(c("estimate", "std.error", "conf.low", "conf.high",
    "weight", "elevation", "transect") %in% names(td)))
  expect_equal(nrow(td), length(unique(ant_gradient$site)))
  expect_equal(td$weight, 1 / td$std.error^2)
  expect_error(add_site_data(est, ant_gradient, cols = species),
    "constant")
})

test_that("div_boot() returns replicates", {
  set.seed(1)
  b <- div_boot(toy(), q = c(0, 2), nboot = 15)
  expect_equal(nrow(b), 2 * 2 * 15)
  expect_named(b, c("site", "q", ".draw", "diversity"))
  s <- generics::tidy(b)
  expect_equal(s$nboot, rep(15L, 4))
  b2 <- div_boot(toy(), q = 0, type = "standardised", size = 10, nboot = 5)
  expect_true(all(b2$m == 10))
})

test_that("beta_decay() accepts coordinates and beta_dist() builds dist", {
  df <- ant_gradient
  df$x <- df$elevation / 100
  df$y <- 0
  d1 <- beta_decay(df, gradient = elevation, .by = transect)
  d2 <- beta_decay(df, gradient = c(x, y), .by = transect)
  expect_equal(d2$distance, d1$distance / 100)
  expect_false("gradient_1" %in% names(d2))
  north <- beta_pair(ant_gradient[ant_gradient$transect == "north", ])
  d <- beta_dist(north, "turnover")
  expect_s3_class(d, "dist")
  expect_equal(attr(d, "Size"), 8L)
  expect_error(beta_dist(beta_pair(ant_gradient, .by = transect)),
    "single group")
})

test_that("grouped results are not drawn on top of each other", {
  skip_if_not_installed("ggplot2")
  curves <- div_rarefy(ant_gradient, q = 0, knots = 5, .by = transect)
  p <- ggplot2::autoplot(curves)
  expect_s3_class(p$facet, "FacetGrid")
  b <- ggplot2::ggplot_build(p)
  expect_equal(length(unique(b$data[[1]]$group)),
    2 * length(unique(ant_gradient$site)))
  hill <- div_hill(ant_gradient, .by = transect)
  expect_s3_class(ggplot2::autoplot(hill)$facet, "FacetWrap")
  single <- div_hill(toy())
  expect_s3_class(ggplot2::autoplot(single)$facet, "FacetNull")
})
