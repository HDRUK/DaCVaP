source("r_clear_and_load.r")

# load =========================================================================
cat("load\n")

d_cohort_clean <- qread(s_drive("d_cohort_clean.qs"))
d_cohort_hosp_raw <- qread(s_drive("d_cohort_hosp_raw.qs"))
d_cohort_early_vac <- qread("results/t_early_vac.qs")

# Count vacc dose patterns =====================================================
cat("Count vacc dose patterns\n")

t_cohort_vacc_pattern <-
  d_cohort_clean %>%
  count(
    vacc_dose1_name,
    vacc_dose2_name,
    vacc_doseb_name
  ) %>%
  mutate(
    vacc_pattern = str_glue(
        "{dose1}-{dose2}-{doseb}",
        dose1 = vacc_dose1_name,
        dose2 = vacc_dose2_name,
        doseb = vacc_doseb_name
      ) %>%
      str_replace("NA-NA-NA", "Unvacc") %>%
      str_replace_all("-?NA", "")
  ) %>%
  select(
    vacc_pattern,
    n
  ) %>%
  arrange(desc(n))

# Simple count first, second and booster doses =================================
cat("Simple count first, second and booster doses\n")

p_week_vacc_dose <-
  d_cohort_clean %>%
  mutate(
    vacc_dose1_week = floor_date(vacc_dose1_date, "week"),
    vacc_dose2_week = floor_date(vacc_dose2_date, "week"),
    vacc_doseb_week = floor_date(vacc_doseb_date, "week")
  ) %>%
  select(
    age_cat,
    vacc_dose1_week,
    vacc_dose2_week,
    vacc_doseb_week
  ) %>%
  pivot_longer(
    cols = matches("vacc_dose._week"),
    names_to = "vacc_dose",
    values_to = "week"
  ) %>%
  filter(not_na(week)) %>%
  mutate(
    vacc_dose = str_replace(vacc_dose, "_week", ""),
    age_cat = str_replace(age_cat, "_", "-"),
    vacc_dose = factor(
      vacc_dose, 
      c("vacc_dose1", "vacc_dose2", "vacc_doseb"), 
      c("First dose", "Second dose", "Booster")
      )
  ) %>%
  count(age_cat, vacc_dose, week) %>%
  mutate_if(is.numeric, less_than_ten) %>%
  ggplot(aes(x = week, y = n, colour = vacc_dose)) +
  facet_wrap(~age_cat, ncol = 1) +
  geom_line() +
    # formatting
  scale_x_date(
    name = "Weeks",
    date_breaks = "1 month",
    date_labels = "%b\n%Y"
  ) +
  scale_y_continuous(
    breaks = pretty_breaks(),
    labels = comma
  ) + 
  labs(colour = "Vaccination")


# Count weeks between doses ====================================================
cat("Count weeks between doses\n")

d_week_between_doses <-
  d_cohort_clean %>%
  mutate(
    vacc_interval_1 = 
      as.numeric(floor(difftime(vacc_dose2_date, vacc_dose1_date, units = "weeks"))),
    vacc_interval_2 = 
      as.numeric(floor(difftime(vacc_doseb_date, vacc_dose2_date, units = "weeks"))),
    vacc_dose1_week = floor_date(vacc_dose1_date, "week"),
    vacc_dose2_week = floor_date(vacc_dose2_date, "week"),
    vacc_doseb_week = floor_date(vacc_doseb_date, "week")
  ) %>%
  select(
    age_cat,
    vacc_dose1_week,
    vacc_dose2_week,
    vacc_doseb_week,
    vacc_interval_1,
    vacc_interval_2
  ) %>%
  filter(
    not_na(vacc_interval_1)
  ) %>%
  pivot_longer(
    cols = matches("vacc_interval_"), 
    values_to = "interval", 
    names_to = "vacc_dose") %>%
  mutate(
    age_cat = str_replace(age_cat, "_", "-"),
    vacc_dose = factor(
      vacc_dose, 
      c("vacc_interval_1", "vacc_interval_2"), 
      c("First interval", "Second interval"))
  )

p_week_between_doses <-
  d_week_between_doses %>%
  group_by(age_cat,vacc_dose) %>%
  count(vacc_dose, interval) %>%
  mutate(
    n = ifelse(between(n,1,9), 10, n)
  ) %>%
  ggplot(aes(x = interval, y = n, colour = age_cat)) + 
  facet_wrap(~ vacc_dose, ncol = 1) + 
  geom_line() + 
  scale_y_continuous(
    name = "n",
    breaks = pretty_breaks(),
    labels = comma,
    limits = c(0,25000)
  ) + 
  scale_x_continuous(
    name = "Weeks between doses",
    breaks = pretty_breaks()
  ) + 
  labs(colour = "Age")
  
  
  
