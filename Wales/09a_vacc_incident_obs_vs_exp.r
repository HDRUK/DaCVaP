rm(list=ls())
gc()
source("01_load.r")

usr <- Sys.info()["user"]

if (usr == "bedstons") {
    sql <- sail_connect()
}

if (usr == "torabif") {
    source("S:/0000 - Analysts Shared Resources/r-share/login_box.r");
    login = getLogin();
    #Connect and get the database
    sql = odbcConnect('PR_SAIL',login[1],login[2]);
    login = 0 # this will make your password anonymous
}
# baseline rate ================================================================

# October 01-28
# - age-band
# - incident type
# - number of incidents
# - exposure time as person-days

sql_oct <- "
SELECT DISTINCT AGE_CAT, READ_CAT, COUNT(DISTINCT ALF_E) N_INCIDENT, 
SUM(PERSON_DAYS) PERSON_DAYS  
FROM 
(
	SELECT ALF_E , 
		AGE_CAT, READ_CAT, 
		CASE
	         WHEN EVENT_DT IS NOT NULL  THEN DAYS(EVENT_DT) - DAYS('2020-10-01') + 1
	         WHEN c20_cohort_end_date < '2020-10-28' THEN DAYS(c20_cohort_end_date) - DAYS('2020-10-01') + 1
	         ELSE DAYS('2020-10-28') - DAYS('2020-10-01') + 1
	            END AS person_days	
	FROM             
	(	
		SELECT DISTINCT 
		            CASE
		                WHEN age BETWEEN 16 AND 39 THEN '16-39'
		                WHEN age BETWEEN 40 AND 59 THEN '40-59'
		                WHEN age BETWEEN 60 AND 79 THEN '60-79'
		                WHEN age >= 80 THEN '80+'
		                ELSE CAST(age AS VARCHAR(5))
		            END AS age_cat, 
		            CASE 
							WHEN pre_venous_thromboembolic_dt 	IS NOT NULL THEN 'Venous thromboembolic events (excluding CSVT)'
							WHEN pre_csvt_dt					IS NOT NULL THEN 'CSVT'
							WHEN pre_haemorrhage_dt				IS NOT NULL THEN 'Hemorrhagic events'
							WHEN pre_thrombocytopenia_dt		IS NOT NULL THEN 'Thrombocytopenia (excluding ITP)'
							WHEN pre_ITP_dt 					IS NOT NULL THEN 'Idiopathic thrombocytopenic purpura'
							ELSE NULL END AS read_cat, 
					 CASE 
							WHEN pre_venous_thromboembolic_dt 	IS NOT NULL THEN pre_venous_thromboembolic_dt
							WHEN pre_csvt_dt					IS NOT NULL THEN pre_csvt_dt
							WHEN pre_haemorrhage_dt				IS NOT NULL THEN pre_haemorrhage_dt
							WHEN pre_thrombocytopenia_dt		IS NOT NULL THEN pre_thrombocytopenia_dt
							WHEN pre_ITP_dt 					IS NOT NULL THEN pre_ITP_dt
							ELSE NULL END AS EVENT_DT, 		
		ALF_E , C20_COHORT_END_DATE 
		FROM 
		 SAILW0911V.DACVAP_COHORT 
		 WHERE IS_SAMPLE =1
	)
)
GROUP BY 
AGE_CAT, READ_CAT
ORDER BY AGE_CAT, READ_CAT
;"

#SB
#d_oct <- sail_query(conn, sql_oct)
#FT
d_oct <- sqlQuery(sql,sql_oct)%>%
    janitor::clean_names()

d_baseline_rate <-
    d_oct %>%
    # collapse and rename incident categories
    mutate(
        incident_cat = case_when(
            read_cat %in% c("CSVT", "Venous thromboembolic events (excluding CSVT)") ~ "Venous thromboembolic events (including CSVT)",
            read_cat == "Thrombocytopenia (excluding idiopathic thrombocytopenic purpura (ITP))"      ~ "Thrombocytopenia (excluding ITP)",
            read_cat == "Hemorrhage"                                                                  ~ "Hemorrhagic events",
            read_cat == "ITP"                                                                         ~ "Idiopathic phrombocytopenic purpura",
            TRUE ~ read_cat
        )
    ) %>%
    group_by(
        age_cat,
        incident_cat
    ) %>%
    summarise(
        person_days = sum(person_days),
        n_incident  = sum(n_incident)
    ) %>%
    ungroup() %>%
    # get total person days for each age group
    group_by(
        age_cat
    ) %>%
    mutate(
        total_person_days = sum(person_days)
    ) %>%
    ungroup() %>%
    # remove rows for those with no events
    filter(
        !is.na(incident_cat)
    ) %>%
    # calculate baseline rate for events
    mutate(
        baseline_rate = n_incident / total_person_days
    ) %>%
    select(
        age_cat,
        incident_cat,
        baseline_person_days = total_person_days,
        baseline_incident_n = n_incident,
        baseline_rate
    )

# exposure person time =========================================================

sql_post_vacc <- "
 SELECT DISTINCT VACC_FIRST_NAME ,AGE_CAT, INCIDENT_CAT , COUNT(DISTINCT ALF_E) N_INCIDENT, 
