# Load data ====================================================================

ms_vacc_all <- readRDS("~/DaCVaP CYP/d_ms_vacc_all.rds")

# ------------------------------------------------------------------------------
# correct format and add transition matrix
# ------------------------------------------------------------------------------ 
cat("Create transition matrix\n")

tmat <- transMat(x = list(c(2,3,6),c(1,3,4,6), c(2,4,6), c(2,5,6), c(6), c()),
                 names = c("unvacc","infection","dose_1", "dose_2", "dose_3", "death"
                 ))
tmat

class(ms_vacc_all) <- c("msdata", "data.frame")
attr(ms_vacc_all, "trans") <- tmat

d_events <- events(ms_vacc_all)
t_events <- data.frame(d_events$Frequencies)

# ==============================================================================
# Run multi-state model with 16-17 as reference
# ==============================================================================
# Expand covariates
# ------------------------------------------------------------------------------
cat("Expanding covariates\n")

ms_vacc_a <- expand.covs(ms_vacc_all, 
                         covs = c("age_cat", "household_n", 
                                  "hh_vaccinated", "sex"), append = TRUE)

# ------------------------------------------------------------------------------
# run the model
# ------------------------------------------------------------------------------
cat("Running the multistate model...\n")


c1 <- coxph(Surv(tstart, tstop, status) ~
              age_cat12_15.1 + age_cat12_15.2 + age_cat12_15.3 + age_cat12_15.4 + age_cat12_15.5 +
              age_cat12_15.6 + age_cat12_15.7 + age_cat12_15.8 + age_cat12_15.9 + age_cat12_15.10 +
              age_cat12_15.11 + age_cat12_15.12 + age_cat12_15.13 + + age_cat12_15.14 +
              age_cat05_11.1 + age_cat05_11.2 + age_cat05_11.3 + age_cat05_11.4 + age_cat05_11.5 +
              age_cat05_11.6 + age_cat05_11.7 + age_cat05_11.8 + age_cat05_11.9 + age_cat05_11.10 +
              age_cat05_11.11 + age_cat05_11.12 + age_cat05_11.13 + age_cat05_11.14 +
              household_n2.1 + household_n2.2 + household_n2.3 + household_n2.4 +
              household_n2.5 + household_n2.6 + household_n2.7 + household_n2.8 + household_n2.9 +
              household_n2.10 + household_n2.11 + household_n2.12 + household_n2.13 + household_n2.14 +
              household_n4.1 + household_n4.2 + household_n4.3 + household_n4.4 + household_n4.5 +
              household_n4.6 + household_n4.7 + household_n4.8 + household_n4.9 + household_n4.10 +
              household_n4.11 + household_n4.12 + household_n4.13 + household_n4.14 +
              household_n5..1 + household_n5..2 + household_n5..3 + household_n5..4 + household_n5..5 +
              household_n5..6 + household_n5..7 + household_n5..8 + household_n5..9 + household_n5..10 +
              household_n5..11 + household_n5..12 + household_n5..13 + household_n5..14 +
              hh_vaccinateduv.1 + hh_vaccinateduv.2 + hh_vaccinateduv.3 + hh_vaccinateduv.4 + hh_vaccinateduv.5 +
              hh_vaccinateduv.6 + hh_vaccinateduv.7 + hh_vaccinateduv.8 + hh_vaccinateduv.9 + hh_vaccinateduv.10 +
              hh_vaccinateduv.11 + hh_vaccinateduv.12 + hh_vaccinateduv.13 + hh_vaccinateduv.14 +
              hh_vaccinatedfv.1 + hh_vaccinatedfv.2 + hh_vaccinatedfv.3 + hh_vaccinatedfv.4 + hh_vaccinatedfv.5 +
              hh_vaccinatedfv.6 + hh_vaccinatedfv.7 + hh_vaccinatedfv.8 + hh_vaccinatedfv.9 + hh_vaccinatedfv.10 +
              hh_vaccinatedfv.11 + hh_vaccinatedfv.12 + hh_vaccinatedfv.13 + hh_vaccinatedfv.14 +
              sexM.1 + sexM.2 + sexM.3 + sexM.4 + sexM.5 + sexM.6 + sexM.7 + sexM.8 + sexM.9 + sexM.10 +
              sexM.11 + sexM.12 + sexM.13 + sexM.14 +
              strata(trans), data = ms_vacc_a, method = "breslow")

