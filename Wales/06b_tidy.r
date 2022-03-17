# Prepare cohort for analysis ==================================================
cat("Prepare cohort for analysis\n")

d_analysis <- qread(project_dir("data/d1_analysis_raw.qs"))

# demographics -----------------------------------------------------------------
cat("\tfactor stuff\n")

d_analysis <-
    d_analysis %>%
    rename(
        has_event = event
    ) %>%
    mutate(
        event_cat  = if_else(alf_type == 'CONTROL', NA_character_, event_cat,  event_cat),
        event_time = if_else(alf_type == 'CONTROL', NA_Date_,      event_time, event_time),
        event_type = if_else(alf_type == 'CONTROL', NA_integer_,   event_type, event_type)
    ) %>%
    mutate(
        alf_type = factor(alf_type),
        has_event_cat = factor(has_event, 0:1, c("event_no", "event_yes")),
        age_band = factor(age_band),
        sex = factor(sex, 1:2, c("Male", "Female")),
        event_cat =
            event_cat %>%
            fct_infreq(),
        vacc_type =
            vacc_type %>%
            factor() %>%
            fct_explicit_na("UV"),
        wimd_2019_quintile =
            wimd_2019_quintile %>%
            factor() %>%
            fct_inseq() %>%
            fct_recode(
                "1 Most" = "1",
                "5 Least" = "5"
            ),
        n_tests_cat =
            case_when(
                n_tests %in% 0:3  ~ str_c(0, n_tests),
                n_tests %in% 4:5  ~ "04-05",
                n_tests %in% 6:10 ~ "06-10",
                n_tests >= 11 ~ "11+"
            ) %>%
            factor(),
        smoking_cat =
            smoking_cat %>%
            fct_recode(
                "Non-smoker" = "N",
                "Ex-smoker" = "E",
                "Smoker" = "S"
            ) %>%
            fct_explicit_na("Unknown") %>%
            fct_infreq(),
        hypertension_cat =
            as.numeric(hypertension_event < '2020-12-07') %>%
            factor(0:1, c("No", "Yes")) %>%
            fct_explicit_na("No")
    )

# let the controls inherit the event of their case --------------------------
cat("\tcontrols inherit case event_cat\n")

d_analysis <-
  d_analysis %>%
  group_by(groups) %>%
  mutate(
    group_event_cat  = first(na.omit(event_cat)),
    group_event_time = first(na.omit(event_time))
  ) %>%
  ungroup() %>%
  mutate(
    group_event_simple_cat = group_event_cat %>% fct_collapse(
        "Venous thromboembolic events" = c(
            "Venous thromboembolic events (excluding CSVT)",
            "CSVT"
        )
    )
  )

# rebuild "vs" as its broken for controls --------------------------------------
cat("\trebuild vacc_time\n")

d_analysis <-
  d_analysis %>%
  mutate(
    event_to_vacc_dose1_days = interval(vacc_dt,       group_event_time) / ddays(),
    event_to_vacc_dose2_days = interval(vacc_dose2_dt, group_event_time) / ddays(),
    vacc_time_cat = case_when(
      # dose 2
      event_to_vacc_dose2_days >= 0             ~ "Dose 2 Day 00+",
      # dose 1
      event_to_vacc_dose1_days >= 28            ~ "Dose 1 Day 28+",
      between(event_to_vacc_dose1_days, 21, 27) ~ "Dose 1 Day 21-27",
      between(event_to_vacc_dose1_days, 14, 20) ~ "Dose 1 Day 14-20",
      between(event_to_vacc_dose1_days,  7, 13) ~ "Dose 1 Day 07-13",
      between(event_to_vacc_dose1_days,  0,  6) ~ "Dose 1 Day 00-06",
      # unvaccinated
      TRUE ~ NA_character_
    ) %>% factor(),
    # collapse all categories from 00 to 28 days
    vacc_time28_cat = vacc_time_cat %>% fct_collapse(
        "Dose 1 Day 00-28" = c(
          "Dose 1 Day 21-27",
          "Dose 1 Day 14-20",
          "Dose 1 Day 07-13",
          "Dose 1 Day 00-06"
        )
    ),
    # collapse all categories
    vacc_post_cat = vacc_time_cat %>% fct_collapse(
        "Dose 1 Day 00+" = c(
          "Dose 1 Day 28+",
          "Dose 1 Day 21-27",
          "Dose 1 Day 14-20",
          "Dose 1 Day 07-13",
          "Dose 1 Day 00-06"
        )
    ),
    # prefix with vaccination type
    vacc_type_time_cat =
        str_c(vacc_type, " ", vacc_time_cat) %>%
        factor() %>%
        fct_explicit_na("UV") %>%
        fct_relevel("UV"),
    vacc_type_time28_cat =
        str_c(vacc_type, " ", vacc_time28_cat) %>%
        factor() %>%
        fct_explicit_na("UV") %>%
        fct_relevel("UV"),
    vacc_type_post_cat =
        str_c(vacc_type, " ", vacc_post_cat) %>%
        factor() %>%
        fct_explicit_na("UV") %>%
        fct_relevel("UV")
  )

