#' Fit and test a distance-decay model
#'
#' Fits a nonlinear distance-decay model to the pairwise similarities from
#' [beta_decay()] and tests it by permutation, as in
#' [betapart::decay.model()] (Gómez-Rodríguez and Baselga 2018). Similarity
#' is one minus the chosen dissimilarity component. The models are
#'
#' * `"exponential"`: \eqn{S = a e^{-b d}} (Nekola and White 1999), and
#' * `"power"`: \eqn{S = a d^{-b}}, which needs positive distances.
#'
#' Here `a` is the similarity at distance zero (exponential) or one (power),
#' and `b` is the rate of decay: positive values mean similarity falls with
#' distance. The fit is by nonlinear least squares, and the fit statistic is
#' the pseudo-\eqn{R^2}, one minus the residual deviance over the deviance
#' of a constant model.
#'
#' Pairs of sites are not independent, so the test permutes site labels:
#' rows and columns of the similarity matrix are shuffled together while
#' the distances stay in place, as in a Mantel test, and the model is
#' refitted each time. The p-value is
#' \eqn{(1 + \#\{R^2_{perm} \ge R^2_{obs}\}) / (1 + B)}. betapart instead
#' reports the proportion of permuted values strictly greater than the
#' observed one, which can be zero; the version here cannot.
#'
#' @param x A `td_beta_decay` tibble from [beta_decay()]. Its groups are
#'   kept and fitted separately.
#' @param model `"exponential"` or `"power"`.
#' @param component Dissimilarity component turned into similarity:
#'   `"total"`, `"turnover"` or `"nestedness"`.
#' @param permutations Number of permutations for the test; `0` skips it.
#' @return A tibble with one row per group: `model`, `component`,
#'   `n_pairs`, `a`, `b`, `half_distance` (the distance over which
#'   similarity halves, \eqn{\log 2 / b} for the exponential model and
#'   the factor \eqn{2^{1/b}} for the power model), `pseudo_r2`, `aic` and
#'   `p.value`.
#' @references Nekola, J. C. and White, P. S. (1999). The distance decay of
#'   similarity in biogeography and ecology. *Journal of Biogeography*, 26,
#'   867-878. \doi{10.1046/j.1365-2699.1999.00305.x}
#'
#'   Gómez-Rodríguez, C. and Baselga, A. (2018). Variation among European
#'   beetle taxa in patterns of distance decay of similarity suggests a
#'   major role of dispersal processes. *Ecography*, 41, 1825-1834.
#'   \doi{10.1111/ecog.03693}
#' @export
#' @examples
#' decay <- beta_decay(png_ants, gradient = elevation, .by = season)
#' set.seed(1)
#' beta_decay_model(decay, permutations = 199)
beta_decay_model <- function(x,
                             model = c("exponential", "power"),
                             component = c("total", "turnover", "nestedness"),
                             permutations = 999) {
  model <- rlang::arg_match(model)
  component <- rlang::arg_match(component)
  if (!inherits(x, "td_beta_decay")) {
    cli::cli_abort("{.arg x} must be the output of {.fn beta_decay}.")
  }
  df <- tibble::as_tibble(unclass(x))
  grp <- setdiff(
    names(df),
    c(
      "site_1", "site_2", "turnover", "nestedness", "total",
      "gradient_1", "gradient_2", "distance"
    )
  )
  keys <- if (length(grp)) vctrs::vec_group_loc(df[grp]) else NULL
  locs <- if (is.null(keys)) list(seq_len(nrow(df))) else keys$loc
  rows <- lapply(locs, function(i) {
    decay_fit_one(df[i, ], model, component, permutations)
  })
  out <- dplyr::bind_rows(rows)
  if (!is.null(keys)) out <- dplyr::bind_cols(keys$key, out)
  out
}

decay_fit_one <- function(d, model, component, permutations) {
  y <- 1 - d[[component]]
  dist <- d$distance
  if (model == "power" && any(dist <= 0)) {
    cli::cli_abort(
      "The power model needs positive distances between all sites."
    )
  }
  fit <- decay_nls(y, dist, model)
  null_dev <- sum((y - mean(y))^2)
  r2 <- 1 - fit$dev / null_dev
  p <- NA_real_
  if (permutations > 0) {
    labs <- unique(c(as.character(d$site_1), as.character(d$site_2)))
    i <- match(as.character(d$site_1), labs)
    j <- match(as.character(d$site_2), labs)
    m <- matrix(NA_real_, length(labs), length(labs))
    m[cbind(i, j)] <- y
    m[cbind(j, i)] <- y
    perm <- vapply(seq_len(permutations), function(k) {
      s <- sample.int(length(labs))
      yp <- m[cbind(s[i], s[j])]
      1 - decay_nls(yp, dist, model, fit$coef)$dev / null_dev
    }, numeric(1))
    p <- (1 + sum(perm >= r2 - 1e-12)) / (1 + permutations)
  }
  a <- fit$coef[[1]]
  b <- fit$coef[[2]]
  tibble::tibble(
    model = model, component = component, n_pairs = length(y),
    a = a, b = b,
    half_distance = if (model == "exponential") log(2) / b else 2^(1 / b),
    pseudo_r2 = r2, aic = fit$aic, p.value = p
  )
}

