# Figures, tables and console output for the tidydiversity marketing video.
# Run from the package root:  Rscript video/figures.R <output-dir>
# Needs: tidydiversity, dplyr, ggplot2 (>= 3.5), vegan, iNEXT.3D (for the data
# and the speed comparison).

suppressMessages({
  library(tidydiversity)
  library(dplyr)
  library(ggplot2)
})
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "video/build/fig"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
set.seed(1)
sv <- function(p, f, w = 9, h = 5) ggsave(file.path(out, f), p, width = w, height = h, dpi = 220, bg = "white")
keep <- function(x, f) writeLines(utils::capture.output(print(x, width = 72)), file.path(out, f))

# 1. Hill numbers (live-coding scene 1)
wet <- filter(png_ants, season == "wet")
keep(div_hill(wet)[1:6, ], "hill_out.txt")

# 2. Coverage-based rarefaction and extrapolation (scene 2)
curves <- div_rarefy(wet, q = c(0, 1, 2), knots = 30)
sv(autoplot(curves, x = "coverage"), "coverage.png")

# 3. Asymptotic estimates (scene 3)
est <- div_estimate(png_ants, .by = season, nboot = 50)
keep(select(est, 1:6) |> head(6), "est_out.txt")
sv(autoplot(est), "estimate.png", h = 5.5)

# 4. Beta diversity
sv(autoplot(beta_pair(png_ants, .by = season)), "betapair.png", h = 5)

# 5. Taxonomic, phylogenetic and functional diversity, and the speed test
data(list = c(
  "Brazil_rainforest_abun_data", "Brazil_rainforest_phylo_tree",
  "Brazil_rainforest_distance_matrix"
), package = "iNEXT.3D")
wide <- Brazil_rainforest_abun_data
brazil <- tibble(
  site = rep(colnames(wide), each = nrow(wide)),
  species = rep(rownames(wide), ncol(wide)),
  n = unlist(wide, use.names = FALSE)
) |> filter(n > 0)
tr <- Brazil_rainforest_phylo_tree
dm <- as.matrix(Brazil_rainforest_distance_matrix)
curves3 <- bind_rows(
  div_rarefy(brazil, abundance = n, type = "TD") |> mutate(type = "TD"),
  div_rarefy(brazil, abundance = n, type = "PD", tree = tr),
  div_rarefy(brazil, abundance = n, type = "FD", distance = dm)
)
curves3$type <- factor(curves3$type, levels = c("TD", "PD", "FD"))
p3 <- ggplot(curves3, aes(m, diversity, colour = site)) +
  geom_line(aes(linetype = method == "extrapolation")) +
  geom_point(data = filter(curves3, method == "observed"), size = 2) +
  facet_wrap(vars(q, type), ncol = 3, scales = "free_y") +
  theme_tidydiversity() + scale_colour_tidydiversity() +
  labs(x = "Number of individuals", y = "Diversity", linetype = "Extrapolated", colour = NULL)
sv(p3, "threed.png", h = 5.6)

# 6. Ordination and the tidyvisor advice (post hoc and for the paper)
data(dune, dune.env, package = "vegan")
long <- data.frame(
  site = rep(rownames(dune), ncol(dune)), species = rep(colnames(dune), each = nrow(dune)),
  abundance = unlist(dune)
)
env <- data.frame(site = rownames(dune), Management = dune.env$Management, A1 = dune.env$A1)
ord <- ord_fit(long, abundance = abundance, method = "rda", formula = ~ Management + A1, env = env, transform = "hellinger")
sv(autoplot(ord), "ordination.png", w = 7, h = 6.2)
i <- ord_interpret(ord, permutations = 199)
writeLines(c(i$sections$`After the overall test`[1], i$sections$`For the paper`[1]), file.path(out, "advice.txt"))
cat("Figures, tables and output written to", out, "\n")
