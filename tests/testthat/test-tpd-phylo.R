test_that("native TPD indices match the TPD package", {
  skip_if_not_installed("TPD")
  set.seed(1)
  sp <- rep(c("a", "b", "c"), each = 15)
  tr <- data.frame(
    species = sp,
    t1 = c(rnorm(15, 0), rnorm(15, 1), rnorm(15, 2.5)),
    t2 = c(rnorm(15, 0), rnorm(15, 2), rnorm(15, 1))
  )
  comm <- data.frame(
    site = rep(c("s1", "s2", "s3"), each = 3), species = rep(c("a", "b", "c"), 3),
    n = c(5, 1, 0, 1, 1, 1, 0, 2, 6)
  )
  comm <- comm[comm$n > 0, ]
  r <- trait_tpd(comm, tr, abundance = n, cols = c(t1, t2), n_divisions = 60)
  d <- trait_tpd_dissim(comm, tr, abundance = n, cols = c(t1, t2),
                        n_divisions = 60)
  cap <- function(e) {
    o <- NULL
    utils::capture.output(o <- suppressMessages(e))
    o
  }
  m <- matrix(c(5, 1, 0, 1, 1, 1, 0, 2, 6), 3, byrow = TRUE,
              dimnames = list(c("s1", "s2", "s3"), c("a", "b", "c")))
  s <- cap(TPD::TPDs(tr$species, tr[c("t1", "t2")], n_divisions = 60))
  tc <- cap(TPD::TPDc(s, m))
  ref <- cap(TPD::REND(TPDc = tc))$communities
  expect_equal(r$FRic, unname(ref$FRichness[r$site]))
  expect_equal(r$FEve, unname(ref$FEvenness[r$site]))
  expect_equal(r$FDiv, unname(ref$FDivergence[r$site]))
  expect_equal(r$redundancy, unname(cap(TPD::redundancy(tc))$redundancy[r$site]))
  dr <- cap(TPD::dissim(tc))$communities
  expect_equal(d$dissimilarity, dr$dissimilarity[cbind(d$site_1, d$site_2)])
  expect_equal(d$p_shared, dr$P_shared[cbind(d$site_1, d$site_2)])
  tr5 <- cbind(tr, t3 = tr$t1, t4 = tr$t2, t5 = tr$t1)
  expect_error(trait_tpd(comm, tr5, abundance = n, cols = t1:t5), "one to four")
  bad <- tr[c(1:2, 16:45), ]
  expect_error(trait_tpd(comm, bad, abundance = n, cols = t1), "at least 3")
})

test_that("native Blomberg's K matches phytools", {
  skip_if_not_installed("ape")
  skip_if_not_installed("phytools")
  set.seed(2)
  tree <- ape::rcoal(40)
  x <- phytools::fastBM(tree)
  tr <- data.frame(species = names(x), x = x, noise = rnorm(40))
  k <- phylo_signal(tr, tree, nsim = 99)
  expect_equal(k$statistic[1], as.numeric(phytools::phylosig(tree, x)))
  expect_true(k$p.value[1] < 0.05)
  l <- phylo_signal(tr[1:5, ], ape::rcoal(5, tip.label = tr$species[1:5]),
                    cols = x, method = "lambda")
  expect_equal(l$method, "lambda")
  expect_error(phylo_signal(tr, "tree"), "phylo")
})

test_that("phylogenetic and combined distances", {
  skip_if_not_installed("ape")
  tree <- ape::rcoal(6)
  d <- phylo_dist(tree)
  expect_equal(max(d), 1)
  f <- stats::dist(seq_len(6))
  attr(f, "Labels") <- tree$tip.label
  c1 <- phylo_combine_dist(f, d, weight = 1)
  expect_equal(as.matrix(c1), as.matrix(f) / max(f),
               ignore_attr = TRUE, tolerance = 1e-12)
  expect_error(phylo_combine_dist(f, d, weight = 2), "between 0 and 1")
})
