star <- function(spp, depth = 3) {
  ape::read.tree(text = paste0("(", paste0(spp, ":", depth, collapse = ","), ");"))
}
comm <- tibble::tibble(
  site = rep(c("a", "b"), each = 4),
  species = rep(c("s1", "s2", "s3", "s4"), 2),
  abundance = c(10, 5, 2, 1, 3, 3, 1, 1)
)

test_that("a star tree gives PD equal to TD (mean) and TD x depth (total)", {
  skip_if_not_installed("ape")
  tr <- star(paste0("s", 1:4), 3)
  td <- div_hill(comm, abundance = abundance, q = c(0, 1, 2))
  pd <- div_hill(comm, abundance = abundance, type = "PD", tree = tr)
  expect_equal(pd$diversity, td$diversity)
  pdt <- div_hill(comm,
    abundance = abundance, type = "PD", tree = tr,
    pd_unit = "total"
  )
  expect_equal(pdt$diversity, 3 * td$diversity)
  est <- div_estimate(comm, abundance = abundance, type = "PD", tree = tr)
  td_est <- div_estimate(comm, abundance = abundance, nboot = 0)
  expect_equal(est$estimate, td_est$estimate)
  expect_true(all(est$se >= 0))
})

test_that("FD with tau = 0 equals TD", {
  d <- matrix(0.5, 4, 4, dimnames = list(paste0("s", 1:4), paste0("s", 1:4)))
  diag(d) <- 0
  td <- div_hill(comm, abundance = abundance)
  fd <- div_hill(comm, abundance = abundance, type = "FD", distance = d, tau = 0)
  expect_equal(fd$diversity, td$diversity)
  r_td <- div_rarefy(comm, abundance = abundance, size = c(2, 5, 8))
  r_fd <- div_rarefy(comm,
    abundance = abundance, size = c(2, 5, 8), type = "FD",
    distance = d, tau = 0
  )
  expect_equal(r_fd$diversity, r_td$diversity)
})

test_that("results do not depend on species order", {
  skip_if_not_installed("ape")
  tr <- ape::read.tree(text = "((s1:1,s2:1):2,(s3:2,s4:2):1);")
  a <- div_estimate(comm, abundance = abundance, type = "PD", tree = tr)
  b <- div_estimate(comm[c(4, 2, 3, 1, 8, 6, 7, 5), ],
    abundance = abundance,
    type = "PD", tree = tr
  )
  expect_equal(a$estimate, b$estimate)
})

test_that("missing species give informative errors", {
  skip_if_not_installed("ape")
  tr <- star(c("s1", "s2", "s3"))
  expect_error(div_hill(comm, abundance = abundance, type = "PD", tree = tr), "s4")
  d <- matrix(0, 3, 3, dimnames = list(c("s1", "s2", "s3"), c("s1", "s2", "s3")))
  expect_error(div_hill(comm, abundance = abundance, type = "FD", distance = d), "s4")
  expect_error(div_hill(comm, abundance = abundance, type = "PD"), "phylo")
})

