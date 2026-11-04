# Phylogenetic (PD) and functional (FD) Hill numbers.
#
# Both are computed from "attribute" data: a vector of abundances `a` and a
# matching vector of weights `w`. For PD these are the branch abundances and
# branch lengths of the tree (Chao et al. 2010); for FD they are the
# functional abundances and attribute contributions under a distance
# threshold tau (Chao et al. 2019). Taxonomic diversity is the special case
# a = species counts, w = 1. The estimators follow iNEXT.3D and reproduce its
# point estimates.

# ---- Building attribute data --------------------------------------------

# Branch abundances and lengths of the tree pruned to the species in `x`,
# cut at (or extended to) `reftime`. `undetected` (used by the bootstrap)
# names extra species that are not tips of the tree; each becomes its own
# branch of the given length, joined to the others at the root.
phylo_attr <- function(x, tree, reftime, undetected = NULL) {
  x <- x[x > 0]
  u <- x[names(x) %in% undetected$names]
  x <- x[!names(x) %in% undetected$names]
  if (length(x) <= 1) {
    a <- c(x, u)
    len <- c(rep(reftime, length(x)), rep(min(undetected$length, reftime), length(u)))
    keep <- len > 0 & a > 0
    return(list(a = unname(a[keep]), w = len[keep], kind = "PD"))
  }
  drop <- setdiff(tree$tip.label, names(x))
  sub <- if (length(drop) > 0) ape::drop.tip(tree, drop) else tree
  sub$root.edge <- NULL
  ntip <- length(sub$tip.label)
  depth <- ape::node.depth.edgelength(sub)
  height <- max(depth)
  abun <- numeric(ntip + sub$Nnode)
  abun[seq_len(ntip)] <- x[sub$tip.label]
  post <- ape::reorder.phylo(sub, "postorder")$edge
  for (i in seq_len(nrow(post))) {
    abun[post[i, 1]] <- abun[post[i, 1]] + abun[post[i, 2]]
  }
  child <- sub$edge[, 2]
  len <- sub$edge.length
  age_child <- height - depth[child]
  top <- len + age_child
  len <- ifelse(top >= reftime, pmax(0, len - top + reftime), len)
  a <- abun[child]
  root_len <- max(0, reftime - height)
  a <- c(a, sum(x) + sum(u))
  len <- c(len, root_len)
  if (length(u) > 0) {
    a <- c(a, u)
    len <- c(len, rep(min(undetected$length, reftime), length(u)))
  }
  keep <- len > 0 & a > 0
  list(a = a[keep], w = len[keep], kind = "PD")
}

# Functional abundances and attribute contributions under threshold tau.
func_attr <- function(x, dist, tau, integer = FALSE, cap = Inf) {
  x <- x[x > 0]
  d <- dist[names(x), names(x), drop = FALSE]
  if (tau == 0) {
    d[d > 0] <- 1
    tau_ <- 1
  } else {
    d[d > tau] <- tau
    tau_ <- tau
  }
  a <- as.vector((1 - d / tau_) %*% x)
  keep <- a != 0
  x <- x[keep]
  a <- a[keep]
  a[a < 1] <- 1
  # For incidence data a functional incidence cannot exceed the number of
  # sampling units (iNEXT.3D).
  a[a > cap] <- cap
  if (integer) a <- round(a)
  list(a = a, w = x / a, kind = "FD")
}

# Mean distance between two individuals drawn from the pooled data.
dist_mean <- function(x, dist) {
  p <- x / sum(x)
  d <- dist[names(x), names(x), drop = FALSE]
  sum(outer(p, p) * d)
}

# ---- Estimators on attribute data ----------------------------------------

attr_obs <- function(at, q) {
  a <- at$a
  w <- at$w
  p <- a / sum(a * w)
  vapply(q, function(qq) {
    if (qq == 1) {
      exp(-sum(w * p * log(p)))
    } else {
      sum(w * p^qq)^(1 / (1 - qq))
    }
  }, numeric(1))
}

