#' Partial-effect and two-predictor surface plots (visreg / plotmo style)
#'
#' Publication-ready ggplot replacements for the **visreg** and **plotmo**
#' workflow used in Moses et al. (2021). [plot_partial()] draws a
#' one-predictor conditional (partial) effect with optional residuals and
#' confidence band. [plot_surface()] draws a two-predictor response surface
#' as a filled contour (the pattern that paper built by converting
#' `visreg::visreg2d()` into ggplot by hand). No visreg or plotmo dependency.
#'
#' @param model A fitted model (`lm`, `glm`, `negbin`, `gam`, or
#'   [model_count()] / `td_count_model`).
#' @param x,y Focal predictor names (character) or bare names.
#' @param data Optional data frame used to build the prediction grid. Defaults
#'   to `model.frame(model)`.
#' @param by Optional conditioning variable for panels (partial plots).
#' @param residuals Overlay partial residuals?
#' @param se Draw a pointwise confidence band (partial) or skip (surface)?
#' @param level Confidence level for the band.
#' @param n Number of grid points per axis.
#' @param type `"contour"` (filled contours; default) or `"persp"` (base
#'   [graphics::persp()] drawn to the current device and returned as a
#'   recorded plot list; prefer `"contour"` for publication ggplot output).
#' @param points Overlay observed (x, y) points on the surface?
#' @param ... Passed to `predict` methods.
#' @return A ggplot object (`plot_partial`, `plot_surface` with
#'   `type = "contour"`). For `type = "persp"`, a list with the persp
#'   transformation matrix and the prediction grid (still no plotmo).
#' @references
#' Moses, J., Fayle, T. M., Novotny, V. and Klimes, P. (2021). Elevation and
#' leaf litter interact in determining the structure of ant communities on a
#' tropical mountain. *Biotropica*, 53, 906-919. \doi{10.1111/btp.12914}
#' @name plot-partial
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' ants <- png_ants |>
#'   dplyr::group_by(site, elevation) |>
#'   dplyr::summarise(richness = dplyr::n_distinct(species), .groups = "drop")
#' ants$litter <- 1 + ants$elevation / 2000 + stats::rnorm(nrow(ants), 0, 0.3)
#' fit <- model_count(ants, richness ~ poly(elevation, 2) * litter,
#'                    family = "poisson")
#' plot_partial(fit, elevation, residuals = TRUE)
#' plot_surface(fit, elevation, litter)
NULL

#' @rdname plot-partial
#' @export
plot_partial <- function(model,
                         x,
                         data = NULL,
                         by = NULL,
                         residuals = FALSE,
                         se = TRUE,
                         level = 0.95,
                         n = 100,
                         ...) {
  rlang::check_installed("ggplot2")
  x_name <- plot_term_name(enquo(x), model)
  by_q <- enquo(by)
  by_name <- if (quo_is_null(by_q)) NULL else plot_term_name(by_q, model)
  mf <- data %||% plot_model_frame(model)
  td_check_data(mf)
  if (!x_name %in% names(mf)) {
    cli::cli_abort("Predictor {.val {x_name}} not found in the model frame.")
  }

  grid <- plot_partial_grid(mf, x_name, by_name, n = n)
  pred <- plot_predict_response(model, grid, se = se, level = level, ...)
  grid$.fit <- pred$fit
  if (isTRUE(se)) {
    grid$.lower <- pred$lower
    grid$.upper <- pred$upper
  }

  p <- ggplot2::ggplot(grid, ggplot2::aes(.data[[x_name]], .data$.fit))
  if (isTRUE(se)) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$.lower, ymax = .data$.upper),
      alpha = 0.2, fill = plot_palette(1), colour = NA
    )
  }
  if (isTRUE(residuals)) {
    res <- plot_partial_residuals(model, mf, x_name)
    p <- p + ggplot2::geom_point(
      data = res,
      ggplot2::aes(.data[[x_name]], .data$.partial),
      inherit.aes = FALSE,
      alpha = 0.45, size = 1.6, colour = "grey30"
    )
  }
  p <- p +
    ggplot2::geom_line(linewidth = 0.9, colour = plot_palette(1)) +
    theme_tidydiversity() +
    ggplot2::labs(x = x_name, y = "Partial effect")
  if (!is.null(by_name)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[by_name]]))
  }
  p
}

