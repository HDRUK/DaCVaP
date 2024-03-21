setwd("~/DaCVaP CYP")
# Info =========================================================================

# Q: What does vaccine uptake look like in children and young people?

# Convert data to usable format ================================================
# step 1
source("r_clear_and_load.R")
# Load data ====================================================================

d_vacc_status <- readRDS("~/DaCVaP CYP/d_vacc_status.rds")

# Generate key values ==========================================================
cat("Generating key values\n")
d_key_trans <- d_vacc_status %>%
  filter(transition %in% c(2,9,12) | is.na(transition)) %>%
  group_by(alf_e) %>%
  mutate(transition = replace_na(transition, 0),
         status = case_when(transition == 0 ~ "No vaccine", transition == 2 ~ "1st dose",
                            transition == 9 ~ "2nd dose", transition == 12 ~ "3rd dose")
  ) %>%
  filter(transition == max(transition))

d_sum <- d_key_trans %>%
  group_by(age_cat) %>% count(status) %>% rename("variable" = age_cat) %>% ungroup %>%
  add_row(d_key_trans %>%
            group_by(household_n) %>% count(status) %>% rename("variable" = household_n) %>% ungroup) %>%
  add_row(d_key_trans %>%
            group_by(hh_vaccinated) %>% count(status) %>% rename("variable" = hh_vaccinated) %>% ungroup) %>%
  add_row(d_key_trans %>%
            group_by(sex) %>% count(status) %>% rename("variable" = sex) %>% ungroup) %>%
  pivot_wider(names_from = status, values_from = n) %>%
  select(variable, 'No vaccine', '1st dose', '2nd dose', '3rd dose')

write.csv(d_sum, "request_out/vacc_summary_cohort_eng.csv")
