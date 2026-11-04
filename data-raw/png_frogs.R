# Frogs recorded at eight sites from 200 to 3700 m on Mt Wilhelm, Papua New
# Guinea (Dahl et al. 2023, Biotropica).
# Source: Dahl, C., Richards, S. J., Basien, I., Mungkaje, A. J. &
# Novotny, V. (2023). Local and regional diversity of frog communities
# along an extensive rainforest elevation gradient in Papua New Guinea.
# Dryad, https://doi.org/10.5061/dryad.3n5tb2rqf (CC0 1.0), mirrored on
# Zenodo record 10150940.
# Run from the package root to rebuild data/png_frogs.rda.
xls <- tempfile(fileext = ".xls")
utils::download.file(
  "https://zenodo.org/records/10150940/files/DahlEtAl_Data_Dryad_repository.xls?download=1",
  xls,
  mode = "wb"
)
com <- as.data.frame(readxl::read_excel(xls, "CommunityData"))
elev_cols <- grep("^[0-9]+$", names(com), value = TRUE)
com <- com[!is.na(com$SpCode), ]

png_frogs <- do.call(rbind, lapply(elev_cols, function(e) {
  n <- as.numeric(com[[e]])
  k <- !is.na(n) & n > 0
  data.frame(
    site = sprintf("MW%04d", as.integer(e)),
    elevation = as.integer(e),
    species = com$SpCode[k],
    scientific_name = sub("\\*$", "", com$Species[k]),
    family = com$Family[k],
    reproduction = ifelse(com$Reproduction[k] == "Terr", "terrestrial", "aquatic"),
    abundance = as.integer(n[k])
  )
}))
png_frogs <- tibble::as_tibble(png_frogs)

usethis::use_data(png_frogs, overwrite = TRUE)
