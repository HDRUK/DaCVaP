# Load data ====================================================================

d_vacc_status <- qread(s_drive("d_vacc_status.qs"))

# Generate key values ==========================================================
cat("Generating key values\n")
total_cyp <- length(unique(d_vacc_status$alf_e))
v_tot <- d_vacc_status %>% filter(transition %in% c(2,9,12)) %>% count(transition)
d_tot <- d_vacc_status %>% filter(state_to == "death") %>% count(state_to)
i_tot <- d_vacc_status %>% filter(state_to == "infection") %>% select(alf_e, state_to) %>% distinct() %>% count(state_to)
d_sum <- d_vacc_status%>% filter(transition %in% c(2,9,12) | is.na(transition)) %>% 
  group_by(alf_e) %>% 
  mutate(transition = replace_na(transition, 0),
         status = case_when(transition == 0 ~ "No vaccine", transition == 2 ~ "1st dose", 
                            transition == 9 ~ "2nd dose", transition == 12 ~ "3rd dose")
         ) %>% 
  filter(transition == max(transition)) %>%
  group_by(age_cat) %>% count(status)
p_sum <- d_sum %>%
  ggplot(aes(fill = age_cat, y = n, x = status)) + 
  geom_bar(position = "dodge", stat = "identity")
t_sex <- d_vacc_status %>% distinct(alf_e, sex) %>% group_by(sex) %>% summarise(n = n()) %>% rename(type = sex)
t_age <- d_vacc_status %>% distinct(alf_e, age_cat) %>%group_by(age_cat) %>% summarise(n = n()) %>% rename(type = age_cat)
t_hhn <- d_vacc_status %>% distinct(alf_e, household_n) %>%group_by(household_n) %>% summarise(n = n()) %>% rename(type = household_n)
t_hhv <- d_vacc_status %>% distinct(alf_e, hh_vaccinated) %>%group_by(hh_vaccinated) %>% summarise(n = n()) %>% rename(type = hh_vaccinated)
t_sum <- rbind(t_sex, t_age, t_hhn, t_hhv)

# ==============================================================================
# convert to long format
# ==============================================================================
# All doses
# ------------------------------------------------------------------------------
cat("Convert transition data to long format\n")

ms_vacc_all <-
  d_vacc_status %>%
  mutate(
    id = as.numeric(factor(alf_e)),
    possible_state_to_1 = case_when(state_no == 1 ~ 2, state_no == 2 ~ 1, state_no == 3 ~ 2, 
                                    state_no == 4 ~ 2, state_no == 5 ~ 6),
    possible_state_to_2 = case_when(state_no == 1 ~ 3, state_no == 2 ~ 3, state_no == 3 ~ 4, 
                                    state_no == 4 ~ 5),
    possible_state_to_3 = case_when(state_no == 1 ~ 6, state_no == 2 ~ 4, state_no == 3 ~ 6, 
                                    state_no == 4 ~ 6
    ),
    possible_state_to_4 = case_when(state_no == 2 ~ 6),
    state_to = case_when(state_to == "unvacc" ~ 1, state_to == "infection" ~ 2, 
                         state_to == "dose_1" ~ 3, state_to == "dose_2" ~ 4, 
                         state_to == "dose_3" ~ 5, state_to == "death" ~ 6)
  ) %>%
  pivot_longer(
    cols = c(possible_state_to_1, possible_state_to_2, possible_state_to_3, possible_state_to_4),
    names_pattern = "(\\d+)",
    names_to = "x",
    values_to = "state_to_val",
    values_drop_na = TRUE
  ) %>%
  mutate(
    status = as.numeric(case_when(state_to == state_to_val ~ 1, TRUE ~ 0)),
    trans = case_when(state_no == 1 & state_to_val == 2 ~ 1,
                      state_no == 1 & state_to_val == 3 ~ 2,
                      state_no == 1 & state_to_val == 6 ~ 3,
                      state_no == 2 & state_to_val == 1 ~ 4,
                      state_no == 2 & state_to_val == 3 ~ 5,
                      state_no == 2 & state_to_val == 4 ~ 6,
                      state_no == 2 & state_to_val == 6 ~ 7,
                      state_no == 3 & state_to_val == 2 ~ 8,
                      state_no == 3 & state_to_val == 4 ~ 9,
                      state_no == 3 & state_to_val == 6 ~ 10,
                      state_no == 4 & state_to_val == 2 ~ 11,
                      state_no == 4 & state_to_val == 5 ~ 12,
                      state_no == 4 & state_to_val == 6 ~ 13,
                      state_no == 5 & state_to_val == 6 ~ 14
    ),
    hh_vaccinated = case_when(hh_vaccinated == "Fully vaccinated" ~ "fv", 
                              hh_vaccinated == "Partially vaccinated" ~ "pv",
                              hh_vaccinated == "Unvaccinated" ~ "uv")
  ) %>%
  select(
    id, from = state_no, to = state_to_val, trans,
    tstart, tstop, status, age_cat, household_n, hh_vaccinated, sex
  )

# define reference groups
ms_vacc_all$age_cat <- factor(ms_vacc_all$age_cat, levels = c("16_17", "12_15", "05_11"))
ms_vacc_all$hh_vaccinated <- factor(ms_vacc_all$hh_vaccinated, levels = c("pv", "uv", "fv"))
ms_vacc_all$household_n <- factor(ms_vacc_all$household_n, levels = c("3", "2", "4", "5+"))
ms_vacc_all$sex <- factor(ms_vacc_all$sex, levels = c("Female", "Male"))

key_values <- ms_vacc_all %>% filter(tstart == "0") %>% select(id, from) %>% 
  mutate(
    from = as.character(from),
    from = str_replace(from, "1", "Starting state = Uninfected"), 
    from = str_replace(from, "2", "Starting state = Infected")) %>%
  distinct() %>%
  count("Variable" = from) %>%
  add_row("Variable" = "Total cyp", n = total_cyp) %>%
  add_row("Variable" = "1st vaccine", n = v_tot$n[1]) %>%
  add_row("Variable" = "2nd vaccine", n = v_tot$n[2]) %>%
  add_row("Variable" = "3rd vaccine", n = v_tot$n[3]) %>%
  add_row("Variable" = "Death", n = d_tot$n[1]) %>%
  add_row("Variable" = "Infected", n = i_tot$n[1])

qsave(
  ms_vacc_all,
  file = s_drive("d_ms_vacc_all.qs")
)

qsave(
  key_values,
  file = ("results/key_values.qs")
)

qsave(
  d_sum,
  file = ("results/d_sum.qs")
)

qsave(
  p_sum,
  file = ("results/p_sum.qs")
)

qsave(
  t_sum,
  file = ("results/t_sum.qs")
)


