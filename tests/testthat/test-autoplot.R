test_that("autoplot methods return ggplots", {
  skip_if_not_installed("ggplot2")
  curves <- div_rarefy(toy(), q = c(0, 1), knots = 10)
  expect_s3_class(ggplot2::autoplot(curves), "ggplot")
  expect_s3_class(ggplot2::autoplot(curves, x = "coverage"), "ggplot")
  decay <- beta_decay(ant_gradient, elevation, .by = transect)
  expect_s3_class(ggplot2::autoplot(decay), "ggplot")
})
