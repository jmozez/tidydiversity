skip_if_not_installed("ade4")
skip_if_not_installed("FD")
a <- data_aravo()
e <- new.env()
utils::data("aravo", package = "ade4", envir = e)
spe <- as.matrix(e$aravo$spe)
tr <- e$aravo$traits

test_that("data_aravo reproduces the ade4 data", {
  expect_equal(sum(a$community$cover), sum(spe))
  expect_equal(nrow(a$traits), 82)
})

test_that("trait_dist matches FD::gowdis and gawdis", {
  d <- trait_dist(a$traits)
  expect_equal(as.matrix(d), as.matrix(FD::gowdis(tr)), ignore_attr = TRUE)
  skip_if_not_installed("gawdis")
  g <- trait_dist(a$traits, method = "gawdis")
  expect_s3_class(g, "dist")
  expect_error(trait_dist(rbind(a$traits, a$traits[1, ])), "one row")
})

test_that("trait_cwm matches FD::functcomp", {
  cw <- trait_cwm(a$community, a$traits, abundance = cover)
  ref <- FD::functcomp(tr, spe)
  got <- cw[cw$trait == "SLA", ]
  expect_equal(got$cwm, ref[got$site, "SLA"])
  expect_true(all(c("Snow", "PhysD") %in% names(cw)))
  bad <- a$traits[-1, ]
  expect_error(trait_cwm(a$community, bad, abundance = cover), "needs a row")
})

test_that("trait_cwm handles categorical traits and NAs", {
  comm <- tibble::tibble(site = c("a", "a", "b"), species = c("x", "y", "x"),
                         n = c(1, 3, 2))
  trt <- tibble::tibble(species = c("x", "y"), h = c(1, NA),
                        f = c("grass", "forb"))
  cw <- trait_cwm(comm, trt, abundance = n)
  expect_equal(cw$cwm[cw$trait == "h"], c(1, 1))
  expect_equal(cw$cwm[cw$trait == "f_forb" & cw$site == "a"], 0.75)
})

test_that("trait_cwm_test gives the observed correlation and valid p", {
  set.seed(1)
  t1 <- trait_cwm_test(a$community, a$traits, abundance = cover, cols = SLA,
                       env_vars = Snow, permutations = 49)
  ref <- FD::functcomp(tr, spe)
  expect_equal(t1$r, stats::cor(ref$SLA, e$aravo$env$Snow))
  expect_equal(t1$p_max, max(t1$p_row, t1$p_col))
  expect_error(trait_cwm_test(a$community, a$traits, abundance = cover,
                              env_vars = Form), "numeric")
})

test_that("trait_fd_indices matches FD::dbFD", {
  fd <- trait_fd_indices(a$community, a$traits, abundance = cover,
                         indices = c("FDis", "RaoQ"))
  ref <- FD::dbFD(FD::gowdis(tr), spe, calc.FRic = FALSE, calc.FDiv = FALSE,
                  calc.CWM = FALSE, corr = "cailliez", messages = FALSE)
  got <- fd[fd$index == "FDis", ]
  expect_equal(got$value, unname(ref$FDis[got$site]))
})

test_that("trait_rao partitions with equivalent numbers", {
  r <- trait_rao(a$community, a$traits, abundance = cover)
  expect_equal(r$equivalent[2], r$equivalent[3] / r$equivalent[1])
  expect_true(r$rao[3] >= r$rao[1])
  # Taxonomic case: d = 1 gives Simpson diversity
  spp <- unique(a$community$species)
  d1 <- stats::as.dist(1 - diag(length(spp)))
  attr(d1, "Labels") <- spp
  r1 <- trait_rao(a$community, dist = d1, abundance = cover)
  p <- spe / rowSums(spe)
  expect_equal(r1$rao[1], mean(1 - rowSums(p^2)))
  expect_error(trait_rao(a$community, abundance = cover), "traits")
})

test_that("trait_ses returns standardised effect sizes", {
  set.seed(1)
  for (nm in c("traits", "richness", "swap")) {
    s <- trait_ses(a$community, a$traits, abundance = cover, times = 9,
                   null = nm)
    expect_equal(nrow(s), 75)
    expect_equal(s$ses, (s$observed - s$null_mean) / s$null_sd)
  }
  s <- trait_ses(a$community, a$traits, abundance = cover, times = 9,
                 index = "FDis")
  ref <- FD::dbFD(FD::gowdis(tr), spe, calc.FRic = FALSE, calc.FDiv = FALSE,
                  calc.CWM = FALSE, corr = "sqrt", messages = FALSE)
  expect_equal(s$observed, unname(ref$FDis[s$site]), tolerance = 1e-6)
})

test_that("trait_itv decomposes specific = turnover + intraspecific + cov", {
  comm <- tibble::tibble(
    site = rep(c("a", "b", "c"), each = 2), species = rep(c("x", "y"), 3),
    n = c(3, 1, 1, 1, 1, 3), moist = rep(c(1, 2, 3), each = 2)
  )
  trt <- tibble::tibble(
    site = rep(c("a", "b", "c"), each = 2), species = rep(c("x", "y"), 3),
    sla = c(10, 20, 12, 22, 14, 24)
  )
  it <- trait_itv(comm, trt, abundance = n, cols = sla)
  ss <- setNames(it$ss, it$component)
  expect_equal(unname(ss["total"]), sum(ss[c("turnover", "intraspecific",
                                             "covariation")]))
  it2 <- trait_itv(comm, trt, abundance = n, cols = sla, formula = ~moist)
  expect_true(all(it2$prop[it2$component != "covariation"] >= 0))
})

test_that("trait_fourth_corner matches ade4::fourthcorner", {
  set.seed(1)
  fc <- trait_fourth_corner(a$community, a$traits, abundance = cover,
                            cols = SLA, env_vars = Snow, permutations = 49)
  ref <- ade4::fourthcorner(e$aravo$env["Snow"], e$aravo$spe,
                            tr["SLA"], modeltype = 6, nrepet = 49)
  expect_equal(fc$statistic, unname(ref$tabD2$obs))
  expect_named(fc, c("trait", "variable", "statistic", "p.value", "p.adj"))
})
