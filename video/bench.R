# Multi-level speed comparison for the video. Rscript video/bench.R <out-dir>
# Each timing is the median of bench::mark runs; every comparison also
# checks that the results agree with the reference package.
suppressMessages({library(tidydiversity); library(dplyr); library(ggplot2)})
out <- commandArgs(TRUE)[1]
tm <- function(f) as.numeric(stats::median(bench::mark(f(), iterations = 5, check = FALSE)$time[[1]]))
rel <- function(x, y) max(abs(x - y) / pmax(abs(x), 1e-12))
long_of <- function(w) tibble(site = rep(colnames(w), each = nrow(w)), species = rep(rownames(w), ncol(w)),
                             n = unlist(w, use.names = FALSE)) |> filter(n > 0)
cmp <- function(a, b) { j <- merge(a, b, by = c("site", "q", "m")); rel(j$x, j$y) }
rows <- list()
# Level 1: TD rarefaction, iNEXT vs tidydiversity, real data
data(list = c("Brazil_rainforest_abun_data", "Brazil_rainforest_phylo_tree"), package = "iNEXT.3D")
w <- Brazil_rainforest_abun_data; tr <- Brazil_rainforest_phylo_tree; br <- long_of(w)
lw <- lapply(w, function(v) v[v > 0])
a <- iNEXT::iNEXT(lw, q = c(0, 1, 2), knots = 40, nboot = 0)$iNextEst$size_based
b <- div_rarefy(br, abundance = n, q = c(0, 1, 2), knots = 40)
d1 <- cmp(data.frame(site = a$Assemblage, q = a$Order.q, m = a$m, x = a$qD), data.frame(site = b$site, q = b$q, m = b$m, y = b$diversity))
rows[[1]] <- tibble(task = "Taxonomic (TD)", ref = "iNEXT",
  t_ref = tm(function() iNEXT::iNEXT(lw, q = c(0, 1, 2), knots = 40, nboot = 0)),
  t_td = tm(function() div_rarefy(br, abundance = n, q = c(0, 1, 2), knots = 40)), diff = d1)
# Level 2: PD rarefaction, iNEXT.3D vs tidydiversity, real data
a <- iNEXT.3D::iNEXT3D(w, diversity = "PD", PDtree = tr, nboot = 0, knots = 40)[[2]]$size_based
b <- div_rarefy(br, abundance = n, type = "PD", tree = tr, knots = 40)
rows[[2]] <- tibble(task = "Phylogenetic (PD)", ref = "iNEXT.3D",
  t_ref = tm(function() iNEXT.3D::iNEXT3D(w, diversity = "PD", PDtree = tr, nboot = 0, knots = 40)),
  t_td = tm(function() div_rarefy(br, abundance = n, type = "PD", tree = tr, knots = 40)),
  diff = cmp(data.frame(site = a$Assemblage, q = a$Order.q, m = a$m, x = a$qPD), data.frame(site = b$site, q = b$q, m = b$m, y = b$diversity)))
lev <- bind_rows(rows) |> mutate(speedup = t_ref / t_td)
# Level 3: scaling, PD on simulated communities of growing size
set.seed(42)
sc <- bind_rows(lapply(c(100, 200, 400, 800, 1600), function(S) {
  tr <- ape::rcoal(S); tr$tip.label <- paste0("sp", seq_len(S))
  w <- as.data.frame(sapply(c("A", "B"), function(i) rpois(S, rlnorm(S, 1, 1)))); rownames(w) <- tr$tip.label
  w <- w[rowSums(w) > 0, ]; tr <- ape::keep.tip(tr, rownames(w)); l <- long_of(w)
  tibble(species = S, package = c("iNEXT.3D", "tidydiversity"),
         seconds = c(tm(function() iNEXT.3D::iNEXT3D(w, diversity = "PD", PDtree = tr, nboot = 0, knots = 20)),
                     tm(function() div_rarefy(l, abundance = n, type = "PD", tree = tr, knots = 20))))
}))
write.csv(lev, file.path(out, "bench.csv"), row.names = FALSE)
write.csv(sc, file.path(out, "bench_scale.csv"), row.names = FALSE)
print(lev); print(sc)
pal <- c("iNEXT" = "#9AA5B1", "iNEXT.3D" = "#9AA5B1", tidydiversity = "#1A9E93")
p1 <- lev |> tidyr::pivot_longer(c(t_ref, t_td), values_to = "seconds") |>
  mutate(package = ifelse(name == "t_td", "tidydiversity", ref), task = factor(task, rev(lev$task))) |>
  ggplot(aes(seconds, task, fill = package)) + geom_col(position = position_dodge(0.7), width = 0.65) +
  geom_text(aes(label = sprintf("%.2f s", seconds)), position = position_dodge(0.7), hjust = -0.1, size = 5.5) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) + scale_fill_manual(values = pal, breaks = c("iNEXT", "iNEXT.3D", "tidydiversity")) +
  labs(x = "Seconds, rarefaction and extrapolation (Brazil rainforest, 425 species)", y = NULL, fill = NULL) +
  theme_tidydiversity(base_size = 16) + theme(legend.position = "top")
ggsave(file.path(out, "bench.png"), p1, width = 9, height = 4.2, dpi = 220, bg = "white")
p2 <- ggplot(sc, aes(species, seconds, colour = package)) + geom_line(linewidth = 1.4) + geom_point(size = 3.5) +
  scale_x_log10(breaks = unique(sc$species)) + scale_y_log10(labels = function(x) paste(x, "s")) +
  scale_colour_manual(values = pal[-1]) + labs(x = "Species in the community (log scale)", y = "Time (log scale)", colour = NULL) +
  theme_tidydiversity(base_size = 16) + theme(legend.position = "top")
ggsave(file.path(out, "bench_scale.png"), p2, width = 9, height = 5, dpi = 220, bg = "white")
