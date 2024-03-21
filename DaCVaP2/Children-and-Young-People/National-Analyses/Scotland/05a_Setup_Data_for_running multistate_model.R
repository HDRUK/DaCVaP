# useful dates =================================================================

study_end_date      <- ymd("2022-05-31")
start_date_5_to_11  <- ymd("2022-02-15")
start_date_12_to_15 <- ymd("2021-09-14")
start_date_16_over  <- ymd("2021-08-04")

z_df = df

z_df = z_df %>% mutate(alf_e = EAVE_LINKNO)
# Rename the columns to fit Sarah's code
z_df = z_df %>% rename(sex = Sex, age_cat = age_range_group, 
                       household_n = num_people_in_household, hh_vaccinated = household_vacc_status,
                       vacc_dose1_date = date_vacc_1, vacc_dose2_date = date_vacc_2,
                       vacc_doseb_date = date_vacc_3, death_date = NRS.Date.Death.x)

# Remove anyone who supposedly lives alone
z_df = z_df %>% filter(!is.na(household_n) & household_n != 1) %>%
  mutate(household_n = droplevels(household_n))

# Remove people if we don't kjnow about their household vaccination 
z_df = z_df %>% filter(!is.na(hh_vaccinated))

# We don't know when someone moves out of Scotland
z_df = z_df %>% mutate(move_out_date = if_else(is.na(death_date), a_end, death_date))

# Massage the age_cat into the correct structure
z_df = z_df %>% mutate(age_cat = case_when(age_cat == "5 - 11" ~ "05_11",
                                 age_cat == "12 - 15" ~ "12_15",
                                 age_cat == "16 - 17" ~ "16_17"))

# Put the sex variable into the right format
z_df = z_df %>% mutate(sex = case_when(sex == "M" ~ "Male",
                                       sex == "F" ~ "Female"))


# Remove anyone vaccinated before the start of the program
z_df = z_df %>% mutate(eligibility_date = 
  case_when(age_cat == "16_17" ~ start_date_16_over,
            age_cat == "12_15" ~ start_date_12_to_15,
            age_cat == "05_11" ~ start_date_5_to_11)) %>%
  filter(is.na(vacc_dose1_date) | vacc_dose1_date > eligibility_date)

# Figure out the infection dates

# The first one is easy, just check if we have a date of a positive test
# less than 28 days before the start of their eligibility date
z_df = z_df %>% mutate(infection1_test_date = 
                         if_else(date_ecoss_specimen > (eligibility_date - days(14)), date_ecoss_specimen, NA_Date_))

# Next set up the Positive Tests dataframe so we can look into it
# Discard any tests that belong to the same infection - 
# this is defined as 90 days between positive tests

z_pos = Positive_Tests %>% left_join(select(z_df, EAVE_LINKNO, eligibility_date), by="EAVE_LINKNO") %>% 
  filter(!is.na(eligibility_date))

z_pos = z_pos %>% filter(EAVE_LINKNO %in% z_df$EAVE_LINKNO) %>%
  filter(date_ecoss_specimen > (eligibility_date - days(14))) %>%
  arrange(EAVE_LINKNO, date_ecoss_specimen) %>%  
  mutate(pos_days_diff = as.numeric(date_ecoss_specimen - lag(date_ecoss_specimen))) %>% 
  mutate(pos_days_diff = if_else(EAVE_LINKNO==lag(EAVE_LINKNO), pos_days_diff, NA_real_)) 

z_pos = z_pos %>%
  filter(pos_days_diff > 90 | is.na(pos_days_diff)) %>%
  select(-pos_days_diff)

# See who was infected multiple times
z_multiple_infections = z_pos %>% group_by(EAVE_LINKNO) %>% summarise(n = n()) %>% 
  filter(n > 1)

# Just check if we have any triple reinfections as currently we don't
# handle this
assertthat::are_equal(0, nrow(z_multiple_infections %>% filter(n > 2)))

z_second_infections = z_pos %>% filter(EAVE_LINKNO %in% z_multiple_infections$EAVE_LINKNO) %>%
  arrange(EAVE_LINKNO, desc(date_ecoss_specimen)) %>% filter(!duplicated(EAVE_LINKNO)) %>%
  rename(infection2_test_date = date_ecoss_specimen)

z_df = z_df %>% left_join(z_second_infections, by="EAVE_LINKNO")

# Set the other infection dates to NA as we don't have any
z_df = z_df %>% mutate(infection3_test_date = NA_Date_, infection4_test_date = NA_Date_) %>%
  select(alf_e, EAVE_LINKNO, sex, age_cat, household_n, hh_vaccinated, vacc_dose1_date, vacc_dose2_date,
         vacc_doseb_date, infection1_test_date, infection2_test_date, infection3_test_date, infection4_test_date,
         move_out_date, death_date)

d_analysis = z_df
#d_analysis = d_analysis %>% group_by(age_cat) %>% sample_n(5000)
#d_analysis = d_analysis %>% mutate(vacc_doseb_date = NA_Date_)

#idx = which(d_analysis$age_cat == "05_11" & !is.na(d_analysis$vacc_dose2_date))

#idx_s = sample(idx, size = 50)
#rand_days = sample.int(20, 50, replace=TRUE)

#d_analysis[idx_s,]$vacc_doseb_date = as.Date("2022-03-10") + days(rand_days)