# c1 <- coxph(Surv(tstart, tstop, status) ~ 
#               age_cat12_15.1 + age_cat12_15.2 + age_cat12_15.3 + age_cat12_15.4 + age_cat12_15.5 + 
#               age_cat12_15.6 + age_cat12_15.7 + age_cat12_15.8 + age_cat12_15.9 + age_cat12_15.10 + 
#               age_cat12_15.11 + age_cat12_15.12 + age_cat12_15.13 + + age_cat12_15.14 + 
#               age_cat05_11.1 + age_cat05_11.2 + age_cat05_11.3 + age_cat05_11.4 + age_cat05_11.5 + 
#               age_cat05_11.6 + age_cat05_11.7 + age_cat05_11.8 + age_cat05_11.9 + age_cat05_11.10 + 
#               age_cat05_11.11 + 
#               household_n2.1 + household_n2.2 + household_n2.3 + household_n2.4 +
#               household_n2.5 + household_n2.6 + household_n2.7 + household_n2.8 + household_n2.9 +
#               household_n2.10 + household_n2.11 + household_n2.12 + household_n2.13 + household_n2.14 +
#               household_n4.1 + household_n4.2 + household_n4.3 + household_n4.4 + household_n4.5 + 
#               household_n4.6 + household_n4.7 + household_n4.8 + household_n4.9 + household_n4.10 + 
#               household_n4.11 + household_n4.12 + household_n4.13 + household_n4.14 + 
#               household_n5..1 + household_n5..2 + household_n5..3 + household_n5..4 + household_n5..5 + 
#               household_n5..6 + household_n5..7 + household_n5..8 + household_n5..9 + household_n5..10 + 
#               household_n5..11 + household_n5..12 + household_n5..13 + household_n5..14 +
#               hh_vaccinateduv.1 + hh_vaccinateduv.2 + hh_vaccinateduv.3 + hh_vaccinateduv.4 + hh_vaccinateduv.5 +
#               hh_vaccinateduv.6 + hh_vaccinateduv.7 + hh_vaccinateduv.8 + hh_vaccinateduv.9 + hh_vaccinateduv.10 +
#               hh_vaccinateduv.11 + hh_vaccinateduv.12 + hh_vaccinateduv.13 + hh_vaccinateduv.14 + 
#               hh_vaccinatedfv.1 + hh_vaccinatedfv.2 + hh_vaccinatedfv.3 + hh_vaccinatedfv.4 + hh_vaccinatedfv.5 + 
#               hh_vaccinatedfv.6 + hh_vaccinatedfv.7 + hh_vaccinatedfv.8 + hh_vaccinatedfv.9 + hh_vaccinatedfv.10 + 
#               hh_vaccinatedfv.11 + hh_vaccinatedfv.12 + hh_vaccinatedfv.13 + hh_vaccinatedfv.14 + 
#               sexM.1 + sexM.2 + sexM.3 + sexM.4 + sexM.5 + sexM.6 + sexM.7 + sexM.8 + sexM.9 + sexM.10 + 
#               sexM.11 + sexM.12 + sexM.13 + sexM.14 +
#               strata(trans), data = ms_vacc_a, method = "breslow")


cat("Checking proportional hazards\n")
pha <- cox.zph(c1)
t_pha <- data.frame(pha$table) %>% rownames_to_column("variable")

sum_c1 <- summary(c1) 
c1_ci <- as.data.frame(sum_c1$conf.int) %>% rownames_to_column("variable") %>% select(variable, "lower .95", "upper .95")
t_sum_c1 <- data.frame(sum_c1$coefficients) %>% rownames_to_column("variable") %>% 
  left_join(c1_ci, by = "variable") %>%
  mutate(variable = str_replace_all(variable, "_", ""),
         variable = str_replace(variable, "agecat", "agecat_"),
         variable = str_replace(variable, "householdn", "householdn_"),
         variable = str_replace(variable, "hhvaccinated", "hhvaccinated_"),
         variable = str_replace(variable, "sex", "sex_")

  ) %>%
  separate(variable, c("variable", "type", "transition")) %>%
  mutate(variable = str_replace(variable,"agecat", "age category"),
         variable = str_replace(variable,"householdn", "household n"),
         variable = str_replace(variable,"hhvaccinated", "vaccinated household"),
         type = str_replace(type, "1215", "12-15"),
         type = str_replace(type, "0511", "5-11"),
         type = str_replace(type, "1215", "12-15"),
         type = str_replace(type, "uv", "Unvaccinated"),
         type = str_replace(type, "pv", "Partially vaccinated"),
         type = str_replace(type, "fv", "Fully vaccinated"),
         type = str_replace(type, "f", "Female"),
         type = str_replace(type, "m", "Male")
  )

# qsave(
#   t_events,
#   file = ("results/t_events.qs")
# )
saveRDS(t_events, "results/t_events.rds")

# qsave(
#   c1,
#   file = ("results/c1.qs")
# )
saveRDS(c1, "results/c1.rds")

# qsave(
#   t_pha,
#   file = ("results/t_pha.qs")
# )
saveRDS(t_pha, "results/t_pha.rds")

# qsave(
#   t_sum_c1,
#   file = ("results/t_sum_c1.qs")
# )
saveRDS(t_sum_c1, "results/t_sum_c1.rds")

# qsave(
#   ms_vacc_a,
#   file = s_drive("d_ms_vacc_a.qs")
# )
saveRDS(ms_vacc_a, "ms_vacc_a.rds")

#variable = str_replace(variable, "12.15", "1215"),
#variable = str_replace(variable, "5.11", "511"),
#variable = str_replace(variable, "agecat_121511", "agecat_1215.11")