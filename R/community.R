#' Tidy community data
#'
#' @description
#' `as_community()` tidies long-format records into a community table with
#' one row per site and species, and standard column names `site`, `species`
#' and `abundance`. Repeated records are summed and zero counts are dropped.
#'
#' `community_wide()` pivots a community into a site by species matrix
#' stored as a tibble, and `community_long()` turns such a wide table back
#' into long format.
#'
#' @param data A data frame in long format, with one row per record.
#' @param site,species <[`tidy-select`][dplyr::dplyr_tidy_select]> The
#'   column holding site identifiers and the column holding species names.
#' @param abundance <[`tidy-select`][dplyr::dplyr_tidy_select]> The column
#'   holding counts. If `NULL` (the default), a column called `abundance` is
#'   used when present, otherwise every row counts as one individual.
#' @param .by <[`tidy-select`][dplyr::dplyr_tidy_select]> Optional grouping
#'   columns, kept in the output. Grouped data frames are also respected.
#'
#' @return `as_community()` returns a `td_community` tibble with the
#'   grouping columns followed by `site`, `species` and `abundance`.
#' @export
#' @examples
#' ants <- as_community(ant_gradient, .by = transect)
#' ants
#'
#' wide <- community_wide(ants, .by = transect)
#' wide
#'
#' community_long(wide, -c(transect, site))
as_community <- function(data,
                         site = site,
                         species = species,
                         abundance = NULL,
                         .by = NULL) {
  prep <- td_prepare(
    data,
    enquo(site),
    enquo(species),
    enquo(abundance),
    enquo(.by)
  )
  out <- prep$data
  names(out)[match(c(".site", ".species", ".n"), names(out))] <-
    c("site", "species", "abundance")
  out <- vctrs::vec_slice(
    out,
    vctrs::vec_order(out[c(prep$by, "site", "species")])
  )
  td_new(out, "td_community")
}

#' @exportS3Method pillar::tbl_sum
tbl_sum.td_community <- function(x, ...) {
  c(
    "A community" = paste0(
      vctrs::vec_unique_count(x$site), " sites, ",
      vctrs::vec_unique_count(x$species), " species, ",
      format(sum(x$abundance), big.mark = ","), " individuals"
    )
  )
}

#' @rdname as_community
#' @param fill Value used for species absent from a site.
#' @export
community_wide <- function(data,
                           site = site,
                           species = species,
                           abundance = NULL,
                           fill = 0,
                           .by = NULL) {
  prep <- td_prepare(
    data,
    enquo(site),
    enquo(species),
    enquo(abundance),
    enquo(.by)
  )
  d <- prep$data
  spp <- sort(unique(d$.species))
  keys <- vctrs::vec_unique(d[c(prep$by, ".site")])
  row <- vctrs::vec_match(d[c(prep$by, ".site")], keys)
  col <- match(d$.species, spp)
  mat <- matrix(fill, nrow = nrow(keys), ncol = length(spp))
  mat[cbind(row, col)] <- d$.n
  colnames(mat) <- spp
  out <- vctrs::vec_cbind(keys, tibble::as_tibble(mat, .name_repair = "minimal"))
  td_rename_site(out, prep$site)
}

#' @rdname as_community
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> In
#'   `community_long()`, the species columns of a wide table.
#' @return `community_wide()` returns a tibble with one column per species.
#'   `community_long()` returns a `td_community`.
#' @export
community_long <- function(data, cols) {
  td_check_data(data)
  loc <- tidyselect::eval_select(enquo(cols), data, allow_rename = FALSE)
  if (length(loc) == 0) {
    cli::cli_abort("{.arg cols} must select at least one species column.")
  }
  keep <- setdiff(names(data), names(loc))
  if (!"site" %in% keep) {
    cli::cli_abort("{.arg data} must have a {.field site} column.")
  }
  vals <- as.matrix(data[names(loc)])
  if (!is.numeric(vals)) {
    cli::cli_abort("Species columns selected by {.arg cols} must be numeric.")
  }
  idx <- rep(seq_len(nrow(data)), times = length(loc))
  long <- vctrs::vec_slice(data[keep], idx)
  long$species <- rep(names(loc), each = nrow(data))
  long$abundance <- as.vector(vals)
  by <- setdiff(keep, "site")
  as_community(long, .by = tidyselect::all_of(by))
}
