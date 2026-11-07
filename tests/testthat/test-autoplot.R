test_that("autoplot methods return ggplots", {
  skip_if_not_installed("ggplot2")
  curves <- div_rarefy(toy(), q = c(0, 1), knots = 10)
  expect_s3_class(ggplot2::autoplot(curves), "ggplot")
  expect_s3_class(ggplot2::autoplot(curves, x = "coverage"), "ggplot")
  decay <- beta_decay(png_ants, elevation, .by = season)
  expect_s3_class(ggplot2::autoplot(decay), "ggplot")
})

test_that("autoplot covers every result type", {
  skip_if_not_installed("ggplot2")
  is_gg <- function(x) expect_s3_class(x, "ggplot")
  hill <- div_hill(png_ants, q = c(0, 1, 2), .by = c(season, elevation))
  is_gg(ggplot2::autoplot(hill))
  is_gg(ggplot2::autoplot(hill, gradient = elevation))
  expect_snapshot(ggplot2::autoplot(hill, gradient = site), error = TRUE)
  set.seed(1)
  is_gg(ggplot2::autoplot(div_estimate(toy(), nboot = 5)))
  is_gg(ggplot2::autoplot(div_coverage(png_ants, .by = season)))
  is_gg(ggplot2::autoplot(beta_pair(png_ants, .by = season)))
  is_gg(ggplot2::autoplot(beta_pair(toy()), component = "turnover"))
  is_gg(ggplot2::autoplot(beta_multi(png_ants, .by = season)))
  expect_s3_class(hill, "td_hill")
  expect_s3_class(dplyr::filter(hill, q == 0), "td_hill")
})

test_that("plots keep every row: no data dropped by axis limits", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  plots <- list(
    ggplot2::autoplot(beta_decay(png_ants, elevation, .by = season)),
    ggplot2::autoplot(beta_decay(png_frogs, gradient = elevation)),
    ggplot2::autoplot(div_rarefy(png_ants, q = c(0, 1), .by = season, nboot = 10)),
    ggplot2::autoplot(div_hill(png_ants, q = seq(0, 3, by = 0.5), .by = season))
  )
  for (p in plots) expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("plots are always on a white background", {
  skip_if_not_installed("ggplot2")
  th <- theme_tidydiversity()
  expect_equal(th$plot.background$fill, "white")
  expect_equal(th$panel.background$fill, "white")
  p <- ggplot2::autoplot(beta_pair(png_ants, .by = season))
  expect_equal(ggplot2::calc_element("plot.background", p$theme)$fill, "white")
})

test_that("fixed-aspect plots are drawn on an opaque white device", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("vegan")
  skip_if_not_installed("png")
  ord <- ord_fit(png_frogs, method = "cca", formula = ~elevation)
  p <- ggplot2::autoplot(ord)
  expect_s3_class(p, "td_gg")
  f <- tempfile(fileext = ".png")
  grDevices::png(f, 700, 300, bg = "transparent")
  print(p)
  grDevices::dev.off()
  img <- png::readPNG(f)
  expect_true(all(img[2, 2, ] == 1))
  expect_s3_class(ggplot2::autoplot(beta_pair(png_ants)), "td_gg")
})

test_that("autoplot methods give plots default alt text", {
  skip_if_not_installed("ggplot2")
  r <- div_rarefy(png_ants, q = 0, .by = season, knots = 5)
  p <- ggplot2::autoplot(r)
  expect_match(ggplot2::get_alt_text(p), "^Plot of .+ against .+\\.$")
  custom <- ggplot2::autoplot(div_hill(png_ants, .by = season)) +
    ggplot2::labs(alt = "My description")
  expect_equal(ggplot2::get_alt_text(custom), "My description")
  h <- ggplot2::autoplot(beta_pair(png_ants, .by = season))
  expect_match(ggplot2::get_alt_text(h), "^Heatmap of pairwise")
})
