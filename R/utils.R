# Column handling ---------------------------------------------------------

td_check_data <- function(data, call = caller_env()) {
  if (!is.data.frame(data)) {
    cli::cli_abort(
      "{.arg data} must be a data frame, not {.obj_type_friendly {data}}.",
      call = call
    )
  }
  if (nrow(data) == 0) {
    cli::cli_abort("{.arg data} must have at least one row.", call = call)
  }
  invisible(data)
}

td_pick <- function(quo, data, arg, call = caller_env()) {
  loc <- tidyselect::eval_select(
    quo,
    data,
    allow_rename = FALSE,
    error_call = call
  )
  if (length(loc) != 1) {
    cli::cli_abort(
      "{.arg {arg}} must select exactly one column, not {length(loc)}.",
      call = call
    )
  }
  names(loc)
}

td_group_cols <- function(data, by, call = caller_env()) {
  by_cols <- names(tidyselect::eval_select(by, data, error_call = call))
  if (length(by_cols) > 0 && dplyr::is_grouped_df(data)) {
    cli::cli_abort(
      "Can't supply {.arg .by} when {.arg data} is a grouped data frame.",
      call = call
    )
  }
  if (length(by_cols) == 0) {
    by_cols <- dplyr::group_vars(data)
  }
  by_cols
}

# Tidy the input into one row per group, site and species with a count.
td_prepare <- function(data,
                       site,
                       species,
                       abundance,
                       by,
                       counts = FALSE,
                       unit = rlang::quo(NULL),
                       n_units = rlang::quo(NULL),
                       call = caller_env()) {
  td_check_data(data, call = call)
  site_col <- td_pick(site, data, "site", call = call)
  species_col <- td_pick(species, data, "species", call = call)
  if (quo_is_null(abundance)) {
    ab_col <- if ("abundance" %in% names(data)) "abundance" else NULL
  } else {
    ab_col <- td_pick(abundance, data, "abundance", call = call)
  }
  by_cols <- td_group_cols(data, by, call = call)

  clash <- intersect(c(site_col, species_col, ab_col), by_cols)
  if (length(clash) > 0) {
    cli::cli_abort(
      "Grouping column{?s} {.field {clash}} can't also be used as \\
      {.arg site}, {.arg species} or {.arg abundance}.",
      call = call
    )
  }

  n <- if (is.null(ab_col)) rep(1, nrow(data)) else data[[ab_col]]
  if (!is.numeric(n)) {
    cli::cli_abort(
      "Column {.field {ab_col}} must be numeric, not \\
      {.obj_type_friendly {n}}.",
      call = call
    )
  }
  bad <- is.na(n) | !is.finite(n) | n < 0
  if (any(bad)) {
    cli::cli_abort(
      c(
        "Column {.field {ab_col}} must contain non-negative, finite values.",
        "x" = "Problem at {cli::qty(sum(bad))}row{?s} \\
        {head(which(bad), 5)}."
      ),
      call = call
    )
  }
  if (counts && any(abs(n - round(n)) > 1e-8)) {
    cli::cli_abort(
      c(
        "Column {.field {ab_col}} must contain whole-number counts.",
        "i" = "Estimators based on sampling theory need counts of \\
        individuals."
      ),
      call = call
    )
  }
  for (col in c(site_col, species_col)) {
    if (anyNA(data[[col]])) {
      cli::cli_abort(
        "Column {.field {col}} must not contain missing values.",
        call = call
      )
    }
  }

  df <- tibble::as_tibble(dplyr::ungroup(data)[by_cols])
  df$.site <- data[[site_col]]
  df$.species <- as.character(data[[species_col]])
  df$.n <- n
  if (!quo_is_null(unit)) {
    return(td_prepare_incidence(
      df, data, by_cols, site_col, unit, n_units,
      call = call
    ))
  }
  df <- dplyr::summarise(
    df,
    .n = sum(.data$.n),
    .by = dplyr::all_of(c(by_cols, ".site", ".species"))
  )
  df <- df[df$.n > 0, , drop = FALSE]
  if (nrow(df) == 0) {
    cli::cli_abort("{.arg data} has no positive abundances.", call = call)
  }

  list(data = df, by = by_cols, site = site_col)
}

