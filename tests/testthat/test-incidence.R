fish_long <- function() {
  e <- new.env()
  utils::data(list = c(
    "Fish_incidence_data", "Fish_phylo_tree", "Fish_distance_matrix"
  ), package = "iNEXT.3D", envir = e)
  fish <- e$Fish_incidence_data
  long <- do.call(rbind, lapply(names(fish), function(p) {
    m <- fish[[p]]
    w <- which(m > 0, arr.ind = TRUE)
    data.frame(
      site = p, species = rownames(m)[w[, 1]], unit = colnames(m)[w[, 2]],
      n_units = ncol(m)
    )
  }))
  list(
    raw = fish, long = long, tree = e$Fish_phylo_tree,
    dist = as.matrix(e$Fish_distance_matrix)
  )
}

test_that("incidence TD, PD and FD reproduce iNEXT.3D", {
  skip_on_cran()
  skip_if_not_installed("iNEXT.3D")
  skip_if_not_installed("ape")
  f <- fish_long()
  q <- c(0, 1, 2)
  for (dv in c("TD", "PD", "FD")) {
    ref <- suppressMessages(iNEXT.3D::ObsAsy3D(f$raw,
      diversity = dv, q = q, datatype = "incidence_raw", nboot = 0,
      PDtree = f$tree, FDdistM = f$dist, FDtype = "tau_values"
    ))
    ref <- ref[order(ref$Assemblage, ref$Order.q), ]
    ours <- div_estimate(f$long,
      unit = unit, n_units = n_units, type = dv,
      tree = f$tree, distance = f$dist, nboot = 0
    )
    ours <- ours[order(ours$site, ours$q), ]
    col <- paste0("q", dv)
    expect_equal(ours$observed, ref[[col]][ref$Method == "Observed"],
      tolerance = 1e-6
    )
    expect_equal(ours$estimate, ref[[col]][ref$Method == "Asymptotic"],
      tolerance = 1e-6
    )
    sz <- suppressMessages(iNEXT.3D::estimate3D(f$raw,
      diversity = dv, q = q, datatype = "incidence_raw", base = "size",
      level = c(10, 60), nboot = 0, PDtree = f$tree, FDdistM = f$dist,
      FDtype = "tau_values"
    ))
    for (lev in c(10, 60)) {
      mine <- suppressWarnings(div_standardise(f$long,
        unit = unit, n_units = n_units, type = dv, tree = f$tree,
        distance = f$dist, size = lev, nboot = 0
      ))
      mine <- mine[order(mine$site, mine$q), ]
      r <- sz[sz$mT == lev, ]
      r <- r[order(r$Assemblage, r$Order.q), ]
      expect_equal(mine$diversity, r[[col]], tolerance = 1e-6)
    }
  }
})

test_that("incidence coverage and coverage standardisation match iNEXT", {
  skip_on_cran()
  skip_if_not_installed("iNEXT")
  skip_if_not_installed("iNEXT.3D")
  f <- fish_long()
  freq <- lapply(f$raw, function(m) c(ncol(m), rowSums(m)))
  ref <- iNEXT::iNEXT(freq, datatype = "incidence_freq", nboot = 0)$DataInfo
  cov <- div_coverage(f$long, unit = unit, n_units = n_units)
  expect_equal(cov$coverage, ref$SC, tolerance = 1e-4)
  expect_equal(cov$n, c(36, 36))
  std <- suppressMessages(iNEXT.3D::estimate3D(f$raw,
    diversity = "TD", q = c(0, 1, 2), datatype = "incidence_raw",
    base = "coverage", level = 0.95, nboot = 0
  ))
  std <- std[order(std$Assemblage, std$Order.q), ]
  mine <- div_standardise(f$long,
    unit = unit, n_units = n_units, coverage = 0.95, nboot = 0
  )
  mine <- mine[order(mine$site, mine$q), ]
  expect_equal(mine$diversity, std$qTD, tolerance = 1e-6)
  expect_equal(mine$m, std$mT, tolerance = 1e-6)
})

test_that("bait occurrences of png_ants match iNEXT incidence estimates", {
  skip_on_cran()
  skip_if_not_installed("iNEXT")
  ours <- div_estimate(png_ants,
    unit = bait, n_units = baits, .by = season, nboot = 0
  )
  key <- paste(png_ants$season, png_ants$site)
  freq <- lapply(split(png_ants, key), function(d) {
    y <- tapply(d$bait, d$species, function(b) length(unique(b)))
    c(d$baits[1], as.vector(y))
  })
  freq <- freq[vapply(freq, length, integer(1)) > 2]
  ref <- suppressWarnings(iNEXT::iNEXT(freq,
    q = c(0, 1, 2), datatype = "incidence_freq", nboot = 0
  ))$AsyEst
  ref$q <- c(
    "Species richness" = 0, "Shannon diversity" = 1, "Simpson diversity" = 2
  )[ref$Diversity]
  ours$key <- paste(ours$season, ours$site)
  both <- merge(ours, ref, by.x = c("key", "q"), by.y = c("Assemblage", "q"))
  expect_gt(nrow(both), 20)
  expect_equal(both$estimate, both$Estimator, tolerance = 1e-5)
  expect_equal(both$observed, both$Observed, tolerance = 1e-8)
})

test_that("incidence results carry the number of units and bootstrap SEs", {
  out <- div_hill(png_ants, unit = bait, n_units = baits, .by = season)
  expect_true(all(out$n == 60))
  # Without n_units only the baits that some ant visited are counted
  out2 <- div_hill(png_ants, unit = bait, .by = season)
  expect_true(all(out2$n <= 60))
  set.seed(1)
  est <- div_estimate(png_ants,
    unit = bait, n_units = baits, .by = season, nboot = 30
  )
  expect_true(all(is.finite(est$se) & est$se >= 0))
  curves <- div_rarefy(png_ants[png_ants$season == "wet", ],
    unit = bait, n_units = baits, q = 0, size = c(10, 60, 120)
  )
  expect_equal(unique(curves$method), c("rarefaction", "observed", "extrapolation"))
})

test_that("incidence input errors are informative", {
  bad <- png_ants
  bad$baits[1] <- 59
  expect_error(
    div_hill(bad, unit = bait, n_units = baits, .by = season),
    "constant"
  )
  small <- png_ants
  small$baits <- 2L
  expect_error(
    div_hill(small, unit = bait, n_units = baits, .by = season),
    "at least the number of units"
  )
  one <- data.frame(site = "a", species = c("x", "y"), unit = "u1")
  expect_error(div_hill(one, unit = unit), "at least 2 sampling units")
})