attr_asy <- function(at, q, n) {
  a <- at$a
  w <- at$w
  tbar <- sum(a * w) / n
  i1 <- a == 1 & w > 0
  i2 <- a == 2 & w > 0
  f1 <- sum(i1)
  f2 <- sum(i2)
  g1 <- sum(w[i1])
  g2 <- sum(w[i2])
  big_a <- if (f2 > 0) {
    2 * f2 / ((n - 1) * f1 + 2 * f2)
  } else if (f1 > 0) {
    2 / ((n - 1) * (f1 - 1) + 2)
  } else {
    1
  }
  vapply(q, function(qq) {
    if (qq == 0) {
      sum(w) + undetected_0(n, f1, f2, g1, g2, at$kind)
    } else if (qq == 1) {
      ok <- a <= n - 1
      h1 <- sum(w[ok] * a[ok] * (digamma(n) - digamma(a[ok]))) / n
      h2 <- undetected_1(n, g1, big_a)
      tbar * exp((h1 + h2) / tbar)
    } else {
      den <- sum(w * a * (a - 1)) / (n * (n - 1))
      out <- tbar^2 / den
      if (!is.finite(out)) out <- tbar^2 / sum(w * (a / n)^2)
      out
    }
  }, numeric(1))
}

undetected_0 <- function(n, f1, f2, g1, g2, kind) {
  if (kind == "FD") {
    if (g1 + g2 == 0) {
      return(0)
    }
    return(if (g2 > 0) (n - 1) / n * g1^2 / (2 * g2) else (n - 1) / n * g1^2 / 2)
  }
  if (f1 == 0) {
    0
  } else if (g1 * f2 / (2 * f1) < g2) {
    (n - 1) / n * g1^2 / (2 * g2)
  } else {
    (n - 1) / n * g1 * (f1 - 1) / (2 * (f2 + 1))
  }
}

undetected_1 <- function(n, g1, big_a) {
  if (big_a == 1 || g1 == 0 || is.infinite((1 - big_a)^(1 - n))) {
    return(0)
  }
  r <- seq_len(n - 1)
  s <- sum((1 - big_a)^r / r)
  (g1 / n) * (1 - big_a)^(1 - n) * round((-log(big_a) - s) * 1e12) / 1e12
}

# Expected diversity in a random subsample of integer size m < n.
attr_rare_int <- function(at, n, m, q) {
  a <- at$a
  w <- at$w
  tbar <- sum(a * w) / n
  # Terms with k above the largest abundance are zero, so skip them.
  k <- seq_len(min(m, max(a)))
  pk <- outer(a, k, function(ai, kk) {
    ok <- ai >= kk & ai <= n - m + kk
    out <- lchoose(ai, kk) + lchoose(n - ai, m - kk) - lchoose(n, m)
    ifelse(ok, exp(out), 0)
  })
  g <- colSums(w * pk)
  r <- k / (m * tbar)
  vapply(q, function(qq) {
    if (qq == 0) {
      sum(g)
    } else if (qq == 1) {
      exp(-sum(r * log(r) * g))
    } else {
      sum(r^qq * g)^(1 / (1 - qq))
    }
  }, numeric(1))
}

# Diversity at sample sizes m (rows) for orders q (columns), with
# rarefaction below n and extrapolation above, as in iNEXT.3D.
attr_at_size <- function(at, n, m, q) {
  obs <- attr_obs(at, q)
  a <- at$a
  w <- at$w
  tbar <- sum(a * w) / n
  cache <- new.env(parent = emptyenv())
  one <- function(mm) {
    if (mm == n) {
      return(obs)
    }
    if (mm < n) {
      lo <- floor(mm)
      hi <- ceiling(mm)
      d_lo <- if (lo == 0) rep(0, length(q)) else attr_rare_int(at, n, lo, q)
      if (lo == hi) {
        return(d_lo)
      }
      d_hi <- if (hi == n) obs else attr_rare_int(at, n, hi, q)
      return((hi - mm) * d_lo + (mm - lo) * d_hi)
    }
    if (is.null(cache$ext)) {
      asy <- pmax(attr_asy(at, q, n), obs)
      rm1 <- attr_rare_int(at, n, n - 1, q)
      if (at$kind == "FD") rm1 <- pmin(rm1, obs)
      beta <- ifelse(asy != obs, (obs - rm1) / (asy - rm1), 0)
      beta[beta == -Inf] <- 1
      cache$ext <- list(asy = asy, beta = beta)
    }
    ext <- cache$ext
    vapply(seq_along(q), function(j) {
      if (q[j] == 2) {
        if (ext$beta[j] == 0) {
          return(ext$asy[j])
        }
        mix <- a / (mm * n) + (mm - 1) / mm * a * (a - 1) / (n * (n - 1))
        return(tbar^2 / sum(w * mix))
      }
      obs[j] + (ext$asy[j] - obs[j]) * (1 - (1 - ext$beta[j])^(mm - n))
    }, numeric(1))
  }
  out <- vapply(m, one, numeric(length(q)))
  matrix(out, nrow = length(m), ncol = length(q), byrow = length(q) > 1)
}

