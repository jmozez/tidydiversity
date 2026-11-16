# Argument names users bring from vegan, betapart and indicspecies.
#
# `td_alias()` returns the value of an alias argument when it is given, and
# refuses a conflicting value of the tidydiversity argument. `main_given` is
# `!missing(<main>)` at the call site.
td_alias <- function(main, alias, main_given, main_name, alias_name,
                     call = rlang::caller_env()) {
  if (is.null(alias)) {
    return(main)
  }
  if (main_given && !identical(main, alias)) {
    cli::cli_abort(
      "Give {.arg {main_name}} or {.arg {alias_name}}, not both with different values.",
      call = call
    )
  }
  alias
}

# vegan's numeric scaling codes: 1 sites, 2 species, 3 symmetric
td_scaling <- function(scaling) {
  if (is.numeric(scaling) && length(scaling) == 1 && scaling %in% 1:3) {
    return(c("sites", "species", "symmetric")[scaling])
  }
  scaling
}
