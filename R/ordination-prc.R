#' Principal response curves
#'
#' @description
#' `ord_prc()` fits principal response curves (PRC; van den Brink and ter
#' Braak 1999), a partial redundancy analysis that shows how the community
#' of each treatment departs from a control over time, with time as a
#' condition. Each treatment's departure at each time is one canonical
#' coefficient, and each species has a weight: species with large positive
#' weights follow the curves, species with large negative weights do the
#' opposite. `autoplot()` draws the classic PRC diagram: the curves of the
#' treatments against time, with the control as the zero line, and the
#' species weights on a scale beside them.
#'
#' @inheritParams ord_fit
#' @param treatment,time Columns giving the treatment and the time (survey
#'   year or sampling date) of each site (sample).
#' @param control Level of `treatment` used as the control; default the
#'   first level.
#' @param transform Transformation of the abundances (as in [ord_fit()]);
#'   default `"log"` (log(x + 1)), usual for PRC.
#' @param permutations Number of permutations for the test of the first
#'   axis; permutations are restricted within times.
#' @return A list of class `td_prc`: `curves` (a tibble of `treatment`,
#'   `time` and `coefficient`), `species` (a tibble of `species` and
#'   `weight`), `test` (the permutation test of the first PRC axis),
#'   `explained` (share of the variation explained by treatment, after
#'   time) and the fitted `vegan::prc()` model.
#' @references
#' van den Brink, P. J. and ter Braak, C. J. F. (1999). Principal response
#' curves: analysis of time-dependent multivariate responses of biological
#' community to stress. Environmental Toxicology and Chemistry, 18,
#' 138-148.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' p <- ord_prc(portal_rodents,
#'   treatment = treatment, time = year,
#'   abundance = abundance, permutations = 99
#' )
#' p
#' ggplot2::autoplot(p)
ord_prc <- function(data,
                    treatment,
                    time,
                    site = site,
                    species = species,
                    abundance = NULL,
                    control = NULL,
                    transform = "log",
                    permutations = 999) {
  rlang::check_installed("vegan", "for principal response curves.")
  td_check_data(data)
  trt_col <- td_pick(enquo(treatment), data, "treatment")
  time_col <- td_pick(enquo(time), data, "time")
  site_col <- td_pick(enquo(site), data, "site")
  prep <- td_prepare(data, enquo(site), enquo(species), enquo(abundance), rlang::quo(NULL))
  y <- ord_matrix(prep$data)
  y <- ord_transform(y, transform)
  info <- unique(as.data.frame(data)[c(site_col, trt_col, time_col)])
  info <- info[match(rownames(y), as.character(info[[site_col]])), , drop = FALSE]
  if (anyNA(info[[trt_col]]) || anyDuplicated(info[[site_col]])) {
    cli::cli_abort("Each site needs exactly one {.field {trt_col}} and one {.field {time_col}}.")
  }
  trt <- as.factor(info[[trt_col]])
  control <- control %||% levels(trt)[1]
  if (!control %in% levels(trt)) {
    cli::cli_abort("{.arg control} must be a level of {.field {trt_col}}.")
  }
  trt <- stats::relevel(trt, control)
  tm <- as.factor(info[[time_col]])
  fit <- vegan::prc(response = y, treatment = trt, time = tm)
  sm <- summary(fit)
  cf <- sm$coefficients
  curves <- tibble::tibble(
    treatment = rep(rownames(cf), times = ncol(cf)),
    time = rep(colnames(cf), each = nrow(cf)),
    coefficient = as.vector(cf)
  )
  curves <- vctrs::vec_rbind(
    tibble::tibble(treatment = control, time = colnames(cf), coefficient = 0),
    curves
  )
  curves$treatment <- factor(curves$treatment, c(control, rownames(cf)))
  tnum <- suppressWarnings(as.numeric(curves$time))
  curves$time <- if (!anyNA(tnum)) tnum else factor(curves$time, levels(tm))
  sp <- sm$sp
  species_w <- tibble::tibble(species = names(sp), weight = unname(sp))
  ctrl <- permute::how(nperm = permutations, blocks = tm)
  test <- vegan::anova.cca(fit, permutations = ctrl, first = TRUE)
  explained <- fit$CCA$tot.chi / (fit$tot.chi - (if (is.null(fit$pCCA)) 0 else fit$pCCA$tot.chi))
  structure(list(
    curves = curves, species = species_w[order(-species_w$weight), ],
    test = tibble::tibble(
      axis = "PRC1", statistic = test$F[1], p.value = test$`Pr(>F)`[1],
      permutations = permutations
    ),
    explained = explained, control = control, treatment = trt_col, time = time_col,
    fit = fit
  ), class = "td_prc")
}

#' @export
print.td_prc <- function(x, ...) {
  cli::cli_text(
    "Principal response curves: {nlevels(x$curves$treatment) - 1} treatment{?s} against ",
    "{.val {x$control}}, {length(unique(x$curves$time))} times."
  )
  cli::cli_text(
    "Treatment explains {round(100 * x$explained, 1)}% of the variation after time; ",
    "first axis F = {signif(x$test$statistic, 3)}, p = {signif(x$test$p.value, 2)}."
  )
  invisible(x)
}

