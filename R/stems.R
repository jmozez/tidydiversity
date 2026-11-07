#' ForestGEO-style stem and tree census verbs
#'
#' @description
#' Tidyverse-style helpers for ForestGEO / CTFS plot inventories. They accept
#' data frames with the usual columns (`plot`, `census`, `treeID`, `stemID`,
#' `gx`, `gy`, `dbh`, `species` / `sp`, `status`, optionally `date`) and return
#' tibbles. Callers stay inside tidydiversity instead of using the fgeo or
#' CTFS packages.
#'
#' Typical workflow: standardise names with [stems_as_trees()] (main stem per
#' tree) or keep stems; summarise [stems_abundance()] and
#' [stems_basal_area()]; size classes with [stems_size_class()]; demography
#' between two censuses with [stems_demography()]; feed species counts to
#' [div_hill()] via [stems_as_community()].
#'
#' Spatial stem verbs (quadrats, habitat joins, neighbourhoods, the
#' torus-translation habitat test) and stem maps over topography are in
#' the companion package tidymapr (`tidymapr::stems_quadrat()`,
#' `tidymapr::stems_habitat_test()`, `tidymapr::plot_topo()`).
#'
#' Basal area for one stem is `\eqn{\pi/4 \times \mathrm{dbh}^2}` (Condit
#' 1998; fgeo.analyze). With `dbh_unit = "cm"` the result is cm\eqn{^2}; with
#' `"mm"` it is mm\eqn{^2}. Convert afterwards if you need m\eqn{^2} ha\eqn{^{-1}}.
#'
#' @param data A ForestGEO-like data frame.
#' @param census1,census2 Two census tables for demography (tree-level
#'   preferred).
#' @param .by Optional grouping columns (species, quadrat, habitat).
#' @param dbh_unit `"mm"` or `"cm"` for the `dbh` column.
#' @param alive Character codes of `status` that mean alive (default `"A"`).
#' @param alive_only Keep only stems/trees whose `status` is in `alive`?
#' @param level `"tree"` (collapse to one row per `treeID`) or `"stem"`.
#' @references Condit, R. (1998). *Tropical Forest Census Plots*. Springer.
#'   Anderson-Teixeira, K. J. et al. (2015). CTFS-ForestGEO: a worldwide
#'   network monitoring forests in an era of global change. *Global Change
#'   Biology*, 21, 528-549. \doi{10.1111/gcb.12712}.
#'   Condit, R. et al. (2014). Data and database standards for permanent
#'   forest plots in a global network. *Forest Ecology and Management*.
#'   ForestGEO: <https://forestgeo.si.edu/>. Analysis conventions also follow
#'   the fgeo.analyze package (rOpenSci / ForestGEO).
#' @name stems
#' @examplesIf requireNamespace("tidymapr", quietly = TRUE)
#' # A small simulated ForestGEO-style table, for trying the code only
#' stems <- tidymapr::geo_example_stems()
#' stems_abundance(stems, .by = species)
#' stems_basal_area(stems, dbh_unit = "mm", .by = species)
NULL

stems_find_col <- function(data, candidates, arg, required = TRUE,
                           call = caller_env()) {
  nms <- names(data)
  low <- tolower(nms)
  hit <- candidates[candidates %in% low]
  if (length(hit) == 0) {
    if (required) {
      cli::cli_abort(
        "{.arg data} needs a {.field {arg}} column (tried {.val {candidates}}).",
        call = call
      )
    }
    return(NULL)
  }
  nms[match(hit[1], low)]
}

stems_prepare <- function(data, call = caller_env()) {
  td_check_data(data, call = call)
  sp <- stems_find_col(data, c("species", "sp", "mnemonic"), "species", call = call)
  dbh <- stems_find_col(data, c("dbh", "dbh_mm", "dbh_cm"), "dbh",
    required = FALSE, call = call
  )
  status <- stems_find_col(data, c("status", "dfstatus"), "status",
    required = FALSE, call = call
  )
  tree <- stems_find_col(data, c("treeid", "tree_id", "tag"), "treeID",
    required = FALSE, call = call
  )
  stem <- stems_find_col(data, c("stemid", "stem_id"), "stemID",
    required = FALSE, call = call
  )
  gx <- stems_find_col(data, c("gx", "x"), "gx", required = FALSE, call = call)
  gy <- stems_find_col(data, c("gy", "y"), "gy", required = FALSE, call = call)
  census <- stems_find_col(data, c("census", "censusid", "census_id"), "census",
    required = FALSE, call = call
  )
  plot <- stems_find_col(data, c("plot", "plotname", "plot_name"), "plot",
    required = FALSE, call = call
  )
  date <- stems_find_col(data, c("date", "exactdate"), "date",
    required = FALSE, call = call
  )
  list(
    data = tibble::as_tibble(dplyr::ungroup(data)),
    species = sp, dbh = dbh, status = status, tree = tree, stem = stem,
    gx = gx, gy = gy, census = census, plot = plot, date = date
  )
}

