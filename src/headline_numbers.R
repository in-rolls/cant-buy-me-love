# Headline descriptive numbers of the kind a reader asks for first: what share of
# letters cross caste lines, in which direction, and how elastic a caste's letter
# share to a groom is with respect to his advertised income.

source("src/functions.R")
set.seed(20260914)

letters <- readRDS(paths$letters)
sample <- analysis_sample(letters)
caste_rank <- c(HC = 1, MC = 2, LC = 3)

cross_caste <- function(data) {
  data |>
    mutate(direction = case_when(
      responder_caste == groom_caste ~ "own caste",
      caste_rank[responder_caste] < caste_rank[groom_caste] ~ "down (to lower-caste groom)",
      TRUE ~ "up (to higher-caste groom)"
    ))
}
summarise_cross <- function(data, by = NULL) {
  data |>
    cross_caste() |>
    group_by(across(all_of(by))) |>
    summarise(letters = n(),
              own_caste = mean(direction == "own caste"),
              cross_caste = 1 - own_caste,
              down = mean(direction == "down (to lower-caste groom)"),
              up = mean(direction == "up (to higher-caste groom)"),
              .groups = "drop")
}
cross_overall <- bind_rows(
  summarise_cross(sample) |> mutate(sample = "paper (1,123 letters)", responder_caste = "All", .before = 1),
  summarise_cross(sample, "responder_caste") |> mutate(sample = "paper (1,123 letters)", .before = 1),
  summarise_cross(letters) |> mutate(sample = "all letters (1,366)", responder_caste = "All", .before = 1),
  summarise_cross(letters, "responder_caste") |> mutate(sample = "all letters (1,366)", .before = 1)
)
write_table(cross_overall, "headline_cross_caste_shares", digits = 3)

# Cross-caste share by groom income: does money pull letters across caste lines?
cross_by_income <- sample |>
  cross_caste() |>
  filter(responder_caste != "LC") |>
  group_by(responder_caste, groom_income) |>
  summarise(letters = n(), share_to_lower_caste = mean(direction == "down (to lower-caste groom)"), .groups = "drop")
write_table(cross_by_income, "headline_down_caste_by_income", digits = 3)

# Income elasticity of a caste's letter share to a groom caste: the slope of
# log(share) on log(income) through the three design points, and the two arc
# elasticities. Bootstrap resamples letters within responder caste.
share_matrix <- function(data) {
  data |>
    count(responder_caste, groom_caste, groom_income) |>
    complete(responder_caste, groom_caste = c("HC", "MC", "LC"), groom_income = c(7000L, 15000L, 35000L),
             fill = list(n = 0L)) |>
    group_by(responder_caste) |>
    mutate(share = n / sum(n)) |>
    ungroup()
}
elasticities <- function(shares) {
  shares |>
    group_by(responder_caste, groom_caste) |>
    arrange(groom_income, .by_group = TRUE) |>
    summarise(
      share_7k = share[1], share_15k = share[2], share_35k = share[3],
      elasticity_loglog = if (any(share == 0)) NA_real_ else unname(coef(lm(log(share) ~ log(groom_income)))[2]),
      arc_7k_to_15k = log(share[2] / share[1]) / log(15 / 7),
      arc_15k_to_35k = log(share[3] / share[2]) / log(35 / 15),
      .groups = "drop"
    )
}
point <- elasticities(share_matrix(sample))
boot <- bind_rows(lapply(seq_len(2000), function(b) {
  resampled <- sample |>
    group_by(responder_caste) |>
    slice_sample(prop = 1, replace = TRUE) |>
    ungroup()
  elasticities(share_matrix(resampled)) |> mutate(draw = b)
}))
boot_ci <- boot |>
  group_by(responder_caste, groom_caste) |>
  summarise(elasticity_lower = quantile(elasticity_loglog, 0.025, na.rm = TRUE),
            elasticity_upper = quantile(elasticity_loglog, 0.975, na.rm = TRUE),
            .groups = "drop")
elasticity_table <- point |>
  left_join(boot_ci, by = c("responder_caste", "groom_caste")) |>
  mutate(relation = case_when(responder_caste == groom_caste ~ "own caste",
                              caste_rank[responder_caste] < caste_rank[groom_caste] ~ "lower-caste groom",
                              TRUE ~ "higher-caste groom")) |>
  arrange(match(responder_caste, c("HC", "MC", "LC")), match(groom_caste, c("HC", "MC", "LC"))) |>
  select(responder_caste, groom_caste, relation, share_7k, share_15k, share_35k,
         elasticity_loglog, elasticity_lower, elasticity_upper, arc_7k_to_15k, arc_15k_to_35k)
