source("r_clear_and_load.r")


# Load =========================================================================
cat("Load\n")

d_cohort_raw <- qread(s_drive("d_cohort_raw.qs"))
d_cohort_hosp_raw <- qread(s_drive("d_cohort_hosp_raw.qs"))

# Collapse dose 3 and booster ==================================================
cat("Collapse dose 3 and booster\n")

d_cohort_raw <- d_cohort_raw %>%
  left_join((
    d_cohort_hosp_raw %>%
      group_by(alf_e) %>%
      summarise(spell_length = max(spell_length)) %>%
    select (alf_e, spell_length)), 
    by = "alf_e"
  ) %>%
  mutate(
    vacc_dose3b_date = pmin(vacc_dose3_date, vacc_doseb_date, na.rm = TRUE),
    vacc_dose3b_name = if_else(
      condition = not_na(vacc_dose3_date) & vacc_dose3b_date == vacc_dose3_date,
      true = vacc_dose3_name,
      false = vacc_doseb_name
    )
  ) %>%
  select(
    -matches("vacc_dose3_.+"),
    -matches("vacc_doseb_.+")
  ) %>%
  rename(
    vacc_doseb_date = vacc_dose3b_date,
    vacc_doseb_name = vacc_dose3b_name
  )


# Select sample ================================================================
cat("Select cohort\n")

lkp_vacc_primary <- c(
  "Astrazeneca",
  "Moderna",
  "Moderna half",
  "Pfizer Biontech",
  "Pfizer child"
)

lkp_vacc_booster <- c(
  "Astrazeneca",
  "Pfizer Biontech",
  "Pfizer child",
  "Moderna",
  "Moderna half"
)


d_cohort_raw <-
  d_cohort_raw %>%
  mutate(
    age_start = floor(interval(wob, start_date_16_over) / dyears(1)),
    age_sep14 = floor(interval(wob, start_date_12_to_15) / dyears(1)),
    age_feb15 = floor(interval(wob, start_date_5_to_11) / dyears(1)),
    age_end = floor(interval(wob, study_end_date) / dyears(1))
  ) %>%
  mutate(
    has_wob_sex           = not_na(wob) & not_na(gndr_cd),
    is_5_17               = 5 <= age_end & age_start <= 17,
    is_welsh_resident     = c20_start_date <= start_date_16_over &
                            c20_end_date >= start_date_16_over &
                            (is.na(death_date) | death_date >= start_date_16_over),
    has_ralf              = not_na(ralf_e) & not_na(lsoa2011_cd),
    has_hh_lte10          = household_n <= 10,
    has_hh_1adult         = adult_n >= 1,
    has_sail_gp           = gp_end_date >= start_date_16_over,
    hosp_spell_lwk        = spell_length <= 7 | is.na(spell_length),
    has_good_vacc_record  = (is.na(has_bad_vacc_record) | has_bad_vacc_record == 0) &
                            (is.na(vacc_dose1_date) | vacc_dose1_date >= start_date_16_over),
    is_study_vacc_primary = (is.na(vacc_dose1_date) | vacc_dose1_name %in% lkp_vacc_primary) &
                            (is.na(vacc_dose2_date) | vacc_dose2_name %in% lkp_vacc_primary) &
                            (is.na(vacc_dose2_date) | vacc_dose2_name == vacc_dose1_name),
    is_study_booster      = (is.na(vacc_doseb_date) | vacc_doseb_name %in% lkp_vacc_booster)
  )

nrow(d_cohort_raw %>% filter(adult_n == 0))

# sample selection summary -----------------------------------------------------

t_cohort_selection <- tribble(
  ~step, ~criteria, ~n,
  1, "In cohort from Aug 2021 to Mar 2022",
    d_cohort_raw %>% nrow(),
  2, "Has wob and sex recorded",
    d_cohort_raw %>% filter(has_wob_sex) %>% nrow(),
  3, "Is aged between 5 and 17 between Aug 2021 and end of study",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17) %>% nrow(),
  4, "Is Welsh resident from Jan 2020",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident) %>% nrow(),
  5, "Has RALF",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf) %>% nrow(),
  6, "Household has less than 10",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf, has_hh_lte10) %>% nrow(),
  7, "Minimum of 1 adult in household",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf, has_hh_lte10, has_hh_1adult) %>% nrow(),
  8, "Is registered with SAIL GP",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf, has_hh_lte10, has_hh_1adult, has_sail_gp) %>% nrow(),
  9, "Does not have a spell in hospital of more than 1 week",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf, has_hh_lte10, has_hh_1adult, has_sail_gp, hosp_spell_lwk) %>% nrow(),
  10, "Has good vacc records",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf, has_hh_lte10, has_hh_1adult, has_sail_gp, hosp_spell_lwk, has_good_vacc_record) %>% nrow(),
  11, "If has first and second dose, then with AZ, MD or PB",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf, has_hh_lte10, has_hh_1adult, has_sail_gp, hosp_spell_lwk, has_good_vacc_record, is_study_vacc_primary) %>% nrow(),
  12, "If has booster dose, then with AZ, MD or PB",
    d_cohort_raw %>% filter(has_wob_sex, is_5_17, is_welsh_resident, has_ralf, has_hh_lte10, has_hh_1adult, has_sail_gp, hosp_spell_lwk, has_good_vacc_record, is_study_vacc_primary, is_study_booster) %>% nrow(),
) %>%
  mutate(
    n_diff = n - lag(n),
    p_diff = round(n_diff / first(n), 3) * 100
  )