p_week_between_doses 
  

# Count those with early 2nd/booster vaccines ==================================
d_early_vacc_int <- d_week_between_doses %>% 
  filter(interval < 12) %>%
  mutate(
    interval = 
      case_when(
        interval < 6 ~ "<6",
        between(interval, 6, 8) ~ "6-8",
        between(interval, 9, 11) ~ "9-11"
      )
  ) %>%
  group_by(age_cat, interval, vacc_dose) %>%
  count(interval) %>%
  pivot_wider(
    names_from = interval,
    values_from = n
  ) %>%
  relocate(
    '6-8', .after = '<6'
  )
d_early_vacc_int[is.na(d_early_vacc_int)] <-0
# there must be a tidier way to do this!
d_early_vacc_int$`<6`[between(d_early_vacc_int$`<6`, 1,9) ] <- 10
d_early_vacc_int$`6-8`[between(d_early_vacc_int$`6-8`, 1,9) ] <- 10
d_early_vacc_int$`9-11`[between(d_early_vacc_int$`9-11`, 1,9) ] <- 10


p_early_vacc_int <-
d_early_vacc_int %>%
  pivot_longer(!c(age_cat, vacc_dose),
               names_to = "Interval",
               values_to = "n"
  ) %>%
  ggplot(aes(x = factor(Interval, level = c("<6", "6-8", "9-11")), y = n, fill = vacc_dose)) + 
  facet_wrap(~age_cat) +
  geom_col(position = "dodge") +
  xlab("Interval (weeks)")  

# Count those with early vaccines ==============================================

d_early_vacc <- d_cohort_early_vac

# Count week infections ========================================================
cat("Count weekly infections\n")

d_week_infection <-
  d_cohort_clean %>%
  select(
    age_cat,
    infection1_test_date,
    infection2_test_date,
    infection3_test_date,
    infection4_test_date
  ) %>%
  pivot_longer(cols = matches("infection"), values_to = "infection_date") %>%
  filter(not_na(infection_date)) %>%
  mutate(infection_date = floor_date(infection_date, "week")) %>%
  count(age_cat, infection_date, name = "infection_n") %>%
  filter(infection_date >= floor_date(start_date_16_over, "week")) %>%
  mutate_if(is.numeric, less_than_ten)

p_week_infection <-
  d_week_infection %>%
  ggplot(aes(x = infection_date, y = infection_n)) +
  facet_wrap(~ age_cat, ncol = 1) +
  geom_col() +
  # formatting
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b\n%Y"
  ) +
  scale_y_continuous(
    breaks = pretty_breaks(),
    labels = comma
  )


# Count weeks between previous infection and first dose  =======================
cat("Count weeks between previous infection and first dose \n")

d_week_between_infection_and_dose <-
  d_cohort_clean %>%
  select(
    alf_e,
    age_cat,
    infection1_test_date,
    infection2_test_date,
    infection3_test_date,
    infection4_test_date,
    vacc_dose1_date
  ) %>%
  pivot_longer(
    cols = matches("infection._test_date"),
    names_to = "infection",
    values_to = "date_of_infection"
  ) %>%
  filter(
    !is.na(vacc_dose1_date),
    !is.na(date_of_infection)
  ) %>%
  mutate(
    infection = str_replace(infection, "_test_date", "")
  ) %>%
  group_by(alf_e) %>% 
  mutate(
    weeks_to_1st_dose = as.numeric(floor(difftime(date_of_infection, vacc_dose1_date, units = "weeks")))
  ) %>%
  ungroup() %>%
  mutate(
    week_of_infection = floor_date(date_of_infection, "week"),
    vacc_dose1_week = floor_date(vacc_dose1_date, "week")
  ) %>%
  mutate(
    age_cat = str_replace(age_cat, "_", "-")
  ) 


p_week_between_infection_and_dose <-
  d_week_between_infection_and_dose %>%
  select(age_cat, weeks_to_1st_dose) %>%
  # count(age_cat, vacc_dose1_week, infection, week_of_infection, weeks_to_1st_dose) %>%
  group_by(age_cat, weeks_to_1st_dose) %>%
  count(age_cat, weeks_to_1st_dose) %>%
  mutate(
    n = ifelse(between(n,1,9), 10, n)
  ) %>%
  ggplot(aes(x = weeks_to_1st_dose, y = n)) +
  facet_wrap(~ age_cat, ncol = 1) +
  geom_col() +
  # formatting
  scale_x_continuous(
    name = "Weeks",
    breaks = pretty_breaks(),
    label = comma
  ) + 
  scale_y_continuous(
    name = "n",
    breaks = pretty_breaks(),
    label = comma
  )


