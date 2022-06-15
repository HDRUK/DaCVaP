# Sample selection criteria summary ============================================

# how does criteria effect number of individuals eligible for analysis and
# number of events under analysis
    library(RODBC);
    source("S:/0000 - Analysts Shared Resources/r-share/login_box.r");
    login = getLogin();
    sql = odbcConnect('PR_SAIL',login[1],login[2]);
    login = 0
    setwd("P:/torabif/workspace/vac17-vaccine-safety-clotting-wales")
#===============================================================================    
q_summary <- "
	SELECT
        0                            AS step,
        'c20 total'                  AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
--				'CSVT',				
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
    FROM
        sailw0911V.vac17_cohort
UNION
    SELECT
        1                            AS step,
        'in c20 at study start'      AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
--				'CSVT',
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
 FROM
        sailw0911v.vac17_cohort
    WHERE
        c20_cohort_end_date > '2020-12-07'
UNION
    SELECT
        2                            AS step,
        'has wob and sex'            AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
--				'CSVT',
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
FROM
        sailw0911v.vac17_cohort
    WHERE
        c20_cohort_end_date > '2020-12-07'
        AND c20_wob IS NOT NULL
        AND c20_gndr_cd IS NOT NULL
UNION
    SELECT
        3                            AS step,
        'has lsoa at study start'    AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
--				'CSVT',
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
    FROM sailw0911v.vac17_cohort
    WHERE
        c20_cohort_end_date > '2020-12-07'
        AND c20_wob IS NOT NULL
        AND c20_gndr_cd IS NOT NULL
        AND lsoa2011_cd IS NOT NULL
UNION
    SELECT
        4                            AS step,
        'is registered with a gp'    AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
--				'CSVT',
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
    FROM
        sailw0911v.vac17_cohort
    WHERE
        c20_cohort_end_date > '2020-12-07'
        AND c20_wob IS NOT NULL
        AND c20_gndr_cd IS NOT NULL
        AND lsoa2011_cd IS NOT NULL
        AND c20_gp_end_date > '2020-12-07'
/*
UNION

    SELECT
        5                            AS step,
        'has qcovid measures'        AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
--				'CSVT',
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
    FROM
        sailw0911v.vac17_cohort
    WHERE
        c20_cohort_end_date > '2020-12-07'
        AND c20_wob IS NOT NULL
        AND c20_gndr_cd IS NOT NULL
        AND lsoa2011_cd IS NOT NULL
        AND c20_gp_end_date > '2020-12-07'
        AND has_qc = 1
*/
UNION
    SELECT
        5                            AS step,
        'has no bad vacc records'    AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
--				'CSVT',
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
    FROM
        sailw0911v.vac17_cohort
    WHERE
        c20_cohort_end_date > '2020-12-07'
        AND c20_wob IS NOT NULL
        AND c20_gndr_cd IS NOT NULL
        AND lsoa2011_cd IS NOT NULL
        AND c20_gp_end_date > '2020-12-07'
 --       AND has_qc = 1
        AND (has_bad_vacc_record IS NULL OR has_bad_vacc_record = 0)
UNION
    SELECT
        7                            AS step,
        'aged 16 years or older'     AS criteria,
        COUNT(*)                     AS n_alf,
        SUM(incident_dt IS NOT NULL
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)
				and 
				INCIDENT_CAT IN 
				(
				'Arterial Thrombosis',
			--	'CSVT',
				'Hemorrhagic events',
				'Idiopathic thrombocytopenic purpura',
				'Ischeamic Stroke',
				'Myocardial Infarction',
				'Thrombocytopenia (excluding ITP)',
				'Venous thromboembolic events (excluding CSVT)'
				)
		        
        	) AS n_event
    FROM
        sailw0911v.vac17_cohort
    WHERE
        c20_cohort_end_date > '2020-12-07'
        AND c20_wob IS NOT NULL
        AND c20_gndr_cd IS NOT NULL
        AND lsoa2011_cd IS NOT NULL
        AND c20_gp_end_date > '2020-12-07'
 --       AND has_qc = 1
        AND (has_bad_vacc_record IS NULL OR has_bad_vacc_record = 0)
        AND age >= 16
--excludin MD vaccines
    AND 
		(
		VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
		or
		VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
		OR 
		VACC_FIRST_DATE IS NULL 
		)

;"

library(data.table)
t_summary <-
    sqlQuery(sql, q_summary)
    setnames(t_summary, tolower(names(t_summary[1:ncol(t_summary)])))
t_summary <-
    t_summary  %>%
    arrange(step) %>%
    mutate(
        diff_alf = n_alf - lag(n_alf),
        pdiff_alf = n_alf / first(n_alf) * 100,
        .after = n_alf
    ) %>%
    mutate(
        diff_event = n_event - lag(n_event),
        pdiff_event = n_event / first(n_event) * 100,
        .after = n_event
    )

write_csv(
    t_summary,
    file = "results/t_sample_selection_summary.csv"
)