#' @rdname stems
#' @param hom Optional height-of-measure column; the largest HOM row is kept
#'   when several measures share a stem.
#' @export
stems_as_trees <- function(data, hom = NULL) {
  prep <- stems_prepare(data)
  d <- prep$data
  if (is.null(prep$tree)) {
    cli::cli_abort("{.fn stems_as_trees} needs a {.field treeID} column.")
  }
  if (is.null(prep$dbh)) {
    cli::cli_abort("{.fn stems_as_trees} needs a {.field dbh} column.")
  }
  # Pick the main stem: largest dbh within tree (and census/plot when present)
  keys <- c(prep$plot, prep$census, prep$tree)
  keys <- keys[!vapply(keys, is.null, logical(1))]
  d$.ord <- seq_len(nrow(d))
  if (!quo_is_null(enquo(hom)) || "hom" %in% tolower(names(d))) {
    hom_col <- stems_find_col(d, c("hom"), "hom", required = FALSE)
  } else {
    hom_col <- NULL
  }
  # Arrange so first row per key is the main stem
  ord_cols <- c(prep$dbh, hom_col)
  d <- d[do.call(
    order,
    c(
      lapply(keys, function(k) d[[k]]),
      lapply(ord_cols, function(k) -as.numeric(d[[k]])),
      list(d$.ord)
    )
  ), , drop = FALSE]
  keep <- !duplicated(d[keys])
  out <- d[keep, , drop = FALSE]
  out$.ord <- NULL
  tibble::as_tibble(out)
}

#' @rdname stems
#' @export
stems_abundance <- function(data,
                            .by = NULL,
                            alive_only = TRUE,
                            alive = "A",
                            level = c("tree", "stem")) {
  level <- rlang::arg_match(level)
  prep <- stems_prepare(data)
  d <- prep$data
  if (isTRUE(alive_only) && !is.null(prep$status)) {
    d <- d[d[[prep$status]] %in% alive, , drop = FALSE]
  }
  if (identical(level, "tree")) {
    if (is.null(prep$tree)) {
      cli::cli_abort("{.arg level} = {.val tree} needs a {.field treeID} column.")
    }
    d <- stems_as_trees(d)
    prep <- stems_prepare(d)
  }
  by_cols <- td_group_cols(d, enquo(.by))
  if (length(by_cols) == 0) {
    return(tibble::tibble(n = nrow(d)))
  }
  dplyr::summarise(d, n = dplyr::n(), .by = dplyr::all_of(by_cols))
}

#' @rdname stems
#' @export
stems_basal_area <- function(data,
                             .by = NULL,
                             dbh_unit = c("mm", "cm"),
                             alive_only = TRUE,
                             alive = "A") {
  dbh_unit <- rlang::arg_match(dbh_unit)
  prep <- stems_prepare(data)
  if (is.null(prep$dbh)) {
    cli::cli_abort("{.fn stems_basal_area} needs a {.field dbh} column.")
  }
  d <- prep$data
  if (isTRUE(alive_only) && !is.null(prep$status)) {
    d <- d[d[[prep$status]] %in% alive, , drop = FALSE]
  }
  dbh <- as.numeric(d[[prep$dbh]])
  ba <- pi / 4 * dbh^2
  d$basal_area <- ba
  d$basal_area_unit <- paste0(dbh_unit, "2")
  by_cols <- td_group_cols(d, enquo(.by))
  if (length(by_cols) == 0) {
    return(tibble::tibble(
      basal_area = sum(ba, na.rm = TRUE),
      basal_area_unit = paste0(dbh_unit, "2"),
      n_stem = sum(is.finite(dbh))
    ))
  }
  dplyr::summarise(
    d,
    basal_area = sum(.data$basal_area, na.rm = TRUE),
    basal_area_unit = paste0(dbh_unit, "2"),
    n_stem = sum(is.finite(.data[[prep$dbh]])),
    .by = dplyr::all_of(by_cols)
  )
}

