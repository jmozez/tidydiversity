test_that("as_community() standardises names and sums repeats", {
  df <- tibble::tibble(
    plot = c("x", "x", "y"),
    taxon = c("a", "a", "b"),
    n = c(1, 2, 0)
  )
  out <- as_community(df, plot, taxon, n)
  expect_s3_class(out, "td_community")
  expect_named(out, c("site", "species", "abundance"))
  expect_equal(out$abundance, 3)
})

test_that("rows count as individuals without an abundance column", {
  df <- tibble::tibble(site = c("x", "x", "x"), species = c("a", "a", "b"))
  out <- as_community(df)
  expect_equal(out$abundance, c(2, 1))
})

test_that("community_wide() and community_long() round trip", {
  com <- as_community(ant_gradient, .by = transect)
  wide <- community_wide(com, .by = transect)
  expect_equal(nrow(wide), 16)
  back <- community_long(wide, -c(transect, site))
  expect_equal(
    dplyr::arrange(tibble::as_tibble(back), transect, site, species),
    dplyr::arrange(tibble::as_tibble(com), transect, site, species),
    ignore_attr = TRUE
  )
})

test_that("community print header is informative", {
  expect_snapshot(as_community(toy()))
})

test_that("input errors are informative", {
  expect_snapshot(error = TRUE, {
    as_community(1:3)
    as_community(toy(), site = c(site, species))
    as_community(toy(), abundance = species)
    as_community(dplyr::mutate(toy(), abundance = -1))
    div_estimate(dplyr::mutate(toy(), abundance = 1.5))
    as_community(dplyr::group_by(toy(), site), .by = species)
    div_estimate(toy(), q = 3)
    div_standardise(toy(), coverage = 0.9, size = 10)
  })
})
