test_that("constrained ordinations advise on pairwise PERMANOVA and the paper", {
  skip_if_not_installed("vegan")
  set.seed(1)
  data(dune, dune.env, package = "vegan")
  long <- data.frame(
    site = rep(rownames(dune), ncol(dune)), species = rep(colnames(dune), each = nrow(dune)),
    abundance = unlist(dune)
  )
  env <- data.frame(site = rownames(dune), Management = dune.env$Management, A1 = dune.env$A1)
  ord <- ord_fit(long,
    abundance = abundance, method = "rda", formula = ~ Management + A1,
    env = env, transform = "hellinger"
  )
  i <- ord_interpret(ord, permutations = 199)
  after <- i$sections$`After the overall test`
  expect_match(after[1], "Management \\(4 levels\\) has a significant effect")
  pairwise <- eval(parse(text = after[2]))
  expect_length(pairwise, 6)
  paper <- i$sections$`For the paper`
  expect_match(paper[1], "related to Management and A1")
  expect_match(paper[1], "199 permutations")
  expect_true(any(grepl("ggsave", paper)))
})

test_that("unconstrained ordinations, PRC and variation partitioning are written up", {
  skip_if_not_installed("vegan")
  o <- ord_fit(png_frogs, abundance = abundance, method = "pca", transform = "hellinger")
  i <- ord_interpret(o)
  expect_match(i$sections$`After the overall test`[1], "no overall test")
  expect_match(i$sections$`For the paper`[1], "first two PCA axes explained")

  set.seed(1)
  ants <- dplyr::mutate(png_ants, unit = paste(site, season, transect))
  vp <- ord_varpart(ants, site = unit, elevation = ~elevation, season = ~season, permutations = 99)
  expect_match(ord_interpret(vp)$sections$`For the paper`[1], "elevation alone explained")
})
