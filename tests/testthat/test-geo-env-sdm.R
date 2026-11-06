test_that("geo_distance environmental Euclidean matches scaled reference", {
  sites <- tibble::tibble(
    site = c("a", "b", "c"),
    lon = c(147, 147.1, 147.2),
    lat = c(-9.4, -9.5, -9.6),
    bio1 = c(10, 20, 30),
    bio12 = c(100, 200, 400)
  )
  d <- geo_distance(sites, method = "environmental", vars = c("bio1", "bio12"),
                    scale = TRUE, metric = "euclidean")
  expect_s3_class(d, "td_geo_distance")
  expect_equal(nrow(d), 3)
  # Manual scaled Euclidean a-b
  x <- scale(as.matrix(sites[c("bio1", "bio12")]))
  ref <- sqrt(sum((x[1, ] - x[2, ])^2))
  ab <- d$distance[d$site_1 == "a" & d$site_2 == "b"]
  expect_equal(ab, ref, tolerance = 1e-6)
})

test_that("geo_decay environmental feeds beta_decay_model", {
  sites <- unique(png_ants[c("site", "elevation", "season")])
  sites$lon <- 145.0 + sites$elevation / 1e5
  sites$lat <- -5.8 - sites$elevation / 2e5
  sites$bio1 <- 25 - sites$elevation / 400
  com <- dplyr::left_join(
    png_ants, sites[c("site", "season", "lon", "lat", "bio1")],
    by = c("site", "season")
  )
  decay <- geo_decay(
    dplyr::filter(com, season == "wet"),
    lon, lat, method = "environmental", vars = "bio1", .by = NULL
  )
  expect_true("distance" %in% names(decay))
  expect_true(all(is.finite(decay$distance)))
  fit <- beta_decay_model(decay, permutations = 19)
  expect_true(all(c("model", "estimate") %in% names(fit)) ||
                "td_beta_decay_model" %in% class(fit) ||
                is.data.frame(fit))
})

test_that("plot_geo maps Hill numbers with scale bar", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("sf")
  sites <- geo_example_sites()
  # Fake Hill estimates
  est <- dplyr::filter(sites, !is.na(lon))
  est$diversity <- seq_len(nrow(est)) + 5
  p <- plot_geo(est, diversity, lon, lat, basemap = "coast",
                label = site, scale_bar = TRUE)
  expect_s3_class(p, "ggplot")
})

test_that("geo_mem returns positive eigenvectors", {
  set.seed(1)
  g <- expand.grid(lon = 1:5, lat = 1:4)
  g$site <- paste0("s", seq_len(nrow(g)))
  mem <- geo_mem(g, lon, lat, site = site, method = "euclidean")
  expect_s3_class(mem, "td_geo_mem")
  expect_true(any(grepl("^MEM", names(mem))))
  ev <- attr(mem, "eigenvalues")
  expect_true(all(ev > 0))
})

test_that("geo_rarefy_spatial increases with sample size", {
  set.seed(1)
  pts <- expand.grid(x = 1:4, y = 1:3)
  pts$site <- paste0("s", seq_len(nrow(pts)))
  com <- expand.grid(site = pts$site, species = paste0("sp", 1:5),
                     stringsAsFactors = FALSE)
  com$abundance <- rpois(nrow(com), 1.5)
  com <- dplyr::left_join(com, pts, by = "site")
  out <- geo_rarefy_spatial(com, lon = x, lat = y, nperm = 9)
  expect_s3_class(out, "td_geo_rarefy")
  expect_true(all(diff(out$richness_spatial) >= 0))
  expect_true("richness_random" %in% names(out))
})

test_that("geo_grain recomputes Hill numbers at coarser cells", {
  set.seed(1)
  pts <- expand.grid(lon = seq(145, 145.4, by = 0.1),
                     lat = seq(-5.9, -5.5, by = 0.1))
  pts$site <- paste0("s", seq_len(nrow(pts)))
  com <- expand.grid(site = pts$site, species = paste0("sp", 1:6),
                     stringsAsFactors = FALSE)
  com$abundance <- rpois(nrow(com), 2)
  com <- dplyr::left_join(com, pts, by = "site")
  out <- geo_grain(com, grains = c(0.15, 0.3), q = 0)
  expect_s3_class(out, "td_geo_grain")
  expect_true(all(c(0.15, 0.3) %in% out$grain))
  # Coarser grain has fewer cells
  expect_lt(
    dplyr::n_distinct(out$cell[out$grain == 0.3]),
    dplyr::n_distinct(out$cell[out$grain == 0.15])
  )
})

test_that("geo_middomain null envelope covers mid elevations", {
  set.seed(1)
  occ <- expand.grid(
    species = paste0("sp", 1:15),
    elevation = seq(200, 3000, by = 200),
    stringsAsFactors = FALSE
  )
  occ <- dplyr::filter(
    occ,
    elevation >= 200 + (as.integer(factor(species)) - 1) * 40,
    elevation <= 1400 + (as.integer(factor(species)) - 1) * 60
  )
  out <- geo_middomain(occ, nperm = 39, seed = 1)
  expect_s3_class(out, "td_geo_middomain")
  expect_true(all(c("richness", "null_mean", "null_lower", "null_upper") %in% names(out)))
  expect_true(any(out$null_mean > 0))
})

