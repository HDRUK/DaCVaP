rm(list=ls())
gc()
source("01_load.r")

# load clean data ==============================================================

d_analysis <- qread(project_dir("data/d2_analysis_clean.qs"))

# count any events =============================================================

d_analysis <- d_analysis %>%
  mutate(
    group_event_simple_cat = group_event_cat %>% fct_collapse(
      "Thrombocytopenia (including ITP)" = c("Thrombocytopenia (excluding ITP)",
        "Idiopathic thrombocytopenic purpura"))
        )

t_count_any_time <-
  d_analysis %>%
  count(vacc_type_time_cat, has_event_cat) %>%
#  filter(!str_detect(vacc_type_time_cat, "Dose 2")) %>%
  pivot_wider(names_from = has_event_cat, values_from = n, values_fill = 0) %>%
  mutate(n_individuals = event_no + event_yes) %>%
  select(vacc_type_time_cat, n_individuals, n_event = event_yes) %>%
  mutate(p_event = round(n_event / n_individuals * 100, 1)) %>%
  mutate(
    group_event_cat = "Any event",
    .before = "vacc_type_time_cat"
  ) %>%
  rename(
    event_type = group_event_cat,
    vacc_type_time = vacc_type_time_cat
  )

t_count_any_time28 <-
  d_analysis %>%
  count(vacc_type_time28_cat, has_event_cat) %>%
  pivot_wider(names_from = has_event_cat, values_from = n, values_fill = 0) %>%
  mutate(n_individuals = event_no + event_yes) %>%
  select(vacc_type_time28_cat, n_individuals, n_event = event_yes) %>%
  mutate(p_event = round(n_event / n_individuals * 100, 1)) %>%
  mutate(
    group_event_cat = "Any event",
    .before = "vacc_type_time28_cat"
  ) %>%
  filter(str_detect(vacc_type_time28_cat, "00-28")) %>%
  rename(
    event_type = group_event_cat,
    vacc_type_time = vacc_type_time28_cat
  )

t_count_any_post <-
  d_analysis %>%
  count(vacc_type_post_cat, has_event_cat) %>%
  pivot_wider(names_from = has_event_cat, values_from = n, values_fill = 0) %>%
  mutate(n_individuals = event_no + event_yes) %>%
  select(vacc_type_post_cat, n_individuals, n_event = event_yes) %>%
  mutate(p_event = round(n_event / n_individuals * 100, 1)) %>%
  mutate(
    group_event_cat = "Any event",
    .before = "vacc_type_post_cat"
  ) %>%
  filter(str_detect(vacc_type_post_cat, "00+")) %>%
  rename(
    event_type = group_event_cat,
    vacc_type_time = vacc_type_post_cat
  )

t_count_any <-
  bind_rows(
    t_count_any_time,
    t_count_any_time28,
    t_count_any_post
  )

write_csv(
  t_count_any,
  file = "results/t_desc_any.csv"
)

# count specific events ========================================================

t_count_specific_time <-
  d_analysis %>%
  count(group_event_simple_cat, vacc_type_time_cat, has_event_cat) %>%
#  filter(!str_detect(vacc_type_time_cat, "Dose 2")) %>%
  pivot_wider(names_from = has_event_cat, values_from = n, values_fill = 0) %>%
  mutate(n_individuals = event_no + event_yes) %>%
  select(group_event_simple_cat, vacc_type_time_cat, n_individuals, n_event = event_yes) %>%
  mutate(p_event = round(n_event / n_individuals * 100, 1)) %>%
  rename(
    event_type = group_event_simple_cat,
    vacc_type_time = vacc_type_time_cat
  )

t_count_specific_time28 <-
  d_analysis %>%
  count(group_event_simple_cat, vacc_type_time28_cat, has_event_cat) %>%
  pivot_wider(names_from = has_event_cat, values_from = n, values_fill = 0) %>%
  mutate(n_individuals = event_no + event_yes) %>%
  select(group_event_simple_cat, vacc_type_time28_cat, n_individuals, n_event = event_yes) %>%
  mutate(p_event = round(n_event / n_individuals * 100, 1)) %>%
  filter(str_detect(vacc_type_time28_cat, "00-28")) %>%
  rename(
    event_type = group_event_simple_cat,
    vacc_type_time = vacc_type_time28_cat
  )

t_count_specific_post <-
  d_analysis %>%
  count(group_event_simple_cat, vacc_type_post_cat, has_event_cat) %>%
  pivot_wider(names_from = has_event_cat, values_from = n, values_fill = 0) %>%
  mutate(n_individuals = event_no + event_yes) %>%
  select(group_event_simple_cat, vacc_type_post_cat, n_individuals, n_event = event_yes) %>%
  mutate(p_event = round(n_event / n_individuals * 100, 1)) %>%
  filter(str_detect(vacc_type_post_cat, "00+")) %>%
  rename(
    event_type = group_event_simple_cat,
    vacc_type_time = vacc_type_post_cat
  )

t_count_specific <-
  bind_rows(
    t_count_specific_time,
    t_count_specific_time28,
    t_count_specific_post
  )

write_csv(
  t_count_specific,
  file = "results/t_desc_event_type.csv"
)