# ---- Dispatch for the three dimensions -----------------------------------

# Settings shared by every site, resolved once from the pooled data.
td_dimension <- function(type, prep, tree, reftime, pd_unit, distance, tau,
                         call = caller_env()) {
  type <- toupper(type)
  if (!type %in% c("TD", "PD", "FD")) {
    cli::cli_abort("{.arg type} must be one of {.val TD}, {.val PD} or {.val FD}.",
      call = call
    )
  }
  pooled <- tapply(prep$data$.n, prep$data$.species, sum)
  pooled <- pooled[pooled > 0]
  spp <- names(pooled)
  if (type == "PD") {
    rlang::check_installed("ape", "to compute phylogenetic diversity.")
    if (!inherits(tree, "phylo")) {
      cli::cli_abort("{.arg tree} must be a {.cls phylo} tree for {.code type = \"PD\"}.",
        call = call
      )
    }
    if (is.null(tree$edge.length)) {
      cli::cli_abort("{.arg tree} must have branch lengths.", call = call)
    }
    miss <- setdiff(spp, tree$tip.label)
    if (length(miss) > 0) {
      cli::cli_abort(c(
        "Every species must be a tip of {.arg tree}.",
        "x" = "Missing: {.val {utils::head(miss, 5)}}."
      ), call = call)
    }
    if (is.null(reftime)) {
      pruned <- ape::drop.tip(tree, setdiff(tree$tip.label, spp))
      reftime <- max(ape::node.depth.edgelength(pruned))
    }
    td_check_number(reftime, "reftime", 0)
    return(list(
      type = type, tree = tree, reftime = reftime,
      divisor = if (pd_unit == "mean") reftime else 1
    ))
  }
  if (type == "FD") {
    if (inherits(distance, "dist")) distance <- as.matrix(distance)
    bad_dist <- !is.matrix(distance) || !is.numeric(distance) ||
      is.null(rownames(distance))
    if (bad_dist) {
      cli::cli_abort(
        "{.arg distance} must be a named numeric distance matrix or {.cls dist}.",
        call = call
      )
    }
    miss <- setdiff(spp, rownames(distance))
    if (length(miss) > 0) {
      cli::cli_abort(c(
        "Every species must be in {.arg distance}.",
        "x" = "Missing: {.val {utils::head(miss, 5)}}."
      ), call = call)
    }
    if (any(distance < 0) || any(distance > 1)) {
      cli::cli_abort("{.arg distance} must be scaled to lie between 0 and 1.",
        call = call
      )
    }
    auc <- identical(tau, "auc") || identical(tau, "AUC")
    if (is.null(tau)) tau <- dist_mean(pooled, distance)
    if (!auc) td_check_number(tau, "tau", 0, 1)
    return(list(type = type, distance = distance, tau = if (auc) "auc" else tau))
  }
  list(type = "TD")
}

# The FD threshold grid used for the area under the tau profile.
auc_grid <- function() seq(1e-8, 1, length.out = 50)

auc_integrate <- function(vals) {
  tau <- auc_grid()
  dt <- diff(tau)
  k <- length(tau)
  (colSums(vals[-k, , drop = FALSE] * dt) + colSums(vals[-1, , drop = FALSE] * dt)) / 2
}

# Smallest non-zero distance between species observed at the site.
dist_min <- function(x, dist) {
  d <- dist[names(x), names(x), drop = FALSE]
  min(d[lower.tri(d)])
}

