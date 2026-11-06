# Internal estimators. These follow Chao et al. (2014) and reproduce the
# point estimates of iNEXT 3.0 for abundance data.

hill_obs <- function(x, q) {
  p <- x / sum(x)
  vapply(q, function(qq) {
    if (qq == 0) {
      length(p)
    } else if (qq == 1) {
      exp(-sum(p * log(p)))
    } else {
      sum(p^qq)^(1 / (1 - qq))
    }
  }, numeric(1))
}

f0_hat <- function(n, f1, f2) {
  if (f2 > 0) (n - 1) / n * f1^2 / 2 / f2 else (n - 1) / n * f1 * (f1 - 1) / 2
}

d1_second <- function(n, f1, f2) {
  if (f2 > 0) {
    a <- 2 * f2 / ((n - 1) * f1 + 2 * f2)
  } else if (f1 != 0) {
    a <- 2 / ((n - 1) * (f1 - 1) + 2)
  } else {
    a <- 1
  }
  if (a == 1 || f1 == 0 || n < 2) {
    return(0)
  }
  r <- seq_len(n - 1)
  s <- sum((1 - a)^r / r)
  (f1 / n) * (1 - a)^(1 - n) * round((-log(a) - s) * 1e12) / 1e12
}

hill_asy <- function(x, q) {
  n <- sum(x)
  f1 <- sum(x == 1)
  f2 <- sum(x == 2)
  vapply(q, function(qq) {
    if (qq == 0) {
      length(x) + f0_hat(n, f1, f2)
    } else if (qq == 1) {
      tab <- table(x)
      sx <- as.numeric(names(tab))
      tab <- as.numeric(tab)
      h <- sum(tab * sx / n * (digamma(n) - digamma(sx)))
      exp(h + d1_second(n, f1, f2))
    } else if (qq == 2) {
      1 / (sum(x * (x - 1)) / (n * (n - 1)))
    } else {
      hill_asy_q(x, qq, n, f1, f2)^(1 / (1 - qq))
    }
  }, numeric(1))
}

# Estimated sum of p^q for any order q (Chao and Jost 2015, eq. 9),
# as used by iNEXT.3D and iNEXT.4steps.
hill_asy_q <- function(x, q, n, f1, f2) {
  big_a <- coverage_big_a(n, f1, f2)
  tab <- table(x)
  z <- as.numeric(names(tab))
  term <- vapply(z, function(zz) {
    k <- 0:(n - zz)
    sum(choose(k - q, k) * exp(lchoose(n - k - 1, zz - 1) - lchoose(n, zz)))
  }, numeric(1))
  out <- sum(as.numeric(tab) * term)
  if (f1 > 0 && big_a != 1) {
    r <- 0:(n - 1)
    out <- out + f1 / n * (1 - big_a)^(1 - n) *
      (big_a^(q - 1) - sum(choose(q - 1, r) * (big_a - 1)^r))
  }
  out
}

coverage_big_a <- function(n, f1, f2) {
  if (f2 > 0) {
    2 * f2 / ((n - 1) * f1 + 2 * f2)
  } else if (f1 > 0) {
    2 / ((n - 1) * (f1 - 1) + 2)
  } else {
    1
  }
}

# Expected Hill numbers in a subsample of integer size m < n.
hill_rare_int <- function(x, m, q) {
  n <- sum(x)
  k <- seq_len(min(m, max(x)))
  # Expected number of species with k individuals in the subsample
  # (C++ kernel, hypergeometric terms by recurrence).
  fk <- rare_gk(as.double(x), rep(1, length(x)), n, m, length(k))
  vapply(q, function(qq) {
    if (qq == 0) {
      sum(fk)
    } else if (qq == 1) {
      exp(-sum(k / m * log(k / m) * fk))
    } else {
      sum((k / m)^qq * fk)^(1 / (1 - qq))
    }
  }, numeric(1))
}

# Diversity at sample sizes m (rows) for orders q (columns).
hill_at_size <- function(x, m, q) {
  n <- sum(x)
  obs <- hill_obs(x, q)
  cache <- new.env(parent = emptyenv())
  one <- function(mm) {
    if (mm == n) {
      return(obs)
    }
    if (mm < n) {
      lo <- floor(mm)
      hi <- ceiling(mm)
      if (lo == hi) {
        return(hill_rare_int(x, mm, q))
      }
      d_lo <- if (lo == 0) rep(0, length(q)) else hill_rare_int(x, lo, q)
      d_hi <- if (hi == n) obs else hill_rare_int(x, hi, q)
      return(d_lo + (mm - lo) * (d_hi - d_lo))
    }
    if (is.null(cache$asy)) {
      cache$asy <- hill_asy(x, q)
      cache$rfd <- hill_rare_int(x, n - 1, q)
    }
    asy <- cache$asy
    rfd <- cache$rfd
    vapply(seq_along(q), function(j) {
      if (q[j] == 2) {
        s2 <- sum(x * (x - 1)) / (n * (n - 1))
        return(1 / (1 / mm + (1 - 1 / mm) * s2))
      }
      if (!is.finite(asy[j]) || !is.finite(rfd[j]) || asy[j] == rfd[j]) {
        return(obs[j])
      }
      beta <- (obs[j] - rfd[j]) / (asy[j] - rfd[j])
      beta[is.nan(beta) | !is.finite(beta)] <- 0
      obs[j] + (asy[j] - obs[j]) * (1 - (1 - beta)^(mm - n))
    }, numeric(1))
  }
  out <- vapply(m, one, numeric(length(q)))
  matrix(out, nrow = length(m), ncol = length(q), byrow = length(q) > 1)
}

