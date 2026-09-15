setwd(Sys.getenv("PROJECT_ROOT", unset = ".."))
source("src/functions.R")
source("src/published_values.R")

letters <- readRDS(paths$letters)
sample <- analysis_sample(letters)

test_that("letters are conserved from the stacked file", {
  expect_equal(nrow(letters), 1366)
  expect_equal(nrow(stack_letters(letters)), 12294)
  expect_equal(nrow(sample), 1123)
  expect_equal(as.vector(table(sample$responder_caste)[c("HC", "MC", "LC")]), c(478, 374, 271))
})

test_that("Table 4 counts match the paper", {
  counts <- sample |>
    count(groom, responder_caste) |>
    pivot_wider(names_from = responder_caste, values_from = n) |>
    arrange(match(groom, groom_levels))
  expect_equal(counts$HC, published_table4$HC)
  expect_equal(counts$MC, published_table4$MC)
  expect_equal(counts$LC, published_table4$LC)
})

fits <- lapply(c(HC = "HC", MC = "MC", LC = "LC"), function(c) fit_lpm(stack_letters(sample), c))

test_that("Table 5 coefficients and HC1 standard errors match to four decimals", {
  for (caste in c("HC", "MC")) {
    b <- coef(fits[[caste]]$fit)
    se <- sqrt(diag(fits[[caste]]$vcov_hc1))
    terms <- c(paste0("groom", published_table5$term[1:8]), "(Intercept)")
    expect_equal(round(unname(b[terms]), 4), published_table5[[paste0(caste, "_est")]], tolerance = 1e-8)
    expect_equal(round(unname(se[terms]), 4), published_table5[[paste0(caste, "_se")]], tolerance = 1e-8)
    expect_equal(nobs(fits[[caste]]$fit), unname(published_table5_n[caste]))
  }
})

test_that("Table 6 HC panels match and the MC panel follows the stated formula", {
  t6 <- compensation_table(fits)
  expect_equal(t6$compensation_k[1:6], c(27.40, 34.87, 40.47, 35.95, 36.56, 49.33), tolerance = 0.002)
  expect_equal(t6$compensation_k[7:9], c(22.56, 13.54, 1.79), tolerance = 0.002)
})

test_that("height conversion reads feet.inches", {
  expect_equal(height_to_inches(c(5.3, 4.11, 5, 6)), c(63, 59, 60, 72))
})
