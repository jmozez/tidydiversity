# Further ordination diagrams, chosen with autoplot(type = ). Each uses the
# style of ord_style() and returns a ggplot (or a patchwork) that can be
# customised further.

ord_plot_dispatch <- function(object, type, st, args) {
  switch(type,
    gradient = ord_plot_gradient(object, st,
      path = args$path, species = args$species %||% 12, axes = args$axes %||% c(1, 2)
    ),
    response = ord_plot_response(object, st,
      axis = args$axis %||% 1, variable = args$variable, species = args$species %||% 6,
      model = args$model %||% "glm", layout = args$layout %||% "facet",
      level = args$level %||% 0.95, palette = args$palette %||% "okabe_ito"
    ),
    scree = ord_plot_scree(object, st, n = args$n_axes %||% 10),
    shepard = ord_plot_shepard(object, st),
    vandobben = ord_plot_vandobben(object, st,
      variable = args$variable, species = args$species %||% 25
    ),
    stability = ord_plot_stability(object, st,
      nboot = args$nboot %||% 199, level = args$level %||% 0.95, axes = args$axes %||% c(1, 2)
    ),
    tvalue = ord_plot_tvalue(object, st,
      variable = args$variable, species = args$species %||% 20, axes = args$axes %||% c(1, 2)
    )
  )
}

ord_theme <- function(st) {
  ggplot2::theme_bw(base_family = st$font, base_size = 10) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(colour = "grey25", linewidth = 0.5),
      axis.ticks = ggplot2::element_line(colour = "grey25", linewidth = 0.3),
      axis.text = ggplot2::element_text(colour = "grey20"),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "italic", hjust = 0),
      legend.position = "bottom",
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
}

ord_fmt_p <- function(p) formatC(p, format = "g", digits = 2)

# Fitted vectors with their r2 and p, scaled like autoplot()
ord_vectors_fit <- function(object, site_df, ax) {
  vec <- object$vectors
  if (!nrow(vec) || !all(ax %in% names(vec))) {
    return(NULL)
  }
  vec$.x <- vec[[ax[1]]]
  vec$.y <- vec[[ax[2]]]
  mul <- ord_arrow_mul(site_df, vec)
  vec$.x <- vec$.x * mul
  vec$.y <- vec$.y * mul
  ef <- object$envfit
  m <- if (!is.null(ef)) match(vec$term, ef$term) else rep(NA_integer_, nrow(vec))
  vec$r2 <- if (!is.null(ef)) ef$r2[m] else NA_real_
  vec$p <- if (!is.null(ef)) ef$p.value[m] else NA_real_
  vec$sig <- is.na(vec$p) | vec$p < 0.05
  vec$.label <- ifelse(is.na(vec$r2), ord_pretty(vec$term), sprintf(
    "%s  r\u00b2 = %.2f, p = %s", ord_pretty(vec$term), vec$r2, ord_fmt_p(vec$p)
  ))
  vec
}

# ---- Gradient layout --------------------------------------------------------

