# Ground-foraging ants at nutrient baits along the Mt Wilhelm elevational
# gradient, Papua New Guinea (Moses et al. 2023, Global Ecology and
# Biogeography). Data compiled by Jimmy Moses and Petr Klimes; used here
# with the lead author's permission.
# Source: Mottl, O., Moses, J. & Klimes, P. (2023). Data and code for
# 'Nutrient use by tropical ant communities varies among three extensive
# elevational gradients: a cross-continental comparison'. Zenodo.
# https://doi.org/10.5281/zenodo.8191946
# Run from the package root to rebuild data/png_ants.rda.
zip <- tempfile(fileext = ".zip")
utils::download.file(
  "https://zenodo.org/records/8191946/files/OndrejMottl/Ant_Nutrient_use-v1.0.1.zip?download=1",
  zip,
  mode = "wb"
)
csv <- grep("data_full_clean_2023-02-11.csv$", utils::unzip(zip, list = TRUE)$Name,
  value = TRUE
)
raw <- utils::read.csv(unz(zip, csv))
raw <- raw[raw$regions == "png" & !is.na(raw$sp_code) & raw$abundance > 0, ]

png_ants <- tibble::tibble(
  site = sprintf("MW%04d", as.integer(raw$elevational_bands)),
  elevation = as.integer(raw$elevational_bands),
  season = raw$seasons,
  transect = as.integer(raw$transect_number),
  bait = raw$trap_number_code,
  bait_type = raw$bait_type,
  species = raw$sp_code,
  genus = tools::toTitleCase(raw$genus),
  subfamily = tools::toTitleCase(raw$subfamily),
  guild = raw$guild,
  workers = as.integer(raw$abundance)
)
png_ants <- png_ants[order(png_ants$elevation, png_ants$season, png_ants$bait), ]

usethis::use_data(png_ants, overwrite = TRUE)
