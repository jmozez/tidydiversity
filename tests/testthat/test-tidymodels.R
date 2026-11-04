test_that("td_group_folds keeps groups together", {
  skip_if_not_installed("rsample")
  units <- div_hill(png_ants, q = 0, .by = c(season, transect))
  folds <- td_group_folds(units, group = site)
  expect_s3_class(folds, "rset")
  expect_equal(nrow(folds), length(unique(units$site)))
  for (s in folds$splits) {
    expect_length(intersect(
      rsample::analysis(s)$site, rsample::assessment(s)$site
    ), 0)
  }
  expect_error(td_group_folds(units, group = c(site, q)), "exactly one")
})

test_that("td_case_weights gives capped inverse-variance weights", {
  skip_if_not_installed("hardhat")
  w <- td_case_weights(c(1, 2, 4))
  expect_s3_class(w, "hardhat_importance_weights")
  v <- as.double(w)
  expect_equal(mean(v), 1)
  expect_equal(v[1] / v[2], 4)
  expect_equal(max(as.double(td_case_weights(c(0, 10), cap = 100))) /
                 min(as.double(td_case_weights(c(0, 10), cap = 100))), 100)
  expect_error(td_case_weights(-1), "non-negative")
})

test_that("step_hill matches hill_obs and works on new data", {
  skip_if_not_installed("recipes")
  wide <- data.frame(
    y = c(1, 2, 3), sp1 = c(5, 0, 2), sp2 = c(1, 3, 0), sp3 = c(2, 2, 0)
  )
  rec <- recipes::prep(
    step_hill(recipes::recipe(y ~ ., data = wide),
              dplyr::starts_with("sp"), q = c(0, 1, 2))
  )
  out <- recipes::bake(rec, new_data = NULL)
  expect_named(out, c("y", "hill_q0", "hill_q1", "hill_q2"))
  expect_equal(out$hill_q0, c(3, 2, 1))
  expect_equal(unname(unlist(out[1, 2:4])), hill_obs(c(5, 1, 2), 0:2))
  new <- recipes::bake(rec, new_data = wide[1, ])
  expect_equal(new$hill_q2, out$hill_q2[1])
  expect_equal(nrow(recipes::tidy(rec, 1)), 3)
})

test_that("step_hill fits in a tidymodels workflow", {
  skip_if_not_installed("workflows")
  skip_if_not_installed("parsnip")
  wide <- data.frame(
    y = c(1, 2, 3, 4, 5), sp1 = c(5, 0, 2, 1, 4),
    sp2 = c(1, 3, 0, 2, 2), sp3 = c(2, 2, 0, 1, 6)
  )
  rec <- step_hill(recipes::recipe(y ~ ., data = wide),
                   dplyr::starts_with("sp"), q = 1)
  wf <- workflows::workflow(rec, parsnip::linear_reg())
  fit <- parsnip::fit(wf, wide)
  expect_length(predict(fit, wide)$.pred, 5)
})
