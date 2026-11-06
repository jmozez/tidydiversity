#' Overdispersed count and proportion models (aods3-free)
#'
#' Fits Poisson, quasi-Poisson, negative binomial, binomial or
#' quasi-binomial GLMs with a tidy interface so callers never need
#' **aods3**, and need **MASS** only when `family = "negbin"` (Suggests).
#' Designed for the abundance / richness models in Moses et al. (2021),
#' which switched to negative binomial after detecting overdispersion.
#'
#' @param data A data frame (for example a site table of abundance or
#'   Hill richness).
#' @param formula A model formula, such as `abundance ~ poly(elevation, 2) * litter`.
#' @param family One of `"poisson"`, `"quasipoisson"`, `"negbin"`,
#'   `"binomial"`, `"quasibinomial"`.
#' @param weights,offset Optional columns (bare names or expressions) passed
#'   to [stats::glm()] / [MASS::glm.nb()].
#' @param ... Additional arguments forwarded to the fitter.
#' @return A `td_count_model` list with `fit`, `family`, `formula`, `data`,
#'   and dispersion diagnostics. [generics::tidy()] / [generics::glance()]
#'   methods are provided as `tidy.td_count_model()` and
#'   `glance.td_count_model()`.
#' @references
#' Moses, J., Fayle, T. M., Novotny, V. and Klimes, P. (2021). Elevation and
#' leaf litter interact in determining the structure of ant communities on a
#' tropical mountain. *Biotropica*, 53, 906-919. \doi{10.1111/btp.12914}
#' @export
#' @examples
#' ants <- png_ants |>
#'   dplyr::group_by(site, elevation) |>
#'   dplyr::summarise(richness = dplyr::n_distinct(species), .groups = "drop")
#' fit <- model_count(ants, richness ~ poly(elevation, 2), family = "poisson")
#' tidy(fit)
#' glance(fit)
model_count <- function(data,
                        formula,
                        family = c("poisson", "quasipoisson", "negbin",
                                   "binomial", "quasibinomial"),
                        weights = NULL,
                        offset = NULL,
                        ...) {
  family <- rlang::arg_match(family)
  td_check_data(data)
  if (!inherits(formula, "formula")) {
    cli::cli_abort("{.arg formula} must be a formula.")
  }
  w_q <- enquo(weights)
  o_q <- enquo(offset)
  wts <- if (quo_is_null(w_q)) NULL else rlang::eval_tidy(w_q, data)
  off <- if (quo_is_null(o_q)) NULL else rlang::eval_tidy(o_q, data)

  args <- list(formula = formula, data = data, ...)
  if (!is.null(wts)) args$weights <- wts
  if (!is.null(off)) args$offset <- off
  if (identical(family, "negbin")) {
    rlang::check_installed("MASS", reason = "for negative binomial models.")
    fit <- do.call(MASS::glm.nb, args)
  } else {
    fam <- switch(
      family,
      poisson = stats::poisson(),
      quasipoisson = stats::quasipoisson(),
      binomial = stats::binomial(),
      quasibinomial = stats::quasibinomial()
    )
    args$family <- fam
    fit <- do.call(stats::glm, args)
  }

  # Dispersion diagnostic (Pearson chi^2 / df)
  pearson <- sum(stats::residuals(fit, type = "pearson")^2, na.rm = TRUE)
  df_res <- stats::df.residual(fit)
  dispersion <- if (is.finite(df_res) && df_res > 0) pearson / df_res else NA_real_

  out <- list(
    fit = fit,
    family = family,
    formula = formula,
    data = tibble::as_tibble(data),
    dispersion = dispersion,
    overdispersed = is.finite(dispersion) && dispersion > 1.5
  )
  class(out) <- c("td_count_model", "list")
  out
}

#' @export
print.td_count_model <- function(x, ...) {
  cli::cli_text(
    "Count model ({.val {x$family}}); dispersion = {round(x$dispersion, 3)}"
  )
  if (isTRUE(x$overdispersed) && x$family %in% c("poisson", "binomial")) {
    cli::cli_inform(
      "Possible overdispersion; consider {.val quasipoisson}/{.val negbin} or {.val quasibinomial}."
    )
  }
  print(x$fit, ...)
  invisible(x)
}

#' @param x A `td_count_model` from [model_count()].
#' @export
#' @importFrom generics tidy
#' @rdname model_count
tidy.td_count_model <- function(x, ...) {
  sm <- summary(x$fit)$coefficients
  tibble::tibble(
    term = rownames(sm),
    estimate = sm[, 1],
    std.error = if (ncol(sm) >= 2) sm[, 2] else NA_real_,
    statistic = if (ncol(sm) >= 3) sm[, 3] else NA_real_,
    p.value = if (ncol(sm) >= 4) sm[, 4] else NA_real_
  )
}

#' @export
#' @importFrom generics glance
#' @rdname model_count
glance.td_count_model <- function(x, ...) {
  fit <- x$fit
  tibble::tibble(
    family = x$family,
    dispersion = x$dispersion,
    overdispersed = x$overdispersed,
    null.deviance = fit$null.deviance,
    deviance = fit$deviance,
    aic = tryCatch(stats::AIC(fit), error = function(e) NA_real_),
    df.residual = stats::df.residual(fit),
    nobs = stats::nobs(fit)
  )
}

#' @export
predict.td_count_model <- function( # nolint: object_name_linter.
  object,
  newdata = NULL,
  type = "response",
  se.fit = FALSE, # nolint: object_name_linter.
  ...
) {
  stats::predict(
    object$fit, newdata = newdata, type = type, se.fit = se.fit, ...
  )
}
