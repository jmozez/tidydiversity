# Numerical agreement with reference implementations.

spider_df <- function(col = "Girdled") {
  skip_if_not_installed("iNEXT")
  x <- pkg_data("spider", "iNEXT")[[col]]
  tibble::tibble(
    site = col, species = paste0("s", seq_along(x)),
    abundance = x
  )
}

test_that("size-based rarefaction and extrapolation match iNEXT", {
  skip_if_not_installed("iNEXT")
  for (col in c("Girdled", "Logged")) {
    x <- pkg_data("spider", "iNEXT")[[col]]
    n <- sum(x)
    m <- c(1, 10, 50, n - 1, n, n + 1, round(1.5 * n), 2 * n)
    ref <- iNEXT::iNEXT(x, q = c(0, 1, 2), size = m, nboot = 0)
    ref <- ref$iNextEst$size_based
    mine <- div_rarefy(spider_df(col), size = m)
    ref <- ref[order(ref$Order.q, ref$m), ]
    expect_equal(mine$diversity, ref$qD, tolerance = 1e-6)
    expect_equal(mine$coverage, ref$SC, tolerance = 1e-6)
  }
})

test_that("default curves stop at twice the sample size", {
  out <- div_rarefy(spider_df(), q = 0)
  expect_equal(max(out$m), 2 * sum(pkg_data("spider", "iNEXT")$Girdled))
  expect_equal(sum(out$method == "observed"), 1)
})

test_that("extrapolating richness beyond 2n warns", {
  expect_warning(
    div_rarefy(spider_df(), q = 0, endpoint = 1000),
    "twice the observed"
  )
  expect_no_warning(div_rarefy(spider_df(), q = 1, endpoint = 1000))
  expect_warning(
    div_standardise(spider_df(), coverage = 0.999, nboot = 0),
    "twice the observed"
  )
})

test_that("coverage-based standardisation matches iNEXT::estimateD", {
  skip_if_not_installed("iNEXT")
  x <- pkg_data("spider", "iNEXT")$Girdled
  for (lev in c(0.8, 0.9, 0.95)) {
    ref <- iNEXT::estimateD(x,
      datatype = "abundance", base = "coverage",
      level = lev, nboot = 0
    )
    mine <- div_standardise(spider_df(), coverage = lev, nboot = 0)
    expect_equal(mine$diversity, ref$qD, tolerance = 1e-5)
    expect_equal(mine$m, ref$m, tolerance = 1e-4)
  }
  ref <- iNEXT::estimateD(x,
    datatype = "abundance", base = "size",
    level = 100, nboot = 0
  )
  mine <- div_standardise(spider_df(), size = 100, nboot = 0)
  expect_equal(mine$diversity, ref$qD, tolerance = 1e-6)
})

test_that("asymptotic estimates match iNEXT on real data", {
  skip_if_not_installed("iNEXT")
  for (col in c("North.site", "South.site")) {
    x <- pkg_data("bird", "iNEXT")[[col]]
    df <- tibble::tibble(site = col, species = seq_along(x), abundance = x)
    ref <- iNEXT::iNEXT(x, q = c(0, 1, 2), nboot = 0)$AsyEst
    expect_equal(div_estimate(df, nboot = 0)$estimate,
      unname(ref$Estimator),
      tolerance = 1e-8
    )
  }
})

test_that("observed Hill numbers match hillR and vegan", {
  skip_if_not_installed("vegan")
  bci <- vegan_bci()
  mine <- div_hill(bci, q = c(0, 1, 2))
  wide <- tapply(bci$abundance, list(bci$site, bci$species), sum)
  wide[is.na(wide)] <- 0
  wide <- wide[unique(bci$site), ]
  expect_equal(mine$diversity[mine$q == 0], unname(vegan::specnumber(wide)))
  expect_equal(mine$diversity[mine$q == 1],
    unname(exp(vegan::diversity(wide))),
    tolerance = 1e-10
  )
  expect_equal(mine$diversity[mine$q == 2],
    unname(vegan::diversity(wide, "invsimpson")),
    tolerance = 1e-10
  )
  skip_if_not_installed("hillR")
  expect_equal(mine$diversity[mine$q == 1],
    unname(hillR::hill_taxa(wide, q = 1)),
    tolerance = 1e-10
  )
})

test_that("Chao1 log-normal interval follows Chao (1987)", {
  set.seed(1)
  out <- div_estimate(spider_df(), q = 0, nboot = 50)
  t <- out$estimate - out$observed
  k <- exp(1.959964 * sqrt(log(1 + out$se^2 / t^2)))
  expect_equal(out$lower, out$observed + t / k, tolerance = 1e-6)
  expect_equal(out$upper, out$observed + t * k, tolerance = 1e-6)
  expect_true(out$lower >= out$observed)
  set.seed(1)
  nrm <- div_estimate(spider_df(), nboot = 50, ci = "normal")
  expect_equal(nrm$upper, nrm$estimate + 1.959964 * nrm$se,
    tolerance = 1e-6
  )
  expect_true(all(nrm$lower >= nrm$observed))
})

test_that("bootstrap SE is close to iNEXT's", {
  skip_if_not_installed("iNEXT")
  skip_on_cran()
  set.seed(2024)
  mine <- div_estimate(spider_df(), q = c(1, 2), nboot = 400)
  set.seed(2024)
  ref <- iNEXT::iNEXT(pkg_data("spider", "iNEXT")$Girdled, q = c(1, 2), nboot = 400)
  expect_equal(mine$se, unname(ref$AsyEst$Est_s.e.[2:3]), tolerance = 0.25)
})

test_that("abundance-based beta partitions match betapart and vegan", {
  skip_if_not_installed("betapart")
  skip_if_not_installed("vegan")
  bci <- vegan_bci(1:6)
  wide <- tapply(bci$abundance, list(bci$site, bci$species), sum)
  wide[is.na(wide)] <- 0
  wide <- wide[unique(bci$site), ]
  ref <- betapart::beta.pair.abund(wide)
  mine <- beta_pair(bci, index = "bray")
  expect_equal(mine$turnover, as.vector(ref$beta.bray.bal))
  expect_equal(mine$nestedness, as.vector(ref$beta.bray.gra))
  expect_equal(mine$total, as.vector(vegan::vegdist(wide)))
  m <- betapart::beta.multi.abund(wide)
  mm <- beta_multi(bci, index = "bray")
  expect_equal(
    c(mm$turnover, mm$nestedness, mm$total),
    unname(unlist(m))
  )
  expect_equal(as.vector(beta_dist(mine)), as.vector(vegan::vegdist(wide)))
})

test_that("incidence beta partitions match betapart on real data", {
  skip_if_not_installed("betapart")
  ceram_s <- pkg_data("ceram.s", "betapart")
  long <- do.call(rbind, lapply(seq_len(nrow(ceram_s)), function(i) {
    data.frame(
      site = rownames(ceram_s)[i],
      species = colnames(ceram_s)[ceram_s[i, ] > 0]
    )
  }))
  for (idx in c("sorensen", "jaccard")) {
    ref <- betapart::beta.multi(ceram_s, index.family = idx)
    mine <- beta_multi(long, index = idx)
    expect_equal(
      c(mine$turnover, mine$nestedness, mine$total),
      unname(unlist(ref))
    )
    refp <- betapart::beta.pair(ceram_s, index.family = idx)
    expect_equal(beta_pair(long, index = idx)$total, as.vector(refp[[3]]))
  }
})