ord_plot_gradient <- function(object, st, path = NULL, species = 12, axes = c(1, 2)) {
  rlang::check_installed("patchwork", "for the gradient layout.")
  ax <- paste0("axis", axes)
  sd <- object$sites
  sd$.x <- sd[[ax[1]]]
  sd$.y <- sd[[ax[2]]]
  sd$.label <- sd[[object$site_col]]
  vec <- ord_vectors_fit(object, sd, ax)
  lab <- ord_axis_labels(object, axes)
  xr <- range(c(sd$.x, vec$.x, 0))
  yr <- range(c(sd$.y, vec$.y, 0))
  xr <- xr + c(-0.12, 0.12) * diff(xr)
  yr <- yr + c(-0.12, 0.12) * diff(yr)
  p <- ggplot2::ggplot() +
    ggplot2::geom_hline(
      yintercept = 0, colour = st$origin_colour,
      linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_vline(xintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth)
  if (!is.null(path)) {
    o_ <- order(sd[[path]])
    tr <- data.frame(
      x = utils::head(sd$.x[o_], -1), y = utils::head(sd$.y[o_], -1),
      xend = sd$.x[o_][-1], yend = sd$.y[o_][-1]
    )
    p <- p + ggplot2::geom_segment(
      ggplot2::aes(.data$x, .data$y, xend = .data$xend, yend = .data$yend),
      data = tr, colour = st$path_colour, linewidth = st$path_linewidth
    ) + ggplot2::geom_segment(
      ggplot2::aes(.data$x, .data$y,
        xend = (.data$x + .data$xend) / 2, yend = (.data$y + .data$yend) / 2
      ),
      data = tr, colour = st$path_colour, linewidth = st$path_linewidth,
      arrow = ggplot2::arrow(length = ggplot2::unit(1.6, "mm"), type = "closed")
    )
  }
  ends <- c("", "")
  if (!is.null(vec)) {
    # Fit drawn into the arrows: width follows r2; non-significant are thin,
    # dashed and grey
    vec$.w <- ifelse(is.na(vec$r2), st$env_linewidth, 0.3 + 1.1 * vec$r2)
    vec$.col <- ifelse(vec$sig, st$env_colour, "grey60")
    vec$.lty <- ifelse(vec$sig, "solid", "22")
    p <- p + ggplot2::geom_segment(
      ggplot2::aes(0, 0,
        xend = .data$.x, yend = .data$.y, linewidth = I(.data$.w),
        colour = I(.data$.col), linetype = I(.data$.lty)
      ),
      data = vec, arrow = ggplot2::arrow(length = ggplot2::unit(2.4, "mm"), type = "closed")
    ) + ggplot2::geom_label(
      ggplot2::aes(.data$.x, .data$.y,
        label = .data$.label, colour = I(.data$.col),
        hjust = ifelse(abs(.data$.x) < 0.3 * abs(.data$.y), 0.5, ifelse(.data$.x > 0, 1, 0)),
        vjust = ifelse(.data$.y >= 0, -0.45, 1.45)
      ),
      data = vec, family = st$font, size = st$label_size, fill = "white",
      label.r = ggplot2::unit(0.12, "lines")
    )
    # What the first axis means, from the significant variables loading on it
    v <- vec[vec$sig & abs(vec$.x) > 0.6 * sqrt(vec$.x^2 + vec$.y^2), ]
    if (nrow(v)) {
      hi <- paste(ifelse(v$.x > 0, "higher", "lower"), tolower(ord_pretty(v$term)), collapse = ", ")
      lo <- paste(ifelse(v$.x > 0, "lower", "higher"), tolower(ord_pretty(v$term)), collapse = ", ")
      ends <- c(paste("\u2190", lo), paste(hi, "\u2192"))
    }
  }
  p <- p +
    ggplot2::geom_point(ggplot2::aes(.data$.x, .data$.y),
      data = sd, shape = 21, fill = st$site_fill, colour = st$site_outline,
      size = st$site_size, stroke = st$site_stroke
    ) +
    ord_text(
      tibble::tibble(
        .x = sd$.x, .y = sd$.y, .label = as.character(sd$.label),
        .col = st$site_label_colour, .face = st$site_fontface, .size = 1.1 * st$label_size
      ),
      sd[c(".x", ".y")], st$font
    ) +
    ggplot2::annotate("text",
      x = xr[1], y = -Inf, label = ends[1], hjust = 0, vjust = -0.6,
      family = st$font, size = st$label_size, colour = st$env_colour, fontface = "italic"
    ) +
    ggplot2::annotate("text",
      x = xr[2], y = -Inf, label = ends[2], hjust = 1, vjust = -0.6,
      family = st$font, size = st$label_size, colour = st$env_colour, fontface = "italic"
    ) +
    ggplot2::coord_cartesian(xlim = xr, ylim = yr, expand = FALSE, clip = "off") +
    ggplot2::labs(x = NULL, y = lab[2]) +
    ord_theme(st) +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
  # Species sorted along the first axis, in their own panel
  spp <- object$species
  spp$.x <- spp[[ax[1]]]
  spp$.len <- sqrt(spp[[ax[1]]]^2 + spp[[ax[2]]]^2)
  spp <- spp[order(-spp$.len), ][seq_len(min(species, nrow(spp))), ]
  spp$.x <- spp$.x * (0.9 * max(abs(sd$.x)) / max(abs(spp$.x)))
  spp <- spp[order(spp$.x), ]
  spp$.row <- seq_len(nrow(spp))
  strip <- ggplot2::ggplot(spp, ggplot2::aes(.data$.x, .data$.row)) +
    ggplot2::geom_vline(
      xintercept = 0, colour = st$origin_colour,
      linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_point(
      shape = st$species_shape, colour = st$species_colour,
      size = st$species_size, stroke = 0.6
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data$species, hjust = ifelse(.data$.x > 0, 1.15, -0.15)),
      family = st$font, fontface = st$species_fontface, size = st$label_size,
      colour = st$species_label_colour
    ) +
    ggplot2::coord_cartesian(xlim = xr, ylim = c(0.3, nrow(spp) + 0.7), expand = FALSE) +
    ggplot2::labs(x = lab[1], y = sprintf("Species\n(%d best fitted)", nrow(spp))) +
    ord_theme(st) +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank())
  patchwork::wrap_plots(p, strip, ncol = 1, heights = c(
    diff(yr) / diff(xr),
    0.06 * nrow(spp) + 0.05
  ))
}