coverage_a <- function(n, f1, f2) {
  f0 <- f0_hat(n, f1, f2)
  if (f1 > 0) n * f0 / (n * f0 + f1) else 1
}

# Expected sample coverage at sample size m. For incidence data the sample
# size is the number of units and coverage is weighted by the incidence
# total U (Chao et al. 2014); for abundance data U equals n.
coverage_at_size <- function(x, m) {
  n <- smp_n(x)
  x <- as.vector(x)
  u <- sum(x)
  f1 <- sum(x == 1)
  f2 <- sum(x == 2)
  a <- coverage_a(n, f1, f2)
  one_int <- function(mm) {
    if (mm < n) {
      xx <- x[(n - x) >= mm]
      lg <- lgamma(n - xx + 1) - lgamma(n - xx - mm + 1) -
        lgamma(n) + lgamma(n - mm)
      1 - sum(xx / u * exp(lg))
    } else if (mm == n) {
      1 - f1 / u * a
    } else {
      1 - f1 / u * a^(mm - n + 1)
    }
  }
  vapply(m, function(mm) {
    lo <- floor(mm)
    hi <- ceiling(mm)
    if (lo == hi) {
      return(one_int(mm))
    }
    c_lo <- if (lo == 0) 0 else one_int(lo)
    c_lo + (mm - lo) * (one_int(hi) - c_lo)
  }, numeric(1))
}

# Sample size that reaches coverage `level`.
size_for_coverage <- function(x, level) {
  n <- smp_n(x)
  ref <- coverage_at_size(x, n)
  if (ref > level) {
    opt <- stats::optimize(
      function(m) abs(coverage_at_size(x, m) - level),
      lower = 0,
      upper = n
    )
    mm <- opt$minimum
  } else if (ref == level) {
    mm <- n
  } else {
    f1 <- sum(x == 1)
    f2 <- sum(x == 2)
    if (f1 > 0 && f2 > 0) {
      a <- (n - 1) * f1 / ((n - 1) * f1 + 2 * f2)
    } else if (f1 > 1 && f2 == 0) {
      a <- (n - 1) * (f1 - 1) / ((n - 1) * (f1 - 1) + 2)
    } else {
      a <- 0
    }
    # log(U / f1): U, the total count, equals n for abundance data
    mm <- if (a == 0) n else (log(sum(x) / f1) + log(1 - level)) / log(a) - 1 + n
  }
  max(mm, 1)
}

# The estimated community used for bootstrap resampling.
boot_community <- function(x) {
  n <- sum(x)
  f1 <- sum(x == 1)
  f2 <- sum(x == 2)
  f0 <- f0_hat(n, f1, f2)
  a <- coverage_a(n, f1, f2)
  a1 <- f1 / n * a
  b <- sum(x / n * (1 - x / n)^n)
  w <- if (f0 == 0) 0 else a1 / b
  p <- x / n * (1 - w * (1 - x / n)^n)
  k <- ceiling(f0)
  if (k > 0) p <- c(p, rep(a1 / k, k))
  p
}

# Bootstrap replicates of `fn(xb, dim)`, where `xb` is a resampled
# community and `dim` the dimension settings that cover its species.
boot_draws <- function(x, nboot, fn, dim = list(type = "TD")) {
  if (nboot == 0) {
    return(NULL)
  }
  if (is_incidence(x)) {
    return(boot_draws_inc(x, nboot, fn, dim))
  }
  n <- sum(x)
  if (dim$type == "TD") {
    p <- boot_community(x)
  } else {
    comm <- boot_dim_community(x, dim)
    p <- comm$p
    dim <- comm$dim
  }
  td_check_boot_n(n, call = NULL)
  draws <- lapply(seq_len(nboot), function(b) {
    xb <- as.vector(stats::rmultinom(1, n, p))
    names(xb) <- names(p)
    suppressWarnings(fn(xb[xb > 0], dim))
  })
  simplify2array(draws)
}

boot_se <- function(draws, dims) {
  if (is.null(draws)) {
    return(array(NA_real_, dims))
  }
  if (is.null(dim(draws)) || length(dim(draws)) == 1) {
    draws <- matrix(draws, nrow = 1)
  }
  if (length(dim(draws)) == 2) {
    se <- apply(draws, 1, stats::sd, na.rm = TRUE)
  } else {
    se <- apply(draws, c(1, 2), stats::sd, na.rm = TRUE)
  }
  array(se, dims)
}

# Default coverage level of each site: the lowest coverage that the sites in
# its group reach at twice their sample size (as iNEXT::estimateD()).
default_coverage_level <- function(prep) {
  c2n <- td_per_site(prep, function(x, i) {
    tibble::tibble(.c2n = coverage_at_size(x, 2 * smp_n(x)))
  })
  grp <- if (length(prep$by)) vctrs::vec_group_id(c2n[prep$by]) else rep(1L, nrow(c2n))
  stats::ave(c2n$.c2n, grp, FUN = min)
}
