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
  if (inherits(x, c("td_ordination", "td_prc", "td_varpart"))) {
    ord_interpret(x, ...)
  } else if (is.data.frame(x)) {
    ord_advise(x, ...)
  } else {
    cli::cli_abort(c(
      "{.fn tidyvisor} needs community data or an ordination result.",
      i = "Got an object of class {.cls {class(x)}}."
    ))
  }
}
