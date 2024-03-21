source("r_clear_and_load.r")

# Get raw cohort ===============================================================
cat("Get raw cohort\n")

con <- sail_open()

q_cohort <- "
SELECT
-- main id
    cohort.alf_e,
-- c19 cohort 20
    cohort.pers_id_e,
    cohort.wob,
    cohort.gndr_cd,
    cohort.wds_start_date,
    cohort.wds_end_date,
    cohort.gp_start_date,
    cohort.gp_end_date,
    cohort.c20_start_date,
    cohort.c20_end_date,
-- ethnicity
    cohort.ethn_cat,
-- area and household info at 2020-12-07
    cohort.ralf_e,
    cohort.ralf_sts_cd,
    cohort.lsoa2011_cd,
    cohort.wimd2019_quintile,
    cohort.health_board,
    cohort.urban_rural_class,
    hh.household_n,
    hh.adult_n,
    hh_vaccinated,
-- shielded patient
    cohort.shielded_flg,
-- vaccine data quality
    vacc.has_bad_vacc_record,
-- first dose
    vacc.vacc_dose1_date,
    vacc.vacc_dose1_name,
    vacc.vacc_dose1_reaction_ind,
    vacc.vacc_dose1_reaction_cd,
-- second dose
    vacc.vacc_dose2_date,
    vacc.vacc_dose2_name,
    vacc.vacc_dose2_reaction_ind,
    vacc.vacc_dose2_reaction_cd,
-- third dose
    vacc.vacc_dose3_date,
    vacc.vacc_dose3_name,
    vacc.vacc_dose3_reaction_ind,
    vacc.vacc_dose3_reaction_cd,
-- booster dose
    vacc.vacc_doseb_date,
    vacc.vacc_doseb_name,
    vacc.vacc_doseb_reaction_ind,
    vacc.vacc_doseb_reaction_cd,
-- pcr test history
    lft_pcr_test.pcr_ever_flg,
    lft_pcr_test.pcr_pre08dec2020_n,
    lft_pcr_test.pcr_pre16sep2021_n,
-- lft test history
    lft_pcr_test.lft_ever_flg,
    lft_pcr_test.lft_pre08dec2020_n,
    lft_pcr_test.lft_pre16sep2021_n,
-- number of infections
    lft_pcr_test.infection_n,
-- positive tests 90 days apart
    lft_pcr_test.infection1_test_date,
    lft_pcr_test.infection2_test_date,
    lft_pcr_test.infection3_test_date,
    lft_pcr_test.infection4_test_date,
-- death
    death.death_date,
    death.death_covid_flg
FROM sailw1151v.dacvap2_cyp AS cohort
LEFT JOIN sailw1151v.sa_dacvap_vacc AS vacc
    ON cohort.alf_e = vacc.alf_e
LEFT JOIN sailw1151v.sa_dacvap_lft_pcr_test AS lft_pcr_test
    ON cohort.alf_e = lft_pcr_test.alf_e
LEFT JOIN sailw1151v.sa_dacvap_death AS death
    ON cohort.alf_e = death.alf_e
LEFT JOIN sailw1151v.sa_dacvap_hh  AS hh
    ON cohort.alf_e = hh.alf_e
;"

d_cohort <- sail_run(con, q_cohort) %>%
    arrange(alf_e)

# check if alf is unique
total_n <- d_cohort %>% nrow()
alf_n   <- d_cohort %>% select(alf_e) %>% distinct() %>% nrow()

if (alf_n < total_n) {
    stop("ALF is not unique in d_cohort")
}

# Get raw cohort hospitalisations ==============================================
cat("Get raw cohort hospitalisations\n")

q_cohort_hosp <- "
WITH 
super_spell AS 
	(select
		person_spell_num_e,
    	min(spell_admis_date) AS admis_dt,
    	max(spell_disch_date) AS disch_dt,
    	DAYS_BETWEEN(max(spell_disch_date), min(spell_admis_date)) + 1 AS spell_length
    FROM sailw1151v.sa_dacvap_hosp_long
    GROUP BY person_spell_num_e
    )
SELECT
    cohort.alf_e,
    cohort.wob,
    hosp.spell_admis_date,
    hosp.epi_start_date,
    spell_length,
    hosp.admis_covid19_cause_flg,
    hosp.admis_with_covid19_flg,
    hosp.covid19_during_admis_flg,
    hosp.within_14days_positive_pcr_flg
FROM sailw1151v.dacvap2_cyp AS cohort
LEFT JOIN sailw1151v.sa_dacvap_hosp_long AS hosp
    ON cohort.alf_e = hosp.alf_e
LEFT JOIN super_spell AS superspell
	ON hosp.person_spell_num_e = superspell.person_spell_num_e
;"

d_cohort_hosp <- sail_run(con, q_cohort_hosp)

# Save =========================================================================
cat("Save\n")

qsave(
  d_cohort,
  file = s_drive("d_cohort_raw.qs")
)

qsave(
  d_cohort_hosp,
  file = s_drive("d_cohort_hosp_raw.qs")
)


# Goodbye ======================================================================

sail_close(con)
beep()