# ---- Species response curves ------------------------------------------------

ord_plot_response <- function(object, st, axis = 1, variable = NULL, species = 6,
                              model = c("glm", "gam"), layout = c("facet", "overlay"),
                              level = 0.95, palette = "okabe_ito") {
  model <- rlang::arg_match(model)
  layout <- rlang::arg_match(layout)
  y <- object$community
  if (is.null(y)) cli::cli_abort("Refit the ordination with this version of {.fn ord_fit}.")
  sd <- object$sites
  if (!is.null(variable)) {
    if (!variable %in% names(sd) || !is.numeric(sd[[variable]])) {
      cli::cli_abort("{.arg variable} must be a numeric site variable of the ordination.")
    }
    x <- sd[[variable]]
    xlab <- ord_pretty(variable)
  } else {
    x <- sd[[paste0("axis", axis)]]
    xlab <- ord_axis_labels(object, c(axis, axis))[1]
  }
  y <- y[as.character(sd[[object$site_col]]), , drop = FALSE]
  z <- stats::qnorm(1 - (1 - level) / 2)
  n <- length(x)
  # Fit on a standardised gradient, for numerical stability
  xm <- mean(x)
  xs <- stats::sd(x)
  fits <- lapply(colnames(y), function(s) {
    d <- data.frame(x = (x - xm) / xs, y = y[, s])
    # A response curve needs the species at three or more sites
    if (sum(d$y > 0) < 3) {
      return(NULL)
    }
    f <- tryCatch(
      if (model == "glm") {
        # ter Braak's Gaussian response: a quadratic on the log scale
        suppressWarnings(stats::glm(y ~ x + I(x^2), family = stats::poisson(), data = d))
      } else {
        rlang::check_installed("mgcv")
        mgcv::gam(y ~ s(x, k = min(4, n - 1)), family = stats::poisson(), data = d, method = "REML")
      },
      error = function(e) NULL
    )
    if (is.null(f) || !isTRUE(f$converged)) {
      return(NULL)
    }
    dev <- 1 - f$deviance / f$null.deviance
    g <- data.frame(x = seq(min(d$x), max(d$x), length.out = 101))
    pr <- stats::predict(f, g, type = "link", se.fit = TRUE)
    # Unstable fits (near-separation) have huge standard errors: skip them
    if (!all(is.finite(pr$se.fit)) || stats::median(pr$se.fit) > 2) {
      return(NULL)
    }
    top <- 1.5 * max(d$y, exp(pr$fit))
    list(
      curve = data.frame(
        species = s, x = g$x * xs + xm, fit = exp(pr$fit),
        lower = exp(pr$fit - z * pr$se.fit),
        upper = pmin(exp(pr$fit + z * pr$se.fit), top)
      ),
      obs = data.frame(species = s, x = d$x * xs + xm, y = d$y), dev = dev
    )
  })
  fits <- fits[!vapply(fits, is.null, logical(1))]
  if (!length(fits)) {
    cli::cli_abort("No species could be fitted: each needs three or more occurrences.")
  }
  dev <- vapply(fits, function(f) f$dev, numeric(1))
  keep <- fits[order(-dev)][seq_len(min(species, length(fits)))]
  cur <- do.call(rbind, lapply(keep, function(f) f$curve))
  obs <- do.call(rbind, lapply(keep, function(f) f$obs))
  lev <- vapply(keep, function(f) f$curve$species[1], character(1))
  cur$species <- factor(cur$species, lev)
  obs$species <- factor(obs$species, lev)
  lab_dev <- stats::setNames(
    sprintf("%s\nD\u00b2 = %.2f", lev, vapply(keep, function(f) f$dev, numeric(1))), lev
  )
  p <- ggplot2::ggplot(cur, ggplot2::aes(.data$x))
  if (layout == "facet") {
    p <- p +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
        fill = st$env_colour, alpha = 0.18
      ) +
      ggplot2::geom_line(ggplot2::aes(y = .data$fit), colour = st$env_colour, linewidth = 0.8) +
      ggplot2::geom_point(ggplot2::aes(.data$x, .data$y),
        data = obs, shape = 21, fill = st$site_fill, colour = st$site_outline,
        size = 0.7 * st$site_size, stroke = st$site_stroke
      ) +
      ggplot2::facet_wrap(~species, scales = "free_y", labeller = ggplot2::as_labeller(lab_dev))
  } else {
    p <- p +
      ggplot2::geom_ribbon(
        ggplot2::aes(
          ymin = .data$lower, ymax = .data$upper,
          fill = .data$species
        ),
        alpha = 0.12
      ) +
      ggplot2::geom_line(ggplot2::aes(y = .data$fit, colour = .data$species), linewidth = 0.9) +
      ggplot2::geom_point(ggplot2::aes(.data$x, .data$y, colour = .data$species),
        data = obs, size = 1.6
      )
    p <- td_style(p, palette, NULL) +
      ggplot2::guides(
        colour = ggplot2::guide_legend(ncol = 2),
        fill = ggplot2::guide_legend(ncol = 2)
      )
  }
  p + ggplot2::labs(
    x = xlab, y = "Abundance",
    caption = sprintf(
      paste0(
        "%s (Poisson) with %d%% confidence band from the model; ",
        "D\u00b2 = deviance explained;\nspecies at three or more sites with a stable fit"
      ),
      if (model == "glm") "Quadratic GLM" else "GAM", round(100 * level)
    )
  ) + ord_theme(st) + ggplot2::theme(legend.title = ggplot2::element_blank())
}