#' @rdname stems
#' @param breaks Breakpoints for DBH size classes (in the same unit as `dbh`).
#' @param labels Optional labels for size classes.
#' @export
stems_size_class <- function(data,
                             breaks = c(10, 20, 50, 100, Inf),
                             labels = NULL,
                             dbh_unit = c("mm", "cm"),
                             .by = NULL,
                             alive_only = TRUE,
                             alive = "A") {
  dbh_unit <- rlang::arg_match(dbh_unit)
  prep <- stems_prepare(data)
  if (is.null(prep$dbh)) {
    cli::cli_abort("{.fn stems_size_class} needs a {.field dbh} column.")
  }
  d <- prep$data
  if (isTRUE(alive_only) && !is.null(prep$status)) {
    d <- d[d[[prep$status]] %in% alive, , drop = FALSE]
  }
  dbh <- as.numeric(d[[prep$dbh]])
  # Ensure breaks start at -Inf or 0 for cut()
  br <- breaks
  if (is.finite(br[1]) && br[1] > 0) {
    br <- c(0, br)
  }
  d$size_class <- cut(dbh, breaks = br, right = FALSE, labels = labels)
  by_cols <- c(td_group_cols(d, enquo(.by)), "size_class")
  dplyr::summarise(
    d,
    n = dplyr::n(),
    basal_area = sum(pi / 4 * .data[[prep$dbh]]^2, na.rm = TRUE),
    basal_area_unit = paste0(dbh_unit, "2"),
    .by = dplyr::all_of(by_cols)
  )
}

