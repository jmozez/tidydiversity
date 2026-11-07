even <- tibble::tibble(site = "a", species = letters[1:5], n = rep(4, 5))

test_that("an even community has evenness 1 for every class", {
  e <- div_evenness(even,
    abundance = n, q = c(0.5, 1, 2), method = "observed",
    nboot = 0
  )
  expect_equal(e$evenness, rep(1, nrow(e)))
})

test_that("a singleton-free sample has completeness 1 at q = 0", {
  x <- tibble::tibble(site = "a", species = letters[1:4], n = c(2, 3, 5, 9))
  expect_equal(div_completeness(x, abundance = n, q = 0, nboot = 0)$completeness, 1)
})

test_that("completeness and evenness match iNEXT.4steps", {
  skip_on_cran()
  skip_if_not_installed("iNEXT.4steps")
  e <- new.env()
  utils::data("Data_spider", package = "iNEXT.4steps", envir = e)
  d <- e$Data_spider
  long <- tibble::tibble(
    site = rep(colnames(d), each = nrow(d)),
    species = rep(paste0("sp", seq_len(nrow(d))), ncol(d)),
    n = unlist(d, use.names = FALSE)
  )
  long <- long[long$n > 0, ]
  q <- seq(0, 2, 0.25)
  ref <- iNEXT.4steps::Completeness(d, q = q, nboot = 0)
  ref <- ref[order(ref$Assemblage, ref$Order.q), ]
  ours <- div_completeness(long, abundance = n, q = q, nboot = 0)
  ours <- ours[order(ours$site, ours$q), ]
  expect_equal(ours$completeness, ref$Estimate.SC, tolerance = 1e-6)
  for (meth in c("Estimated", "Observed")) {
    ref <- iNEXT.4steps::Evenness(d, q = q, nboot = 0, method = meth)
    ours <- div_evenness(long, abundance = n, q = q, nboot = 0, method = tolower(meth))
    for (k in 1:5) {
      r <- ref[[k]]
      r <- r[order(r$Assemblage, r$Order.q), ]
      o <- ours[ours$class == paste0("E", k), ]
      o <- o[order(o$site, o$q), ]
      expect_equal(o$evenness, r$Evenness, tolerance = 1e-6)
    }
  }
})

test_that("bootstrap intervals and plots work", {
  set.seed(1)
  cmp <- div_completeness(png_ants, q = c(0, 1, 2), .by = season, nboot = 10)
  expect_true(all(cmp$lower <= cmp$completeness & cmp$upper <= 1))
  skip_if_not_installed("ggplot2")
  expect_s3_class(ggplot2::autoplot(cmp), "ggplot")
  ev <- div_evenness(png_ants, q = c(0, 1, 2), .by = season, nboot = 0)
  expect_s3_class(ggplot2::autoplot(ev), "ggplot")
  expect_named(ev, c(
    "season", "site", "class", "q", "evenness", "se", "lower", "upper",
    "coverage"
  ))
})

test_that("div_completeness warns about singleton-only samples", {
  d <- data.frame(site = "a", species = letters[1:10], abundance = 1)
  expect_warning(
    out <- div_completeness(d, q = c(0, 1), nboot = 0),
    "only singletons"
  )
  expect_equal(nrow(out), 2)
})