# ---- Scree plot -------------------------------------------------------------

ord_plot_scree <- function(object, st, n = 10) {
  if (object$method %in% c("nmds", "dca")) {
    cli::cli_abort("A scree plot needs eigenvalues; use {.code type = \"shepard\"} for NMDS.")
  }
  ev <- vegan::eigenvals(object$fit)
  ev <- ev[ev > 0]
  share <- ev / sum(ev)
  k <- min(n, length(ev))
  constrained <- grepl("^(RDA|CCA|CAP|dbRDA)", names(ev))
  d <- data.frame(
    axis = factor(names(ev)[seq_len(k)], names(ev)[seq_len(k)]),
    share = 100 * share[seq_len(k)],
    kind = ifelse(constrained[seq_len(k)], "Constrained", "Unconstrained")
  )
  # Broken-stick expectation for the unconstrained axes
  un <- !constrained
  bs <- rep(NA_real_, length(ev))
  if (any(un)) {
    bs[un] <- 100 * vegan::bstick(sum(un), sum(ev[un])) / sum(ev)
  }
  d$broken <- bs[seq_len(k)]
  ggplot2::ggplot(d, ggplot2::aes(.data$axis, .data$share)) +
    ggplot2::geom_col(ggplot2::aes(fill = .data$kind),
      width = 0.7, colour = st$site_outline,
      linewidth = 0.3
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        y = .data$broken, group = 1,
        linetype = "Broken-stick expectation"
      ),
      colour = "#B2182B", linewidth = 0.6, na.rm = TRUE
    ) +
    ggplot2::geom_point(ggplot2::aes(y = .data$broken),
      colour = "#B2182B", size = 1.4,
      na.rm = TRUE
    ) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f", .data$share)),
      vjust = -0.5, family = st$font, size = 0.95 * st$label_size, colour = "grey20"
    ) +
    ggplot2::scale_fill_manual(values = c(
      Constrained = st$env_colour,
      Unconstrained = "grey80"
    ), name = NULL) +
    ggplot2::scale_linetype_manual(values = "solid", name = NULL) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
    ggplot2::labs(x = NULL, y = "Variation explained (%)") +
    ord_theme(st)
}

# ---- Shepard plot (NMDS) ----------------------------------------------------