test_that("PD and FD reproduce iNEXT.3D", {
  skip_on_cran()
  skip_if_not_installed("iNEXT.3D")
  skip_if_not_installed("ape")
  e <- new.env()
  utils::data(list = c(
    "Brazil_rainforest_abun_data", "Brazil_rainforest_phylo_tree",
    "Brazil_rainforest_distance_matrix"
  ), package = "iNEXT.3D", envir = e)
  d <- e$Brazil_rainforest_abun_data
  tr <- e$Brazil_rainforest_phylo_tree
  dm <- as.matrix(e$Brazil_rainforest_distance_matrix)
  long <- tibble::tibble(
    site = rep(colnames(d), each = nrow(d)),
    species = rep(rownames(d), ncol(d)),
    n = unlist(d, use.names = FALSE)
  )
  long <- long[long$n > 0, ]
  q <- c(0, 1, 2)
  for (dv in c("PD", "FD")) {
    for (ft in c("tau_values", "AUC")) {
      if (dv == "PD" && ft == "AUC") next
      ref <- suppressMessages(iNEXT.3D::ObsAsy3D(d,
        diversity = dv, q = q,
        datatype = "abundance", nboot = 0, PDtree = tr, FDdistM = dm,
        FDtype = ft
      ))
      ref <- ref[order(ref$Assemblage, ref$Order.q), ]
      tau <- if (ft == "AUC") "auc" else NULL
      ours <- div_estimate(long,
        abundance = n, type = dv, tree = tr,
        distance = dm, tau = tau
      )
      ours <- ours[order(ours$site, ours$q), ]
      col <- paste0("q", dv)
      expect_equal(ours$estimate, ref[[col]][ref$Method == "Asymptotic"],
        tolerance = 1e-6
      )
      expect_equal(ours$observed, ref[[col]][ref$Method == "Observed"],
        tolerance = 1e-6
      )
    }
    m <- c(10, 200, 1000, 2500)
    ref <- suppressMessages(iNEXT.3D::estimate3D(d,
      diversity = dv, q = q,
      datatype = "abundance", base = "size", level = m, nboot = 0,
      PDtree = tr, FDdistM = dm, FDtype = "tau_values"
    ))
    ours <- div_standardise(long,
      abundance = n, type = dv, tree = tr,
      distance = dm, size = 1000
    )
    ref <- ref[ref$m == 1000, ]
    ref <- ref[order(ref$Assemblage, ref$Order.q), ]
    ours <- ours[order(ours$site, ours$q), ]
    expect_equal(ours$diversity, ref[[paste0("q", dv)]], tolerance = 1e-6)
  }
})

test_that("observed PD matches hillR::hill_phylo", {
  skip_if_not_installed("hillR")
  skip_if_not_installed("iNEXT.3D")
  e <- new.env()
  utils::data(list = c(
    "Brazil_rainforest_abun_data", "Brazil_rainforest_phylo_tree"
  ), package = "iNEXT.3D", envir = e)
  d <- e$Brazil_rainforest_abun_data
  d <- d[rowSums(d) > 0, ]
  tr <- ape::drop.tip(
    e$Brazil_rainforest_phylo_tree,
    setdiff(e$Brazil_rainforest_phylo_tree$tip.label, rownames(d))
  )
  long <- tibble::tibble(
    site = rep(colnames(d), each = nrow(d)),
    species = rep(rownames(d), ncol(d)),
    n = unlist(d, use.names = FALSE)
  )
  long <- long[long$n > 0, ]
  ours <- div_hill(long,
    abundance = n, type = "PD", tree = tr,
    pd_unit = "total"
  )
  for (q in 0:2) {
    ref <- hillR::hill_phylo(t(d), tr, q = q)
    expect_equal(ours$diversity[ours$q == q], unname(ref[c("Edge", "Interior")]),
      tolerance = 1e-8
    )
  }
})

test_that("PD and FD have bootstrap standard errors and intervals", {
  skip_if_not_installed("ape")
  tr <- ape::read.tree(text = "((s1:1,s2:1):2,(s3:2,s4:2):1);")
  d <- as.matrix(stats::dist(c(s1 = 0, s2 = 0.1, s3 = 0.5, s4 = 1)))
  set.seed(1)
  pd <- div_estimate(comm, abundance = abundance, type = "PD", tree = tr, nboot = 50)
  fd <- div_estimate(comm, abundance = abundance, type = "FD", distance = d, nboot = 50)
  for (res in list(pd, fd)) {
    expect_true(all(is.finite(res$se) & res$se > 0))
    expect_true(all(res$upper >= res$estimate))
  }
  st <- div_standardise(comm,
    abundance = abundance, type = "PD", tree = tr,
    size = 10, nboot = 20
  )
  expect_true(all(is.finite(st$se)))
  rf <- div_rarefy(comm,
    abundance = abundance, type = "FD", distance = d,
    size = c(3, 10), nboot = 20
  )
  expect_true(all(rf$upper >= rf$diversity))
  set.seed(2)
  a <- div_estimate(comm, abundance = abundance, type = "PD", tree = tr, nboot = 20)
  set.seed(2)
  b <- div_estimate(comm, abundance = abundance, type = "PD", tree = tr, nboot = 20)
  expect_equal(a$se, b$se)
})

