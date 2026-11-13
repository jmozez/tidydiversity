#' Elevational (or other gradient) ranges of species
#'
#' @description
#' `range_edges()` summarises where each species occurs along a gradient,
#' such as elevation: the lower and upper edges (lowest and highest site of
#' occurrence), the midpoint, the breadth and the abundance-weighted
#' optimum (mean position of individuals). Species found at the first or
#' last sampled position have ranges that may extend beyond the transect;
#' `truncated_lower` and `truncated_upper` flag them (Colwell and Hurtt
#' 1994), as their edges and breadth are underestimated.
#'
#' @inheritParams div_hill
#' @param gradient Column giving the position of each site on the
#'   gradient, such as elevation in metres.
#' @return A tibble with one row per species (and group): `species`,
#'   `lower`, `upper`, `midpoint`, `breadth`, `optimum`, `n_sites`,
#'   `abundance`, `truncated_lower`, `truncated_upper`.
#' @references
#' Colwell, R. K. and Hurtt, G. C. (1994). Nonbiological gradients in
#' species richness and a spurious Rapoport effect. American Naturalist,
#' 144, 570-595.
#' @export
#' @examples
#' range_edges(png_frogs, abundance = abundance, gradient = elevation)
range_edges <- function(data,
                        gradient,
                        site = site,
                        species = species,
                        abundance = NULL,
                        .by = NULL) {
  td_check_data(data)
  g_col <- td_pick(enquo(gradient), data, "gradient")
  site_col <- td_pick(enquo(site), data, "site")
  sp_col <- td_pick(enquo(species), data, "species")
  ab_q <- enquo(abundance)
  ab_col <- if (quo_is_null(ab_q)) NULL else td_pick(ab_q, data, "abundance")
  by_cols <- td_group_cols(data, enquo(.by))
  if (!is.numeric(data[[g_col]])) {
    cli::cli_abort("{.arg gradient} must be numeric.")
  }
  d <- dplyr::ungroup(data)
  d$.g <- d[[g_col]]
  d$.n <- if (is.null(ab_col)) 1 else d[[ab_col]]
  d$.sp <- as.character(d[[sp_col]])
  d$.site <- d[[site_col]]
  # Sampled extent of the gradient (all sites, even empty ones)
  ext <- d |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by_cols))) |>
    dplyr::summarise(.gmin = min(.data$.g), .gmax = max(.data$.g), .groups = "drop")
  pres <- d[!is.na(d$.n) & d$.n > 0, , drop = FALSE]
  out <- pres |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(by_cols, ".sp")))) |>
    dplyr::summarise(
      lower = min(.data$.g), upper = max(.data$.g),
      optimum = sum(.data$.g * .data$.n) / sum(.data$.n),
      n_sites = dplyr::n_distinct(.data$.site),
      abundance = sum(.data$.n), .groups = "drop"
    )
  out <- if (length(by_cols)) dplyr::left_join(out, ext, by = by_cols) else cbind(out, ext)
  out <- tibble::tibble(
    !!!as.list(out[by_cols]),
    species = out$.sp, lower = out$lower, upper = out$upper,
    midpoint = (out$lower + out$upper) / 2, breadth = out$upper - out$lower,
    optimum = out$optimum, n_sites = out$n_sites, abundance = out$abundance,
    truncated_lower = out$lower <= out$.gmin, truncated_upper = out$upper >= out$.gmax
  )
  if (is.null(ab_col)) out$optimum <- NA_real_
  td_new(out, "td_range_edges")
}

