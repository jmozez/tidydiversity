.onLoad <- function(libname, pkgname) {
  # Register tidydiversity's advisor with tidyvisor, replacing tidyvisor's
  # built-in one, so tidyvisor() uses the functions of this version.
  tidyvisor::register_advisor(
    package = pkgname,
    title = "Community ecology: ordination and its tests",
    questions = c("explore", "explain", "groups", "time", "partition"),
    classes = c("td_ordination", "td_prc", "td_varpart"),
    advise = ord_advise,
    interpret = ord_interpret,
    claims = function(x, args) any(c("abundance", "formula", "treatment") %in% args)
  )
}
