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

print(benchmark)
