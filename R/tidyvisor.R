#' tidyvisor: advice before the analysis, interpretation after it
#'
#' @description
#' `tidyvisor()` is the package's adviser. Give it **data** and a question,
#' and it recommends the analysis, the test, the plots and the code to run
#' (see [ord_advise()]). Give it a **result**, and it explains the tables
#' and the diagram in plain sentences (see [ord_interpret()]).
#'
#' Its advice follows the standard references of community ecology, and it
#' always gives its reasons, so it can be checked and overruled: the
#' question, which only the analyst knows, comes first.
#'
#' @param x Community data in long format (to be advised), or the result of
#'   [ord_fit()], [ord_prc()] or [ord_varpart()] (to be interpreted).
#'   tidymapr results and mapping questions (`question = "spread"` and so
#'   on) are passed to tidymapr's `tidyvisor()`, so it does not matter which
#'   of the two packages was attached last.
#' @param ... Passed to [ord_advise()] (data) or [ord_interpret()] (results).
#' @return A `td_ord_advice` or a `td_ord_interpretation` object.
#' @export
#' @examplesIf rlang::is_installed("vegan")
#' data("dune", "dune.env", package = "vegan")
#' d <- community_long(cbind(site = rownames(dune), dune.env, dune),
#'   cols = dplyr::all_of(names(dune))
#' )
#' # Before: which analysis?
#' tidyvisor(d, abundance = abundance, formula = ~ A1 + Management)
#' # After: what does it show?
#' o <- ord_fit(d,
#'   abundance = abundance, method = "rda", transform = "hellinger",
#'   formula = ~ A1 + Management
#' )
#' tidyvisor(o, permutations = 199)
tidyvisor <- function(x, ...) {
  # tidymapr has its own tidyvisor(); whichever package is attached last
  # masks the other, so each hands over what belongs to the other.
  if (inherits(x, c("td_ordination", "td_prc", "td_varpart"))) {
    ord_interpret(x, ...)
  } else if (td_for_tidymapr(x, ...)) {
    td_companion("tidymapr", "tidyvisor")(x, ...)
  } else if (is.data.frame(x)) {
    ord_advise(x, ...)
  } else {
    cli::cli_abort(c(
      "{.fn tidyvisor} needs community data or an ordination result.",
      i = "Got an object of class {.cls {class(x)}}."
    ))
  }
}

# Objects and questions that belong to tidymapr's tidyvisor
td_for_tidymapr <- function(x, ...) {
  # read `question` alone: other arguments may be bare column names
  q <- if ("question" %in% ...names()) ...elt(match("question", ...names()))
  mapping <- c("distribution", "spread", "epidemic", "range_shift", "autocorrelation")
  any(grepl("^tmr_", class(x))) ||
    (is.data.frame(x) && !is.null(q) && q[1] %in% mapping)
}

# A function from a companion package, looked up at run time
td_companion <- function(pkg, fun, call = rlang::caller_env()) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cli::cli_abort(c(
      "This needs the {.pkg {pkg}} package, which is not installed.",
      i = "Install it with {.code remotes::install_github(\"jmozez/{pkg}\")}."
    ), call = call)
  }
  getExportedValue(pkg, fun)
}
