# Portal Project rodent captures, Chihuahuan Desert, Arizona, USA.
# Source: Ernest, S. K. M. et al. Portal Project Teaching Database and
# PortalData, https://github.com/weecology/PortalData (CC0 1.0).
# Run from the package root to rebuild data/portal_rodents.rda.
base <- "https://raw.githubusercontent.com/weecology/PortalData/main/"
rod <- utils::read.csv(paste0(base, "Rodents/Portal_rodent.csv"))
spp <- utils::read.csv(paste0(base, "Rodents/Portal_rodent_species.csv"))
trt <- utils::read.csv(paste0(base, "SiteandMethods/Portal_plot_treatments.csv"))

target <- spp$speciescode[spp$censustarget == 1 & spp$unidentified == 0 &
  spp$rodent == 1]
rod <- rod[rod$year >= 2016 & rod$year <= 2019 & rod$species %in% target &
  !is.na(rod$plot) & rod$plot %in% 1:24, ]
trt <- trt[trt$term == "shortterm" | !duplicated(trt$plot), ]
trt <- trt[!duplicated(trt$plot), c("plot", "Apr2015_present")]
names(trt)[2] <- "treatment"
trt$treatment <- factor(
  trt$treatment,
  levels = c(
    "Unmanipulated control", "Kangaroo rats removed",
    "All rodents removed"
  ),
  labels = c("control", "krat_exclosure", "removal")
)

counts <- stats::aggregate(
  list(abundance = rep(1L, nrow(rod))),
  rod[c("plot", "year", "species")],
  sum
)
counts <- merge(counts, trt, by = "plot")
counts <- merge(
  counts,
  data.frame(species = spp$speciescode, scientific_name = spp$scientificname),
  by = "species"
)
counts$site <- sprintf("P%02d-%d", counts$plot, counts$year)
counts <- counts[order(counts$plot, counts$year, -counts$abundance), ]
portal_rodents <- tibble::as_tibble(counts[c(
  "site", "plot", "year", "treatment", "species", "scientific_name",
  "abundance"
)])
portal_rodents$plot <- as.integer(portal_rodents$plot)
portal_rodents$year <- as.integer(portal_rodents$year)
portal_rodents$abundance <- as.integer(portal_rodents$abundance)
usethis::use_data(portal_rodents, overwrite = TRUE, compress = "xz")
