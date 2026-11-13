test_that("div_invasion counts native and alien species and abundance", {
  d <- data.frame(
    site = rep(c("a", "b"), each = 4),
    species = c("s1", "s2", "s3", "s4", "s1", "s5", "s6", "s7"),
    status = c("native", "native", "native", "Alien", "native", "introduced", "alien", "native"),
    count = c(10, 5, 3, 2, 4, 20, 6, 0)
  )
  r <- div_invasion(d, status = status, abundance = count)
  expect_equal(r$richness, c(4, 3))
  expect_equal(r$alien, c(1, 2))
  expect_equal(r$native, c(3, 1))
  expect_equal(r$alien_share, c(1 / 4, 2 / 3))
  expect_equal(r$alien_abundance_share, c(2 / 20, 26 / 30))
})

test_that("div_homogenisation matches vegan similarities and splits the alien part", {
  skip_if_not_installed("vegan")
  set.seed(3)
  sp <- paste0("s", 1:20)
  mk <- function(p) {
    do.call(rbind, lapply(1:6, function(i) {
      data.frame(site = i, species = sp[stats::runif(20) < p], status = "native")
    }))
  }
  before <- mk(0.3)
  after <- rbind(before, data.frame(site = 1:6, species = "alien1", status = "alien"))
  h <- div_homogenisation(before, after, status = status, nboot = 199, seed = 1)
  m <- as.matrix(table(before$site, before$species) > 0) * 1
  jb <- 1 - as.matrix(vegan::vegdist(m, "jaccard", binary = TRUE))
  expect_equal(h$similarity_before[1], mean(jb[lower.tri(jb)]))
  expect_gt(h$change[1], 0)
  expect_equal(h$change[2], 0)
  expect_equal(attr(h, "alien_contribution"), h$change[1])
  expect_true(h$lower[1] <= h$change[1] && h$change[1] <= h$upper[1])
  s <- div_homogenisation(before, after, index = "sorensen", nboot = 9)
  sb <- 1 - as.matrix(vegan::vegdist(m, "bray", binary = TRUE))
  expect_equal(s$similarity_before, mean(sb[lower.tri(sb)]))
})
