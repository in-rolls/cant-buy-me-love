# Build the analysis files from the two original files. Nothing here changes a
# value; it reshapes, labels, and flags.

source("src/functions.R")

lpm <- read_lpm()
letters <- build_letters(lpm)
stacked <- stack_letters(letters)

# Row conservation: the stacked file must reproduce the original 12,294 rows,
# and the response indicator must agree row by row after sorting.
original <- lpm |>
  mutate(rid = row_number()) |>
  group_by(across(all_of(letter_keys))) |>
  mutate(responses = sum(response01)) |>
  ungroup()
stopifnot(
  nrow(stacked) == nrow(lpm),
  sum(stacked$response) == sum(lpm$response01),
  all(table(stacked$groomid) == table(lpm$groomid))
)
# Per groom and responder caste, the count of responses must match the original file.
check <- full_join(
  lpm |> filter(response01 == 1) |> count(groomid, respondercaste, name = "original"),
  stacked |>
    filter(response == 1) |>
    mutate(respondercaste = names(responder_caste_labels)[match(responder_caste, responder_caste_labels)]) |>
    count(groomid, respondercaste, name = "rebuilt"),
  by = c("groomid", "respondercaste")
)
stopifnot(all(check$original == check$rebuilt))

# The maletype string carries the groom and the edition the letter answered;
# check it against groomid and setno.
maletype <- lpm |>
  filter(response01 == 1) |>
  transmute(groomid, setno,
    caste_txt = case_when(grepl("^Br", maletype) ~ "HC", grepl("^Kay", maletype) ~ "MC", TRUE ~ "LC"),
    income_txt = as.integer(sub(".*?/+(\\d+)/.*", "\\1", maletype)),
    edition_txt = ifelse(grepl("sep16", maletype), 2L, 1L)
  ) |>
  left_join(groom_design, by = "groomid")
maletype_check <- maletype |>
  summarise(
    n = n(),
    caste_mismatch = sum(caste_txt != groom_caste),
    income_mismatch = sum(income_txt != groom_income),
    edition_mismatch = sum(edition_txt != setno)
  )
print(maletype_check)

saveRDS(letters, paths$letters)
write.csv(letters, paths$letters_csv, row.names = FALSE)
write_table(maletype_check, "check_maletype")

# Real advertisements. Age and height in the Brahmin sheet contain many
# non-integer values (e.g. 31.6214, 5.9050) that cannot be transcriptions of a
# printed ad; flag them rather than drop them so Table 2 can be built both ways.
sheets <- c(HC = "Brahmin-ABP MAY JUNE 2007 ", MC = "Kayastha-ABP MAY JUNE 2007 ", LC = "Lower-ABP MAY JUNE 2007 ")
ads <- bind_rows(lapply(names(sheets), function(caste) {
  read_excel(paths$ads, sheet = sheets[[caste]], .name_repair = "unique_quiet") |>
    transmute(
      groom_caste = caste,
      sheet_row = row_number() + 1L,
      income = suppressWarnings(as.numeric(`Income (Rs.)`)),
      education = trimws(as.character(Education)),
      job = trimws(as.character(Job)),
      age = suppressWarnings(as.numeric(Age)),
      height_raw = suppressWarnings(as.numeric(Height)),
      communication = trimws(as.character(Communication)),
      caste_no_bar = trimws(as.character(`Caste no bar`)),
      looks_mentioned = trimws(as.character(Looks))
    )
})) |>
  mutate(
    age_noninteger = !is.na(age) & abs(age - round(age)) > 1e-6,
    height_noninteger = !is.na(height_raw) & abs(height_raw * 10 - round(height_raw * 10)) > 1e-6,
    height_in = ifelse(height_noninteger, NA_real_, height_to_inches(height_raw)),
    govt_job = !is.na(job) & grepl("^gov", job, ignore.case = TRUE),
    po_box = !is.na(communication) & grepl("box", communication, ignore.case = TRUE),
    caste_no_bar_flag = !is.na(caste_no_bar) & grepl("^(o\\.k|ok|yes)", caste_no_bar, ignore.case = TRUE),
    education_missing = is.na(education) | education %in% c("na", "n.a", "nm", "")
  )
saveRDS(ads, paths$ads_derived)

ads_flags <- ads |>
  group_by(groom_caste) |>
  summarise(
    rows = n(), income_n = sum(!is.na(income)), age_n = sum(!is.na(age)),
    age_noninteger = sum(age_noninteger), height_n = sum(!is.na(height_raw)),
    height_noninteger = sum(height_noninteger)
  )
print(ads_flags)
write_table(ads_flags, "check_ads_sheets")

codebook <- c(
  "# Codebook: data/derived/letters.csv",
  "",
  "One row per response letter (1,366). Built by `src/prepare.R` from `lpmdata.dta`, which stacks each letter",
  "nine times (once per fictitious groom). Original column names are given in brackets.",
  "",
  "| column | meaning |",
  "|---|---|",
  "| letter_id | sequential id assigned here; the original file has none |",
  "| profile_id | id shared by letters with identical reported covariates (4 pairs) |",
  "| duplicate_profile | TRUE for those 8 letters |",
  "| edition | 1 = 2 September 2007 placement, 2 = 16 September 2007 [setno] |",
  "| responder_caste | HC / MC / LC = Brahmin / Kayastha / Namasudra [respondercaste h/m/l] |",
  "| repeat_letter | TRUE if flagged as a repeat responder [repeat == 'y']; the paper drops these |",
  "| groomid, groom, groom_caste, groom_income, income_level | the ad this letter answered |",
  "| height_in | bride height in inches; [height] is feet.inches, 5.3 = 5 ft 3 in |",
  "| age | bride age [age] |",
  "| education | [educid] 1 below bachelors, 2 bachelors, 3 masters, 4 phd; raw text in education_raw [educan] |",
  "| sons, daughters, unmdaughters | siblings and unmarried daughters in the family |",
  "| girl_working | [gworking] |",
  "| father_*, mother_* | parent occupation dummies and raw text [foccupn, moccupn, ...] |",
  "| complexion | [complexionid] 1 fair, 2 medium fair, 3 very fair; raw text in complexion_raw |",
  "| looks | [looksid] 1 fair/medium, 2 good, 3 very good; raw text in looks_raw |",
  "| bride_income_pm | bride's monthly income where reported [bridesincomepm] |",
  "| own_house, own_apartment, own_land, own_car | family wealth dummies |"
)
writeLines(codebook, "data/derived/codebook.md")

cat("letters:", nrow(letters), " analysis sample:", nrow(analysis_sample(letters)), "\n")
print(table(analysis_sample(letters)$responder_caste))
