source("r_clear_and_load.r")

# Load =========================================================================
cat("Load\n")

d_cohort <-
  qread(s_drive("d_cohort_clean.qs")) %>%
  rename(move_out_date = c20_end_date)


# Select analysis sample =======================================================
cat("Select analysis sample\n")

# exclude those who had been vaccinated prior to the general eligibility
# for their age group

d_cohort <- d_cohort %>%
  mutate(
    first_dose_start_date = case_when(
      age_cat == "05_11" ~ start_date_5_to_11,
      age_cat == "12_15" ~ start_date_12_to_15,
      age_cat == "16_17" ~ start_date_16_over
    ),
    second_dose_start_date = case_when(
      difftime(study_end_date, vacc_dose1_date, units = "days") >= 28 ~ vacc_dose1_date + 28
    ),
    booster_dose_start_date = case_when(
      difftime(study_end_date, vacc_dose2_date, units = "days") >= 28 ~ vacc_dose2_date + 28
    )
  ) %>%
  mutate(
    has_valid_dose1 = is.na(vacc_dose1_date) | first_dose_start_date   <= vacc_dose1_date,
    has_valid_dose2 = is.na(vacc_dose2_date) | second_dose_start_date  <= vacc_dose2_date,
    has_valid_doseb = is.na(vacc_doseb_date) | booster_dose_start_date <= vacc_doseb_date
  )


t_analysis_sample_selection <- tribble(
    ~step, ~criteria, ~n,
  1, "In cleaned cohort",
    d_cohort %>% nrow(),
  2, "Date of dose 1 is after eligibility",
    d_cohort %>% filter(has_valid_dose1) %>% nrow(),
  3, "Time between dose 1 and dose 2 is at least 28 days",
    d_cohort %>% filter(has_valid_dose1, has_valid_dose2) %>% nrow(),
  4, "Time between dose 2 and booster dose is at least 28 days",
    d_cohort %>% filter(has_valid_dose1, has_valid_dose2, has_valid_doseb) %>% nrow()
)

print(t_analysis_sample_selection)

d_analysis <- d_cohort %>%
  filter(
    has_valid_dose1,
    has_valid_dose2,
    has_valid_doseb
  )



# Make analysis sample =========================================================
cat("Make analysis sample\n")

d_analysis <-
  d_analysis %>%
  mutate(
    # first dose
    first_dose_stop_date = pmin(
      vacc_dose1_date,
      study_end_date,
      na.rm = TRUE
    ),
    first_dose_event_cat = case_when(
      vacc_dose1_date == first_dose_stop_date ~ "vacc_dose1",
      study_end_date  == first_dose_stop_date ~ "study_end"
    ),
    first_dose_event_flg = as.numeric(
      first_dose_event_cat == "vacc_dose1"
    ),
    # second dose
    second_dose_stop_date = pmin(
      vacc_dose2_date,
      study_end_date,
      na.rm = TRUE
    ),
    second_dose_event_cat = case_when(
      vacc_dose2_date == second_dose_stop_date ~ "vacc_dose2",
      study_end_date  == second_dose_stop_date ~ "study_end"
    ),
    second_dose_event_flg = as.numeric(
      second_dose_event_cat == "vacc_dose2"
    ),
    # booster dose
    booster_dose_stop_date = pmin(
      vacc_doseb_date,
      study_end_date,
      na.rm = TRUE
    ),
    booster_dose_event_cat = case_when(
      vacc_doseb_date == booster_dose_stop_date ~ "vacc_doseb",
      study_end_date  == booster_dose_stop_date ~ "study_end"
    ),
    booster_dose_event_flg = as.numeric(
      booster_dose_event_cat == "vacc_doseb"
    )
  ) %>%
  # survivals analysis needs "days since" rather than dates
  mutate(
    first_dose_tstart   = 0,
    first_dose_tstop    = interval(first_dose_start_date, first_dose_stop_date) / ddays(),
    second_dose_tstart  = 0,
    second_dose_tstop   = interval(second_dose_start_date, second_dose_stop_date) / ddays(),
    booster_dose_tstart = 0,
    booster_dose_tstop  = interval(booster_dose_start_date, booster_dose_stop_date) / ddays()
  ) %>%
  # survival analysis doesn't like events occurring at time = 0
  # so we do a trick and just add half a day on to those with tstop = 0
  mutate(
    first_dose_tstop   = ifelse(first_dose_tstop   == 0, 0.5, first_dose_tstop),
    second_dose_tstop  = ifelse(second_dose_tstop  == 0, 0.5, second_dose_tstop),
    booster_dose_tstop = ifelse(booster_dose_tstop == 0, 0.5, booster_dose_tstop)
  ) %>%
  verify(first_dose_tstart < first_dose_tstop) %>%
  verify(second_dose_tstart < second_dose_tstop | is.na(second_dose_tstop)) %>%
  verify(booster_dose_tstart < booster_dose_tstop | is.na(booster_dose_tstop))

# Derive any extra variables ===================================================
cat("Derive any extra variables\n")

d_analysis <- d_analysis %>%
  mutate(
    household_n = case_when(
      household_n < 5  ~ as.character(household_n),
      household_n >= 5 ~ "5+"
    )
  ) %>%
  mutate(
    first_infection = pmin(
      infection1_test_date,
      infection2_test_date,
      infection3_test_date,
      infection4_test_date,
      na.rm = TRUE
    ),
    prior_infection = if_else(first_infection < first_dose_start_date, "Yes", "No", "No"),
    prior_infection = factor(prior_infection, c("No", "Yes"))
  )


# Save =========================================================================
cat("Save\n")

qsave(
  t_analysis_sample_selection,
  file = "results/t_analysis_sample_selection.qs"
)

qsave(
  d_analysis,
  file = s_drive("d_analysis.qs")
)

beep()