# Attribute data of an incidence sample: TD uses the incidence frequencies
# with unit weights, PD the branch incidences, FD the functional incidences.
inc_attr <- function(x, dim, tau = NULL, integer = TRUE) {
  y <- stats::setNames(as.vector(x), names(x))
  switch(dim$type,
    TD = list(a = unname(y), w = rep(1, length(y)), kind = "PD"),
    PD = phylo_attr_inc(attr(x, "inc"), dim$tree, dim$reftime, dim$undetected),
    FD = func_attr(y, dim$distance, tau,
      integer = integer, cap = attr(x, "n_units")
    )
  )
}

# Incidence version of the estimators: the attribute estimators with the
# number of units as the sample size.
dim_inc <- function(x, q, dim, what, m = NULL) {
  nt <- attr(x, "n_units")
  div <- if (dim$type == "PD") dim$divisor else 1
  one <- function(tau) {
    if (dim$type == "FD" && tau <= dist_min(x, dim$distance)) {
      at <- inc_attr(x, list(type = "TD"))
    } else {
      # Observed values use the unrounded functional incidences, the
      # estimators the rounded ones, as for abundance data.
      at <- inc_attr(x, dim, tau, integer = what != "obs")
    }
    switch(what,
      obs = attr_obs(at, q),
      asy = attr_asy(at, q, nt),
      size = attr_at_size(at, nt, m, q)
    )
  }
  if (dim$type == "FD" && identical(dim$tau, "auc")) {
    vals <- lapply(auc_grid(), one)
    tau <- auc_grid()
    dt <- diff(tau)
    acc <- 0
    for (i in seq_len(length(vals) - 1)) {
      acc <- acc + (vals[[i]] + vals[[i + 1]]) / 2 * dt[i]
    }
    return(acc)
  }
  one(if (dim$type == "FD") dim$tau else NULL) / div
}

# Observed diversity of one site.
dim_obs <- function(x, q, dim) {
  if (is_incidence(x)) {
    return(dim_inc(x, q, dim, "obs"))
  }
  switch(dim$type,
    TD = hill_obs(x, q),
    PD = attr_obs(phylo_attr(x, dim$tree, dim$reftime, dim$undetected), q) / dim$divisor,
    FD = {
      one <- function(tau) {
        if (tau <= dist_min(x, dim$distance)) {
          hill_obs(x, q)
        } else {
          attr_obs(func_attr(x, dim$distance, tau), q)
        }
      }
      if (identical(dim$tau, "auc")) {
        auc_integrate(t(vapply(auc_grid(), one, numeric(length(q)))))
      } else {
        one(dim$tau)
      }
    }
  )
}

# Asymptotic estimate of one site.
dim_asy <- function(x, q, dim) {
  if (is_incidence(x)) {
    return(dim_inc(x, q, dim, "asy"))
  }
  n <- sum(x)
  switch(dim$type,
    TD = hill_asy(x, q),
    PD = attr_asy(phylo_attr(x, dim$tree, dim$reftime, dim$undetected), q, n) / dim$divisor,
    FD = {
      one <- function(tau) {
        if (tau <= dist_min(x, dim$distance)) {
          hill_asy(x, q)
        } else {
          attr_asy(func_attr(x, dim$distance, tau, integer = TRUE), q, n)
        }
      }
      if (identical(dim$tau, "auc")) {
        auc_integrate(t(vapply(auc_grid(), one, numeric(length(q)))))
      } else {
        one(dim$tau)
      }
    }
  )
}

# Rarefied or extrapolated diversity of one site at sizes m.
dim_at_size <- function(x, m, q, dim) {
  if (is_incidence(x)) {
    return(dim_inc(x, q, dim, "size", m))
  }
  n <- sum(x)
  switch(dim$type,
    TD = hill_at_size(x, m, q),
    PD = attr_at_size(phylo_attr(x, dim$tree, dim$reftime, dim$undetected), n, m, q) /
      dim$divisor,
    FD = {
      one <- function(tau) {
        attr_at_size(func_attr(x, dim$distance, tau, integer = TRUE), n, m, q)
      }
      if (identical(dim$tau, "auc")) {
        vals <- lapply(auc_grid(), one)
        tau <- auc_grid()
        dt <- diff(tau)
        k <- length(vals)
        acc <- 0
        for (i in seq_len(k - 1)) acc <- acc + (vals[[i]] + vals[[i + 1]]) / 2 * dt[i]
        acc
      } else {
        one(dim$tau)
      }
    }
  )
}