# Least-squares fit of S = a exp(-b d) or S = a d^-b. Starting values come
# from a log-linear fit; a failed fit (for example a flat permuted pattern)
# falls back to the constant model, which has R2 = 0.
decay_nls <- function(y, d, model, start = NULL) {
  xx <- if (model == "exponential") d else log(d)
  if (is.null(start)) {
    ok <- y > 0
    lf <- if (sum(ok) >= 2) {
      stats::coef(stats::lm(log(y[ok]) ~ xx[ok]))
    } else {
      c(log(mean(y) + 1e-8), 0)
    }
    start <- c(a = exp(lf[[1]]), b = -lf[[2]])
  }
  fit <- tryCatch(
    suppressWarnings(stats::nls(y ~ a * exp(-b * xx),
      start = list(a = start[[1]], b = start[[2]]),
      control = stats::nls.control(maxiter = 200, warnOnly = TRUE)
    )
    ),
    error = function(e) NULL
  )
  if (is.null(fit)) {
    dev <- sum((y - mean(y))^2)
    return(list(coef = c(a = mean(y), b = 0), dev = dev, aic = NA_real_))
  }
  list(
    coef = stats::coef(fit), dev = stats::deviance(fit),
    aic = stats::AIC(fit)
  )
}

#' Bootstrap confidence interval for a distance-decay slope
#'
#' @description
#' `beta_decay_boot()` estimates the slope of dissimilarity against
#' distance (from [beta_decay()]) and its bootstrap confidence interval.
#' Because pairs of sites share sites and are not independent, sites, not
#' pairs, are resampled: each replicate draws the sites with replacement
#' and refits the slope on every pair of distinct drawn sites. Compare the
#' slopes of two transects (or taxa) by whether their intervals overlap,
#' or by the interval of their difference (`compare`).
#'
#' @param decay A [beta_decay()] result.
#' @param component Dissimilarity column: `"total"` (default),
#'   `"turnover"` or `"nestedness"`.
#' @param nboot Number of bootstrap replicates.
#' @param conf Confidence level.
#' @param group Optional column of `decay` identifying transects or taxa;
#'   slopes are estimated within each, and with exactly two groups their
#'   difference is added.
#' @param per Scale the slope to dissimilarity per `per` distance units
#'   (for example 1000 for per km when distance is in metres).
#' @param seed Optional random seed.
#' @return A tibble with `group` (if given), `slope`, `lower`, `upper`,
#'   `n_sites` and `nboot`; with two groups an extra row `difference`.
#' @export
#' @examples
#' d <- beta_decay(png_frogs, elevation)
#' beta_decay_boot(d, nboot = 200, per = 1000, seed = 1)
beta_decay_boot <- function(decay,
                            component = c("total", "turnover", "nestedness"),
                            nboot = 999,
                            conf = 0.95,
                            group = NULL,
                            per = 1,
                            seed = NULL) {
  component <- rlang::arg_match(component)
  td_check_number(nboot, "nboot", 10, whole = TRUE)
  td_check_number(conf, "conf", 0, 1)
  need <- c("site_1", "site_2", "distance", component)
  if (!is.data.frame(decay) || !all(need %in% names(decay))) {
    cli::cli_abort("{.arg decay} must be a {.fn beta_decay} result.")
  }
  if (!is.null(seed)) set.seed(seed)
  g_q <- enquo(group)
  g <- if (rlang::quo_is_null(g_q)) rep("all", nrow(decay)) else
    as.character(decay[[td_pick(g_q, decay, "group")]])
  a <- (1 - conf) / 2
  parts <- split(seq_len(nrow(decay)), g)
  draws <- list()
  res <- lapply(names(parts), function(k) {
    d <- decay[parts[[k]], ]
    sites <- sort(unique(c(d$site_1, d$site_2)))
    key <- function(i, j) paste(pmin(i, j), pmax(i, j), sep = "\r")
    lut <- stats::setNames(seq_len(nrow(d)), key(d$site_1, d$site_2))
    fit <- function(rows) {
      x <- d$distance[rows]
      y <- d[[component]][rows]
      if (length(unique(x)) < 2) return(NA_real_)
      stats::coef(stats::lm(y ~ x))[[2]] * per
    }
    est <- fit(seq_len(nrow(d)))
    b <- vapply(seq_len(nboot), function(r) {
      s <- sample(sites, length(sites), replace = TRUE)
      ij <- utils::combn(length(s), 2)
      keep <- s[ij[1, ]] != s[ij[2, ]]
      rows <- lut[key(s[ij[1, keep]], s[ij[2, keep]])]
      fit(rows[!is.na(rows)])
    }, numeric(1))
    draws[[k]] <<- b
    tibble::tibble(
      group = k, slope = est,
      lower = stats::quantile(b, a, na.rm = TRUE, names = FALSE),
      upper = stats::quantile(b, 1 - a, na.rm = TRUE, names = FALSE),
      n_sites = length(sites), nboot = sum(!is.na(b))
    )
  })
  out <- vctrs::vec_rbind(!!!res)
  if (length(parts) == 2) {
    dif <- draws[[2]] - draws[[1]]
    out <- vctrs::vec_rbind(out, tibble::tibble(
      group = paste(names(parts)[2], "-", names(parts)[1]),
      slope = out$slope[2] - out$slope[1],
      lower = stats::quantile(dif, a, na.rm = TRUE, names = FALSE),
      upper = stats::quantile(dif, 1 - a, na.rm = TRUE, names = FALSE),
      n_sites = NA_integer_, nboot = sum(!is.na(dif))
    ))
  }
  if (rlang::quo_is_null(g_q)) out$group <- NULL
  out
}
