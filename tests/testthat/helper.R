toy <- function() {
  tibble::tibble(
    site = rep(c("a", "b"), c(6, 5)),
    species = c("s1", "s2", "s3", "s4", "s5", "s6", "s1", "s2", "s7", "s8", "s9"),
    abundance = c(10, 5, 3, 2, 1, 1, 4, 4, 2, 1, 1)
  )
}

counts_of <- function(data, s) {
  data$abundance[data$site == s]
}

vegan_bci <- function(rows = 1:10) {
  e <- new.env()
  utils::data("BCI", package = "vegan", envir = e)
  m <- as.matrix(e$BCI[rows, ])
  out <- lapply(seq_len(nrow(m)), function(i) {
    keep <- m[i, ] > 0
    data.frame(site = paste0("plot", rows[i]), species = colnames(m)[keep],
      abundance = m[i, keep])
  })
  tibble::as_tibble(do.call(rbind, out))
}

pkg_data <- function(name, package) {
  e <- new.env()
  utils::data(list = name, package = package, envir = e)
  e[[name]]
}
