test_that("venn_counts() puts each species in exactly one region", {
  sets <- list(a = c("x", "y"), b = c("y", "z"), c = "y")
  r <- venn_counts(sets)
  expect_equal(nrow(r), 7)
  expect_equal(sum(r$n), 3)
  expect_equal(r$n[r$groups == "a"], 1)
  expect_equal(r$n[r$groups == "a & b & c"], 1)
  expect_equal(r$n[r$groups == "a & b"], 0)
})

test_that("Venn layouts give every combination its own region", {
  for (k in 2:4) {
    expect_equal(nrow(venn_label_pos(venn_shapes(k))), 2^k - 1)
  }
})

test_that("plot_venn() draws 2 to 4 groups and rejects others", {
  skip_if_not_installed("ggplot2")
  p <- plot_venn(png_tree_ants, group = site)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
  r <- attr(p, "regions")
  expect_equal(sum(r$n), length(unique(png_tree_ants$species)))
  expect_error(plot_venn(png_frogs, group = site), "2 to 4 groups")
  expect_error(plot_venn(png_tree_ants[0, ], group = site), "2 to 4 groups")
})

test_that("plot_venn() orders numeric groups numerically", {
  skip_if_not_installed("ggplot2")
  d <- png_ants[png_ants$elevation %in% c(200, 700, 1200), ]
  p <- plot_venn(d, group = elevation)
  expect_equal(attr(p, "regions")$groups[1], "1200")
  expect_equal(levels(p$layers[[1]]$data$set), c("200", "700", "1200"))
})

test_that("phylo_layout() and plot_phylo() give the right PD", {
  skip_if_not_installed("ape")
  skip_if_not_installed("ggplot2")
  tree <- ape::read.tree(text = "((a:1,b:1):1,c:2);")
  lay <- phylo_layout(tree)
  expect_setequal(lay$nodes$y[1:3], 1:3)
  expect_equal(lay$nodes$x[1:3], c(2, 2, 2))
  d <- data.frame(
    site = c("s1", "s1", "s2"), species = c("a", "c", "b"),
    abundance = c(2, 1, 5)
  )
  p <- plot_phylo(tree, d, abundance = abundance, highlight = "s1")
  expect_no_error(ggplot2::ggplot_build(p))
  expect_match(p$labels$subtitle, "PD = 4")
  expect_match(ggplot2::get_alt_text(p), ".")
  expect_s3_class(plot_phylo(tree), "ggplot")
  expect_error(plot_phylo(tree, d, highlight = "nope"), "highlight")
  expect_error(plot_phylo(list()), "phylo")
})

test_that("plot_trait_space() draws hulls and CWMs", {
  skip_if_not_installed("ggplot2")
  tr <- data.frame(species = letters[1:6], t1 = c(1, 2, 3, 4, 5, 9), t2 = c(2, 1, 4, 3, 6, 5))
  dist <- stats::dist(tr[-1])
  attr(dist, "Labels") <- tr$species
  d <- data.frame(
    group = rep(c("g1", "g2"), each = 4),
    species = c("a", "b", "c", "d", "c", "d", "e", "f"),
    n = 1:8
  )
  p <- plot_trait_space(tr, d, group = group, abundance = n, distance = dist, labels = TRUE)
  b <- ggplot2::ggplot_build(p)
  expect_equal(nrow(b$data[[5]]), 2)
  expect_match(p$labels$x, "PCoA 1")
  expect_s3_class(plot_trait_space(tr, distance = dist), "ggplot")
  expect_error(plot_trait_space(tr, d, distance = dist), "group")
  expect_error(plot_trait_space(tr, distance = stats::dist(tr[-1])), "labels")
})
