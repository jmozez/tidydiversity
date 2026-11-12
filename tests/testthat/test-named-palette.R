test_that("a named palette colours categories by name", {
  skip_if_not_installed("ggplot2")
  est <- div_rarefy(png_ants, q = 0, .by = season, knots = 5)
  sites <- sort(unique(est$site))
  pal <- stats::setNames(grDevices::hcl.colors(length(sites)), rev(sites))
  b <- suppressWarnings(ggplot2::ggplot_build(ggplot2::autoplot(est, palette = pal)))
  sc <- b$plot$scales$get_scales("colour")
  expect_equal(sc$map(sites), unname(pal[sites]))
})

test_that("a named palette missing a category is an error, not grey", {
  skip_if_not_installed("ggplot2")
  est <- div_rarefy(png_ants, q = 0, .by = season, knots = 5)
  expect_error(ggplot2::autoplot(est, palette = c(MW0200 = "red")), "no colour for")
})
