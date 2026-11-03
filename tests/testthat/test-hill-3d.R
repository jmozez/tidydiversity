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
  expect_true(all(is.na(est$se)))
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