print(as.data.frame(t_cohort_selection))

# quick count of people who received their vaccines early ----------------------

early_vac <- 
  d_cohort_raw %>%
  mutate(
    early = 
      case_when(
        between(age_start, 5, 11) & vacc_dose1_date < date('2022-03-22') ~ "5-11",
        between(age_start, 12, 15) & vacc_dose1_date < date('2021-10-04') ~ "12-15",
        between(age_start, 16, 17) & vacc_dose1_date < date('2021-08-04') ~ "16-17"
      ),
    pre_jcvi = 
      case_when(
        between(age_start, 5, 11) & vacc_dose1_date < start_date_5_to_11 ~ "5-11",
        between(age_start, 12, 15) & vacc_dose1_date < start_date_12_to_15 ~ "12-15",
        between(age_start, 16, 17) & vacc_dose1_date < start_date_16_over ~ "16-17"
      )
  ) %>%
  select(
    alf_e, wob, age_start, age_sep14, age_feb15, vacc_dose1_date, vacc_dose1_name, early, pre_jcvi, shielded_flg
  )

early_vac <- early_vac %>%
  select(
    early, pre_jcvi
  ) %>%
#  filter(!is.na(early)) %>%
  mutate(
    age = early,
    early = case_when(!is.na(early) ~ 1),
    pre_jcvi = case_when(!is.na(pre_jcvi) ~ 1)
  ) %>%
  group_by(age) %>%
  summarise(
    early = sum(!is.na(early)),
    pre_jcvi = sum(!is.na(pre_jcvi)),
    tot = nrow(.)
  ) %>%
  mutate(
    early_p = round((early/tot*100),1),
    pre_jcvi_p = round((pre_jcvi/tot*100),1)
  ) %>%
  select(
    age,early, early_p, pre_jcvi, pre_jcvi_p
  ) %>%
  filter(!is.na(age)) %>%
  arrange(factor(age, levels = c("5-11", "12-15", "16-17")))


# apply criteria ---------------------------------------------------------------

d_cohort_raw <-
  d_cohort_raw %>%
  filter(
    has_wob_sex,
    is_5_17,
    is_welsh_resident,
    has_ralf,
    has_hh_lte10,
    has_hh_1adult,
    has_sail_gp,
    hosp_spell_lwk,
    has_good_vacc_record,
    is_study_vacc_primary,
    is_study_booster) %>%
  arrange(alf_e)


# Cleaning =====================================================================
cat("Cleaning\n")

rename_vacc <- function(x) {
  case_when(
    x == "Astrazeneca"     ~ "AZ",
    x == "Moderna"         ~ "MD",
    x == "Moderna half"    ~ "MD",
    x == "Pfizer Biontech" ~ "PB",
    x == "Pfizer child"    ~ "PB"
  )
}

lkp_wimd <- c(
  "1most"  = "1",
  "2"      = "2",
  "3"      = "3",
  "4"      = "4",
  "5least" = "5"
)

