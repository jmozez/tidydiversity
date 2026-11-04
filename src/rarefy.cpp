#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

// g[k] = sum_i w_i * P(K_i = k), k = 1..kmax, where K_i is the number of the
// a_i individuals (or attribute units) of species i found in a random
// subsample of size m drawn without replacement from n (hypergeometric).
// For integer abundances, log P is computed once at the lowest k and then
// updated by the ratio P(k + 1) / P(k), so each term costs two logs and an
// exp instead of three lgamma calls. Used by the rarefaction
// estimators of Hill numbers (Chao et al. 2014) for TD, PD and FD.
// [[Rcpp::export]]
NumericVector rare_gk(NumericVector a, NumericVector w, double n, double m,
                      int kmax) {
  NumericVector g(kmax);
  const double lchoose_nm = R::lchoose(n, m);
  const int s = a.size();
  for (int i = 0; i < s; ++i) {
    const double ai = a[i];
    const double wi = w[i];
    if (wi == 0.0 || ai <= 0.0) continue;
    // Non-zero terms need k <= a_i and a_i - k <= n - m.
    double lo = std::max(1.0, std::ceil(ai - (n - m)));
    double hi = std::min(std::floor(ai), std::min(m, (double) kmax));
    if (lo > hi) continue;
    if (ai != std::floor(ai)) {
      // Non-integer attribute abundances (functional diversity): evaluate
      // each term directly, as iNEXT.3D does.
      for (double k = lo; k <= hi; k += 1.0) {
        g[(int) k - 1] += wi * std::exp(R::lchoose(ai, k) +
          R::lchoose(n - ai, m - k) - lchoose_nm);
      }
      continue;
    }
    // Log-scale recurrence: the probability at the lowest k can underflow
    // for large samples, so carry log P and exponentiate each term.
    double logp = R::lchoose(ai, lo) + R::lchoose(n - ai, m - lo) - lchoose_nm;
    for (double k = lo; k <= hi; k += 1.0) {
      g[(int) k - 1] += wi * std::exp(logp);
      // P(k + 1) / P(k) = (a - k)(m - k) / ((k + 1)(n - a - m + k + 1))
      const double den = (k + 1.0) * (n - ai - m + k + 1.0);
      const double num = (ai - k) * (m - k);
      if (den <= 0.0 || num <= 0.0) break;
      logp += std::log(num) - std::log(den);
    }
  }
  return g;
}
