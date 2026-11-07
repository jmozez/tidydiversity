test_that("basal area matches pi/4 * dbh^2", {
  stems <- tibble::tibble(
    treeID = 1:3, stemID = 1:3,
    gx = 1:3, gy = 1:3,
    dbh = c(10, 20, 30),
    species = c("a", "b", "a"),
    status = "A"
  )
  ba <- stems_basal_area(stems, dbh_unit = "mm")
  expect_equal(ba$basal_area, sum(pi / 4 * stems$dbh^2))
  by_sp <- stems_basal_area(stems, dbh_unit = "mm", .by = species)
  expect_equal(
    by_sp$basal_area[by_sp$species == "a"],
    sum(pi / 4 * c(10, 30)^2)
  )
})

test_that("stems_as_trees picks the largest stem", {
  stems <- tibble::tibble(
    treeID = c(1, 1, 2),
    stemID = c("1.1", "1.2", "2.1"),
    dbh = c(10, 40, 15),
    species = "a",
    status = "A",
    gx = 1:3, gy = 1:3
  )
  trees <- stems_as_trees(stems)
  expect_equal(nrow(trees), 2)
  expect_equal(trees$dbh[trees$treeID == 1], 40)
})

test_that("stems_abundance and size_class work", {
  stems <- stems_fixture(50)
  ab <- stems_abundance(stems, .by = species, level = "tree")
  expect_true(all(c("species", "n") %in% names(ab)))
  alive_trees <- dplyr::n_distinct(stems$treeID[stems$status == "A"])
  expect_equal(sum(ab$n), alive_trees)
  sc <- stems_size_class(stems, breaks = c(10, 50, 100, Inf), dbh_unit = "mm")
  expect_true("size_class" %in% names(sc))
  expect_equal(sum(sc$n), sum(stems$status == "A"))
})

test_that("stems_demography recovers mortality and growth signs", {
  cens <- censuses_fixture(n = 60, seed = 3, time = 5)
  dem <- stems_demography(
    cens$census1, cens$census2,
    time = 5, dbh_unit = "mm", mindbh = 0
  )
  expect_gt(dem$N, 0)
  expect_gte(dem$D, 1)
  expect_gte(dem$R, 1)
  expect_true(is.finite(dem$mortality_rate))
  expect_gt(dem$growth_rate, 0)
})

test_that("stems_as_community feeds div_hill()", {
  stems <- stems_fixture(80)
  stems$quadrat <- paste(floor(stems$gx / 20), floor(stems$gy / 20))
  com <- stems_as_community(stems, level = "tree")
  expect_s3_class(com, "td_community")
  h <- div_hill(com, q = 0)
  expect_true(all(h$diversity >= 1))
})