#Count number of hospitalisations in CYP =======================================
cat("Count weeks between previous infection and first dose \n")

level_order = c("no recorded hopsital stay","1","2","3","4","5","6","7","8","9","10",">10")

d_hospitalisations <-
  left_join(d_cohort_clean, d_cohort_hosp_raw, by = c("alf_e", "wob", "spell_length")) %>%
  mutate(
    spell_length = replace(spell_length, spell_length > 10, ">10"),
    "no recorded hospital stay" = "NA"
    ) %>%
  group_by(spell_length) %>%
  count(spell_length) %>%
  arrange(factor(spell_length, level_order))

p_hospitalisations <-
  d_hospitalisations %>% filter(!is.na(spell_length)) %>%
  ggplot(aes(x = factor(spell_length, level = c("no recorded hopsital stay","1","2","3","4","5","6","7","8","9","10",">10")), y = n)) + 
  geom_col() +
  xlab("Length of stay")


# Count number of deaths in CYP
cat("Count weeks between previous infection and first dose \n")

t_deaths <-
  d_cohort_clean %>%
  select(
    alf_e,
    age_cat,
    death_date) %>%
  filter(!is.na(death_date)) %>%
  group_by(age_cat) %>%
  count(age_cat)


# Counts of child vaccination status v household
cat("Cross referencing child vaccinations status with that of the household \n")

p_hh <-
  d_cohort_clean %>%
  select(
    alf_e,
    age_cat,
    hh_vaccinated,
    vacc_dose1_date,
    vacc_dose2_date,
    vacc_doseb_date
  ) %>%
  mutate(
    vac_dose1 = case_when(!is.na(vacc_dose1_date) ~ "1"),
    vac_dose2 = case_when(!is.na(vacc_dose2_date) ~ "1"),
    vac_doseb = case_when(!is.na(vacc_doseb_date) ~ "1"),
    unvacc = case_when(is.na(vacc_dose1_date) ~ "1")
  ) %>%
  group_by(
    age_cat,
    hh_vaccinated
  ) %>%
  summarise(
    vacc_dose1 = sum(!is.na(vacc_dose1_date)),
    vacc_dose2 = sum(!is.na(vacc_dose2_date)),
    vacc_doseb = sum(!is.na(vacc_doseb_date)),
    vacc_dose0 = sum(!is.na(unvacc))
  ) %>%
  pivot_longer(
    cols = starts_with("vacc_dose"),
    names_to = "vaccine",
    names_prefix = "vacc_dose",
    values_to = "n"
  ) %>%
  mutate(
    vaccine = vaccine %>% factor() %>%
      fct_recode(
        "Unvaccinated" = "0",
        "Dose 1" = "1",
        "Dose 2" = "2",
        "Booster dose" = "b"
      )
  )%>%
  ggplot(aes(x = n, fill = vaccine, y = hh_vaccinated)) + 
  geom_bar(position = "fill", stat = "identity") + 
  facet_wrap(~age_cat, ncol = 1) + 
  ylab("") + 
  xlab("% of cohort")


 # save =========================================================================
cat("save\n")

qsave(
  t_cohort_vacc_pattern,
  file = "results/t_cohort_vacc_pattern.qs"
)

qsave(
  p_week_vacc_dose,
  file = "results/p_week_vacc_dose.qs"
)

qsave(
  p_week_between_doses,
  file = "results/p_week_between_doses.qs"
)

qsave(
  d_early_vacc_int,
  file = "results/t_early_vacc_int.qs"
)

qsave(
  p_early_vacc_int,
  file = "results/p_early_vacc_int.qs"
)

qsave(
  p_week_infection,
  file = "results/p_week_infection.qs"
)

qsave(
  p_week_between_infection_and_dose,
  file = "results/p_week_between_infection_and_dose.qs"
)

qsave(
  p_hospitalisations,
  file = "results/p_hospitalisations.qs"
)

qsave(
  t_deaths,
  file = "results/t_deaths.qs"
)

qsave(
  p_hh,
  file = "results/p_hh_vacc"
)


print(p_week_vacc_dose)
print(p_week_between_doses)
print(p_week_infection)
print(p_early_vacc_int)
print(p_week_between_infection_and_dose)
print(p_hospitalisations)
print(p_hh)
