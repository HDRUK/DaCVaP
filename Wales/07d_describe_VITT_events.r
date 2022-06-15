rm(list=ls())
gc()
source("01_load.r")

# Summarise the clearance and post incident counts =============================


conn <- sail_connect()

sql_vitt <- "
   SELECT
		cohort. INCIDENT_CAT ,
	    cohort.PLATELET_LESS_THAN_150=1	AS PLATELET_LESS_THAN_150,
       	cohort.D_DIMER_LESS_THAN_2000=1 AS D_DIMER_LESS_THAN_2000,
		cohort.POSITIVE_HIT_ASSAY=1 	AS POSITIVE_HIT_ASSAY,	
        cohort.PLATELET_ABOVE_150=1 	AS platelet_above_150,
        count(*)                        AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
        AND 
        INCIDENT_CAT IN ('Venous thromboembolic events (excluding CSVT)', 'CSVT')
    GROUP BY
    	cohort.INCIDENT_CAT ,
        cohort.PLATELET_LESS_THAN_150=1,
       	cohort.D_DIMER_LESS_THAN_2000=1,
   		cohort.POSITIVE_HIT_ASSAY=1,	
        cohort.PLATELET_ABOVE_150=1
    ORDER BY 
   INCIDENT_CAT ";

d_vitt <-
    sail_query(conn, sql_vitt) %>%
    arrange(incident_cat)


write_csv(
    d_vitt,
    file = "results/t_vitt.csv"
)