d_cohort_clean <-
  d_cohort_raw %>%
  mutate(
    # demographics
    age_cat = case_when(
        age_start >= 18               ~ "18_and_over",
        age_sep14 %>% between(16, 17) ~ "16_17",      #catches anyone who turned 16 by Sep 21
        age_feb15 %>% between(12, 16) ~ "12_15",      #catches anyone who turned 12 by Feb 22
        age_end %>% between( 5, 12) ~ "05_11",        #catches anyone who turns 5 by study end
        # also captures individuals who become eligable for the previous vacc during their rollout
        # e.g. people who turn are 15 for sep21, but have turned 16 by feb22
        # means that everyone who has birthday making them old enough will be counted as valid from the rollout date
        age_end <= 4                ~ "04_and_under"
      ) %>%
      factor() %>%
      fct_explicit_na(),
    sex = factor(gndr_cd, 1:2, c("Male", "Female")),
    ethn_cat = fct_infreq(ethn_cat) %>% fct_explicit_na("Unknown")
  ) %>%
  mutate(
    # area
    wimd2019_quintile = fct_recode(as.character(wimd2019_quintile), !!!lkp_wimd),
    health_board = factor(health_board),
    urban_rural_class =
      urban_rural_class %>%
      factor() %>%
      fct_collapse(
        "Urban" = c(
          "C1 Urban city and town",
          "C2 Urban city and town in a sparse setting"
        ),
        "Rural town" = c(
          "D1 Rural town and fringe",
          "D2 Rural town and fringe in a sparse setting"
        ),
        "Rural village" = c(
          "E1 Rural village and dispersed",
          "E2 Rural village and dispersed in a sparse setting"
        )
      )
  ) %>%
  mutate(
    # vaccination
    has_vacc_dose1  = as.numeric(not_na(vacc_dose1_date)),
    has_vacc_dose2  = as.numeric(not_na(vacc_dose2_date)),
    has_vacc_doseb  = as.numeric(not_na(vacc_doseb_date)),
    vacc_dose1_name = rename_vacc(vacc_dose1_name),
    vacc_dose2_name = rename_vacc(vacc_dose2_name),
    vacc_doseb_name = rename_vacc(vacc_doseb_name)
  ) %>%
  mutate(
    # time between 1st and 2nd dose
    vacc_dose1_dose2_diff_week = floor(interval(vacc_dose1_date, vacc_dose2_date) / dweeks(1)),
    vacc_dose1_dose2_diff_cat = case_when(
      has_vacc_dose1 == 0 | has_vacc_dose2 == 0   ~ "No dose 1 or dose 2",
      between(vacc_dose1_dose2_diff_week,  0,  6) ~ "00-06wk",
      between(vacc_dose1_dose2_diff_week,  7,  8) ~ "07-08wk",
      between(vacc_dose1_dose2_diff_week,  9, 10) ~ "09-10wk",
      between(vacc_dose1_dose2_diff_week, 11, 12) ~ "11-12wk",
      vacc_dose1_dose2_diff_week >= 13            ~ "13+wk"
    ) %>% factor()
  ) %>%
  mutate(
    # prior PCR testing
    pcr_pre08dec2020_cat = case_when(
      is.na(pcr_pre08dec2020_n)         ~ "00",
      between(pcr_pre08dec2020_n, 0, 2) ~ str_pad(pcr_pre08dec2020_n, width = 2, pad = "0"),
      between(pcr_pre08dec2020_n, 3, 9) ~ "03-09",
      pcr_pre08dec2020_n >= 10          ~ "10+"
    ) %>%
      factor(),
    lft_pre08dec2020_cat = case_when(
      is.na(lft_pre08dec2020_n)         ~ "00",
      between(lft_pre08dec2020_n, 0, 2) ~ str_pad(lft_pre08dec2020_n, width = 2, pad = "0"),
      between(lft_pre08dec2020_n, 3, 9) ~ "03-09",
      lft_pre08dec2020_n >= 10          ~ "10+"
    ) %>%
      factor()
  ) %>%
  mutate(
    has_covid_infection = as.numeric(not_na(infection1_test_date)),
  ) %>%
  mutate(
    shielded_flg = replace_na(shielded_flg, 0),
    shielded_cat = factor(shielded_flg, c(0, 1), c("No", "Yes"))
  ) %>%
  mutate(
    # death
    death_noncovid_date = if_else(death_covid_flg == 0, death_date, NA_Date_),
    death_covid_date    = if_else(death_covid_flg == 1, death_date, NA_Date_),
    has_death_noncovid  = as.numeric(not_na(death_noncovid_date)),
    has_death_covid     = as.numeric(not_na(death_covid_date))
  ) %>%
  mutate(
    # tidy dates
    c20_end_date   = na_if(c20_end_date, max(c20_end_date)),
    study_end_date = study_end_date,
  )


# Save =========================================================================
cat("Save\n")

qsave(
  early_vac,
  file = "results/t_early_vac.qs"
)

qsave(
  t_cohort_selection,
  file = "results/t_cohort_selection.qs"
)

qsave(
  d_cohort_clean,
  file = s_drive("d_cohort_clean.qs")
)

beep()
