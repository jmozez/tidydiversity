#' Tidy and model-ready output
#'
#' @description
#' Every tidydiversity result is already a tidy tibble with one row per
#' site and order `q`. The [generics::tidy()] methods rename the columns to
#' the broom conventions (`estimate`, `std.error`, `conf.low`,
#' `conf.high`) and add an inverse-variance weight (`weight`, `1 / se^2`,
#' or `NA` when the standard error is zero, as at a site with a single
#' species), so results stack with other broom output and can go straight into
#' weighted models. [generics::glance()] gives one row per site with its
#' sample size, observed richness and coverage.
#'
#' `add_site_data()` joins site-level covariates, such as elevation,
#' habitat or treatment, from the original data or a separate site table,
#' so diversity can be modelled against them.
#'
#' @param x A tidydiversity result.
#' @param ... Not used.
#' @return A tibble.
#' @name tidy-tidydiversity
#' @examples
#' set.seed(1)
#' est <- div_estimate(ant_gradient, q = 0, nboot = 20)
#' generics::tidy(est)
#'
#' # Join elevation and fit a weighted model
#' est <- add_site_data(est, ant_gradient)
#' fit <- lm(estimate ~ elevation,
#'   data = generics::tidy(est),
#'   weights = weight
#' )
#' coef(fit)
NULL

#' @importFrom generics tidy
#' @export
generics::tidy

#' @importFrom generics glance
#' @export
generics::glance

tidy_rename <- function(df, value) {
  df <- tibble::as_tibble(unclass(df))
  names(df)[names(df) == value] <- "estimate"
  names(df)[names(df) == "se"] <- "std.error"
  names(df)[names(df) == "lower"] <- "conf.low"
  names(df)[names(df) == "upper"] <- "conf.high"
  if ("std.error" %in% names(df)) {
    w <- 1 / df$std.error^2
    w[!is.finite(w)] <- NA_real_
    df$weight <- w
  }
  df
}

#' @rdname tidy-tidydiversity
#' @export
tidy.td_estimate <- function(x, ...) tidy_rename(x, "estimate")

#' @rdname tidy-tidydiversity
#' @export
tidy.td_standardise <- function(x, ...) tidy_rename(x, "diversity")

#' @rdname tidy-tidydiversity
#' @export
tidy.td_rarefy <- function(x, ...) {
  df <- tidy_rename(x, "diversity")
  df$weight <- NULL
  df
}

#' @rdname tidy-tidydiversity
#' @export
tidy.td_boot <- function(x, ...) {
  df <- tibble::as_tibble(unclass(x))
  keys <- setdiff(names(df), c(".draw", "diversity"))
  out <- dplyr::summarise(
    df,
    estimate = mean(.data$diversity),
    std.error = stats::sd(.data$diversity),
    conf.low = unname(stats::quantile(.data$diversity, 0.025)),
    conf.high = unname(stats::quantile(.data$diversity, 0.975)),
    nboot = dplyr::n(),
    .by = dplyr::all_of(keys)
  )
  out
}

#' @rdname tidy-tidydiversity
#' @export
tidy.td_beta_pair <- function(x, ...) tibble::as_tibble(unclass(x))

#' @rdname tidy-tidydiversity
#' @export
glance.td_coverage <- function(x, ...) tibble::as_tibble(unclass(x))

#' @rdname tidy-tidydiversity
#' @param data A data frame holding the site column and the covariates,
#'   such as the community data the result came from, or a site table.
#' @param site <[`tidy-select`][dplyr::dplyr_tidy_select]> The site column
#'   of `data`, matched to the site column of `x`.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Covariates to
#'   join. By default every column that is constant within each site and
#'   not already in `x`.
#' @export
add_site_data <- function(x, data, site = site, cols = NULL) {
  td_check_data(data)
  site_col <- td_pick(enquo(site), data, "site")
  if (!site_col %in% names(x)) {
    cli::cli_abort("{.arg x} has no column {.field {site_col}}.")
  }
  cols_q <- enquo(cols)
  data <- tibble::as_tibble(dplyr::ungroup(data))
  if (quo_is_null(cols_q)) {
    cand <- setdiff(names(data), c(names(x), site_col))
    const <- vapply(cand, function(cl) {
      tab <- vctrs::vec_unique(data[c(site_col, cl)])
      !vctrs::vec_duplicate_any(tab[[site_col]])
    }, logical(1))
    cols <- cand[const]
  } else {
    cols <- names(tidyselect::eval_select(cols_q, data))
  }
  sites <- vctrs::vec_unique(data[c(site_col, cols)])
  if (vctrs::vec_duplicate_any(sites[[site_col]])) {
    cli::cli_abort("The covariates must be constant within each site.")
  }
  idx <- vctrs::vec_match(x[[site_col]], sites[[site_col]])
  for (cl in cols) x[[cl]] <- sites[[cl]][idx]
  x
}
