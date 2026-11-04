#' Bootstrap replicates of diversity estimates
#'
#' Returns the individual bootstrap replicates behind the standard errors
#' of [div_estimate()] and [div_standardise()], one row per site, order `q`
#' and replicate. Each replicate is a multinomial sample of the observed
#' size drawn from the estimated community, including undetected species,
#' as in iNEXT (Chao et al. 2014). Use the replicates to carry estimation
#' uncertainty into downstream models, for example by refitting a model to
#' each replicate and pooling the coefficients (see
#' `vignette("modelling")`).
#'
#' @inheritParams div_standardise
#' @param type `"asymptotic"` for the asymptotic estimates of
#'   [div_estimate()], or `"standardised"` for diversity at a common
#'   coverage or size as in [div_standardise()].
#' @param nboot Number of bootstrap replicates.
#' @return A tibble with the grouping columns, the site column, `q`,
#'   `.draw` (replicate number) and `diversity`. For
#'   `type = "standardised"`, also `m`, the size each site was standardised
#'   to (fixed across replicates).
#' @export
#' @examples
#' set.seed(1)
#' draws <- div_boot(png_ants, q = 0, .by = season, nboot = 20)
#' draws
#'
#' # The bootstrap standard error of each site
#' dplyr::summarise(draws, se = sd(diversity), .by = c(season, site, q))
div_boot <- function(data,
                     site = site,
                     species = species,
                     abundance = NULL,
                     q = c(0, 1, 2),
                     type = c("asymptotic", "standardised"),
                     coverage = NULL,
                     size = NULL,
                     nboot = 100,
                     .by = NULL) {
  type <- rlang::arg_match(type)
  prep <- td_prepare(
    data, enquo(site), enquo(species), enquo(abundance), enquo(.by),
    counts = TRUE
  )
  td_check_min_n(prep)
  q <- td_check_q(q, integer = TRUE)
  td_check_number(nboot, "nboot", 1, whole = TRUE)
  if (!is.null(coverage) && !is.null(size)) {
    cli::cli_abort("Supply only one of {.arg coverage} or {.arg size}.")
  }
  if (type == "standardised") {
    if (!is.null(coverage)) td_check_number(coverage, "coverage", 0, 1)
    if (!is.null(size)) td_check_number(size, "size", 1)
    if (is.null(coverage) && is.null(size)) {
      level <- default_coverage_level(prep)
    }
  }
  out <- td_per_site(prep, function(x, i) {
    if (type == "asymptotic") {
      fn <- function(xb, d) hill_asy(xb, q)
      m <- NULL
    } else {
      m <- size %||% size_for_coverage(x, coverage %||% level[i])
      fn <- function(xb, d) as.vector(hill_at_size(xb, m, q))
    }
    draws <- boot_draws(x, nboot, fn)
    draws <- matrix(draws, nrow = length(q))
    nq <- length(q)
    res <- tibble::tibble(
      q = rep(q, times = nboot),
      .draw = rep(seq_len(nboot), each = nq),
      diversity = as.vector(draws)
    )
    if (!is.null(m)) res <- tibble::add_column(res, m = m, .after = "q")
    res
  })
  td_new(out, "td_boot")
}