ord_plot_shepard <- function(object, st) {
  if (object$method != "nmds") {
    cli::cli_abort("A Shepard plot is for NMDS; use {.code type = \"scree\"} otherwise.")
  }
  f <- object$fit
  d <- data.frame(diss = f$diss, dist = f$dist, dhat = f$dhat)
  d <- d[order(d$diss), ]
  r2_nm <- 1 - f$stress^2
  r2_lin <- stats::cor(d$dist, d$diss)^2
  ggplot2::ggplot(d, ggplot2::aes(.data$diss, .data$dist)) +
    ggplot2::geom_point(
      shape = 21, fill = st$site_fill, colour = "grey45", size = 1.6,
      stroke = 0.4
    ) +
    ggplot2::geom_step(ggplot2::aes(y = .data$dhat), colour = st$env_colour, linewidth = 0.8) +
    ggplot2::annotate("text",
      x = min(d$diss), y = max(d$dist), hjust = 0, vjust = 1, family = st$font,
      size = st$label_size,
      label = sprintf(
        "Stress = %.3f\nNon-metric R\u00b2 = %.3f\nLinear R\u00b2 = %.3f",
        f$stress, r2_nm, r2_lin
      )
    ) +
    ggplot2::labs(x = "Observed dissimilarity", y = "Ordination distance") +
    ord_theme(st)
}

# ---- t-value plot -----------------------------------------------------------

