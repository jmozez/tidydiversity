# Incidence data: species detected (present) in sampling units such as
# baits, traps, plots or survey days. Each site is described by its
# incidence frequencies Y_i (the number of units in which species i was
# detected) and its number of units T. Following Chao et al. (2014) and
# iNEXT.3D, the incidence estimators are the attribute-diversity estimators
# applied to the incidence frequencies with sample size T. For PD each
# branch's incidence is the number of units in which any species below it
# was detected, so the unit-by-species matrix is kept for each site.

# ---- Preparing incidence data --------------------------------------------

td_prepare_incidence <- function(df, data, by_cols, site_col, unit, n_units,
                                 call = caller_env()) {
  unit_col <- td_pick(unit, data, "unit", call = call)
  if (anyNA(data[[unit_col]])) {
    cli::cli_abort("Column {.field {unit_col}} must not contain missing values.",
      call = call
    )
  }
  df$.unit <- as.character(data[[unit_col]])
  keys <- c(by_cols, ".site")
  # Total number of units per site: the units present in the data, or a
  # column giving the number of units sampled, including empty ones.
  all_units <- dplyr::summarise(df,
    .t_obs = length(unique(.data$.unit)),
    .by = dplyr::all_of(keys)
  )
  if (!quo_is_null(n_units)) {
    nu_col <- td_pick(n_units, data, "n_units", call = call)
    nu <- tibble::as_tibble(df[keys])
    nu$.t <- data[[nu_col]]
    nu <- vctrs::vec_unique(nu)
    if (vctrs::vec_duplicate_any(nu[keys])) {
      cli::cli_abort(
        "Column {.field {nu_col}} must be constant within each site.",
        call = call
      )
    }
    all_units <- dplyr::left_join(all_units, nu, by = keys)
    bad <- is.na(all_units$.t) | all_units$.t < all_units$.t_obs
    if (any(bad)) {
      cli::cli_abort(c(
        "{.arg n_units} must be at least the number of units in the data.",
        "x" = "Too small at {.val {as.character(all_units$.site[bad])}}."
      ), call = call)
    }
  } else {
    all_units$.t <- all_units$.t_obs
  }
  det <- df[df$.n > 0, , drop = FALSE]
  if (nrow(det) == 0) {
    cli::cli_abort("{.arg data} has no detections.", call = call)
  }
  inc <- dplyr::summarise(det,
    .n = length(unique(.data$.unit)),
    .by = dplyr::all_of(c(keys, ".species"))
  )
  # Unit-by-species detection matrix of each site, for phylogenetic diversity.
  key_of <- function(d) do.call(paste, c(unname(as.list(d[keys])), sep = "\r"))
  det_key <- key_of(det)
  mats <- lapply(split(det, det_key), function(d) {
    spp <- sort(unique(d$.species))
    units <- unique(d$.unit)
    m <- matrix(FALSE, length(spp), length(units), dimnames = list(spp, units))
    m[cbind(match(d$.species, spp), match(d$.unit, units))] <- TRUE
    m
  })
  t_units <- stats::setNames(all_units$.t, key_of(all_units))
  small <- t_units < 2
  if (any(small)) {
    cli::cli_abort(c(
      "Each site needs at least 2 sampling units.",
      "x" = "Too few at {.val {as.character(all_units$.site[small])}}."
    ), call = call)
  }
  list(
    data = inc, by = by_cols, site = site_col,
    incidence = list(n_units = t_units, mats = mats, key_of = key_of)
  )
}

# Attach the number of units and the detection matrix to a site's frequencies.
as_incidence <- function(y, n_units, mat = NULL) {
  attr(y, "n_units") <- n_units
  attr(y, "inc") <- mat
  y
}

is_incidence <- function(x) !is.null(attr(x, "n_units"))

# Sample size: individuals for abundance data, units for incidence data.
smp_n <- function(x) attr(x, "n_units") %||% sum(x)

# ---- Phylogenetic branch incidences ---------------------------------------

