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
