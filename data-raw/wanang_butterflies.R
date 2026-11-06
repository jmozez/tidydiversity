# Butterflies counted on 36 days over three years in the Wanang forest
# dynamics plot, Papua New Guinea (Luk et al. 2019, Biotropica). Only the
# Wanang ("WAN") sheet is used; the other sheets are from outside PNG.
# Source: Luk, C.-L., Basset, Y., Kongnoo, P., Hau, B. C. H. & Bonebrake,
# T. C. (2019). Data from: Inter-annual monitoring improves diversity
# estimation of tropical butterfly assemblages. Dryad,
# https://doi.org/10.5061/dryad.j35fq7r (CC0 1.0), mirrored on Zenodo
# record 4931308.
# Run from the package root to rebuild data/wanang_butterflies.rda.
xlsx <- tempfile(fileext = ".xlsx")
utils::download.file(
  "https://zenodo.org/records/4931308/files/butterfly%20data%20to%20upload.xlsx?download=1",
  xlsx,
  mode = "wb"
)
w <- as.data.frame(suppressMessages(readxl::read_excel(xlsx, "WAN")))
spp <- names(w)[-(1:4)]

wanang_butterflies <- do.call(rbind, lapply(seq_along(spp), function(j) {
  n <- as.numeric(w[[j + 4]])
  k <- !is.na(n) & n > 0
  data.frame(
    site = sprintf("day%02d", as.integer(w[[1]][k])),
    day = as.integer(w[[1]][k]),
    month = as.integer(w[[2]][k]),
    year = as.integer(w[[3]][k]),
    species = trimws(gsub(" ", " ", spp[j])),
    abundance = as.integer(n[k])
  )
}))
# The sheet repeats three species names (Nacaduba pactolus, Nacaduba
# subperusia, Prosotas dubiosa) in two columns each; read_excel() makes the
# names unique with suffixes such as "...135". Strip them and add the counts.
wanang_butterflies$species <- sub("\\.\\.\\.[0-9]+$", "", wanang_butterflies$species)
wanang_butterflies <- stats::aggregate(
  abundance ~ site + day + month + year + species, wanang_butterflies, sum
)
wanang_butterflies <- tibble::as_tibble(
  wanang_butterflies[order(wanang_butterflies$day, wanang_butterflies$species), ]
)

usethis::use_data(wanang_butterflies, overwrite = TRUE)
