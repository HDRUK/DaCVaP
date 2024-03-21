
# Load data ====================================================================
cat("Load in wide table\n")
d_analysis <- qread(s_drive("d_analysis.qs")) %>% 
  select(alf_e, sex, age_cat, household_n, hh_vaccinated,vacc_dose1_date,vacc_dose2_date,vacc_doseb_date,
         infection1_test_date,infection2_test_date,infection3_test_date,infection4_test_date, move_out_date, death_date)

# Convert to long data forma step 1 ============================================
cat("Convert to long data format step 1 - this is a long one\n")

d_vacc_status <-
  d_analysis %>% 
mutate(
  study_end_date = study_end_date,
  eligibility_date = 
    case_when(age_cat == "16_17" ~ start_date_16_over,
              age_cat == "12_15" ~ start_date_12_to_15,
              age_cat == "05_11" ~ start_date_5_to_11),
  vac_flg = case_when(!is.na(vacc_dose1_date)|!is.na(vacc_dose2_date)|!is.na(vacc_doseb_date) ~1) 
) %>%
  filter(
    is.na(death_date) | death_date > eligibility_date
  ) %>%
  pivot_longer(
    cols = c(infection1_test_date, infection2_test_date, infection3_test_date, infection4_test_date),
    names_pattern = "(\\d+)",
    names_to = "infection_case",
    values_to = "infection_date"
  ) %>%
  filter(
    (infection_date > eligibility_date - days(28) & infection_date <= vacc_dose1_date) |
      (infection_date > eligibility_date - days(28) & infection_date <= vacc_dose2_date) |
      (infection_date > eligibility_date - days(28) & infection_date <= vacc_doseb_date) |
      (infection_date > eligibility_date - days(28) & infection_date <= study_end_date & is.na(vac_flg)) |
      is.na(infection_date)
  ) %>%
  pivot_wider(
    names_from = "infection_case",
    values_from = "infection_date",
    names_prefix = "infection_"
  ) %>%
  mutate(
    infection_1 = case_when(infection_1 == vacc_dose1_date | infection_1 == vacc_dose2_date
                            | infection_1 == vacc_doseb_date ~ NA_Date_, TRUE ~ infection_1),
    infection_2 = case_when(infection_2 == vacc_dose1_date | infection_2 == vacc_dose2_date
                            | infection_2 == vacc_doseb_date ~ NA_Date_, TRUE ~ infection_2),
    infection_3 = case_when(infection_3 == vacc_dose1_date | infection_3 == vacc_dose2_date
                            | infection_3 == vacc_doseb_date ~ NA_Date_, TRUE ~ infection_3),
    infection_4 = case_when(infection_4 == vacc_dose1_date | infection_4 == vacc_dose2_date
                            | infection_4 == vacc_doseb_date ~ NA_Date_, TRUE ~ infection_4),
    # when the vacc date is prior to 28 days post inf, shift the eligibility date to date of vacc
    infection_1_end = case_when(
      between((interval(infection_1, vacc_dose1_date) / ddays()), 0, 28) 
      ~ infection_1 + interval(infection_1, vacc_dose1_date) / ddays(),
      between((interval(infection_1, vacc_dose2_date) / ddays()), 0, 28) 
      ~ infection_1 + interval(infection_1, vacc_dose2_date) / ddays(),
      between((interval(infection_1, vacc_doseb_date) / ddays()), 0, 28) 
      ~ infection_1 + interval(infection_1, vacc_doseb_date) / ddays(),
      TRUE ~ infection_1 + days(28)
    ),
    infection_2_end = case_when(
      between((interval(infection_2, vacc_dose1_date) / ddays()), 0, 28) 
      ~ infection_2 + interval(infection_2, vacc_dose1_date) / ddays(),
      between((interval(infection_2, vacc_dose2_date) / ddays()), 0, 28) 
      ~ infection_2 + interval(infection_2, vacc_dose2_date) / ddays(),
      between((interval(infection_2, vacc_doseb_date) / ddays()), 0, 28) 
      ~ infection_2 + interval(infection_2, vacc_doseb_date) / ddays(),
      TRUE ~ infection_2 + days(28)
    ),
    infection_3_end = case_when(
      between((interval(infection_3, vacc_dose1_date) / ddays()), 0, 28) 
      ~ infection_3 + interval(infection_3, vacc_dose1_date) / ddays(),
      between((interval(infection_3, vacc_dose2_date) / ddays()), 0, 28) 
      ~ infection_3 + interval(infection_3, vacc_dose2_date) / ddays(),
      between((interval(infection_3, vacc_doseb_date) / ddays()), 0, 28) 
      ~ infection_3 + interval(infection_3, vacc_doseb_date) / ddays(),
      TRUE ~ infection_3 + days(28)
    ),
    infection_4_end = case_when(
      between((interval(infection_4, vacc_dose1_date) / ddays()), 0, 28) 
      ~ infection_4 + interval(infection_4, vacc_dose1_date) / ddays(),
      between((interval(infection_4, vacc_dose2_date) / ddays()), 0, 28) 
      ~ infection_4 + interval(infection_4, vacc_dose2_date) / ddays(),
      between((interval(infection_4, vacc_doseb_date) / ddays()), 0, 28) 
      ~ infection_4 + interval(infection_4, vacc_doseb_date) / ddays(),
      TRUE ~ infection_4 + days(28) 
    ),
#    futime = case_when(
#      !is.na(move_out_date) & move_out_date < study_end_date ~ interval(eligibility_date, move_out_date) / ddays(),
#      TRUE ~ interval(eligibility_date, study_end_date) / ddays()
#    ),
    # if date of vacc = eligibility date, add on 0.5 to allow future analysis
    vacc_dose1_date = case_when(
      vacc_dose1_date == infection_1_end | vacc_dose1_date == infection_2_end |
        vacc_dose1_date == infection_3_end | vacc_dose1_date == infection_4_end |
        vacc_dose1_date == eligibility_date
      ~ vacc_dose1_date + 0.5, TRUE ~ vacc_dose1_date
    ),
    vacc_dose2_date = case_when(
      vacc_dose2_date == infection_1_end | vacc_dose2_date == infection_2_end |
        vacc_dose2_date == infection_3_end | vacc_dose2_date == infection_4_end
      ~ vacc_dose2_date + 0.5, TRUE ~ vacc_dose2_date
    ),
    vacc_doseb_date = case_when(
      vacc_doseb_date == infection_1_end | vacc_doseb_date == infection_2_end |
        vacc_doseb_date == infection_3_end | vacc_doseb_date == infection_4_end
      ~ vacc_doseb_date + 0.5, TRUE ~ vacc_doseb_date
    ), 
    # censor people who move out of nation
    study_end = case_when(
      !is.na(move_out_date) & move_out_date < study_end_date ~ move_out_date,
      TRUE ~ study_end_date
    )
  ) %>%
  select(
    alf_e,
    sex,
    age_cat,
    household_n,
    hh_vaccinated,
    dose_1 = vacc_dose1_date,
    dose_2 = vacc_dose2_date,
    dose_3 = vacc_doseb_date,
    infection_1,
    infection_1_end,
    infection_2,
    infection_2_end,
    infection_3,
    infection_3_end,
    infection_4,
    infection_4_end,
    eligibility_date,
    death_date,
    study_end
  ) %>%
  group_by(alf_e) %>%
  pivot_longer(
    cols = c(dose_1, dose_2, dose_3, infection_1, infection_1_end, infection_2, infection_2_end,
             infection_3, infection_3_end, infection_4, infection_4_end, death_date, study_end),
    names_to = "state_to",
    values_to = "stop_date"
  ) %>%
  # remove rows for vacc doses if they are missing 
  # (There probably is a neater way of doing this)
  filter(!(is.na(stop_date))) %>%
  # added in row to restrict to vaccines before the end study date
  filter(!(state_to != "study_end" & stop_date >= study_end_date)) %>%
  arrange(alf_e, stop_date)  %>%
  # create start dates
  #  lazy_dt() %>%
  group_by(alf_e) %>%
  mutate(
    state_to_ = state_to,
    state_to = str_replace(state_to, "infection_1_end", lag(state_to, 2, default = "unvacc")),
    state_to = str_replace(state_to, "infection_2_end", lag(state_to, 2, default = "unvacc")),
    state_to = str_replace(state_to, "infection_3_end", lag(state_to, 2, default = "unvacc")),
    state_to = str_replace(state_to, "infection_4_end", lag(state_to, 2, default = "unvacc")),
    state_to = str_replace(state_to, "infection_1", "infection"),
    state_to = str_replace(state_to, "infection_2", "infection"),
    state_to = str_replace(state_to, "infection_3", "infection"),
    state_to = str_replace(state_to, "infection_4", "infection"),
    state_to = str_replace(state_to, "death_date", "death")
  ) %>%
  filter(!is.na(state_to)) %>%
  mutate(
    state_from = lag(state_to, default = "unvacc"),
    start_date = lag(stop_date),
    start_date = case_when(
      !is.na(start_date) ~ start_date,
      is.na(start_date) ~ eligibility_date
    )
  ) %>%
  as_tibble() %>%
  # survival analysis wants follow-up days, not dates
  mutate(
    tstart = interval(eligibility_date, start_date) / ddays(),
    tstart = case_when(tstart < 0 ~ 0, TRUE ~ tstart),
    tstop  = interval(eligibility_date, stop_date) / ddays()
  ) %>%
  # move all tstop values for study_end by 0.5
  #
  # this is a trick to get past the issue of survival analysis
  # always wanting tstart < tstop, yet in reality it is fine if
  # someone were to get vaccinated on the last day of the study
  mutate(
    tstop = ifelse(state_to == "study_end", tstop + 0.5, tstop)
  ) %>%
  # survival analysis assumes first level is the censored category
  mutate(
    state_from = case_when(tstart == 0 & state_to == "unvacc" ~ "infection", TRUE ~ state_from),
    state_from = state_from %>% factor() %>% fct_relevel("unvacc"),
    state_to   = state_to   %>% factor() %>% fct_relevel("study_end")
  ) %>%
  filter(tstop > 0) %>%
  # get our ducks in a row
  select(
    alf_e,
    sex,
    age_cat,
    household_n,
    hh_vaccinated,
#    futime,
    start_date,
    stop_date,
    tstart,
    tstop,
    state_from,
    state_to
  ) %>%
  mutate(
    state_no = case_when(
      state_from == "unvacc" ~ 1,
      state_from == "infection" ~ 2,
      state_from == "dose_1" ~ 3,
      state_from == "dose_2" ~ 4,
      state_from == "dose_3" ~ 5,
      state_from == "death" ~ 6
    ),
    transition = case_when(
      state_from == "unvacc" & state_to == "infection" ~ 1,
      state_from == "unvacc" & state_to == "dose_1" ~ 2,
      state_from == "unvacc" & state_to == "death" ~ 3,
      state_from == "infection" & state_to == "unvacc" ~ 4,
      state_from == "infection" & state_to == "dose_1" ~ 5,
      state_from == "infection" & state_to == "dose_2" ~ 6,
      state_from == "infection" & state_to == "death" ~ 7,
      state_from == "dose_1" & state_to == "infection" ~ 8,
      state_from == "dose_1" & state_to == "dose_2" ~ 9,
      state_from == "dose_1" & state_to == "death" ~ 10,
      state_from == "dose_2" & state_to == "infection" ~ 11,
      state_from == "dose_2" & state_to == "dose_3" ~ 12,
      state_from == "dose_2" & state_to == "death" ~ 13,
      state_from == "dose_3" & state_to == "death" ~ 14
    )
  )

qsave(
  d_vacc_status,
  file = s_drive("d_vacc_status.qs")
)
