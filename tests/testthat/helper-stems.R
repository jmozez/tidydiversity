# Simulated ForestGEO-style tables, for unit tests only (not field data).
# Same generator as tidymapr::geo_example_stems() and
# tidymapr::geo_example_censuses().
stems_fixture <- function(n = 120, seed = 1) {
  td_check_number(n, "n", 1, whole = TRUE)
  if (!is.null(seed)) set.seed(seed)
  spp <- c(
    "Pometia_pinnata", "Intsia_bijuga", "Pterocarpus_indicus",
    "Homalanthus_novoguineensis", "Ficus_sp"
  )
  tibble::tibble(
    plot = "demo100",
    treeID = seq_len(n),
    stemID = seq_len(n),
    gx = stats::runif(n, 2, 98),
    gy = stats::runif(n, 2, 98),
    dbh = pmax(1, round(stats::rlnorm(n, meanlog = 2.2, sdlog = 0.55), 1)),
    species = sample(spp, n, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
    status = sample(c("A", "A", "A", "D"), n, replace = TRUE)
  )
}

censuses_fixture <- function(n = 80, seed = 1, time = 5) {
  td_check_number(n, "n", 1, whole = TRUE)
  td_check_number(time, "time", 0)
  if (!is.null(seed)) set.seed(seed)
  c1 <- stems_fixture(n = n, seed = seed)
  c1$census <- 1L
  c1$date <- as.Date("2015-01-01")
  c1$status <- "A"
  c2 <- c1
  c2$census <- 2L
  c2$date <- as.Date("2015-01-01") + as.integer(round(time * 365.25))
  grow <- stats::runif(n, 0.5, 4)
  c2$dbh <- c1$dbh + grow
  die <- seq_len(n) %in% sample.int(n, max(1, floor(0.08 * n)))
  c2$status[die] <- "D"
  n_rec <- max(2, floor(0.1 * n))
  rec <- stems_fixture(n = n_rec, seed = seed + 1)
  rec$treeID <- n + seq_len(n_rec)
  rec$stemID <- rec$treeID
  rec$census <- 2L
  rec$date <- c2$date[1]
  rec$status <- "A"
  c2 <- vctrs::vec_rbind(c2, rec)
  list(census1 = tibble::as_tibble(c1), census2 = tibble::as_tibble(c2))
}