#' @rdname stems
#' @param mindbh Minimum DBH included in demography counts.
#' @param time Mean census interval in years. When `NULL`, estimated from
#'   `date` columns when present, otherwise required.
#' @param growth `"absolute"` for (dbh2-dbh1)/time or `"relative"` for
#'   (log dbh2 - log dbh1)/time.
#' @export
stems_demography <- function(census1,
                             census2,
                             mindbh = 0,
                             alive = "A",
                             time = NULL,
                             growth = c("absolute", "relative"),
                             dbh_unit = c("mm", "cm"),
                             .by = NULL) {
  growth <- rlang::arg_match(growth)
  dbh_unit <- rlang::arg_match(dbh_unit)
  td_check_number(mindbh, "mindbh", 0)
  p1 <- stems_prepare(census1)
  p2 <- stems_prepare(census2)
  if (is.null(p1$tree) || is.null(p2$tree)) {
    cli::cli_abort("{.fn stems_demography} needs {.field treeID} in both censuses.")
  }
  if (is.null(p1$dbh) || is.null(p2$dbh)) {
    cli::cli_abort("{.fn stems_demography} needs {.field dbh} in both censuses.")
  }
  d1 <- stems_as_trees(p1$data)
  d2 <- stems_as_trees(p2$data)
  p1 <- stems_prepare(d1)
  p2 <- stems_prepare(d2)

  # Estimate time from dates when available
  if (is.null(time)) {
    if (!is.null(p1$date) && !is.null(p2$date)) {
      t1 <- mean(as.numeric(as.Date(d1[[p1$date]])), na.rm = TRUE)
      t2 <- mean(as.numeric(as.Date(d2[[p2$date]])), na.rm = TRUE)
      time <- (t2 - t1) / 365.25
    } else {
      cli::cli_abort(
        "Supply {.arg time} in years, or include {.field date} columns."
      )
    }
  }
  td_check_number(time, "time", 0)

  id <- p1$tree
  # Align by treeID
  keys1 <- d1[[id]]
  keys2 <- d2[[id]]
  alive1 <- if (is.null(p1$status)) {
    is.finite(as.numeric(d1[[p1$dbh]]))
  } else {
    d1[[p1$status]] %in% alive
  }
  alive2 <- if (is.null(p2$status)) {
    is.finite(as.numeric(d2[[p2$dbh]]))
  } else {
    d2[[p2$status]] %in% alive
  }
  dbh1 <- as.numeric(d1[[p1$dbh]])
  dbh2 <- as.numeric(d2[[p2$dbh]])
  above1 <- alive1 & is.finite(dbh1) & dbh1 >= mindbh
  above2 <- alive2 & is.finite(dbh2) & dbh2 >= mindbh

  # Survivors: alive and above mindbh in census 1, still alive in census 2
  in2 <- match(keys1, keys2)
  surv <- above1 & !is.na(in2) & alive2[in2]
  dead <- above1 & (is.na(in2) | !alive2[in2])
  # Recruits: above mindbh and alive in census 2, absent or below mindbh in 1
  in1 <- match(keys2, keys1)
  recruit <- above2 & (is.na(in1) | !above1[in1])

  n_start <- sum(above1, na.rm = TRUE)
  n_surv <- sum(surv, na.rm = TRUE)
  n_dead <- sum(dead, na.rm = TRUE)
  n_recruit <- sum(recruit, na.rm = TRUE)
  mort_rate <- if (n_start > 0 && n_surv > 0 && time > 0) {
    (log(n_start) - log(n_surv)) / time
  } else {
    NA_real_
  }
  # Recruitment rate (Condit-style): based on survivors as the risk set
  recr_rate <- if (n_surv > 0 && time > 0) {
    (log(n_surv + n_recruit) - log(n_surv)) / time
  } else {
    NA_real_
  }

  # Growth for survivors
  g_idx <- which(surv)
  if (length(g_idx) > 0) {
    dbh1_s <- dbh1[g_idx]
    dbh2_s <- dbh2[in2[g_idx]]
    if (identical(growth, "absolute")) {
      g <- (dbh2_s - dbh1_s) / time
    } else {
      g <- (log(dbh2_s) - log(dbh1_s)) / time
    }
    growth_rate <- mean(g[is.finite(g)], na.rm = TRUE)
    n_growth <- sum(is.finite(g))
  } else {
    growth_rate <- NA_real_
    n_growth <- 0L
  }

  out <- tibble::tibble(
    N = n_start,
    S = n_surv,
    D = n_dead,
    R = n_recruit,
    mortality_rate = mort_rate,
    recruitment_rate = recr_rate,
    growth_rate = growth_rate,
    growth = growth,
    n_growth = n_growth,
    time = time,
    mindbh = mindbh,
    dbh_unit = dbh_unit
  )

  # Optional split by a column present in census1
  by_cols <- td_group_cols(d1, enquo(.by))
  if (length(by_cols) == 0) {
    return(out)
  }
  # Per-group demography
  split <- vctrs::vec_split(seq_len(nrow(d1)), d1[by_cols])
  rows <- lapply(seq_along(split$val), function(i) {
    idx <- split$val[[i]]
    sub1 <- d1[idx, , drop = FALSE]
    # Restrict census2 to matching treeIDs plus all of census2 for recruits
    # Re-run on subset of census1 trees; recruits still from full census2
    # filtered by group membership in census2 when the by column exists there
    by_vals <- split$key[i, , drop = FALSE]
    if (all(by_cols %in% names(d2))) {
      keep2 <- Reduce(`&`, lapply(by_cols, function(cl) {
        d2[[cl]] == by_vals[[cl]][1]
      }))
      sub2 <- d2[keep2, , drop = FALSE]
    } else {
      sub2 <- d2[d2[[id]] %in% sub1[[id]], , drop = FALSE]
    }
    res <- stems_demography(
      sub1, sub2,
      mindbh = mindbh, alive = alive, time = time,
      growth = growth, dbh_unit = dbh_unit, .by = NULL
    )
    vctrs::vec_cbind(by_vals, res)
  })
  tibble::as_tibble(vctrs::vec_rbind(!!!rows))
}

#' @rdname stems
#' @param site Column to use as the site identifier in the community table
#'   (default `quadrat`, as added by `tidymapr::stems_quadrat()`, or
#'   `plot`).
#' @export
stems_as_community <- function(data,
                               site = NULL,
                               alive_only = TRUE,
                               alive = "A",
                               level = c("tree", "stem")) {
  level <- rlang::arg_match(level)
  prep <- stems_prepare(data)
  d <- prep$data
  if (isTRUE(alive_only) && !is.null(prep$status)) {
    d <- d[d[[prep$status]] %in% alive, , drop = FALSE]
  }
  if (identical(level, "tree")) {
    d <- stems_as_trees(d)
    prep <- stems_prepare(d)
  }
  site_q <- enquo(site)
  if (quo_is_null(site_q)) {
    site_col <- if ("quadrat" %in% names(d)) {
      "quadrat"
    } else if (!is.null(prep$plot)) {
      prep$plot
    } else {
      cli::cli_abort(
        "Supply {.arg site}, or add quadrats with {.fn tidymapr::stems_quadrat}."
      )
    }
  } else {
    site_col <- td_pick(site_q, d, "site")
  }
  as_community(
    d,
    site = !!rlang::sym(site_col),
    species = !!rlang::sym(prep$species),
    abundance = NULL
  )
}
