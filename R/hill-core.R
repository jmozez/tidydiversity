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
    } else {
      1 / (sum(x * (x - 1)) / (n * (n - 1)))
    }
  }, numeric(1))
}

# Expected Hill numbers in a subsample of integer size m < n.
hill_rare_int <- function(x, m, q) {
  n <- sum(x)
  k <- seq_len(m)
  lc <- outer(x, k, function(xi, kk) {
    ok <- xi >= kk & xi <= n - m + kk
    out <- lchoose(xi, kk) + lchoose(n - xi, m - kk) - lchoose(n, m)
    ifelse(ok, exp(out), 0)
  })
  fk <- colSums(lc)
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
  asy <- NULL
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
    if (is.null(asy)) asy <<- hill_asy(x, q)
    rfd <- hill_rare_int(x, n - 1, q)
    vapply(seq_along(q), function(j) {
      if (q[j] == 2) {
        s2 <- sum(x * (x - 1)) / (n * (n - 1))
        return(1 / (1 / mm + (1 - 1 / mm) * s2))
      }
      if (asy[j] == rfd[j]) {
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

coverage_at_size <- function(x, m) {
  n <- sum(x)
  f1 <- sum(x == 1)
  f2 <- sum(x == 2)
  a <- coverage_a(n, f1, f2)
  one_int <- function(mm) {
    if (mm < n) {
      xx <- x[(n - x) >= mm]
      lg <- lgamma(n - xx + 1) - lgamma(n - xx - mm + 1) -
        lgamma(n) + lgamma(n - mm)
      1 - sum(xx / n * exp(lg))
    } else if (mm == n) {
      1 - f1 / n * a
    } else {
      1 - f1 / n * a^(mm - n + 1)
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
  n <- sum(x)
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
    mm <- if (a == 0) n else (log(n / f1) + log(1 - level)) / log(a) - 1 + n
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

boot_draws <- function(x, nboot, fn) {
  if (nboot == 0) {
    return(NULL)
  }
  n <- sum(x)
  p <- boot_community(x)
  draws <- lapply(seq_len(nboot), function(b) {
    xb <- as.vector(stats::rmultinom(1, n, p))
    fn(xb[xb > 0])
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
