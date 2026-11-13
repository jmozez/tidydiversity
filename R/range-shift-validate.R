#' Validate projected range shifts against resurveys (hindcasting)
#'
#' @description
#' A range-shift model earns trust when it predicts shifts that have already
#' happened. `range_shift_validate()` compares the shifts observed between a
#' historical survey and a resurvey ([range_shift_resurvey()]) with the
#' shifts a model predicted for the same species and period, run from the
#' climate of the first survey to that of the second (hindcasting).
#'
#' For each measure (lower edge, upper edge, midpoint, optimum) it reports:
#'
#' * `bias`: mean of predicted minus observed shift (m);
#' * `mae`, `rmse`: mean absolute and root mean square error (m);
#' * `r`, `rho`: Pearson and Spearman correlation across species;
#' * `slope`: calibration slope of observed on predicted (1 is ideal; below
#'   1, the model overstates differences between species);
#' * `direction`: share of species whose shift has the predicted sign;
#' * `tracking`: mean observed shift divided by mean predicted shift, the
#'   share of the expected shift that species realised (1 = full tracking;
#'   below 1, a lag), with a bootstrap interval resampling species.
#'
#' `range_shift_expected()` gives the simplest prediction, the isotherm
#' shift \eqn{\Delta T / \gamma} for warming \eqn{\Delta T} and lapse rate
#' \eqn{\gamma} (Colwell et al. 2008; Freeman and Freeman 2014). It is the
#' baseline any model must beat.
#'
#' @param observed Result of [range_shift_resurvey()], or a data frame with
#'   `species` and observed `shift_*` columns.
#' @param predicted Data frame with `species` and predicted shifts, in
#'   columns named like those of `observed` (`shift_lower`, `shift_upper`,
#'   `shift_midpoint`, `shift_optimum`), or a single column `shift` used for
#'   every measure.
#' @param drop_truncated Leave out edges truncated at the ends of the
#'   sampled gradient (needs the `truncated_*` columns of `observed`).
#' @param nboot Bootstrap resamples for the tracking interval.
#' @param conf Confidence level.
#' @param seed Optional random seed.
#' @return `range_shift_validate()`: a tibble with one row per measure.
#' @references
#' Colwell, R. K., Brehm, G., Cardelús, C. L., Gilman, A. C. and Longino,
#' J. T. (2008). Global warming, elevational range shifts, and lowland
#' biotic attrition in the wet tropics. Science, 322, 258-261.
#'
#' Freeman, B. G. and Class Freeman, A. M. (2014). Rapid upslope shifts in
#' New Guinean birds illustrate strong distributional responses of tropical
#' montane species to global warming. PNAS, 111, 4490-4494.
#' @export
#' @examples
#' # Virtual resurvey: species realise 60% of a 200 m expected shift
#' before <- png_frogs
#' after <- png_frogs
#' after$elevation <- after$elevation + 120
#' obs <- range_shift_resurvey(before, after, gradient = elevation, abundance = abundance)
#' pred <- data.frame(species = obs$species, shift = range_shift_expected(1, 5))
#' range_shift_validate(obs, pred, nboot = 199, seed = 1)
range_shift_validate <- function(observed,
                                 predicted,
                                 drop_truncated = TRUE,
                                 nboot = 999,
                                 conf = 0.95,
                                 seed = NULL) {
  if (!is.data.frame(observed) || !"species" %in% names(observed)) {
    cli::cli_abort("{.arg observed} must be a data frame with a {.field species} column.")
  }
  if (!is.data.frame(predicted) || !"species" %in% names(predicted)) {
    cli::cli_abort("{.arg predicted} must be a data frame with a {.field species} column.")
  }
  if ("status" %in% names(observed)) observed <- observed[observed$status == "both", , drop = FALSE]
  measures <- c(
    lower = "shift_lower", upper = "shift_upper",
    midpoint = "shift_midpoint", optimum = "shift_optimum"
  )
  measures <- measures[measures %in% names(observed)]
  if (!length(measures)) {
    cli::cli_abort("{.arg observed} has no {.field shift_*} columns.")
  }
  if (!is.null(seed)) set.seed(seed)
  alpha <- (1 - conf) / 2
  rows <- lapply(names(measures), function(m) {
    col <- measures[[m]]
    pcol <- if (col %in% names(predicted)) {
      col
    } else if ("shift" %in% names(predicted)) {
      "shift"
    } else {
      NA
    }
    if (is.na(pcol)) {
      return(NULL)
    }
    d <- merge(observed[c("species", col, intersect(paste0("truncated_", m), names(observed)))],
      predicted[c("species", pcol)],
      by = "species", suffixes = c("_obs", "_pred")
    )
    obs <- d[[if (pcol == col) paste0(col, "_obs") else col]]
    prd <- d[[if (pcol == col) paste0(col, "_pred") else pcol]]
    keep <- !is.na(obs) & !is.na(prd)
    tcol <- paste0("truncated_", m)
    if (drop_truncated && tcol %in% names(d)) keep <- keep & !d[[tcol]]
    obs <- obs[keep]
    prd <- prd[keep]
    n <- length(obs)
    if (n < 3) {
      cli::cli_warn("Fewer than 3 species for {.val {m}}; it is skipped.")
      return(NULL)
    }
    vary <- stats::sd(prd) > 0 && stats::sd(obs) > 0
    track <- function(o, p) mean(o) / mean(p)
    boot <- vapply(seq_len(nboot), function(i) {
      j <- sample.int(n, n, replace = TRUE)
      track(obs[j], prd[j])
    }, numeric(1))
    tibble::tibble(
      measure = m, n = n,
      observed = mean(obs), predicted = mean(prd),
      bias = mean(prd - obs), mae = mean(abs(prd - obs)),
      rmse = sqrt(mean((prd - obs)^2)),
      r = if (vary) stats::cor(obs, prd) else NA_real_,
      rho = if (vary) suppressWarnings(stats::cor(obs, prd, method = "spearman")) else NA_real_,
      slope = if (stats::sd(prd) > 0) unname(stats::coef(stats::lm(obs ~ prd))[2]) else NA_real_,
      direction = mean(sign(obs) == sign(prd)),
      tracking = track(obs, prd),
      tracking_lower = unname(stats::quantile(boot, alpha, na.rm = TRUE)),
      tracking_upper = unname(stats::quantile(boot, 1 - alpha, na.rm = TRUE))
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) {
    cli::cli_abort("No measure could be compared; check the column names of {.arg predicted}.")
  }
  vctrs::vec_rbind(!!!rows)
}

#' @rdname range_shift_validate
#' @param warming Warming in degrees C between the surveys (or scenarios).
#' @param lapse_rate Temperature lapse rate in degrees C per km.
#' @return `range_shift_expected()`: the expected upslope shift in metres.
#' @export
range_shift_expected <- function(warming, lapse_rate) {
  if (!is.numeric(warming) || !is.numeric(lapse_rate) || any(lapse_rate <= 0)) {
    cli::cli_abort("{.arg warming} must be numeric and {.arg lapse_rate} positive.")
  }
  1000 * warming / lapse_rate
}