#' @rdname plot-partial
#' @export
plot_surface <- function(model,
                         x,
                         y,
                         data = NULL,
                         n = 40,
                         type = c("contour", "persp"),
                         points = TRUE,
                         ...) {
  type <- rlang::arg_match(type)
  x_name <- plot_term_name(enquo(x), model)
  y_name <- plot_term_name(enquo(y), model)
  mf <- data %||% plot_model_frame(model)
  td_check_data(mf)
  for (nm in c(x_name, y_name)) {
    if (!nm %in% names(mf)) {
      cli::cli_abort("Predictor {.val {nm}} not found in the model frame.")
    }
  }
  xs <- seq(min(mf[[x_name]], na.rm = TRUE), max(mf[[x_name]], na.rm = TRUE),
            length.out = n)
  ys <- seq(min(mf[[y_name]], na.rm = TRUE), max(mf[[y_name]], na.rm = TRUE),
            length.out = n)
  grid <- expand.grid(xs, ys, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  names(grid) <- c(x_name, y_name)
  # Hold other predictors at typical values
  others <- setdiff(names(mf), c(x_name, y_name, "(weights)", "(offset)"))
  others <- others[others %in% names(mf)]
  for (nm in others) {
    v <- mf[[nm]]
    if (is.numeric(v)) {
      grid[[nm]] <- stats::median(v, na.rm = TRUE)
    } else {
      grid[[nm]] <- names(sort(table(v), decreasing = TRUE))[1]
      if (is.factor(v)) grid[[nm]] <- factor(grid[[nm]], levels = levels(v))
    }
  }
  pred <- plot_predict_response(model, grid, se = FALSE, ...)
  grid$.fit <- pred$fit

  if (identical(type, "persp")) {
    z <- matrix(grid$.fit, nrow = n, ncol = n)
    tr <- graphics::persp(
      xs, ys, z,
      xlab = x_name, ylab = y_name, zlab = "Fitted",
      theta = 35, phi = 25, col = "lightblue", border = "grey40",
      ticktype = "detailed"
    )
    return(invisible(list(persp = tr, grid = tibble::as_tibble(grid),
                          x = xs, y = ys, z = z)))
  }

  rlang::check_installed("ggplot2")
  p <- ggplot2::ggplot(grid, ggplot2::aes(.data[[x_name]], .data[[y_name]])) +
    ggplot2::geom_raster(ggplot2::aes(fill = .data$.fit), interpolate = TRUE) +
    ggplot2::stat_contour(
      ggplot2::aes(z = .data$.fit), colour = "grey40", linewidth = 0.3
    ) +
    ggplot2::scale_fill_viridis_c(name = "Fitted", option = "C") +
    theme_tidydiversity(grid = "none") +
    ggplot2::labs(x = x_name, y = y_name)
  if (isTRUE(points)) {
    p <- p + ggplot2::geom_point(
      data = mf,
      ggplot2::aes(.data[[x_name]], .data[[y_name]]),
      inherit.aes = FALSE,
      shape = 21, fill = "white", colour = "grey10", size = 1.8, stroke = 0.4
    )
  }
  p
}

# ---- internals ----------------------------------------------------------

plot_term_name <- function(quo, model) {
  if (rlang::quo_is_symbol(quo) || rlang::quo_is_call(quo)) {
    return(rlang::as_name(quo))
  }
  val <- rlang::eval_tidy(quo)
  if (is.character(val) && length(val) == 1) return(val)
  cli::cli_abort("Predictor must be a bare name or a string.")
}

plot_model_frame <- function(model) {
  if (inherits(model, "td_count_model")) {
    return(tibble::as_tibble(model$data))
  }
  tibble::as_tibble(stats::model.frame(model))
}

plot_partial_grid <- function(mf, x_name, by_name, n) {
  xr <- range(mf[[x_name]], na.rm = TRUE)
  xs <- seq(xr[1], xr[2], length.out = n)
  if (is.null(by_name)) {
    grid <- tibble::tibble(!!x_name := xs)
  } else {
    by_vals <- unique(stats::na.omit(mf[[by_name]]))
    grid <- tidyr_expand_grid(xs, by_vals, x_name, by_name)
  }
  others <- setdiff(names(mf), c(x_name, by_name, "(weights)", "(offset)"))
  for (nm in others) {
    v <- mf[[nm]]
    if (is.numeric(v)) {
      grid[[nm]] <- stats::median(v, na.rm = TRUE)
    } else {
      grid[[nm]] <- names(sort(table(v), decreasing = TRUE))[1]
      if (is.factor(v)) grid[[nm]] <- factor(grid[[nm]], levels = levels(v))
    }
  }
  grid
}

tidyr_expand_grid <- function(xs, by_vals, x_name, by_name) {
  out <- expand.grid(xs, by_vals, KEEP.OUT.ATTRS = FALSE,
                     stringsAsFactors = FALSE)
  names(out) <- c(x_name, by_name)
  tibble::as_tibble(out)
}

plot_predict_response <- function(model, newdata, se = TRUE, level = 0.95, ...) {
  m <- if (inherits(model, "td_count_model")) model$fit else model
  if (inherits(m, "negbin") || inherits(m, "glm") || inherits(m, "lm") ||
        inherits(m, "gam")) {
    pr <- stats::predict(m, newdata = newdata, type = "response", se.fit = se)
    if (isTRUE(se)) {
      z <- stats::qnorm(1 - (1 - level) / 2)
      fit <- as.numeric(pr$fit)
      sef <- as.numeric(pr$se.fit)
      return(list(fit = fit, lower = pmax(fit - z * sef, 0),
                  upper = fit + z * sef))
    }
    return(list(fit = as.numeric(pr)))
  }
  cli::cli_abort("Unsupported model class {.cls {class(m)}}.")
}

plot_partial_residuals <- function(model, mf, x_name) {
  m <- if (inherits(model, "td_count_model")) model$fit else model
  # Working residuals vs x as a simple partial residual stand-in
  r <- tryCatch(stats::residuals(m, type = "working"), error = function(e) {
    stats::residuals(m)
  })
  # Drop rows removed by NA action
  n <- length(r)
  out <- tibble::tibble(
    !!x_name := mf[[x_name]][seq_len(min(n, nrow(mf)))],
    .partial = as.numeric(r)[seq_len(min(n, nrow(mf)))] +
      as.numeric(stats::predict(m, type = "response"))[seq_len(min(n, nrow(mf)))]
  )
  out
}