SUM(PERSON_DAYS) PERSON_DAYS  
FROM 
(
	SELECT ALF_E , 
		AGE_CAT, INCIDENT_CAT, VACC_FIRST_NAME ,
            CASE
                WHEN incident_dt IS NULL THEN 28
                WHEN incident_dt < (vacc_first_date + 27 days) THEN days(incident_dt) - days(vacc_first_date) + 1
                WHEN c20_cohort_end_date < (vacc_first_date + 27 days) THEN days(c20_cohort_end_date) - days(vacc_first_date) + 1
                ELSE 28
            END
            AS person_days
    FROM             
	(	
		SELECT DISTINCT 
		            CASE
		                WHEN age BETWEEN 16 AND 39 THEN '16-39'
		                WHEN age BETWEEN 40 AND 59 THEN '40-59'
		                WHEN age BETWEEN 60 AND 79 THEN '60-79'
		                WHEN age >= 80 THEN '80+'
		                ELSE CAST(age AS VARCHAR(5))
		            END AS age_cat, 
		INCIDENT_CAT,
		INCIDENT_DT, 		
		ALF_E , C20_COHORT_END_DATE , VACC_FIRST_DATE , VACC_FIRST_NAME 
			FROM 
		SAILW0911V.DACVAP_COHORT 
		WHERE
		is_sample = 1
        AND clearance_incident_dt IS NULL
        AND vacc_first_date IS NOT NULL
        AND c20_cohort_end_date >= vacc_first_date
        AND (
             incident_dt IS NULL
             OR incident_dt >= vacc_first_date
            )
	)
)
GROUP BY 
AGE_CAT, INCIDENT_CAT ,VACC_FIRST_NAME 
ORDER BY AGE_CAT, INCIDENT_CAT ,VACC_FIRST_NAME
;"

d_post_vacc <-
#    sail_query(conn, sql_post_vacc) %>%
    sqlQuery(sql,sql_post_vacc)%>%
    janitor::clean_names()%>%
    # collapse and rename levels in incident_cat
    mutate(
        incident_cat = case_when(
            incident_cat %in% c("CSVT", "Venous thromboembolic events (excluding CSVT)") ~ "Venous thromboembolic events (including CSVT)",
            TRUE ~ incident_cat
        )
    ) %>%
    group_by(
        vacc_first_name,
        age_cat,
        incident_cat
    ) %>%
    summarise(
        person_days = sum(person_days),
        n_incident = sum(n_incident)
    ) %>%
    # calculate total exposed person days
    group_by(
        vacc_first_name,
        age_cat
    ) %>%
    mutate(
        exposure_total_person_days = sum(person_days)
    ) %>%
    ungroup() %>%
    filter(
        !is.na(incident_cat)
    ) %>%
    mutate(
        vacc_first_name = case_when(
            vacc_first_name == "COVID-19 (ASTRAZENECA)"     ~ "AZ",
            vacc_first_name == "COVID-19 (PFIZER BIONTECH)" ~ "PB"
        )
    ) %>%
    select(
        -person_days
    ) %>%
    rename(
        exposure_incident_n = n_incident
    )

# observed vs expected =========================================================

t_obs_exp <-
    # get all combinations of vaccine name, age cat and incident cat
    expand.grid(
        vacc_first_name = unique(d_post_vacc$vacc_first_name),
        age_cat = unique(c(d_post_vacc$age_cat, d_baseline_rate$age_cat)),
        incident_cat = unique(c(d_post_vacc$incident_cat, d_baseline_rate$incident_cat))
    ) %>%
    arrange(
        vacc_first_name,
        age_cat,
        incident_cat
    ) %>%
    # join information
    left_join(d_baseline_rate, by = c("age_cat", "incident_cat")) %>%
    left_join(d_post_vacc, by = c("vacc_first_name", "age_cat", "incident_cat")) %>%
    # fill in missing baseline values
    group_by(age_cat) %>%
    mutate(
        baseline_person_days = replace_na(baseline_person_days, first(na.omit(baseline_person_days))),
        baseline_incident_n = replace_na(baseline_incident_n, 0),
        baseline_rate = replace_na(baseline_rate, 0)
    ) %>%
    ungroup() %>%
    # fill in missing exposure values
    group_by(vacc_first_name, age_cat) %>%
    mutate(
        exposure_total_person_days = replace_na(exposure_total_person_days, first(na.omit(exposure_total_person_days))),
        exposure_incident_n = replace_na(exposure_incident_n, 0)
    ) %>%
    ungroup() %>%
    # calculate expected
    mutate(
        expected_incidient_n = baseline_rate * exposure_total_person_days
    )

write_csv(
    t_obs_exp,
    file = "results/t_vacc_incident_observed_vs_expected_long.csv"
)

# TODO: use rpois to bootstrap confidence intervals

# make pretty ==================================================================

# TODO move the code for the pretty table into README.rmd
#      and stop writing the wide CSV to results/

t_obs_exp_pretty <-
    t_obs_exp %>%
    select(
        vacc_name = vacc_first_name,
        age_cat,
        incident_cat,
        obs_n = exposure_incident_n,
        exp_n = expected_incidient_n
    ) %>%
    pivot_wider(
        names_from = incident_cat,
        values_from = c(obs_n, exp_n),
        names_glue = "{incident_cat}_{.value}"
    ) %>%
    select(
        vacc_name,
        age_cat,
        matches("obs_n"),
        matches("exp_n")
    ) %>%
    select(
        vacc_name,
        age_cat,
        starts_with("Throm"),
        starts_with("Idiop"),
        starts_with("Venou"),
        starts_with("Hemo")
    )

write_csv(
    t_obs_exp_pretty,
    file = "results/t_vacc_incident_observed_vs_expected_wide.csv"
)
