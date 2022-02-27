# devtools::install_github('Mikata-Project/ggthemr')

library(dplyr)
library(readxl)
library(ggplot2)
library(stringr)
library(patchwork)
library(scales)
library(ggh4x)
library(forcats)
library(janitor)
library(readr)
library(ggthemr)

d_coef_vacc <-
  read_csv("Table2-vacc.csv") %>%
  clean_names() %>% 
  select(
    event,
    strata = vc,
    term,
    estimate,
    conf_low,
    conf_high
  )

d_coef_c19 <-
  read_csv("Table2-infec.csv") %>%
  clean_names() %>% 
  mutate(
    strata = "C19"
  ) %>% 
  select(
    event,
    strata,
    term,
    estimate,
    conf_low,
    conf_high
  )

d_coef <- bind_rows(d_coef_vacc, d_coef_c19)

lkp_term <- c(
  # infection
  "Pre-infection" = "1-PRE_TEST_CONTROL",
  "0-28"          = "2-TEST_RISK_PERIOD",
  "29+"           = "3-POST_TEST_CONTROL",
  # first dose
  "Baseline"      = "1-BASELINE_CONTROL",
  "Clearance"     = "2-CLEARANCE_FIRST",
  "0-7"           = "3a-RISK_FIRST 1-7D",
  "8-14"          = "3b-RISK_FIRST 8-14D",
  "15-21"         = "3c-RISK_FIRST 15-21D",
  "22-28"         = "3d-RISK_FIRST 22-28D",
  # second dose
  "Clearance"     = "5-CLEARANCE_SECOND",
  "0-7"           = "6a-RISK_SECOND 1-7D",
  "8-14"          = "6b-RISK_SECOND 8-14D",
  "15-21"         = "6c-RISK_SECOND 15-21D",
  "22-28"         = "6d-RISK_SECOND 22-28D",
  # third dose
  "Clearance"     = "8-CLEARANCE_THIRD",
  "0-7"           = "9a-RISK_third 1-7D",
  "8-14"          = "9b-RISK_third 8-14D",
  "15-21"         = "9c-RISK_third 15-21D",
  "22-28"         = "9d-RISK_third 22-28D",
  # booster dose
  "Clearance"     = "11-CLEARANCE_BOOSTER",
  "0-7"           = "12a-RISK_BOOSTER 1-7D",
  "8-14"          = "12b-RISK_BOOSTER 8-14D",
  "15-21"         = "12c-RISK_BOOSTER 15-21D",
  "22-28"         = "12d-RISK_BOOSTER 22-28D"
)
    
lkp_event <- c(
  "VTE"                    = "Venous thromboembolic events (excluding CSVT)",
  "Haemorrhage"            = "Hemorrhagic events",
  "Arterial thrombosis"    = "Atrial Thrombosis",
  "Arterial thrombosis"    = "Arterial Thrombosis",
  "ITP"                    = "Idiopathic thrombocytopenic purpura",
  "Thrombocytopenia"       = "Thrombocytopenia (excluding ITP)",
  "Ischeamic stroke"       = "Ischeamic Stroke",
  "Myocardial infarction"  = "Myocardial Infarction",
  "Anaphylaxis"            = "Anaph",
  "Anaphylaxis"            = "Anaphylactic shock",
  "Hip fracture"           = "Hip fracture",
  "Hip fracture"           = "Hipfrac"
)

t_coef <-
  d_coef %>% 
  filter(
    term %in% c(
      # infection
      "2-TEST_RISK_PERIOD",
      # first dose
      "3a-RISK_FIRST 1-7D",
      "3b-RISK_FIRST 8-14D",
      "3c-RISK_FIRST 15-21D",
      "3d-RISK_FIRST 22-28D",
      # second dose
      "6a-RISK_SECOND 1-7D",
      "6b-RISK_SECOND 8-14D",
      "6c-RISK_SECOND 15-21D",
      "6d-RISK_SECOND 22-28D",
      # booster dose
      "12a-RISK_BOOSTER 1-7D",
      "12b-RISK_BOOSTER 8-14D",
      "12c-RISK_BOOSTER 15-21D",
      "12d-RISK_BOOSTER 22-28D"
    )
  ) %>% 
  mutate(
    event = factor(event, lkp_event, names(lkp_event)),
    dose = case_when(
      str_detect(str_to_lower(term), "first")    ~ "First",
      str_detect(str_to_lower(term), "second")   ~ "Second",
      str_detect(str_to_lower(term), "third")    ~ "Third",
      str_detect(str_to_lower(term), "booster")  ~ "Booster",
      str_detect(str_to_lower(term), "test")     ~ "Test"
    ),
    term = factor(term, lkp_term, names(lkp_term)),
    dose = factor(dose),
    #edit here for moderna
    strata = factor(strata, c("AZ", "PB", "BOOSTER", "C19"), c("ChAdOx1", "BNT162b2", "mRNA-1273", "C19 infection"))
  ) 

# coef for vacc and infection 

lkp_event2 <- c(
  "Venous\nthromboembolism" = "VTE",
  "Haemorrhage"             = "Haemorrhage",
  "Arterial\nthrombosis"    = "Arterial thrombosis",
  "Thrombocyto-\npenia"     = "Thrombocytopenia",
  "Ischeamic\nstroke"       = "Ischeamic stroke",
  "Myocardial\ninfarction"  = "Myocardial infarction",
  "Hip fracture"            = "Hip fracture",
  "Anaphylaxis"             = "Anaphylaxis"
)

ggthemr(
  palette = 'fresh',
  text_size = 9
)

p_coef <-
  t_coef %>% 
  mutate(
    strata = str_c(strata, " ", dose),
    strata = strata %>% factor() %>% fct_recode(
      "(a) ChAdOx1\nfirst dose"     = "ChAdOx1 First",
      "(b) ChAdOx1\nsecond dose"    = "ChAdOx1 Second",
      "(c) BNT162b2\nfirst dose"    = "BNT162b2 First",
      "(d) BNT162b2\nsecond dose"   = "BNT162b2 Second",
      "(e) BNT162b2\nbooster dose"  = "BNT162b2 Booster",
      "(f) mRNA-1273\nbooster dose" = "mRNA-1273 Booster",
      "(g) COVID-19\ninfection"     = "C19 infection Test"
    ),
    strata = factor(as.character(strata)),
    event = factor(event, lkp_event2, names(lkp_event2))
  ) %>% 
  filter(
    !is.na(event)
  ) %>% 
  ggplot(aes(
    x = term, y = estimate, ymin = conf_low, ymax = conf_high
  )) +
  facet_grid(
    event ~ strata,
    switch = "y",
    scales = "free_x"
  ) +
  geom_hline(yintercept = 1, linetype = 2, colour = "#999999") +
  geom_errorbar(colour = "#999999", width = 0.25) +
  geom_point(colour = "#3ba690") +
  xlab("Days since start of exposure") +
  scale_y_continuous(
    name = "Incidence risk ratio",
    breaks = c(0.5, 1, 2, 4, 8),
    trans='log2'
  ) +
  coord_cartesian(ylim = c(0.25, 8)) +
  theme(
    axis.text.x        = element_text(hjust = 1, vjust = 0.5, angle = 90),
    strip.placement    = "outside",
    strip.background   = element_blank(),
    strip.text.x       = element_text(vjust = 0),
    strip.text.y       = element_text(vjust = 0),
    legend.position    = "none",
    panel.grid.major.x = element_blank()
  )

p_coef

ggsave(
  p_coef,
  file = "fig2-sccs-coef-all.png",
  width = 6,
  height = 7,
  dpi = 600
)
