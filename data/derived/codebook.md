# Codebook: data/derived/letters.csv

One row per response letter (1,366). Built by `src/prepare.R` from `lpmdata.dta`, which stacks each letter
nine times (once per fictitious groom). Original column names are given in brackets.

| column | meaning |
|---|---|
| letter_id | sequential id assigned here; the original file has none |
| profile_id | id shared by letters with identical reported covariates (4 pairs) |
| duplicate_profile | TRUE for those 8 letters |
| edition | 1 = 2 September 2007 placement, 2 = 16 September 2007 [setno] |
| responder_caste | HC / MC / LC = Brahmin / Kayastha / Namasudra [respondercaste h/m/l] |
| repeat_letter | TRUE if flagged as a repeat responder [repeat == 'y']; the paper drops these |
| groomid, groom, groom_caste, groom_income, income_level | the ad this letter answered |
| height_in | bride height in inches; [height] is feet.inches, 5.3 = 5 ft 3 in |
| age | bride age [age] |
| education | [educid] 1 below bachelors, 2 bachelors, 3 masters, 4 phd; raw text in education_raw [educan] |
| sons, daughters, unmdaughters | siblings and unmarried daughters in the family |
| girl_working | [gworking] |
| father_*, mother_* | parent occupation dummies and raw text [foccupn, moccupn, ...] |
| complexion | [complexionid] 1 fair, 2 medium fair, 3 very fair; raw text in complexion_raw |
| looks | [looksid] 1 fair/medium, 2 good, 3 very good; raw text in looks_raw |
| bride_income_pm | bride's monthly income where reported [bridesincomepm] |
| own_house, own_apartment, own_land, own_car | family wealth dummies |