# Species arrows coloured by the sign and significance of their regression
# coefficient on one site variable (the question of CANOCO's t-value
# biplot), from exact t-tests of a multiple regression of each transformed
# species on all site variables. Van Dobben circles are not drawn: they
# approximate these tests only under one particular scaling and can
# contradict them.
ord_plot_tvalue <- function(object, st, variable = NULL, species = 20, axes = c(1, 2)) {
  if (is.null(object$formula) || is.null(object$env)) {
    cli::cli_abort("A t-value plot needs site variables: fit with a {.arg formula}.")
  }
  vars <- all.vars(object$formula)
  variable <- variable %||% vars[1]
  if (!variable %in% vars) cli::cli_abort("{.arg variable} must be one of {.val {vars}}.")
  ax <- paste0("axis", axes)
  sd <- object$sites
  sd$.x <- sd[[ax[1]]]
  sd$.y <- sd[[ax[2]]]
  vec <- ord_vectors_fit(object, sd, ax)
  v <- vec[vec$term == variable, ]
  if (!nrow(v)) cli::cli_abort("{.val {variable}} has no fitted arrow (is it numeric?).")
  y <- ord_transform(
    object$community[as.character(sd[[object$site_col]]), , drop = FALSE], object$transform
  )
  env <- as.data.frame(sd[vars])
  tv <- vapply(colnames(y), function(s) {
    m <- tryCatch(stats::lm(y[, s] ~ ., data = env), error = function(e) NULL)
    if (is.null(m)) {
      return(c(NA_real_, NA_real_))
    }
    cf <- summary(m)$coefficients
    if (variable %in% rownames(cf)) {
      cf[variable, c("t value", "Pr(>|t|)")]
    } else {
      c(
        NA_real_,
        NA_real_
      )
    }
  }, numeric(2))
  spp <- object$species
  spp$t <- tv[1, match(spp$species, colnames(tv))]
  spp$p <- tv[2, match(spp$species, colnames(tv))]
  spp$.x <- spp[[ax[1]]]
  spp$.y <- spp[[ax[2]]]
  spp <- spp[order(-(spp$.x^2 + spp$.y^2)), ][seq_len(min(species, nrow(spp))), ]
  mul <- sqrt(v$.x^2 + v$.y^2) / max(sqrt(spp$.x^2 + spp$.y^2))
  spp$.x <- spp$.x * mul
  spp$.y <- spp$.y * mul
  pos <- paste("Increases with", ord_pretty(variable))
  neg <- paste("Decreases with", ord_pretty(variable))
  spp$class <- ifelse(is.na(spp$p) | spp$p >= 0.05, "No significant relation",
    ifelse(spp$t > 0, pos, neg)
  )
  cols <- stats::setNames(c("#B2182B", "#2166AC", "grey60"), c(pos, neg, "No significant relation"))
  ggplot2::ggplot() +
    ggplot2::geom_hline(
      yintercept = 0, colour = st$origin_colour,
      linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_vline(
      xintercept = 0, colour = st$origin_colour,
      linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(0, 0,
        xend = .data$.x, yend = .data$.y,
        colour = .data$class
      ),
      data = spp, linewidth = 0.45,
      arrow = ggplot2::arrow(length = ggplot2::unit(1.6, "mm"), type = "closed")
    ) +
    ggplot2::geom_segment(ggplot2::aes(0, 0, xend = .data$.x, yend = .data$.y),
      data = v, colour = st$env_colour, linewidth = st$env_linewidth,
      arrow = ggplot2::arrow(length = ggplot2::unit(2.4, "mm"), type = "closed")
    ) +
    ord_text(
      vctrs::vec_rbind(
        tibble::tibble(
          .x = spp$.x, .y = spp$.y, .label = spp$species, .col = unname(cols[spp$class]),
          .face = st$species_fontface, .size = st$label_size
        ),
        tibble::tibble(
          .x = v$.x, .y = v$.y, .label = ord_pretty(variable), .col = st$env_colour,
          .face = "bold", .size = 1.15 * st$label_size
        )
      ),
      spp[c(".x", ".y")], st$font
    ) +
    ggplot2::scale_colour_manual(values = cols, name = NULL, breaks = names(cols)) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::labs(
      x = ord_axis_labels(object, axes)[1], y = ord_axis_labels(object, axes)[2],
      caption = sprintf(
        "Colours: t-test (p < 0.05) of each species' coefficient on %s in a regression on %s",
        tolower(ord_pretty(variable)), paste(vars, collapse = " + ")
      )
    ) +
    ord_theme(st)
}

# ---- Van Dobben circles (t-value biplot) -----------------------------------

# CANOCO's t-value biplot: species and the site variables are placed by a
# rank-2 approximation (singular value decomposition) of the matrix of
# t-values of the regression coefficients of each (transformed) species on
# all numeric site variables. Two Van Dobben circles with a diameter along
# the chosen variable mark, approximately, the species with a t-value above
# the critical value (red) or below its negative (blue). The circles are an
# approximation; species are coloured by the exact t-test.
ord_plot_vandobben <- function(object, st, variable = NULL, species = 25) {
  if (is.null(object$formula) || is.null(object$env)) {
    cli::cli_abort("Van Dobben circles need site variables: fit with a {.arg formula}.")
  }
  vars <- all.vars(object$formula)
  sd <- object$sites
  env <- as.data.frame(sd[vars])
  # Every coefficient of the regression (numeric variables and factor
  # contrasts) is one variable of the t-value biplot
  mm <- stats::model.matrix(stats::reformulate(vars), env)[, -1, drop = FALSE]
  num <- colnames(mm)
  variable <- variable %||% vars[vapply(vars, function(v) is.numeric(sd[[v]]), logical(1))][1]
  if (is.na(variable) || !variable %in% num) {
    cli::cli_abort("{.arg variable} must be one of {.val {num}}.")
  }
  y <- ord_transform(
    object$community[as.character(sd[[object$site_col]]), , drop = FALSE], object$transform
  )
  y <- y[, colSums(y > 0) >= 2, drop = FALSE]
  X <- as.data.frame(mm)
  names(X) <- make.names(num)
  vk_name <- make.names(variable)
  tm <- t(vapply(colnames(y), function(s) {
    m <- tryCatch(stats::lm(y[, s] ~ ., data = X), error = function(e) NULL)
    out <- stats::setNames(rep(NA_real_, length(num) + 1), c(names(X), ".p"))
    if (is.null(m)) {
      return(out)
    }
    cf <- summary(m)$coefficients
    hit <- intersect(names(X), rownames(cf))
    out[hit] <- cf[hit, "t value"]
    if (vk_name %in% rownames(cf)) out[".p"] <- cf[vk_name, "Pr(>|t|)"]
    out
  }, numeric(length(num) + 1)))
  colnames(tm) <- c(num, ".p")
  pv <- tm[, ".p"]
  tm <- tm[, num, drop = FALSE]
  ok <- stats::complete.cases(tm)
  tm <- tm[ok, , drop = FALSE]
  pv <- pv[ok]
  # Rank-2 biplot of the t-values: t[j, k] ~ species[j, ] . variable[k, ]
  sv <- svd(tm, nu = 2, nv = 2)
  dd <- sv$d[seq_len(min(2, length(sv$d)))]
  bsp <- sv$u[, seq_along(dd), drop = FALSE] %*% diag(sqrt(dd), length(dd))
  bvr <- sv$v[, seq_along(dd), drop = FALSE] %*% diag(sqrt(dd), length(dd))
  if (ncol(bsp) < 2) {
    bsp <- cbind(bsp, 0)
    bvr <- cbind(bvr, 0)
  }
  spp <- data.frame(
    species = rownames(tm), .x = bsp[, 1], .y = bsp[, 2], t = tm[, variable], p = pv
  )
  spp <- spp[order(-abs(spp$t)), ][seq_len(min(species, nrow(spp))), ]
  vk <- bvr[match(variable, num), ]
  tcrit <- stats::qt(0.975, max(1, nrow(env) - length(num) - 1))
  # Circle: species b with b . v >= tcrit lie beyond the line at distance
  # tcrit / |v| along v; the circle of that diameter, through the origin,
  # marks them (approximately)
  u <- vk / sqrt(sum(vk^2))
  dia <- 2 * tcrit / sqrt(sum(vk^2))
  tip <- u * dia
  th <- seq(0, 2 * pi, length.out = 200)
  circ <- rbind(
    data.frame(x = tip[1] / 2 + dia / 2 * cos(th), y = tip[2] / 2 + dia / 2 * sin(th), side = "+"),
    data.frame(x = -tip[1] / 2 + dia / 2 * cos(th), y = -tip[2] / 2 + dia / 2 * sin(th), side = "-")
  )
  pos <- paste("Increases with", ord_pretty(variable))
  neg <- paste("Decreases with", ord_pretty(variable))
  spp$class <- ifelse(is.na(spp$p) | spp$p >= 0.05, "No significant relation",
    ifelse(spp$t > 0, pos, neg)
  )
  cols <- stats::setNames(c("#B2182B", "#2166AC", "grey60"), c(pos, neg, "No significant relation"))
  circ$colour <- ifelse(circ$side == "+", cols[[pos]], cols[[neg]])
  v <- data.frame(.x = tip[1], .y = tip[2])
  ov <- data.frame(name = num, .x = bvr[, 1], .y = bvr[, 2])
  ov <- ov[ov$name != variable, , drop = FALSE]
  sc <- max(abs(c(spp$.x, spp$.y))) / max(abs(c(ov$.x, ov$.y, 1e-9)))
  ov$.x <- ov$.x * sc
  ov$.y <- ov$.y * sc
  ggplot2::ggplot() +
    ggplot2::geom_hline(
      yintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_vline(
      xintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_path(ggplot2::aes(.data$x, .data$y, group = .data$side, colour = I(.data$colour)),
      data = circ, linewidth = 0.5, linetype = "22"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(0, 0, xend = .data$.x, yend = .data$.y, colour = .data$class),
      data = spp, linewidth = 0.45,
      arrow = ggplot2::arrow(length = ggplot2::unit(1.6, "mm"), type = "closed")
    ) +
    ggplot2::geom_segment(ggplot2::aes(0, 0, xend = .data$.x, yend = .data$.y),
      data = v, colour = st$env_colour, linewidth = st$env_linewidth,
      arrow = ggplot2::arrow(length = ggplot2::unit(2.4, "mm"), type = "closed")
    ) +
    ggplot2::geom_segment(ggplot2::aes(0, 0, xend = .data$.x, yend = .data$.y),
      data = ov, colour = st$env_colour, alpha = 0.45, linewidth = 0.4, linetype = "42"
    ) +
    ord_text(
      vctrs::vec_rbind(
        tibble::tibble(
          .x = ov$.x, .y = ov$.y,
          .label = sub(paste0("^(", paste(vars, collapse = "|"), ")(.+)$"), "\\1: \\2", ov$name),
          .col = st$env_colour,
          .face = "plain", .size = 0.9 * st$label_size
        ),
        tibble::tibble(
          .x = spp$.x, .y = spp$.y, .label = spp$species, .col = unname(cols[spp$class]),
          .face = st$species_fontface, .size = st$label_size
        ),
        tibble::tibble(
          .x = v$.x, .y = v$.y, .label = ord_pretty(variable), .col = st$env_colour,
          .face = "bold", .size = 1.15 * st$label_size
        )
      ),
      spp[c(".x", ".y")], st$font
    ) +
    ggplot2::scale_colour_manual(values = cols, name = NULL, breaks = names(cols)) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::labs(
      x = "t-value biplot, axis 1", y = "t-value biplot, axis 2",
      caption = paste0(
        "Van Dobben circles (dashed) approximate |t| > ", sprintf("%.2f", tcrit),
        " for ", ord_pretty(variable), "; colours are exact t-tests (p < 0.05)\n",
        "of each species' coefficient in a regression on ", paste(vars, collapse = " + ")
      )
    ) +
    ord_theme(st)
}

# ---- Stability of site positions --------------------------------------------

# Bootstrap the species (columns), refit, rotate each fit onto the original
# by Procrustes, and draw a 95% ellipse of each site's positions: sites with
# small ellipses are placed robustly.
ord_plot_stability <- function(object, st, nboot = 199, level = 0.95, axes = c(1, 2)) {
  if (object$constrained) {
    cli::cli_abort("Stability ellipses are for unconstrained ordinations.")
  }
  ax <- paste0("axis", axes)
  y <- ord_transform(object$community, object$transform)
  ref <- as.matrix(object$sites[ax])
  rownames(ref) <- object$sites[[object$site_col]]
  y <- y[rownames(ref), , drop = FALSE]
  sc_num <- c(sites = 1L, species = 2L, symmetric = 3L)[[object$scaling]]
  boots <- lapply(seq_len(nboot), function(b) {
    cols <- sample.int(ncol(y), ncol(y), replace = TRUE)
    yb <- y[, cols, drop = FALSE]
    yb <- yb[, colSums(yb) > 0, drop = FALSE]
    f <- tryCatch(suppressWarnings(utils::capture.output(
      fit <- ord_vegan(object$method, yb, NULL, NULL, object$distance %|% "bray", 2)
    )), error = function(e) NULL)
    if (is.null(f)) {
      return(NULL)
    }
    s <- vegan::scores(fit,
      display = "sites", choices = axes,
      scaling = if (object$method %in% c("dca", "nmds")) NULL else sc_num
    )
    pr <- vegan::procrustes(ref, s, symmetric = FALSE)
    data.frame(site = rownames(ref), x = pr$Yrot[, 1], y = pr$Yrot[, 2])
  })
  bt <- do.call(rbind, boots)
  ell <- do.call(rbind, lapply(split(bt, bt$site), function(d) {
    if (nrow(d) < 3) {
      return(NULL)
    }
    e <- ord_ellipse(d$x, d$y, level)
    e$site <- d$site[1]
    e
  }))
  sd <- data.frame(site = rownames(ref), .x = ref[, 1], .y = ref[, 2])
  lab <- ord_axis_labels(object, axes)
  ggplot2::ggplot() +
    ggplot2::geom_hline(
      yintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_vline(
      xintercept = 0, colour = st$origin_colour, linewidth = st$origin_linewidth
    ) +
    ggplot2::geom_polygon(ggplot2::aes(.data$x, .data$y, group = .data$site),
      data = ell, fill = st$env_colour, alpha = 0.06, colour = st$env_colour, linewidth = 0.3
    ) +
    ggplot2::geom_point(ggplot2::aes(.data$.x, .data$.y),
      data = sd, shape = 21, fill = st$site_fill, colour = st$site_outline,
      size = st$site_size, stroke = st$site_stroke
    ) +
    ord_text(
      tibble::tibble(
        .x = sd$.x, .y = sd$.y, .label = sd$site, .col = st$site_label_colour,
        .face = st$site_fontface, .size = st$label_size
      ),
      sd[c(".x", ".y")], st$font
    ) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::labs(
      x = lab[1], y = lab[2],
      caption = sprintf(
        paste(
          "%d%% ellipses of %d bootstrap ordinations (species resampled),",
          "Procrustes-rotated to the original"
        ),
        round(100 * level), nboot
      )
    ) +
    ord_theme(st)
}

`%|%` <- function(a, b) if (length(a) == 1 && is.na(a)) b else a

# Normal-theory ellipse of points
ord_ellipse <- function(x, y, level = 0.95, n = 60) {
  cv <- stats::cov(cbind(x, y))
  if (any(!is.finite(cv)) || det(cv) <= 0) {
    return(NULL)
  }
  r <- sqrt(stats::qchisq(level, 2))
  th <- seq(0, 2 * pi, length.out = n)
  ch <- chol(cv)
  pts <- cbind(cos(th), sin(th)) %*% ch * r
  data.frame(x = mean(x) + pts[, 1], y = mean(y) + pts[, 2])
}
