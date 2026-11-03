#' Publication-ready tables
#'
#' Formats a tidydiversity result as a table for a manuscript or report:
#' rounds numbers, combines estimates and confidence limits into one cell
#' in APA style, for example `12.34 [10.10, 14.50]`, renames columns to
#' readable titles, and can spread the orders `q` into columns so each site
#' takes one row. The result can be returned as a tibble, or rendered with
#' knitr, gt or flextable for HTML, PDF or Word output.
#'
#' @param x A tibble from [div_estimate()], [div_standardise()],
#'   [div_hill()], [div_coverage()], [beta_pair()] or [beta_multi()].
#' @param digits Number of decimal places.
#' @param ci Combine the estimate with its confidence limits in one cell.
#' @param ci_style Style of the interval: `"apa"` (`[lower, upper]`),
#'   `"parentheses"` (`(lower-upper)`) or `"pm"` (`+/- SE`).
#' @param wide Spread the orders `q` into columns, one row per site.
#' @param output `"tibble"`, `"kable"` ([knitr::kable()]), `"gt"`
#'   ([gt::gt()]) or `"flextable"` ([flextable::flextable()]).
#' @param caption Optional table caption for the rendered formats.
#' @return A tibble of formatted character columns, or a kable, gt or
#'   flextable object.
#' @export
#' @examples
#' set.seed(1)
#' est <- div_estimate(ant_gradient, .by = transect, nboot = 20)
#' div_table(est)
#' div_table(est, wide = TRUE, digits = 1)
#' div_table(est, output = "kable", caption = "Asymptotic diversity")
div_table <- function(x,
                      digits = 2,
                      ci = TRUE,
                      ci_style = c("apa", "parentheses", "pm"),
                      wide = FALSE,
                      output = c("tibble", "kable", "gt", "flextable"),
                      caption = NULL) {
  ci_style <- rlang::arg_match(ci_style)
  output <- rlang::arg_match(output)
  td_check_number(digits, "digits", 0, 10, whole = TRUE)
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a tidydiversity result.")
  }
  df <- tibble::as_tibble(unclass(x))
  fmt <- function(v) formatC(v, format = "f", digits = digits)
  value <- intersect(c("estimate", "diversity"), names(df))[1]
  has_ci <- all(c("lower", "upper") %in% names(df)) && !all(is.na(df$lower))
  if (!is.na(value) && ci && has_ci) {
    est <- fmt(df[[value]])
    df[[value]] <- switch(ci_style,
      apa = paste0(est, " [", fmt(df$lower), ", ", fmt(df$upper), "]"),
      parentheses = paste0(est, " (", fmt(df$lower), "-", fmt(df$upper),
        ")"),
      pm = paste0(est, " \u00b1 ", fmt(df$se))
    )
    df$lower <- NULL
    df$upper <- NULL
    df$se <- NULL
  }
  num <- vapply(df, is.double, logical(1))
  keep <- c("q", "n", "s_obs", "f1", "f2", "n_sites")
  for (col in setdiff(names(df)[num], keep)) {
    df[[col]] <- if (col == "coverage") {
      formatC(df[[col]] * 100, format = "f", digits = max(digits - 2, 1))
    } else {
      fmt(df[[col]])
    }
  }
  if ("m" %in% names(df)) df$m <- formatC(as.numeric(df$m), format = "f",
    digits = 1)
  if (wide && "q" %in% names(df)) {
    ids <- setdiff(names(df), c("q", value, "observed", "m", "method",
      "coverage", "se", "lower", "upper", "n"))
    vals <- intersect(c("observed", value), names(df))
    df <- tidy_wide(df, ids, vals)
  } else if ("q" %in% names(df)) {
    df$q <- format(df$q)
  }
  names(df) <- pretty_names(names(df), ci && has_ci, ci_style, x)
  render_table(df, output, caption)
}

tidy_wide <- function(df, ids, vals) {
  key <- vctrs::vec_unique(df[ids])
  out <- key
  for (qq in sort(unique(df$q))) {
    rows <- df[df$q == qq, ]
    idx <- vctrs::vec_match(key, rows[ids])
    for (v in vals) {
      lab <- if (length(vals) > 1) paste0(v, " (q = ", qq, ")") else
        paste0("q = ", qq)
      out[[lab]] <- rows[[v]][idx]
    }
  }
  out
}

pretty_names <- function(nms, ci, style, x) {
  lab <- c(
    q = "Order q", n = "Individuals", s_obs = "Observed species",
    f1 = "Singletons", f2 = "Doubletons", coverage = "Coverage (%)",
    observed = "Observed", m = "Sample size", method = "Method",
    n_sites = "Sites", turnover = "Turnover", nestedness = "Nestedness",
    total = "Total", site_1 = "Site 1", site_2 = "Site 2",
    distance = "Distance", se = "SE"
  )
  ci_lab <- switch(style, apa = " [95% CI]", parentheses = " (95% CI)",
    pm = " \u00b1 SE")
  lab["estimate"] <- paste0("Estimate", if (ci) ci_lab)
  lab["diversity"] <- paste0("Diversity", if (ci) ci_lab)
  out <- ifelse(nms %in% names(lab), lab[nms], nms)
  unname(out)
}

render_table <- function(df, output, caption) {
  switch(output,
    tibble = df,
    kable = {
      rlang::check_installed("knitr")
      knitr::kable(df, caption = caption, align = c("l",
        rep("r", ncol(df) - 1)))
    },
    gt = {
      rlang::check_installed("gt")
      tab <- gt::gt(df)
      if (!is.null(caption)) tab <- gt::tab_header(tab, title = caption)
      tab
    },
    flextable = {
      rlang::check_installed("flextable")
      tab <- flextable::flextable(df)
      tab <- flextable::theme_booktabs(tab)
      tab <- flextable::autofit(tab)
      if (!is.null(caption)) tab <- flextable::set_caption(tab, caption)
      tab
    }
  )
}
