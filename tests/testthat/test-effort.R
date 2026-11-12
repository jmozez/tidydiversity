test_that("div_effort reaches each target exactly at the returned size", {
  e <- div_effort(png_ants, .by = season, coverage = c(0.9, 0.95), fraction = c(0.8, 0.9))
  expect_s3_class(e, "td_effort")
  ants <- dplyr::filter(png_ants, season == "wet", site == "MW0700")
  row <- dplyr::filter(e, season == "wet", site == "MW0700")
  rf <- suppressWarnings(div_rarefy(ants, q = 0, size = c(row$total, row$total - 1)))
  for (i in seq_len(nrow(row))) {
    if (row$additional[i] == 0) next
    if (row$target[i] == "coverage") {
      cv <- rf$coverage[match(c(row$total[i], row$total[i] - 1), rf$m)]
      expect_gte(cv[1], row$level[i] - 1e-9)
      expect_lt(cv[2], row$level[i])
    } else {
      s <- rf$diversity[match(c(row$total[i], row$total[i] - 1), rf$m)]
      expect_gte(s[1], row$level[i] * row$s_est[i] - 1e-9)
      expect_lt(s[2], row$level[i] * row$s_est[i])
    }
  }
})

test_that("incidence effort is in sampling units", {
  e <- div_effort(png_ants, unit = bait, n_units = baits, .by = season, fraction = NULL)
  expect_true(all(e$n == 60))
  expect_true(all(e$target == "coverage"))
  expect_true(all(e$additional[e$coverage_now >= e$level] == 0))
  expect_true(all(e$additional[e$coverage_now < e$level] > 0))
})

test_that("div_effort validates targets", {
  expect_error(div_effort(png_ants, fraction = 1), "between 0 and 1")
  expect_error(div_effort(png_ants, coverage = NULL, fraction = NULL), "at least one")
  expect_equal(effort_fraction(100, 10, 0, 0, 0.9), 0)
})
