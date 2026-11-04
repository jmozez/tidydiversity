ants <- dplyr::mutate(png_ants,
  unit = paste(site, season, transect),
  zone = ifelse(elevation <= 700, "lowland", "montane")
)
wide <- function() {
  p <- comm_prep(ants, rlang::quo(unit), rlang::quo(species),
                 rlang::quo(NULL), NULL, ~ elevation + season, "none")
  list(y = p$y, env = as.data.frame(p$env))
}

test_that("beta_permanova matches vegan::adonis2", {
  skip_if_not_installed("vegan")
  w <- wide()
  set.seed(4)
  ours <- beta_permanova(ants, site = unit, formula = ~ elevation + season,
                         permutations = 99)
  set.seed(4)
  ref <- vegan::adonis2(w$y ~ elevation + season, data = w$env,
                        by = "terms", permutations = 99)
  expect_equal(ours$r2, ref$R2)
  expect_equal(ours$statistic, ref$F)
  expect_equal(ours$p.value, ref$`Pr(>F)`)
  expect_error(beta_permanova(ants, site = unit, formula = y ~ x), "one-sided")
})

test_that("beta_dispersion matches vegan::betadisper and plots", {
  skip_if_not_installed("vegan")
  w <- wide()
  d <- beta_dispersion(ants, site = unit, group = season, permutations = 99)
  ref <- vegan::betadisper(vegan::vegdist(w$y), factor(w$env$season))
  expect_equal(d$distance, unname(ref$distances))
  expect_s3_class(attr(d, "test"), "tbl_df")
  skip_if_not_installed("ggplot2")
  expect_s3_class(ggplot2::autoplot(d), "ggplot")
  expect_output(print(d), "Permutation test")
})

test_that("ord_varpart matches vegan::varpart", {
  skip_if_not_installed("vegan")
  w <- wide()
  vp <- ord_varpart(ants, site = unit, elevation = ~elevation,
                    season = ~season, permutations = 99)
  ref <- vegan::varpart(vegan::decostand(w$y, "hellinger"),
                        ~elevation, ~season, data = w$env)
  expect_equal(vp$adj_r2, ref$part$indfract$Adj.R.square)
  expect_equal(vp$label[1:2], c("elevation only", "season only"))
  expect_true(vp$p.value[1] < 0.05)
  expect_error(ord_varpart(ants, site = unit, a = ~elevation), "two to four")
})

test_that("ord_select selects elevation with double stopping", {
  skip_if_not_installed("vegan")
  set.seed(1)
  s <- ord_select(ants, site = unit, formula = ~ elevation + season,
                  permutations = 99)
  expect_equal(s$term[1], "elevation")
  expect_true(all(s$adj_r2 <= attr(s, "adj_r2_full") + 1e-12))
  s2 <- ord_select(ants, site = unit, formula = ~ elevation + season,
                   method = "dbrda", permutations = 99)
  expect_s3_class(s2, "tbl_df")
})

test_that("beta_indicator returns tidy indicator values", {
  skip_if_not_installed("indicspecies")
  set.seed(1)
  ind <- beta_indicator(ants, site = unit, group = zone, permutations = 99,
                        alpha = 1)
  expect_named(ind, c("species", "group", "stat", "A", "B", "p.value"))
  expect_true(all(ind$A >= 0 & ind$A <= 1))
  expect_equal(ind$stat, sqrt(ind$A * ind$B), tolerance = 1e-8)
  r <- beta_indicator(ants, site = unit, group = zone, func = "r.g",
                      permutations = 99, alpha = 1)
  expect_false("A" %in% names(r))
})
