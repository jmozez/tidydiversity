# Tree-nesting ants exhaustively sampled in 1254 trees in rainforest plots
# at 200 m (Wanang), 900 m (Numba) and 1800 m (Yawan), Papua New Guinea
# (Plowman et al. 2020, Ecography).
# Source: Plowman, N., Mottl, O., Novotny, V., Idigel, C., Philip, F. J.
# & Klimes, P. (2019). Data from: Nest microhabitats and tree
# size mediate shifts in ant community structure across elevation in
# tropical rainforest canopies. Dryad, https://doi.org/10.5061/dryad.2fqz612k6
# (CC0 1.0), mirrored on Zenodo record 4966217.
# Plot codes follow the authors' scripts: W = Wanang, N = Numba, Y = Yawan.
# Run from the package root to rebuild data/png_tree_ants.rda.
tx <- utils::read.csv(
  "https://zenodo.org/records/4966217/files/treexants.csv?download=1",
  check.names = FALSE, fileEncoding = "latin1"
)
spp <- grep("^[A-Z]{4} [0-9]{3}$", names(tx), value = TRUE)
plots <- c(Primary_W = "Wanang", Primary_N = "Numba", Primary_Y = "Yawan")
elev <- c(Wanang = 200L, Numba = 900L, Yawan = 1800L)

long <- do.call(rbind, lapply(spp, function(s) {
  k <- tx[[s]] > 0
  data.frame(tree = tx$TreeNo[k], species = s, nests = as.integer(tx[[s]][k]))
}))
meta <- data.frame(
  tree = tx$TreeNo,
  site = unname(plots[tx$Forest]),
  subplot = sub("^.*SUBPLOT_", "", tx$Subplot),
  tree_family = tx$Family,
  tree_genus = tx$Genus,
  dbh = as.numeric(tx$DBH)
)
png_tree_ants <- merge(meta, long, by = "tree")
png_tree_ants$elevation <- unname(elev[png_tree_ants$site])
png_tree_ants$species <- sub(" ", "_", png_tree_ants$species)
png_tree_ants <- tibble::as_tibble(png_tree_ants[order(
  png_tree_ants$elevation, png_tree_ants$tree, png_tree_ants$species
), c(
  "site", "elevation", "subplot", "tree", "tree_family", "tree_genus",
  "dbh", "species", "nests"
)])

usethis::use_data(png_tree_ants, overwrite = TRUE)