test_that("bootstrap extends distances to undetected species", {
  x <- c(s1 = 5, s2 = 1, s3 = 1)
  d <- as.matrix(stats::dist(c(s1 = 0, s2 = 0.4, s3 = 1)))
  ext <- extend_distance(x, d, c(".undetected1", ".undetected2"))
  expect_equal(ext[".undetected1", "s1"], mean(d[c("s2", "s3"), "s1"]))
  expect_equal(ext[".undetected1", ".undetected2"], d["s2", "s3"])
  expect_equal(unname(diag(ext)), rep(0, 5))
  expect_true(isSymmetric(ext))
})

test_that("PD and FD bootstrap SEs are close to iNEXT.3D", {
  skip_on_cran()
  skip_if_not_installed("iNEXT.3D")
  skip_if_not_installed("ape")
  e <- new.env()
  utils::data(list = c(
    "Brazil_rainforest_abun_data", "Brazil_rainforest_phylo_tree",
    "Brazil_rainforest_distance_matrix"
  ), package = "iNEXT.3D", envir = e)
  d <- e$Brazil_rainforest_abun_data
  long <- tibble::tibble(
    site = rep(colnames(d), each = nrow(d)),
    species = rep(rownames(d), ncol(d)),
    n = unlist(d, use.names = FALSE)
  )
  long <- long[long$n > 0, ]
  dm <- as.matrix(e$Brazil_rainforest_distance_matrix)
  for (dv in c("PD", "FD")) {
    set.seed(10)
    ref <- suppressMessages(iNEXT.3D::ObsAsy3D(d,
      diversity = dv, q = c(0, 1, 2), datatype = "abundance", nboot = 200,
      PDtree = e$Brazil_rainforest_phylo_tree, FDdistM = dm,
      FDtype = "tau_values"
    ))
    ref <- ref[ref$Method == "Asymptotic", ]
    ref <- ref[order(ref$Assemblage, ref$Order.q), ]
    set.seed(10)
    ours <- div_estimate(long,
      abundance = n, type = dv, tree = e$Brazil_rainforest_phylo_tree,
      distance = dm, nboot = 200
    )
    ours <- ours[order(ours$site, ours$q), ]
    ratio <- ours$se / ref$s.e.
    expect_true(all(ratio > 0.5 & ratio < 2), info = paste(dv, format(ratio)))
  }
})

test_that("type = 'all' combines TD, PD and FD and equals separate runs", {
  skip_if_not_installed("ape")
  tr <- ape::read.tree(text = "((s1:1,s2:1):2,(s3:2,s4:2):1);")
  d <- as.matrix(stats::dist(c(s1 = 0, s2 = 0.1, s3 = 0.5, s4 = 1)))
  all3 <- div_estimate(comm,
    abundance = abundance, type = "all", tree = tr, distance = d, nboot = 0
  )
  expect_equal(levels(all3$type), c("TD", "PD", "FD"))
  expect_equal(nrow(all3), 3 * 2 * 3)
  sep <- c(
    div_estimate(comm, abundance = abundance, nboot = 0)$estimate,
    div_estimate(comm, abundance = abundance, type = "PD", tree = tr, nboot = 0)$estimate,
    div_estimate(comm, abundance = abundance, type = "FD", distance = d, nboot = 0)$estimate
  )
  expect_equal(all3$estimate, sep)
  two <- div_hill(comm, abundance = abundance, type = c("TD", "FD"), distance = d)
  expect_equal(levels(two$type), c("TD", "FD"))
  curves <- div_rarefy(comm,
    abundance = abundance, type = "all", tree = tr, distance = d, knots = 5
  )
  expect_s3_class(curves, "td_rarefy")
  expect_error(div_hill(comm, abundance = abundance, type = c("TD", "XD")), "TD")
})

test_that("orders q can be run singly or together", {
  one <- div_hill(comm, abundance = abundance, q = 1)
  all <- div_hill(comm, abundance = abundance, q = c(0, 1, 2))
  expect_equal(unique(one$q), 1)
  expect_equal(one$diversity, all$diversity[all$q == 1])
  skip_if_not_installed("ggplot2")
  curves <- div_rarefy(comm, abundance = abundance, q = 1, knots = 5)
  expect_s3_class(ggplot2::autoplot(curves), "ggplot")
})