test_that("geo_elevation reads offline path", {
  skip_if_not_installed("terra")
  dem <- geo_example_dem()
  tmp <- tempfile(fileext = ".tif")
  terra::writeRaster(dem, tmp, overwrite = TRUE)
  r <- geo_elevation(path = tmp, download = FALSE)
  expect_s4_class(r, "SpatRaster")
  expect_equal(names(r), "elevation")
})

test_that("stems_habitat_test detects toy association", {
  skip_if_not_installed("terra")
  set.seed(1)
  # Build a clear habitat pattern: species A only in ridge
  stems <- geo_example_stems()
  q <- stems_quadrat(stems)
  hab <- unique(q[c("quadrat", "gx", "gy")])
  hab$habitat <- ifelse(hab$gx >= 50, "ridge", "valley")
  # Force one species onto ridge quadrats only
  stems2 <- stems
  stems2$species <- ifelse(stems2$gx >= 50, "ridge_sp", "valley_sp")
  out <- stems_habitat_test(stems2, habitat = hab, nperm = 99, seed = 1)
  expect_s3_class(out, "td_stems_habitat_test")
  ridge_a <- out[out$species == "ridge_sp" & out$habitat == "ridge", ]
  expect_true(nrow(ridge_a) == 1)
  expect_true(ridge_a$density > ridge_a$null_mean || ridge_a$p_value < 0.2)
})

test_that("sdm_fit glm recovers high-bio1 preference", {
  skip_if_not_installed("terra")
  set.seed(1)
  grid <- expand.grid(
    lon = seq(145, 145.5, length.out = 15),
    lat = seq(-5.9, -5.5, length.out = 12)
  )
  grid$bio1 <- 15 + 12 * (grid$lat - min(grid$lat)) / diff(range(grid$lat))
  # Presence-absence with a clear bio1 threshold
  pa <- grid
  pa$present <- as.integer(pa$bio1 > 22)
  fit <- sdm_fit(pa, predictors = "bio1", present = present, engine = "glm")
  expect_s3_class(fit, "td_sdm")
  coef_bio <- fit$coefficients$estimate[fit$coefficients$term == "bio1"]
  expect_true(coef_bio > 0)
  ev <- sdm_evaluate(fit)
  expect_true(ev$auc > 0.85)
  pred <- sdm_predict(fit, newdata = grid)
  expect_true(mean(pred$suitability[grid$bio1 > 23]) >
                mean(pred$suitability[grid$bio1 < 18]))
})

test_that("sdm maxnet engine predicts without Java", {
  set.seed(2)
  grid <- expand.grid(lon = 1:8, lat = 1:8)
  grid$bio1 <- grid$lon + grid$lat
  occ <- dplyr::filter(grid, bio1 > 10) |> dplyr::slice_sample(n = 20)
  fit <- sdm_fit(occ, predictors = "bio1", engine = "maxnet",
                 n_background = 80, seed = 2, lambda = 1e-3)
  expect_equal(fit$engine, "maxnet")
  pred <- sdm_predict(fit, newdata = grid)
  expect_true(all(pred$suitability >= 0 & pred$suitability <= 1))
  p <- plot_sdm(pred, basemap = "none")
  expect_s3_class(p, "ggplot")
})

test_that("geo_as_features builds site-by-species matrix", {
  out <- geo_as_features(png_ants)
  expect_true("site" %in% names(out) || names(out)[1] == "site")
  expect_gt(ncol(out), 2)
})

test_that("Rcpp euclidean and torus kernels match R", {
  x <- matrix(c(0, 0, 3, 4, 1, 1), nrow = 3, byrow = TRUE)
  if (exists("geo_euclidean_matrix_cpp", mode = "function")) {
    d <- geo_euclidean_matrix_cpp(x)
    expect_equal(d[1, 2], 5, tolerance = 1e-6)
  }
  grid <- as.integer(1:12)
  if (exists("geo_torus_shift_cpp", mode = "function")) {
    s <- geo_torus_shift_cpp(grid, 3, 4, 1, 0)
    # Shift right by 1: original [0,0]=1 moves to [0,1]
    expect_equal(length(s), 12)
    expect_equal(sum(s, na.rm = TRUE), sum(grid))
  }
})

test_that("as_sf and as_spat_raster return CRS-aware objects", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  sites <- geo_example_sites()
  sites <- sites[!is.na(sites$lon), ]
  pts <- as_sf(sites)
  expect_s3_class(pts, "sf")
  expect_false(is.na(sf::st_crs(pts)))
  sites$diversity <- seq_len(nrow(sites))
  r <- as_spat_raster(sites, value = diversity)
  expect_s4_class(r, "SpatRaster")
  expect_true(nzchar(terra::crs(r)))
})

test_that("model_count and plot_partial/plot_surface return tidy/ggplot", {
  skip_if_not_installed("ggplot2")
  set.seed(1)
  ants <- png_ants |>
    dplyr::group_by(site, elevation) |>
    dplyr::summarise(richness = dplyr::n_distinct(species), .groups = "drop")
  ants$litter <- 1 + ants$elevation / 2000 + stats::rnorm(nrow(ants), 0, 0.2)
  fit <- model_count(ants, richness ~ elevation + litter, family = "poisson")
  expect_s3_class(fit, "td_count_model")
  expect_true(all(c("term", "estimate") %in% names(tidy(fit))))
  expect_true("dispersion" %in% names(glance(fit)))
  p1 <- suppressWarnings(plot_partial(fit, elevation, residuals = TRUE))
  expect_s3_class(p1, "ggplot")
  p2 <- suppressWarnings(plot_surface(fit, elevation, litter))
  expect_s3_class(p2, "ggplot")
})
