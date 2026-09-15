# Values transcribed from the December 2010 final draft (sources/paper_2010_12_final_draft.txt).

published_table4 <- tibble::tribble(
  ~groom, ~HC, ~MC, ~LC,
  "HCG-HI", 110, 27, 3,
  "HCG-MI", 85, 34, 7,
  "HCG-LI", 86, 39, 21,
  "MCG-HI", 66, 83, 10,
  "MCG-MI", 29, 46, 39,
  "MCG-LI", 21, 29, 32,
  "LCG-HI", 51, 58, 69,
  "LCG-MI", 25, 31, 45,
  "LCG-LI", 5, 27, 45
)

# Table 5. Column (3) prints p-values, not standard errors, in parentheses.
published_table5 <- tibble::tribble(
  ~term, ~HC_est, ~HC_se, ~MC_est, ~MC_se, ~LC_est, ~LC_p,
  "HCG-HI", 0.2197, 0.0198, -0.0000, 0.0190, -0.1550, 0.000,
  "HCG-MI", 0.1674, 0.0181, 0.0187, 0.0200, -0.1402, 0.000,
  "HCG-LI", 0.1695, 0.0182, 0.0321, 0.0207, -0.0886, 0.002,
  "MCG-HI", 0.1276, 0.0165, 0.1497, 0.0253, -0.1292, 0.000,
  "MCG-MI", 0.0502, 0.0119, 0.0508, 0.0217, -0.0221, 0.477,
  "MCG-LI", 0.0335, 0.0105, 0.0053, 0.0193, -0.0480, 0.110,
  "LCG-HI", 0.0962, 0.0149, 0.0829, 0.0230, 0.0886, 0.011,
  "LCG-MI", 0.0418, 0.0112, 0.0107, 0.0196, -0.0000, 1.000,
  "Constant", 0.0105, 0.0047, 0.0722, 0.0134, 0.1661, 0.000
)
published_table5_n <- c(HC = 4302, MC = 3366, LC = 2439)
published_table5_r2 <- c(HC = 0.05, MC = 0.02, LC = 0.058)

# Footnotes 15, 16, 19, 20. Tests reported without a statistic carry NA and a
# verbal verdict: "reject_1pct" or "not_rejected".
published_footnote_tests <- tibble::tribble(
  ~responder_caste, ~hypothesis, ~f, ~p, ~verdict,
  "HC", "HCG-HI = MCG-HI", 13.65, 0.000, "reject_1pct",
  "HC", "HCG-HI = LCG-HI", 26.67, 0.000, "reject_1pct",
  "HC", "MCG-HI = LCG-HI", 2.19, 0.138, "not_rejected",
  "HC", "HCG-MI = MCG-MI", 32.22, 0.000, "reject_1pct",
  "HC", "HCG-MI = LCG-MI", 38.39, 0.000, "reject_1pct",
  "HC", "MCG-MI = LCG-MI", 0.31, 0.576, "not_rejected",
  "HC", "HCG-LI = MCG-LI", 46.53, 0.000, "reject_1pct",
  "HC", "HCG-LI = LCG-LI", NA, NA, "reject_1pct",
  "HC", "MCG-LI = LCG-LI", NA, NA, "reject_1pct",
  "HC", "MCG-HI = MCG-MI", 16.24, 0.000, "reject_1pct",
  "HC", "MCG-MI = MCG-LI", 1.35, 0.245, "not_rejected",
  "HC", "MCG-HI = MCG-LI", 26.26, 0.000, "reject_1pct",
  "HC", "LCG-HI = LCG-MI", 9.74, 0.002, "reject_1pct",
  "HC", "LCG-HI = LCG-LI", NA, NA, "reject_1pct",
  "HC", "LCG-MI = LCG-LI", NA, NA, "reject_1pct",
  "MC", "MCG-HI = LCG-HI", 5.49, 0.019, "reject_5pct",
  "MC", "MCG-MI = LCG-MI", 3.26, 0.071, "reject_10pct",
  "MC", "MCG-LI = LCG-LI", NA, NA, "reject_1pct",
  "MC", "LCG-HI = LCG-MI", 9.39, 0.002, "reject_1pct",
  "MC", "LCG-HI = LCG-LI", NA, NA, "reject_1pct",
  "MC", "LCG-MI = LCG-LI", NA, NA, "not_rejected"
)

published_table6 <- tibble::tribble(
  ~pair, ~HI, ~MI, ~LI, ~mean, ~sd,
  "HCR-MCG", 27.40, 34.87, 40.47, 34.25, 6.55,
  "HCR-LCG", 35.95, 36.56, 49.33, 40.61, 7.56,
  "MCR-LCG", 22.56, 17.16, 0.00, 13.24, 11.78
)

published_table3 <- tibble::tribble(
  ~responder_caste, ~responses, ~height_mean, ~age_mean, ~girl_working, ~education_below_bachelors,
  ~education_bachelors, ~education_above_bachelors, ~fair, ~medium_fair, ~very_fair,
  ~fairly_good_looking, ~medium_good_looking, ~very_good_looking, ~siblings_mean, ~unmarried_sisters_mean,
  ~father_absent, ~own_house_or_apt,
  "Aggregate", 1123, 63.2, 25.1, 192, 93, 632, 394, 379, 318, 333, 644, 239, 82, 2.14, 1.13, 77, 307,
  "HC", 478, 63.4, 25.5, 89, 24, 267, 185, 168, 125, 123, 299, 73, 36, 2.19, 1.15, 24, 116,
  "MC", 374, 62.9, 24.9, 52, 37, 205, 131, 130, 93, 128, 196, 100, 22, 2.16, 1.12, 25, 111,
  "LC", 271, 63.5, 24.7, 51, 32, 160, 78, 81, 100, 82, 149, 66, 24, 2.00, 1.10, 28, 80
)

published_table2 <- tibble::tribble(
  ~groom_caste, ~ads, ~income_n, ~income_mean, ~income_sd, ~age_n, ~age_mean, ~height_n, ~height_mean, ~height_sd,
  ~govt_job, ~po_box, ~caste_no_bar, ~looks_mentioned, ~education_not_mentioned,
  "Aggregate", 2777, 1261, 15858, 9894, 2776, 32, 2777, 64.59, 3.26, 2220, 1529, 104, 1619, 571,
  "HC", 1368, 527, 17232, 8376, 1368, 32, 1368, 64.41, 3.12, 1100, 802, 45, 779, 275,
  "MC", 768, 375, 16714, 12317, 768, 31, 768, 65.33, 3.21, 591, 381, 15, 406, 196,
  "LC", 641, 359, 12949, 8421, 640, 32, 641, 64.08, 3.45, 529, 346, 44, 434, 100
)
