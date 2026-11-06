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
#' tree) or keep stems; assign [stems_quadrat()]; summarise
#' [stems_abundance()] and [stems_basal_area()]; size classes with
#' [stems_size_class()]; demography between two censuses with
#' [stems_demography()]; join topography or habitat with [stems_habitat()];
#' map with [plot_topo()]; feed species counts to [div_hill()] via
#' [stems_as_community()].
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
#' @param grid Quadrat size in metres for [stems_quadrat()] (ForestGEO
#'   default 20).
#' @references Condit, R. (1998). *Tropical Forest Census Plots*. Springer.
#'   Anderson-Teixeira, K. J. et al. (2015). CTFS-ForestGEO: a worldwide
#'   network monitoring forests in an era of global change. *Global Change
#'   Biology*, 21, 528-549. \doi{10.1111/gcb.12712}.
#'   Condit, R. et al. (2014). Data and database standards for permanent
#'   forest plots in a global network. *Forest Ecology and Management*.
#'   ForestGEO: <https://forestgeo.si.edu/>. Analysis conventions also follow
#'   the fgeo.analyze package (rOpenSci / ForestGEO).
#' @name stems
#' @examples
#' stems <- geo_example_stems()
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
stems_quadrat <- function(data, grid = 20, gx = gx, gy = gy) {
  td_check_number(grid, "grid", 0)
  prep <- stems_prepare(data)
  d <- prep$data
  gx_q <- enquo(gx)
  gy_q <- enquo(gy)
  gx_col <- tryCatch(td_pick(gx_q, d, "gx"), error = function(e) prep$gx)
  gy_col <- tryCatch(td_pick(gy_q, d, "gy"), error = function(e) prep$gy)
  if (is.null(gx_col) || is.null(gy_col)) {
    cli::cli_abort("{.fn stems_quadrat} needs {.field gx} and {.field gy} columns.")
  }
  x <- as.numeric(d[[gx_col]])
  y <- as.numeric(d[[gy_col]])
  qx <- floor(x / grid) * grid
  qy <- floor(y / grid) * grid
  d$quadrat_x <- qx
  d$quadrat_y <- qy
  d$quadrat <- paste(qx, qy, sep = "_")
  # ForestGEO-style quadrat label when plot is 0-indexed 20 m grid
  d$quadrat_col <- as.integer(qx / grid)
  d$quadrat_row <- as.integer(qy / grid)
  tibble::as_tibble(d)
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

  N <- sum(above1, na.rm = TRUE)
  S <- sum(surv, na.rm = TRUE)
  D <- sum(dead, na.rm = TRUE)
  R <- sum(recruit, na.rm = TRUE)
  mort_rate <- if (N > 0 && S > 0 && time > 0) {
    (log(N) - log(S)) / time
  } else {
    NA_real_
  }
  # Recruitment rate (Condit-style): based on survivors as the risk set
  recr_rate <- if (S > 0 && time > 0) {
    (log(S + R) - log(S)) / time
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
    N = N,
    S = S,
    D = D,
    R = R,
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
#' @param habitat A data frame of quadrat-level habitat or topography
#'   (`quadrat`, or `quadrat_x`/`quadrat_y`, plus covariates).
#' @param grid Quadrat size used to build keys when joining on coordinates.
#' @export
stems_habitat <- function(data, habitat, grid = 20) {
  td_check_data(habitat)
  d <- stems_quadrat(data, grid = grid)
  h <- tibble::as_tibble(dplyr::ungroup(habitat))
  if ("quadrat" %in% names(h)) {
    out <- dplyr::left_join(d, h, by = "quadrat")
  } else if (all(c("quadrat_x", "quadrat_y") %in% names(h))) {
    out <- dplyr::left_join(d, h, by = c("quadrat_x", "quadrat_y"))
  } else {
    cli::cli_abort(
      "{.arg habitat} needs {.field quadrat} or {.field quadrat_x}/{.field quadrat_y}."
    )
  }
  tibble::as_tibble(out)
}

#' @rdname stems
#' @param site Column to use as the site identifier in the community table
#'   (default `quadrat` after [stems_quadrat()], or `plot`).
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
        "Supply {.arg site}, or add quadrats with {.fn stems_quadrat}."
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

#' @rdname stems
#' @param radius Neighbourhood radius in metres (local coordinates).
#' @export
stems_neighbours <- function(data,
                             radius = 10,
                             conspecific = TRUE,
                             alive_only = TRUE,
                             alive = "A") {
  td_check_number(radius, "radius", 0)
  prep <- stems_prepare(data)
  d <- prep$data
  if (is.null(prep$gx) || is.null(prep$gy)) {
    cli::cli_abort("{.fn stems_neighbours} needs {.field gx} and {.field gy}.")
  }
  if (isTRUE(alive_only) && !is.null(prep$status)) {
    d <- d[d[[prep$status]] %in% alive, , drop = FALSE]
  }
  x <- as.numeric(d[[prep$gx]])
  y <- as.numeric(d[[prep$gy]])
  sp <- as.character(d[[prep$species]])
  n <- nrow(d)
  count <- integer(n)
  for (i in seq_len(n)) {
    dx <- x - x[i]
    dy <- y - y[i]
    near <- dx^2 + dy^2 <= radius^2
    near[i] <- FALSE
    if (isTRUE(conspecific)) {
      near <- near & sp == sp[i]
    }
    count[i] <- sum(near, na.rm = TRUE)
  }
  d$n_neighbours <- count
  d$neighbour_radius <- radius
  d$conspecific <- conspecific
  tibble::as_tibble(d)
}


#' Torus-translation habitat association test (ForestGEO)
#'
#' Tests whether a species' density differs among habitat classes by
#' shifting the habitat map on a torus while keeping relative habitat
#' structure (Harms et al. 2001). Observed mean density per habitat is
#' compared to the null distribution from torus shifts.
#'
#' @param data Stem or tree table with `gx`, `gy` and species.
#' @param habitat Either a data frame with `gx`, `gy` (quadrat centres) and
#'   a habitat class column, or a character/factor column name already on
#'   `data` after [stems_habitat()].
#' @param species Species column.
#' @param habitat_col Name of the habitat class column in `habitat` (or in
#'   `data` when `habitat` is a column name).
#' @param grid Quadrat size in metres (ForestGEO default 20).
#' @param nperm Number of torus shifts.
#' @param mindbh Optional minimum DBH filter.
#' @param dbh_unit `"mm"` or `"cm"`.
#' @param seed Optional RNG seed.
#' @return A tibble (`td_stems_habitat_test`) with species, habitat,
#'   observed density, null mean, and two-sided permutation p-value.
#' @references
#' Harms, K. E., Condit, R., Hubbell, S. P. and Foster, R. B. (2001). Habitat
#' associations of trees and shrubs in a 50-ha neotropical forest plot.
#' *Journal of Ecology*, 89, 947-959. \doi{10.1111/j.1365-2745.2001.00615.x}
#' @export
#' @examples
#' stems <- geo_example_stems()
#' # Toy habitat: low vs high elevation from the example DEM
#' dem <- geo_example_dem()
#' elev <- terra::extract(dem, cbind(stems$gx, stems$gy))[, 2]
#' stems$habitat <- ifelse(elev > mean(elev, na.rm = TRUE), "ridge", "valley")
#' # Aggregate to 20 m quadrats for the torus grid
#' q <- stems_quadrat(stems)
#' hab <- unique(q[c("quadrat", "gx", "gy")])
#' # Habitat of quadrat centre
#' hab$habitat <- ifelse(
#'   hab$gx + hab$gy > 100, "ridge", "valley"
#' )
#' set.seed(1)
#' stems_habitat_test(stems, habitat = hab, nperm = 49)
stems_habitat_test <- function(data,
                               habitat,
                               species = species,
                               habitat_col = "habitat",
                               grid = 20,
                               nperm = 999,
                               mindbh = NULL,
                               dbh_unit = c("mm", "cm"),
                               seed = NULL) {
  dbh_unit <- rlang::arg_match(dbh_unit)
  td_check_data(data)
  td_check_number(nperm, "nperm", 0, whole = TRUE)
  td_check_number(grid, "grid", 0)
  sp_col <- td_pick(enquo(species), data, "species")
  prep <- stems_prepare(data)
  data <- prep$data
  if (!is.null(mindbh)) {
    dbh_col <- prep$dbh %||% stems_find_col(data, c("dbh", "DBH"), "dbh")
    dbh <- as.numeric(data[[dbh_col]])
    if (identical(dbh_unit, "cm")) dbh <- dbh * 10
    data <- data[is.finite(dbh) & dbh >= mindbh, , drop = FALSE]
  }
  if (!is.null(seed)) set.seed(seed)

  # Build quadrat-level habitat raster (matrix)
  if (is.character(habitat) && length(habitat) == 1) {
    habitat_col <- habitat
    if (!habitat_col %in% names(data)) {
      cli::cli_abort("Column {.val {habitat_col}} not found on {.arg data}.")
    }
    q <- stems_quadrat(data, grid = grid)
    hab <- unique(q[c("quadrat", "gx", "gy", habitat_col)])
  } else {
    td_check_data(habitat)
    if (!habitat_col %in% names(habitat)) {
      cli::cli_abort("{.arg habitat} needs column {.val {habitat_col}}.")
    }
    hab <- habitat
    if (!all(c("gx", "gy") %in% names(hab)) && "quadrat" %in% names(hab)) {
      # derive centres from quadrat keys if needed later
    }
  }
  if (!all(c("gx", "gy") %in% names(hab))) {
    cli::cli_abort("{.arg habitat} needs {.val gx} and {.val gy} columns.")
  }

  # Snap to grid indices
  gx <- as.numeric(hab$gx)
  gy <- as.numeric(hab$gy)
  ix <- as.integer(floor(gx / grid))
  iy <- as.integer(floor(gy / grid))
  ux <- sort(unique(ix))
  uy <- sort(unique(iy))
  ncol <- length(ux)
  nrow <- length(uy)
  hab_levels <- sort(unique(as.character(hab[[habitat_col]])))
  hab_id <- match(as.character(hab[[habitat_col]]), hab_levels)
  grid_vec <- rep(NA_integer_, nrow * ncol)
  for (i in seq_along(ix)) {
    r <- match(iy[i], uy)
    c <- match(ix[i], ux)
    grid_vec[(r - 1L) * ncol + c] <- hab_id[i]
  }

  # Stem counts per species per habitat under observed map
  stems_q <- stems_quadrat(data, grid = grid)
  stems_q$.sp <- as.character(stems_q[[sp_col]])
  stems_q$.ix <- as.integer(floor(as.numeric(stems_q$gx) / grid))
  stems_q$.iy <- as.integer(floor(as.numeric(stems_q$gy) / grid))
  stems_q$.r <- match(stems_q$.iy, uy)
  stems_q$.c <- match(stems_q$.ix, ux)
  ok <- is.finite(stems_q$.r) & is.finite(stems_q$.c)
  stems_q <- stems_q[ok, , drop = FALSE]
  stems_q$.cell <- (stems_q$.r - 1L) * ncol + stems_q$.c

  spp <- sort(unique(stems_q$.sp))
  stems_q$.sp_i <- match(stems_q$.sp, spp)
  area_obs <- tabulate(grid_vec, nbins = length(hab_levels))
  names(area_obs) <- hab_levels

  obs_counts <- matrix(0, length(spp), length(hab_levels))
  rownames(obs_counts) <- spp
  colnames(obs_counts) <- hab_levels
  for (i in seq_len(nrow(stems_q))) {
    h <- grid_vec[stems_q$.cell[i]]
    si <- stems_q$.sp_i[i]
    if (is.finite(h) && is.finite(si)) {
      obs_counts[si, h] <- obs_counts[si, h] + 1
    }
  }
  dens_obs <- sweep(obs_counts, 2, pmax(area_obs, 1), "/")

  # Null: random torus shifts
  null_dens <- array(0, dim = c(nperm, length(spp), length(hab_levels)))
  if (nperm > 0) {
    for (b in seq_len(nperm)) {
      dx <- sample.int(ncol, 1) - 1L
      dy <- sample.int(nrow, 1) - 1L
      if (exists("geo_torus_shift_cpp", mode = "function")) {
        shifted <- geo_torus_shift_cpp(as.integer(grid_vec), as.integer(nrow),
                                       as.integer(ncol), as.integer(dx),
                                       as.integer(dy))
      } else {
        shifted <- geo_torus_shift_r(as.integer(grid_vec), nrow, ncol, dx, dy)
      }
      area_b <- tabulate(shifted, nbins = length(hab_levels))
      counts_b <- matrix(0, length(spp), length(hab_levels))
      for (i in seq_len(nrow(stems_q))) {
        h <- shifted[stems_q$.cell[i]]
        si <- stems_q$.sp_i[i]
        if (is.finite(h) && h >= 1 && is.finite(si)) {
          counts_b[si, h] <- counts_b[si, h] + 1
        }
      }
      null_dens[b, , ] <- sweep(counts_b, 2, pmax(area_b, 1), "/")
    }
  }

  rows <- list()
  for (si in seq_along(spp)) {
    for (hi in seq_along(hab_levels)) {
      obs <- dens_obs[si, hi]
      if (nperm > 0) {
        null_v <- null_dens[, si, hi]
        p <- (1 + sum(abs(null_v - mean(null_v)) >= abs(obs - mean(null_v)))) /
          (1 + nperm)
        null_mean <- mean(null_v)
      } else {
        p <- NA_real_
        null_mean <- NA_real_
      }
      rows[[length(rows) + 1]] <- tibble::tibble(
        species = spp[si],
        habitat = hab_levels[hi],
        density = obs,
        null_mean = null_mean,
        p_value = p,
        n_stems = obs_counts[si, hi],
        n_quadrats = as.integer(area_obs[hi])
      )
    }
  }
  out <- tibble::as_tibble(vctrs::vec_rbind(!!!rows))
  td_new(out, "td_stems_habitat_test")
}

geo_torus_shift_r <- function(grid, nrow, ncol, dx, dy) {
  sx <- dx %% ncol
  sy <- dy %% nrow
  out <- integer(length(grid))
  for (r in seq_len(nrow) - 1L) {
    for (c in seq_len(ncol) - 1L) {
      rr <- (r + sy) %% nrow
      cc <- (c + sx) %% ncol
      out[rr * ncol + cc + 1L] <- grid[r * ncol + c + 1L]
    }
  }
  out
}