# Columns describing the dimension. Taxonomic results are left unchanged so
# existing code keeps working; PD and FD results gain `type` and the
# reference time or threshold used.
add_dim_cols <- function(out, dim) {
  if (dim$type == "TD") {
    return(out)
  }
  out$type <- dim$type
  if (dim$type == "PD") out$reftime <- dim$reftime
  if (dim$type == "FD") out$tau <- if (is.numeric(dim$tau)) dim$tau else NA_real_
  out
}

# ---- Bootstrap community for PD and FD -----------------------------------

# The estimated community used for bootstrap resampling of PD and FD: the
# species probabilities of `boot_community()`, named, with undetected
# species added, and the dimension settings extended to cover them.
#
# PD: each undetected species gets its own branch of length g0 / f0, where
# g0 is the estimated undetected branch length (the q = 0 correction of
# `attr_asy()`) and f0 the estimated number of undetected species, as in
# Chao et al. (2015) and Hsieh and Chao (2017).
#
# FD: undetected species are taken to resemble the rarest observed
# species. Their distance to each observed species is the mean distance
# from the singletons (or, without singletons, the rarest species) to that
# species, and the distance between two undetected species is the mean
# distance among those rare species.
boot_dim_community <- function(x, dim) {
  p <- boot_community(x)
  k <- length(p) - length(x)
  und <- if (k > 0) paste0(".undetected", seq_len(k)) else character()
  names(p) <- c(names(x), und)
  if (k == 0) {
    return(list(p = p, dim = dim))
  }
  if (dim$type == "PD") {
    at <- phylo_attr(x, dim$tree, dim$reftime)
    n <- sum(x)
    f1 <- sum(at$a == 1)
    f2 <- sum(at$a == 2)
    g0 <- undetected_0(
      n, f1, f2, sum(at$w[at$a == 1]), sum(at$w[at$a == 2]), "PD"
    )
    dim$undetected <- list(names = und, length = g0 / k)
  }
  if (dim$type == "FD") {
    dim$distance <- extend_distance(x, dim$distance, und)
  }
  list(p = p, dim = dim)
}

extend_distance <- function(x, dist, und) {
  obs <- names(x)
  d <- dist[obs, obs, drop = FALSE]
  rare <- obs[x == 1]
  if (length(rare) == 0) rare <- obs[x == min(x)]
  to_obs <- colMeans(d[rare, , drop = FALSE])
  among <- if (length(rare) > 1) {
    mean(d[rare, rare][lower.tri(d[rare, rare])])
  } else if (length(obs) > 1) {
    mean(d[lower.tri(d)])
  } else {
    1
  }
  all <- c(obs, und)
  out <- matrix(among, length(all), length(all), dimnames = list(all, all))
  out[obs, obs] <- d
  out[und, obs] <- matrix(to_obs, length(und), length(obs), byrow = TRUE)
  out[obs, und] <- t(out[und, obs])
  diag(out) <- 0
  out
}

# ---- Several dimensions at once -------------------------------------------

td_is_multi_type <- function(type) {
  length(type) > 1 || identical(tolower(type), "all")
}

# Run a diversity function once per dimension and stack the results, with a
# `type` column (TD results otherwise have none).
td_multi_type <- function(call, env, type, error_call = caller_env()) {
  types <- if (identical(tolower(type), "all")) c("TD", "PD", "FD") else toupper(type)
  bad <- setdiff(types, c("TD", "PD", "FD"))
  if (length(bad) || anyDuplicated(types)) {
    cli::cli_abort(
      "{.arg type} must be distinct values from {.val TD}, {.val PD} and \
      {.val FD}, or {.val all}.",
      call = error_call
    )
  }
  res <- lapply(types, function(t) {
    cl <- call
    cl$type <- t
    out <- eval(cl, env)
    if (!"type" %in% names(out)) out$type <- t
    out
  })
  cls <- setdiff(class(res[[1]]), c("tbl_df", "tbl", "data.frame"))
  out <- dplyr::bind_rows(lapply(res, function(r) tibble::as_tibble(unclass(r))))
  out$type <- factor(out$type, levels = types)
  td_new(out, cls)
}