write_table(elasticity_table, "headline_income_elasticities", digits = 2)

# Elasticity of the pooled "letters to a lower-caste groom" share for HC and MC families.
down_elasticity <- cross_by_income |>
  group_by(responder_caste) |>
  summarise(elasticity_loglog = unname(coef(lm(log(share_to_lower_caste) ~ log(groom_income)))[2]), .groups = "drop")
write_table(down_elasticity, "headline_down_caste_elasticity", digits = 2)

print(cross_overall)
print(cross_by_income)
print(elasticity_table, width = 150)
print(down_elasticity)

# Assortative benchmark. Each caste's letters face three own-caste and six
# other-caste ads with identical income menus, so a caste-blind writer sends one
# third of letters to own-caste grooms whatever income preference she has.
# Observed own-caste shares against that benchmark, with a chance-corrected
# sorting index (observed - 1/3) / (1 - 1/3): 0 = caste-blind, 1 = fully endogamous.
benchmark <- bind_rows(
  summarise_cross(sample) |> mutate(responder_caste = "All", .before = 1),
  summarise_cross(sample, "responder_caste")
) |>
  transmute(responder_caste, letters, own_caste_observed = own_caste, own_caste_caste_blind = 1 / 3,
            ratio_to_benchmark = own_caste / (1 / 3),
            sorting_index = (own_caste - 1 / 3) / (1 - 1 / 3))
write_table(benchmark, "headline_assortative_benchmark", digits = 3)

# Table 6 run backwards. For a responder caste and an alternative groom caste,
# find the own-caste groom income at which the own-caste letter share equals the
# alternative groom's share at Rs 35,000, interpolating on the own-caste share
# curve; 35,000 minus that income would be the "income forgone for caste" if the
# nine ads were a family's choice set. They were not: the ads sat among hundreds
# in the same edition, and a letter count is the number of families who found an
# ad acceptable, not a ranking. The table is produced only to show that the
# paper's logic, inverted, yields bounds as empty as its point estimates.
sacrifice_from_shares <- function(shares, rc, alt) {
  own <- shares |> filter(responder_caste == rc, groom_caste == rc) |> arrange(groom_income)
  alt_hi <- shares$share[shares$responder_caste == rc & shares$groom_caste == alt & shares$groom_income == 35000]
  if (own$share[1] >= alt_hi) {
    return(c(income_at_par = NA_real_, sacrifice_k = 28, bound = 1))
  }
  if (own$share[3] <= alt_hi) {
    return(c(income_at_par = NA_real_, sacrifice_k = 0, bound = -1))
  }
  y <- approx(own$share, own$groom_income, xout = alt_hi, ties = "ordered")$y
  c(income_at_par = y, sacrifice_k = (35000 - y) / 1000, bound = 0)
}
pairs <- tibble(responder_caste = c("HC", "HC", "MC", "MC", "LC", "LC"),
                alternative_caste = c("MC", "LC", "HC", "LC", "HC", "MC"))
point_shares <- share_matrix(sample)
sacrifice <- bind_rows(lapply(seq_len(nrow(pairs)), function(i) {
  rc <- pairs$responder_caste[i]
  alt <- pairs$alternative_caste[i]
  s <- sacrifice_from_shares(point_shares, rc, alt)
  draws <- vapply(seq_len(2000), function(b) {
    resampled <- sample |> filter(responder_caste == rc) |> slice_sample(prop = 1, replace = TRUE)
    sacrifice_from_shares(share_matrix(resampled), rc, alt)[["sacrifice_k"]]
  }, numeric(1))
  own <- point_shares |> filter(responder_caste == rc, groom_caste == rc) |> arrange(groom_income)
  tibble(responder_caste = rc, alternative_caste = alt,
         own_share_7k = own$share[1], own_share_35k = own$share[3],
         alternative_share_35k = point_shares$share[point_shares$responder_caste == rc &
                                                      point_shares$groom_caste == alt &
                                                      point_shares$groom_income == 35000],
         own_income_at_par = s[["income_at_par"]],
         sacrifice_k = s[["sacrifice_k"]],
         sacrifice_share_of_35k = s[["sacrifice_k"]] / 35,
         at_design_bound = s[["bound"]] == 1,
         sacrifice_lower = quantile(draws, 0.025), sacrifice_upper = quantile(draws, 0.975),
         share_draws_at_bound = mean(draws == 28))
}))
write_table(sacrifice, "audit_table6_inverted", digits = 3)
print(benchmark)
print(sacrifice, width = 160)