#' @rdname ord_prc
#' @param object An `ord_prc()` result.
#' @param weights Species weights to show: those with an absolute weight of
#'   at least this.
#' @param palette Colours of the treatments.
#' @param style Look of the diagram, from [ord_style()].
#' @param ... Not used.
#' @exportS3Method ggplot2::autoplot
autoplot.td_prc <- function(object, weights = 0.5, palette = "okabe_ito",
                            style = ord_style(), ...) {
  rlang::check_installed(c("ggplot2", "patchwork"))
  st <- style
  cu <- object$curves
  main <- ggplot2::ggplot(cu, ggplot2::aes(.data$time, .data$coefficient,
    colour = .data$treatment, group = .data$treatment
  )) +
    ggplot2::geom_hline(
      yintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(ggplot2::aes(fill = .data$treatment),
      shape = 21, colour = st$site_outline,
      size = 0.8 * st$site_size, stroke = st$site_stroke
    ) +
    ggplot2::labs(
      x = ord_pretty(object$time), y = "Canonical coefficient (PRC1)",
      colour = ord_pretty(object$treatment), fill = ord_pretty(object$treatment),
      caption = sprintf(
        "Treatment explains %.1f%% of the variation after time; first axis F = %.2f, p = %s",
        100 * object$explained, object$test$statistic, ord_fmt_p(object$test$p.value)
      )
    ) +
    ord_theme(st)
  main <- td_style(main, palette, NULL)
  sp <- object$species[abs(object$species$weight) >= weights, ]
  yr <- range(c(object$species$weight, 0))
  w <- ggplot2::ggplot(sp, ggplot2::aes(0, .data$weight)) +
    ggplot2::geom_hline(
      yintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_segment(ggplot2::aes(x = -0.15, xend = 0, yend = .data$weight),
      colour = "grey40", linewidth = 0.4
    ) +
    ggplot2::geom_text(ggplot2::aes(x = 0.05, label = .data$species),
      hjust = 0,
      family = st$font, fontface = st$species_fontface, size = st$label_size,
      colour = st$species_label_colour
    ) +
    ggplot2::scale_x_continuous(limits = c(-0.2, 1.2), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = yr, position = "right") +
    ggplot2::labs(x = NULL, y = "Species weight") +
    ord_theme(st) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),
      axis.line.y.right = ggplot2::element_line(colour = "grey25", linewidth = 0.4)
    )
  patchwork::wrap_plots(main, w, widths = c(3, 1))
}

# ---- Variation partitioning diagram ---------------------------------------

#' @rdname ord_varpart
#' @param object An `ord_varpart()` result.
#' @param fill Fill colours of the sets.
#' @param style Look of the diagram, from [ord_style()].
#' @param ... Not used.
#' @exportS3Method ggplot2::autoplot
autoplot.td_varpart <- function(object, fill = c("#56B4E9", "#E69F00", "#009E73", "#CC79A7"),
                                style = ord_style(), ...) {
  rlang::check_installed("ggplot2")
  st <- style
  sets <- attr(object, "sets")
  k <- length(sets)
  pct <- function(v) ifelse(is.na(v), "", ifelse(v < 0, "< 0%", sprintf("%.1f%%", 100 * v)))
  frac <- object$adj_r2
  resid <- frac[nrow(object)]
  stars <- ifelse(!is.na(object$p.value) & object$p.value < 0.05, "*", "")
  if (k > 3) {
    d <- object[-nrow(object), ]
    d$label <- factor(d$label, rev(d$label))
    return(ggplot2::ggplot(d, ggplot2::aes(100 * .data$adj_r2, .data$label)) +
      ggplot2::geom_col(fill = fill[1], colour = st$site_outline, linewidth = 0.3, width = 0.7) +
      ggplot2::labs(
        x = "Adjusted R\u00b2 (%)", y = NULL,
        caption = sprintf("Residual: %s", pct(resid))
      ) +
      ord_theme(st))
  }
  th <- seq(0, 2 * pi, length.out = 200)
  ctr <- if (k == 2) {
    data.frame(x = c(-0.55, 0.55), y = c(0, 0))
  } else {
    data.frame(x = c(-0.55, 0.55, 0), y = c(0.35, 0.35, -0.6))
  }
  circ <- do.call(rbind, lapply(seq_len(k), function(i) {
    data.frame(x = ctr$x[i] + cos(th), y = ctr$y[i] + sin(th), set = sets[i])
  }))
  circ$set <- factor(circ$set, sets)
  # Label positions of the fractions (vegan order: unique, then shared)
  pos <- if (k == 2) {
    data.frame(x = c(-0.95, 0.95, 0), y = c(0, 0, 0))
  } else {
    data.frame(
      x = c(-0.95, 0.95, 0, 0, 0.55, -0.55, 0),
      y = c(0.55, 0.55, -1.05, 0.75, -0.25, -0.25, 0.05)
    )
  }
  nf <- nrow(pos)
  pos$lab <- paste0(pct(frac[seq_len(nf)]), stars[seq_len(nf)])
  nm <- data.frame(
    x = if (k == 2) c(-1.25, 1.25) else c(-1.45, 1.45, 0),
    y = if (k == 2) c(1.15, 1.15) else c(1.45, 1.45, -1.75),
    lab = sets
  )
  ggplot2::ggplot() +
    ggplot2::geom_polygon(ggplot2::aes(.data$x, .data$y, fill = .data$set, group = .data$set),
      data = circ, alpha = 0.35, colour = "grey25", linewidth = 0.4
    ) +
    ggplot2::geom_text(ggplot2::aes(.data$x, .data$y, label = .data$lab),
      data = pos,
      family = st$font, size = 1.2 * st$label_size
    ) +
    ggplot2::geom_text(ggplot2::aes(.data$x, .data$y, label = .data$lab),
      data = nm,
      family = st$font, fontface = "bold", size = 1.3 * st$label_size
    ) +
    ggplot2::scale_fill_manual(values = fill[seq_len(k)], guide = "none") +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::labs(caption = sprintf(
      "Adjusted R\u00b2 of each fraction; * testable fraction with p < 0.05; residual %s",
      pct(resid)
    )) +
    ggplot2::theme_void(base_family = st$font) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
}
