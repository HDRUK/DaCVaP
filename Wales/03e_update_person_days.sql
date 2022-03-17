-----------------------------------------------------------
--vac17:   Vaccine Safety
--BY:       fatemeh.torabi@swansea.ac.uk
--DT:       2021-04-08
--aim:      to add columns for time a person been exposed to vaccination
-----------------------------------------------------------

UPDATE sailw0911v.vac17_cohort
SET
person_days_exposed = NULL;

UPDATE sailw0911v.vac17_cohort
SET
person_days_exposed = CASE
						    WHEN vacc_first_date IS NOT NULL
						    THEN CAST(DAYS('2021-12-31') - DAYS(vacc_first_date) AS INTEGER)
						    ELSE 0
						END;
					
UPDATE sailw0911v.vac17_cohort
SET
person_days_exposed = CASE
						    WHEN person_days_exposed >= 0
						    THEN person_days_exposed
						    ELSE 0
						END;
COMMIT;
--------------------------------------------------------------
UPDATE sailw0911v.vac17_cohort
SET 
post_vacc_followup = CASE 
						 WHEN gp_post_vte_dt IS NOT NULL AND vacc_first_date IS NOT NULL 
						 THEN CAST(DAYS(gp_post_vte_dt) - DAYS(vacc_first_date) AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
UPDATE sailw0911v.vac17_cohort
SET 					 
post_vacc_followup = CASE 
						 WHEN gp_post_vte_dt IS NOT NULL AND vacc_first_date IS NULL 
						 THEN CAST(DAYS(gp_post_vte_dt) - DAYS('2021-12-31') AS INTEGER)						 
						 ELSE POST_VACC_FOLLOWUP END; 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_csvt_dt IS NOT NULL AND vacc_first_date IS NOT NULL
						 THEN CAST(DAYS(gp_post_csvt_dt) - DAYS(vacc_first_date) AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_csvt_dt IS NOT NULL AND vacc_first_date IS NULL
						 THEN CAST(DAYS(gp_post_csvt_dt) - DAYS('2021-12-31') AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_haemorrhage_dt IS NOT NULL AND vacc_first_date IS NOT NULL
						 THEN CAST(DAYS(gp_post_haemorrhage_dt) - DAYS(vacc_first_date) AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_haemorrhage_dt IS NOT NULL AND vacc_first_date IS NULL
						 THEN CAST(DAYS(gp_post_haemorrhage_dt) - DAYS('2021-12-31') AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_thrombocytopenia_dt IS NOT NULL AND vacc_first_date IS NOT NULL
						 THEN CAST(DAYS(gp_post_thrombocytopenia_dt) - DAYS(vacc_first_date) AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
						 
UPDATE sailw0911v.vac17_cohort
SET 					 
post_vacc_followup = CASE 
						 WHEN gp_post_thrombocytopenia_dt IS NOT NULL AND vacc_first_date IS NULL
						 THEN CAST(DAYS(gp_post_thrombocytopenia_dt) - DAYS('2021-12-31') AS INTEGER)						 
						 ELSE POST_VACC_FOLLOWUP END; 
						 
UPDATE sailw0911v.vac17_cohort
SET 
post_vacc_followup = CASE 
						 WHEN gp_post_ITP_dt IS NOT NULL AND vacc_first_date IS NOT NULL
						 THEN CAST(DAYS(gp_post_ITP_dt) - DAYS(vacc_first_date) AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
						 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_ITP_dt IS NOT NULL AND vacc_first_date IS NULL
						 THEN CAST(DAYS(gp_post_ITP_dt) - DAYS('2021-12-31') AS INTEGER)						 
						 ELSE POST_VACC_FOLLOWUP END; 
						 
UPDATE sailw0911v.vac17_cohort
SET 
post_vacc_followup = CASE 
						 WHEN gp_post_isch_stroke_dt IS NOT NULL AND vacc_first_date IS NOT NULL
						 THEN CAST(DAYS(gp_post_isch_stroke_dt) - DAYS(vacc_first_date) AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
						 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_isch_stroke_dt IS NOT NULL AND vacc_first_date IS NULL
						 THEN CAST(DAYS(gp_post_isch_stroke_dt) - DAYS('2021-12-31') AS INTEGER)						 
						 ELSE POST_VACC_FOLLOWUP END; 
						 
UPDATE sailw0911v.vac17_cohort
SET 
post_vacc_followup = CASE 
						 WHEN gp_post_mi_dt IS NOT NULL AND vacc_first_date IS NOT NULL
						 THEN CAST(DAYS(gp_post_mi_dt) - DAYS(vacc_first_date) AS INTEGER)
						 ELSE POST_VACC_FOLLOWUP END; 
						 
UPDATE sailw0911v.vac17_cohort
SET 						 
post_vacc_followup = CASE 
						 WHEN gp_post_mi_dt IS NOT NULL AND vacc_first_date IS NULL
						 THEN CAST(DAYS(gp_post_mi_dt) - DAYS('2021-12-31') AS INTEGER)						 			 						 
						 ELSE POST_VACC_FOLLOWUP END; 
						 

/*					
UPDATE sailw0911v.vac17_cohort
SET 
post_vacc_followup = CASE 
						 WHEN post_vacc_followup < 0 THEN NULL 
						 ELSE post_vacc_followup
						END;	
*/						
COMMIT;					