# qcovid: remove single value columns ------------------------------------------
cat("\tremoving single value qcovid columns\n")

qcovid_singular <-
    d_analysis %>%
    select(starts_with("qc_")) %>%
    summarise(across(.fns = n_distinct)) %>%
    pivot_longer(cols = everything()) %>%
    as.data.frame() %>%
    filter(value == 1) %>%
    select(name) %>%
    unlist()

for (qs in qcovid_singular) {
    cat("\t\t", qs, "\n", sep = "")
}

d_analysis <- d_analysis %>% select(-one_of(qs))

# qcovid -------------------------------------------------------------------
cat("\tfactor qcovid variables\n")

fct_yn <- function(x) {factor(x, 0:1, c("No", "Yes"))}

d_analysis <-
    d_analysis %>%
    mutate(
        qc_b2_82               = fct_yn(qc_b2_82),
        qc_b2_leukolaba        = fct_yn(qc_b2_leukolaba),
        qc_b2_prednisolone     = fct_yn(qc_b2_prednisolone),
        qc_b_af                = fct_yn(qc_b_af),
        qc_b_ccf               = fct_yn(qc_b_ccf),
        qc_b_asthma            = fct_yn(qc_b_asthma),
        qc_b_bloodcancer       = fct_yn(qc_b_bloodcancer),
        qc_b_cerebralpalsy     = fct_yn(qc_b_cerebralpalsy),
        qc_b_chd               = fct_yn(qc_b_chd),
        qc_b_cirrhosis         = fct_yn(qc_b_cirrhosis),
        qc_b_congenheart       = fct_yn(qc_b_congenheart),
        qc_b_copd              = fct_yn(qc_b_copd),
        qc_b_dementia          = fct_yn(qc_b_dementia),
        qc_b_epilepsy          = fct_yn(qc_b_epilepsy),
        qc_b_fracture4         = fct_yn(qc_b_fracture4),
        qc_b_neurorare         = fct_yn(qc_b_neurorare),
        qc_b_parkinsons        = fct_yn(qc_b_parkinsons),
        qc_b_pulmhyper         = fct_yn(qc_b_pulmhyper),
        qc_b_pulmrare          = fct_yn(qc_b_pulmrare),
        qc_b_pvd               = fct_yn(qc_b_pvd),
        qc_b_ra_sle            = fct_yn(qc_b_ra_sle),
        qc_b_respcancer        = fct_yn(qc_b_respcancer),
        qc_b_semi              = fct_yn(qc_b_semi),
        qc_b_sicklecelldisease = fct_yn(qc_b_sicklecelldisease),
        qc_b_stroke            = fct_yn(qc_b_stroke),
        qc_diabetes_cat        = factor(qc_diabetes_cat, 0:2, c("None", "Type 1", "Type 2")),
        qc_b_vte               = fct_yn(qc_b_vte),
        qc_chemo_cat           = factor(qc_chemo_cat, 0:3, c("None", "Group A", "Group B", "Group C")),
        qc_home_cat            = factor(qc_home_cat, 0:2, c("Neither", "Care home", "Homeless")),
        qc_learn_cat           = factor(qc_learn_cat, 0:2, c("Neither", "Learning disability", "Down's")),
        #qc_p_marrow6           = fct_yn(qc_p_marrow6),
        qc_p_radio6            = fct_yn(qc_p_radio6),
        qc_p_solidtransplant   = fct_yn(qc_p_solidtransplant),
        qc_renal_cat           = factor(qc_renal_cat, 1:6),
        qc_bmi                 = log(qc_bmi), # log-transform for imputation
        mis_bmi                = is.na(qc_bmi)
    )