#' Range shifts between two surveys of the same gradient
#'
#' @description
#' `range_shift_resurvey()` compares species' ranges in a historical survey
#' and a resurvey of the same gradient (for example the same elevational
#' transect decades apart; Moritz et al. 2008; Freeman and Freeman 2014). For
#' each species found in both surveys it gives the shift of the lower edge,
#' the upper edge, the midpoint and the abundance-weighted optimum, and the
#' change in breadth; species found in only one survey are listed as
#' `"lost"` or `"new"`.
#'
#' `range_shift_test()` asks whether species shifted on average. Species
#' share a gradient and survey design, but their shifts are treated as the
#' units of replication, as in published resurveys: it gives the mean shift
#' of each measure, a bootstrap confidence interval resampling species, and
#' an exact two-sided sign test of whether more species moved up than down.
#' Shifts of edges at the end of the sampled gradient are unreliable, so by
#' default edges flagged as truncated in either survey are left out of the
#' test of that edge.
#'
#' @param before,after Long-format data of the two surveys, with the same
#'   columns.
#' @inheritParams range_edges
#' @return `range_shift_resurvey()`: a tibble with one row per species:
#'   `species`, `status` (`"both"`, `"lost"`, `"new"`), the edges in both
#'   surveys (`lower_before`, `lower_after`, ...), the shifts
#'   (`shift_lower`, `shift_upper`, `shift_midpoint`, `shift_optimum`,
#'   `change_breadth`) and `truncated` (an edge truncated in either survey).
#' @references
#' Freeman, B. G. and Class Freeman, A. M. (2014). Rapid upslope shifts in
#' New Guinean birds illustrate strong distributional responses of tropical
#' montane species to global warming. PNAS, 111, 4490-4494.
#'
#' Moritz, C. et al. (2008). Impact of a century of climate change on
#' small-mammal communities in Yosemite National Park, USA. Science, 322,
#' 261-264.
#' @export
#' @examples
#' # Two virtual surveys: every species moves 100 m upslope
#' before <- png_frogs
#' after <- png_frogs
#' after$elevation <- after$elevation + 100
#' shifts <- range_shift_resurvey(before, after,
#'   gradient = elevation, abundance = abundance
#' )
#' range_shift_test(shifts, nboot = 199, seed = 1)
range_shift_resurvey <- function(before,
                                 after,
                                 gradient,
                                 site = site,
                                 species = species,
                                 abundance = NULL) {
  b <- range_edges(before, {{ gradient }},
    site = {{ site }}, species = {{ species }},
    abundance = {{ abundance }}
  )
  a <- range_edges(after, {{ gradient }},
    site = {{ site }}, species = {{ species }},
    abundance = {{ abundance }}
  )
  keep <- c(
    "species", "lower", "upper", "midpoint", "breadth", "optimum",
    "truncated_lower", "truncated_upper"
  )
  j <- dplyr::full_join(
    tibble::as_tibble(b)[keep], tibble::as_tibble(a)[keep],
    by = "species", suffix = c("_before", "_after")
  )
  status <- ifelse(is.na(j$lower_after), "lost", ifelse(is.na(j$lower_before), "new", "both"))
  out <- tibble::tibble(
    species = j$species, status = status,
    lower_before = j$lower_before, lower_after = j$lower_after,
    upper_before = j$upper_before, upper_after = j$upper_after,
    optimum_before = j$optimum_before, optimum_after = j$optimum_after,
    shift_lower = j$lower_after - j$lower_before,
    shift_upper = j$upper_after - j$upper_before,
    shift_midpoint = j$midpoint_after - j$midpoint_before,
    shift_optimum = j$optimum_after - j$optimum_before,
    change_breadth = j$breadth_after - j$breadth_before,
    truncated_lower = j$truncated_lower_before %in% TRUE | j$truncated_lower_after %in% TRUE,
    truncated_upper = j$truncated_upper_before %in% TRUE | j$truncated_upper_after %in% TRUE
  )
  out <- out[order(match(out$status, c("both", "lost", "new")), out$species), ]
  td_new(out, "td_range_shift")
}

#' @rdname range_shift_resurvey
#' @param x Result of `range_shift_resurvey()`.
#' @param nboot Number of bootstrap resamples of species.
#' @param conf Confidence level.
#' @param drop_truncated Leave out edges truncated at the ends of the
#'   sampled gradient?
#' @param seed Optional random seed.
#' @return `range_shift_test()`: a tibble with one row per measure:
#'   `measure`, `n` (species), `mean`, `lower`, `upper` (bootstrap
#'   interval), `n_up`, `n_down`, `p_sign` (exact sign test).
#' @export
range_shift_test <- function(x, nboot = 999, conf = 0.95,
                             drop_truncated = TRUE, seed = NULL) {
  if (!inherits(x, "td_range_shift")) {
    cli::cli_abort("{.arg x} must come from {.fn range_shift_resurvey}.")
  }
  if (!is.null(seed)) set.seed(seed)
  both <- x[x$status == "both", , drop = FALSE]
  measures <- c(
    lower = "shift_lower", upper = "shift_upper",
    midpoint = "shift_midpoint", optimum = "shift_optimum"
  )
  alpha <- (1 - conf) / 2
  rows <- lapply(names(measures), function(m) {
    v <- both[[measures[[m]]]]
    if (drop_truncated && m == "lower") v <- v[!both$truncated_lower]
    if (drop_truncated && m == "upper") v <- v[!both$truncated_upper]
    v <- v[!is.na(v)]
    n <- length(v)
    if (n == 0) {
      return(tibble::tibble(
        measure = m, n = 0L, mean = NA_real_, lower = NA_real_,
        upper = NA_real_, n_up = 0L, n_down = 0L, p_sign = NA_real_
      ))
    }
    boot <- vapply(seq_len(nboot), function(i) mean(sample(v, n, replace = TRUE)), numeric(1))
    up <- sum(v > 0)
    down <- sum(v < 0)
    p <- if (up + down > 0) stats::binom.test(up, up + down)$p.value else 1
    tibble::tibble(
      measure = m, n = n, mean = mean(v),
      lower = unname(stats::quantile(boot, alpha)),
      upper = unname(stats::quantile(boot, 1 - alpha)),
      n_up = up, n_down = down, p_sign = p
    )
  })
  vctrs::vec_rbind(!!!rows)
}