# Apply `fn` to the counts of each site and bind the results with the keys.
td_per_site <- function(prep, fn) {
  keys <- prep$data[c(prep$by, ".site")]
  counts <- stats::setNames(prep$data$.n, prep$data$.species)
  split <- vctrs::vec_split(counts, keys)
  inc <- prep$incidence
  if (!is.null(inc)) {
    k <- inc$key_of(split$key)
    split$val <- lapply(seq_along(k), function(i) {
      as_incidence(split$val[[i]], inc$n_units[[k[i]]], inc$mats[[k[i]]])
    })
  }
  out <- lapply(seq_along(split$val), function(i) {
    res <- fn(split$val[[i]], i)
    key <- vctrs::vec_slice(split$key, rep(i, nrow(res)))
    vctrs::vec_cbind(key, res)
  })
  out <- vctrs::vec_rbind(!!!out)
  td_rename_site(out, prep$site)
}

# Apply `fn` to each group (a data frame with .site, .species and .n).
td_per_group <- function(prep, fn) {
  if (length(prep$by) == 0) {
    return(tibble::as_tibble(fn(prep$data)))
  }
  split <- vctrs::vec_split(prep$data, prep$data[prep$by])
  out <- lapply(seq_along(split$val), function(i) {
    res <- fn(split$val[[i]])
    key <- vctrs::vec_slice(split$key, rep(i, nrow(res)))
    vctrs::vec_cbind(key, res)
  })
  tibble::as_tibble(vctrs::vec_rbind(!!!out))
}

td_rename_site <- function(x, site) {
  names(x)[names(x) == ".site"] <- site
  tibble::as_tibble(x)
}

td_check_q <- function(q, integer = FALSE, finite = FALSE,
                       call = caller_env()) {
  if (!is.numeric(q) || length(q) == 0 || anyNA(q) || any(q < 0)) {
    cli::cli_abort(
      "{.arg q} must be a numeric vector of non-negative orders.",
      call = call
    )
  }
  if (finite && !all(is.finite(q))) {
    cli::cli_abort("{.arg q} must contain finite orders.", call = call)
  }
  if (integer && !all(q %in% c(0, 1, 2))) {
    cli::cli_abort(
      c(
        "{.arg q} must contain only 0, 1 or 2.",
        "i" = "Estimators for other orders are not yet available."
      ),
      call = call
    )
  }
  sort(unique(q))
}

# rmultinom() draws at most .Machine$integer.max individuals.
td_check_boot_n <- function(n, call = caller_env()) {
  if (any(n > .Machine$integer.max)) {
    cli::cli_abort(
      c(
        "Bootstrap resampling needs at most \\
        {format(.Machine$integer.max, big.mark = \",\")} individuals per sample.",
        "i" = "Use {.code nboot = 0} for larger totals."
      ),
      call = call
    )
  }
}

td_check_number <- function(x, arg, min = 0, max = Inf, whole = FALSE,
                            call = caller_env()) {
  ok <- is.numeric(x) && length(x) == 1 && !is.na(x) && x >= min && x <= max
  if (ok && whole) ok <- abs(x - round(x)) < 1e-8
  if (!ok) {
    what <- if (whole) "a whole number" else "a number"
    cli::cli_abort(
      "{.arg {arg}} must be {what} between {min} and {max}.",
      call = call
    )
  }
  invisible(x)
}

td_check_min_n <- function(prep, min = 2, call = caller_env()) {
  if (!is.null(prep$incidence)) {
    return(invisible(prep))
  }
  tot <- vctrs::vec_split(prep$data$.n, prep$data[c(prep$by, ".site")])
  n <- vapply(tot$val, sum, numeric(1))
  if (any(n < min)) {
    bad <- as.character(tot$key$.site[n < min])
    cli::cli_abort(
      c(
        "Each site needs at least {min} individuals.",
        "x" = "Too few at {.val {bad}}."
      ),
      call = call
    )
  }
  invisible(prep)
}

td_new <- function(x, class) {
  tibble::new_tibble(x, class = class)
}