# impute BMI -------------------------------------------------------------------
cat("\timputing bmi\n")

# create predictor matrix
pred.mat <- matrix(
    data = 0,
    nrow = ncol(d_analysis),
    ncol = ncol(d_analysis),
    dimnames = list(
        names(d_analysis),
        names(d_analysis)
    )
)

# set imputation routine to predict BMI based on the following measures
bmi_xvar <- c(
    "has_event_cat",
    "vacc_type_time_cat",
    "sex",
    "age_band",
    "wimd_2019_quintile",
    "n_tests_cat",
    "smoking_cat",
    "hypertension_cat",
    "qc_b_asthma",
    "qc_b_semi",
    "qc_b_diabetes_type2",
    "qc_b2_82",
    "qc_b2_leukolaba",
    "qc_b2_prednisolone",
    "qc_b_af",
    "qc_b_ccf",
    "qc_b_asthma",
    "qc_b_bloodcancer",
    "qc_b_cerebralpalsy",
    "qc_b_chd",
    "qc_b_cirrhosis",
    "qc_b_congenheart",
    "qc_b_copd",
    "qc_b_dementia",
    "qc_b_epilepsy",
    "qc_b_fracture4",
    "qc_b_neurorare",
    "qc_b_parkinsons",
    "qc_b_pulmhyper",
    "qc_b_pulmrare",
    "qc_b_pvd",
    "qc_b_ra_sle",
    "qc_b_respcancer",
    "qc_b_semi",
    "qc_b_sicklecelldisease",
    "qc_b_stroke",
    "qc_diabetes_cat",
    "qc_b_vte",
    "qc_chemo_cat",
    "qc_home_cat",
    "qc_learn_cat",
    "qc_p_radio6",
    "qc_p_solidtransplant",
    "qc_renal_cat"
)

# predictor matrix
pred.mat[
    rownames(pred.mat) == "qc_bmi",
    colnames(pred.mat) %in% bmi_xvar
] <- 1

# imputation method
# can choose from: sample, norm, norm.boot, rf
mice.method <- rep("", ncol(d_analysis))
mice.method[rownames(pred.mat) == "qc_bmi"] <- "norm"

# impute
imp_cohort <- mice(
    data = d_analysis,
    m = 5,
    predictorMatrix = pred.mat,
    method = mice.method,
    printFlag = FALSE
)

qsave(imp_cohort, file = project_dir("data/imp_cohort.qs"))

# summary plot of imputations
p_bmi_imp <-
    imp_cohort %>%
    complete(
        action = "long",
        include = TRUE
    ) %>%
    select(imp = .imp, alf_e, qc_bmi, mis_bmi, age_band, sex) %>%
    filter(
        (imp == 0 & mis_bmi == FALSE) | (imp >= 1 & mis_bmi == TRUE)
    ) %>%
    mutate(
        imp = factor(imp, 0:5, c("observed", "imp1", "imp2", "imp3", "imp4", "imp5"))
    ) %>%
    ggplot(aes(x = exp(qc_bmi), group = imp, colour = imp)) +
    geom_density() +
    facet_grid(age_band ~ sex, scales = "free_y") +
    labs(x = "qc_bmi") +
    xlim(10, 52)

ggsave(
    p_bmi_imp,
    file = "results/p_bmi_impute_density.png",
    width = p_width * 2,
    height = p_height
)

# complete BMI in the cohort
d_analysis <-
    complete(imp_cohort, 1) %>%
    mutate(
        qc_bmi = exp(qc_bmi), # un-log bmi from earlier
    )


