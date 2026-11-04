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
