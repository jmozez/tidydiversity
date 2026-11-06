#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

static inline double haversine_m(double lon1, double lat1,
                                 double lon2, double lat2) {
  const double to_rad = M_PI / 180.0;
  const double dlon = (lon2 - lon1) * to_rad;
  const double dlat = (lat2 - lat1) * to_rad;
  const double a = std::sin(dlat / 2.0) * std::sin(dlat / 2.0) +
    std::cos(lat1 * to_rad) * std::cos(lat2 * to_rad) *
    std::sin(dlon / 2.0) * std::sin(dlon / 2.0);
  return 6371000.0 * 2.0 * std::atan2(std::sqrt(a), std::sqrt(std::max(0.0, 1.0 - a)));
}

// Pairwise haversine distances for equal-length vectors (pair i uses i-th
// elements of each vector). Used by geo_distance().
// [[Rcpp::export]]
NumericVector geo_haversine_pair_cpp(NumericVector lon1, NumericVector lat1,
                                     NumericVector lon2, NumericVector lat2) {
  const int n = lon1.size();
  if (lat1.size() != n || lon2.size() != n || lat2.size() != n) {
    stop("All coordinate vectors must have the same length.");
  }
  NumericVector out(n);
  for (int i = 0; i < n; ++i) {
    if (!R_finite(lon1[i]) || !R_finite(lat1[i]) ||
        !R_finite(lon2[i]) || !R_finite(lat2[i])) {
      out[i] = NA_REAL;
    } else {
      out[i] = haversine_m(lon1[i], lat1[i], lon2[i], lat2[i]);
    }
  }
  return out;
}

// Dense n x n haversine distance matrix for Moran's I and cleaning.
// [[Rcpp::export]]
NumericMatrix geo_haversine_matrix_cpp(NumericVector lon, NumericVector lat) {
  const int n = lon.size();
  if (lat.size() != n) stop("`lon` and `lat` must have the same length.");
  NumericMatrix out(n, n);
  for (int i = 0; i < n; ++i) {
    out(i, i) = 0.0;
    for (int j = i + 1; j < n; ++j) {
      double d = NA_REAL;
      if (R_finite(lon[i]) && R_finite(lat[i]) &&
          R_finite(lon[j]) && R_finite(lat[j])) {
        d = haversine_m(lon[i], lat[i], lon[j], lat[j]);
      }
      out(i, j) = d;
      out(j, i) = d;
    }
  }
  return out;
}