# tidy categories some more ----------------------------------------------------
cat("\tcollapse qcovid categories\n")

d_analysis <-
    d_analysis %>%
    mutate(
        qc_bmi_cat = case_when(
            is.na(qc_bmi)                  ~ "(missing)",
            qc_bmi < 18.5                  ~ "15.0 <= BMI < 18.5",
            qc_bmi >= 18.5 & qc_bmi < 25.0 ~ "18.5 <= BMI < 25.0",
            qc_bmi >= 25.0 & qc_bmi < 30.0 ~ "25.0 <= BMI < 30.0",
            qc_bmi >= 30.0 & qc_bmi < 40.0 ~ "30.0 <= BMI < 40.0",
            qc_bmi >= 40.0                 ~ "40.0 <= BMI < 47.0"
        ),
        qc_bmi_cat = factor(qc_bmi_cat, levels = c(
            "15.0 <= BMI < 18.5",
            "18.5 <= BMI < 25.0",
            "25.0 <= BMI < 30.0",
            "30.0 <= BMI < 40.0",
            "40.0 <= BMI < 47.0"
        )),
        qc_bmi_cat = fct_relevel(qc_bmi_cat, "25.0 <= BMI < 30.0"),
        qc_learn_cat =
            qc_learn_cat %>%
            fct_collapse(
                "Learning disability / Down's" = c("Learning disability", "Down's")
            ),
        qc_renal_cat =
            qc_renal_cat %>%
            fct_collapse(
                "No" = "1",
                "CKD stage 3 or 4" = c("2", "3"),
                "End stage renal failure" = c("4", "5", "6")
            )
    ) %>%
    mutate(across(where(is.factor), fct_drop))

# qcovid sum score -------------------------------------------------------------
cat("\tmake qcovid sum score\n")

d_analysis <-
    d_analysis %>%
    mutate(
        qc_sum_score =
            (qc_b2_82               == "Yes") +
            (qc_b2_leukolaba        == "Yes") +
            (qc_b2_prednisolone     == "Yes") +
            (qc_b_af                == "Yes") +
            (qc_b_ccf               == "Yes") +
            (qc_b_asthma            == "Yes") +
            (qc_b_bloodcancer       == "Yes") +
            (qc_b_cerebralpalsy     == "Yes") +
            (qc_b_chd               == "Yes") +
            (qc_b_cirrhosis         == "Yes") +
            (qc_b_congenheart       == "Yes") +
            (qc_b_copd              == "Yes") +
            (qc_b_dementia          == "Yes") +
            (qc_b_epilepsy          == "Yes") +
            (qc_b_fracture4         == "Yes") +
            (qc_b_neurorare         == "Yes") +
            (qc_b_parkinsons        == "Yes") +
            (qc_b_pulmhyper         == "Yes") +
            (qc_b_pulmrare          == "Yes") +
            (qc_b_pvd               == "Yes") +
            (qc_b_ra_sle            == "Yes") +
            (qc_b_respcancer        == "Yes") +
            (qc_b_semi              == "Yes") +
            (qc_b_sicklecelldisease == "Yes") +
            (qc_b_stroke            == "Yes") +
            (qc_diabetes_cat        != "None") +
            (qc_b_vte               == "Yes") +
            (qc_chemo_cat           != "None") +
            (qc_home_cat            != "Neither") +
            (qc_learn_cat           != "Neither") +
            (qc_p_radio6            == "Yes") +
            (qc_p_solidtransplant   == "Yes") +
            (qc_renal_cat           != "No") +
            (qc_bmi_cat %in% c("30.0 <= BMI < 40.0", "40.0 <= BMI < 47.0")) +
            (smoking_cat == "Smoker") +
            (hypertension_cat == "Yes")
    ) %>%
    mutate(
        qc_sum_score_cat = if_else(qc_sum_score > 5, as.integer(5), qc_sum_score),
        qc_sum_score_cat = factor(qc_sum_score_cat, 0:5, c(0:4, "5+"))
    )

# goodbye ======================================================================
cat("\tsaving\n")

qsave(
    d_analysis,
    file = project_dir("data/d2_analysis_clean.qs")
)
