# Caterpillars collected from every tree above 5 cm dbh in a primary and a
# secondary forest plot at Wanang, Madang Province, Papua New Guinea, and
# reared to adults where possible (New Guinea Binatang Research Centre).
# Source: Butterill, P. and Redmond, C. (2023). Plot-based sampling and
# rearing of adult lepidoptera from lowland rainforest in Wanang, Papua New
# Guinea. Version 1.1. Occurrence dataset, GBIF.
# https://doi.org/10.15468/7e96ht (CC BY 4.0).
# Run from the package root to rebuild data/wanang_caterpillars.rda.
key <- "5ccd1627-e569-4187-91ff-0feb8c470f42"
cols <- c(
  "occurrenceID", "eventID", "taxonID", "scientificName", "taxonRank",
  "family", "associatedTaxa", "individualCount"
)
n <- jsonlite::fromJSON(sprintf(
  "https://api.gbif.org/v1/occurrence/search?datasetKey=%s&limit=0", key
))$count
occ <- do.call(rbind, lapply(seq(0, n - 1, by = 300), function(off) {
  r <- jsonlite::fromJSON(sprintf(
    "https://api.gbif.org/v1/occurrence/search?datasetKey=%s&limit=300&offset=%d",
    key, off
  ))$results
  for (cl in setdiff(cols, names(r))) r[[cl]] <- NA
  r[cols]
}))
stopifnot(nrow(occ) == n, !anyDuplicated(occ$occurrenceID))

# Event IDs start with W (Wanang), P or S (primary or secondary forest) and
# a digit 1-5 for the sampling unit within the plot.
occ$plot <- substr(occ$eventID, 1, 3)
occ$forest <- ifelse(substr(occ$plot, 2, 2) == "P", "primary", "secondary")
occ$host <- sub("^Host:\\s*", "", occ$associatedTaxa)
# Records without a host keep an empty string here so aggregate() keeps them.
occ$individualCount[is.na(occ$individualCount)] <- 1L
counts <- stats::aggregate(
  list(abundance = occ$individualCount),
  occ[c("forest", "plot", "host", "taxonID")],
  sum
)
# One name, rank and family per morphospecies code
taxa <- occ[!duplicated(occ$taxonID), c("taxonID", "scientificName", "taxonRank", "family")]
counts <- merge(counts, taxa, by = "taxonID")
counts <- counts[order(counts$forest, counts$plot, counts$host, -counts$abundance), ]
wanang_caterpillars <- tibble::tibble(
  site = counts$forest,
  plot = counts$plot,
  host = ifelse(nzchar(counts$host), counts$host, NA_character_),
  species = counts$taxonID,
  scientific_name = counts$scientificName,
  rank = tolower(counts$taxonRank),
  family = counts$family,
  abundance = as.integer(counts$abundance)
)

usethis::use_data(wanang_caterpillars, overwrite = TRUE, compress = "xz")
