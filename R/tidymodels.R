#' Grouped cross-validation folds for community data
#'
#' Samples from the same site (or transect, plot, ...) are not independent,
#' so random cross-validation folds leak information and overstate model
#' skill (Roberts et al. 2017). `model_group_folds()` creates folds that keep
#' every row of a group together, using [rsample::group_vfold_cv()].
#'
#' @param data A data frame, typically one row per sampling unit.
#' @param group <[`tidy-select`][dplyr::dplyr_tidy_select]> The blocking
#'   column, such as `site`.
#' @param v Number of folds. Defaults to the number of groups
#'   (leave-one-group-out).
#' @param ... Passed to [rsample::group_vfold_cv()].
#' @return An `rset` object for use with tune.
#' @references Roberts, D. R. et al. (2017). Cross-validation strategies for
#'   data with temporal, spatial, hierarchical, or phylogenetic structure.
#'   *Ecography*, 40, 913-929. \doi{10.1111/ecog.02881}
#' @examplesIf rlang::is_installed("rsample")
#' units <- div_hill(png_ants, q = 0, .by = c(season, transect))
#' model_group_folds(units, group = site)
#' @export
model_group_folds <- function(data, group, v = NULL, ...) {
  rlang::check_installed("rsample", reason = "to create resamples.")
  col <- names(tidyselect::eval_select(rlang::enquo(group), data))
  if (length(col) != 1) {
    cli::cli_abort("{.arg group} must select exactly one column.")
  }
  n_groups <- length(unique(data[[col]]))
  if (n_groups < 2) {
    cli::cli_abort("{.arg group} needs at least two groups, not {n_groups}.")
  }
  if (is.null(v)) {
    v <- n_groups
  }
  rsample::group_vfold_cv(data, group = tidyselect::all_of(col), v = v, ...)
}

#' Precision weights from estimated diversity
#'
#' Asymptotic diversity estimates differ in precision between sites: a
#' poorly sampled site has a large standard error. `model_case_weights()`
#' turns standard errors from [div_estimate()] or [div_boot()] into
#' inverse-variance weights, normalised to mean 1, as
#' [hardhat::importance_weights()] for use with `workflows::add_case_weights()`.
#'
#' @param se Numeric vector of standard errors.
#' @param cap Largest allowed ratio between weights, to stop sites with an
#'   SE near zero from dominating. `Inf` for no cap.
#' @return A `hardhat_importance_weights` vector.
#' @examplesIf rlang::is_installed("hardhat")
#' est <- div_estimate(png_ants, q = 1, .by = season)
#' est$w <- model_case_weights(est$se)
#' est
#' @export
model_case_weights <- function(se, cap = 100) {
  rlang::check_installed("hardhat", reason = "to create case weights.")
  if (!is.numeric(se) || any(se < 0, na.rm = TRUE)) {
    cli::cli_abort("{.arg se} must be non-negative numbers.")
  }
  if (anyNA(se)) {
    cli::cli_abort("{.arg se} must not contain missing values.")
  }
  floor_se <- max(se) / sqrt(cap)
  w <- 1 / pmax(se, floor_se, .Machine$double.eps)^2
  hardhat::importance_weights(w / mean(w))
}

#' Hill number features in a recipe
#'
#' `step_hill()` is a [recipes](https://recipes.tidymodels.org) step that
#' replaces wide species columns (one column per species, abundance or
#' incidence values) with Hill numbers of chosen orders, so community
#' diversity can be used as a predictor in tidymodels workflows.
#'
#' @param recipe A recipe.
#' @param ... Selectors for the species columns.
#' @param q Orders of diversity; one output column per order, named
#'   `prefix` + `q`.
#' @param prefix Prefix for the new columns.
#' @param keep_original_cols Keep the species columns?
#' @param role,trained,columns,skip,id Standard recipe step arguments.
#' @return An updated recipe.
#' @examplesIf rlang::is_installed("recipes")
#' wide <- data.frame(elev = c(200, 700, 1200),
#'                    sp1 = c(5, 0, 2), sp2 = c(1, 3, 0), sp3 = c(2, 2, 2))
#' recipes::recipe(elev ~ ., data = wide) |>
#'   step_hill(dplyr::starts_with("sp"), q = c(0, 2)) |>
#'   recipes::prep() |>
#'   recipes::bake(new_data = NULL)
#' @export
step_hill <- function(recipe,
                      ...,
                      q = c(0, 1, 2),
                      prefix = "hill_q",
                      keep_original_cols = FALSE,
                      role = "predictor",
                      trained = FALSE,
                      columns = NULL,
                      skip = FALSE,
                      id = NULL) {
  rlang::check_installed("recipes", reason = "to use `step_hill()`.")
  if (is.null(id)) {
    id <- recipes::rand_id("hill")
  }
  recipes::add_step(recipe, step_hill_new(
    terms = rlang::enquos(...), q = q, prefix = prefix,
    keep_original_cols = keep_original_cols, role = role,
    trained = trained, columns = columns, skip = skip, id = id
  ))
}

step_hill_new <- function(terms, q, prefix, keep_original_cols, role,
                          trained, columns, skip, id) {
  recipes::step(
    subclass = "hill", terms = terms, q = q, prefix = prefix,
    keep_original_cols = keep_original_cols, role = role,
    trained = trained, columns = columns, skip = skip, id = id
  )
}

#' @exportS3Method recipes::prep
prep.step_hill <- function(x, training, info = NULL, ...) {
  cols <- recipes::recipes_eval_select(x$terms, training, info)
  recipes::check_type(training[, cols], types = c("double", "integer"))
  step_hill_new(
    terms = x$terms, q = x$q, prefix = x$prefix,
    keep_original_cols = x$keep_original_cols, role = x$role,
    trained = TRUE, columns = cols, skip = x$skip, id = x$id
  )
}

#' @exportS3Method recipes::bake
bake.step_hill <- function(object, new_data, ...) {
  cols <- object$columns
  recipes::check_new_data(cols, object, new_data)
  mat <- as.matrix(new_data[, cols, drop = FALSE])
  if (any(mat < 0, na.rm = TRUE)) {
    cli::cli_abort("Species columns must not be negative.")
  }
  hill <- t(apply(mat, 1, function(x) {
    x <- x[!is.na(x) & x > 0]
    if (length(x) == 0) rep(0, length(object$q)) else hill_obs(x, object$q)
  }))
  if (length(object$q) == 1) {
    hill <- t(hill)
  }
  colnames(hill) <- paste0(object$prefix, object$q)
  if (!isTRUE(object$keep_original_cols)) {
    new_data <- new_data[, setdiff(names(new_data), cols), drop = FALSE]
  }
  new_data[colnames(hill)] <- as.data.frame(hill)
  tibble::as_tibble(new_data)
}

#' @export
print.step_hill <- function(x, width = max(20, options()$width - 30), ...) {
  title <- paste0("Hill numbers (q = ", paste(x$q, collapse = ", "), ") from ")
  recipes::print_step(x$columns, x$terms, x$trained, title, width)
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.step_hill <- function(x, ...) {
  terms <- if (recipes::is_trained(x)) {
    unname(x$columns)
  } else {
    vapply(x$terms, rlang::as_label, character(1))
  }
  tibble::tibble(terms = terms, id = x$id)
}