# Branch incidences (number of units in which each branch is present) and
# lengths, for a unit-by-species detection matrix `mat` (species in rows).
# `undetected` adds bootstrap species as their own branches, as in
# phylo_attr().
phylo_attr_inc <- function(mat, tree, reftime, undetected = NULL) {
  mat <- mat[rowSums(mat) > 0, , drop = FALSE]
  is_u <- rownames(mat) %in% undetected$names
  u <- mat[is_u, , drop = FALSE]
  obs <- mat[!is_u, , drop = FALSE]
  u_len <- rep(min(undetected$length %||% reftime, reftime), nrow(u))
  if (nrow(obs) <= 1) {
    a <- c(rowSums(obs), rowSums(u))
    len <- c(rep(reftime, nrow(obs)), u_len)
    keep <- len > 0 & a > 0
    return(list(a = unname(a[keep]), w = len[keep], kind = "PD"))
  }
  drop <- setdiff(tree$tip.label, rownames(obs))
  sub <- if (length(drop) > 0) ape::drop.tip(tree, drop) else tree
  sub$root.edge <- NULL
  ntip <- length(sub$tip.label)
  depth <- ape::node.depth.edgelength(sub)
  height <- max(depth)
  pres <- matrix(FALSE, ntip + sub$Nnode, ncol(obs))
  pres[seq_len(ntip), ] <- obs[sub$tip.label, , drop = FALSE]
  post <- ape::reorder.phylo(sub, "postorder")$edge
  for (i in seq_len(nrow(post))) {
    pres[post[i, 1], ] <- pres[post[i, 1], ] | pres[post[i, 2], ]
  }
  child <- sub$edge[, 2]
  len <- sub$edge.length
  age_child <- height - depth[child]
  top <- len + age_child
  len <- ifelse(top >= reftime, pmax(0, len - top + reftime), len)
  a <- rowSums(pres[child, , drop = FALSE])
  root_units <- colSums(obs) > 0 | colSums(u) > 0
  a <- c(a, sum(root_units), rowSums(u))
  len <- c(len, max(0, reftime - height), u_len)
  keep <- len > 0 & a > 0
  list(a = unname(a[keep]), w = len[keep], kind = "PD")
}

# ---- Bootstrap ------------------------------------------------------------

# Estimated detection probabilities of the observed species and of the
# undetected ones (iNEXT; Chao et al. 2014).
boot_community_inc <- function(y, n_units) {
  nt <- n_units
  q1 <- sum(y == 1)
  q2 <- sum(y == 2)
  q0 <- f0_hat(nt, q1, q2)
  a_ <- if (q1 > 0) nt * q0 / (nt * q0 + q1) else 1
  a <- q1 / nt * a_
  b <- sum(y / nt * (1 - y / nt)^nt)
  w <- if (q0 == 0) 0 else a / b
  p <- y / nt * (1 - w * (1 - y / nt)^nt)
  k <- ceiling(q0)
  if (k > 0) p <- c(p, rep(a / k, k))
  p
}

# Bootstrap replicates for incidence data: each replicate draws every
# species' presence in each of the T units, so units keep their
# co-occurrence structure (needed for phylogenetic diversity).
boot_draws_inc <- function(x, nboot, fn, dim) {
  nt <- attr(x, "n_units")
  p <- boot_community_inc(as.vector(x), nt)
  k <- length(p) - length(x)
  und <- if (k > 0) paste0(".undetected", seq_len(k)) else character()
  names(p) <- c(names(x), und)
  if (k > 0 && dim$type != "TD") dim <- boot_extend_dim_inc(x, dim, und)
  draws <- lapply(seq_len(nboot), function(b) {
    m <- matrix(stats::runif(length(p) * nt) < p, length(p), nt,
      dimnames = list(names(p), NULL)
    )
    m <- m[rowSums(m) > 0, , drop = FALSE]
    yb <- as_incidence(stats::setNames(rowSums(m), rownames(m)), nt, m)
    suppressWarnings(fn(yb, dim))
  })
  simplify2array(draws)
}

# Undetected species' branch length (PD) or distances (FD) for the bootstrap.
boot_extend_dim_inc <- function(x, dim, und) {
  k <- length(und)
  if (dim$type == "PD") {
    at <- phylo_attr_inc(attr(x, "inc"), dim$tree, dim$reftime)
    nt <- attr(x, "n_units")
    g0 <- undetected_0(
      nt, sum(at$a == 1), sum(at$a == 2), sum(at$w[at$a == 1]),
      sum(at$w[at$a == 2]), "PD"
    )
    dim$undetected <- list(names = und, length = g0 / k)
  }
  if (dim$type == "FD") {
    dim$distance <- extend_distance(x, dim$distance, und)
  }
  dim
}
