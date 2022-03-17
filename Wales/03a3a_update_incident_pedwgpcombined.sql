-----------------------------------------------------------
--vac17: 	Vaccine Safety
--BY:		fatemeh.torabi@swansea.ac.uk
--DT: 		2021-04-08
--aim:		to add columns for first incident after cohort start
-----------------------------------------------------------
--deactivating transaction log for this part of script to avoid errors on long updates:
alter table sailw0911v.vac17_cohort activate not logged INITIALLY;

-----------------------------------------------------------
--combined incident 
-----------------------------------------------------------
UPDATE sailw0911v.vac17_cohort
SET
INCIDENT_DT		=NULL, 
INCIDENT_CAT	=NULL, 
INCIDENT_TYPE	=NULL;

COMMIT;

UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					--vte
					WHEN	(pedw_post_vte_dt 		IS NOT NULL) AND 
							(pedw_clearance_vte_dt 	IS NULL 	AND gp_clearance_vte_dt 	IS NULL)
					THEN pedw_post_vte_dt
					WHEN	(gp_post_vte_dt 			IS NOT NULL) AND 
							(pedw_clearance_vte_dt 	IS NULL 	AND gp_clearance_vte_dt 	IS NULL)
					THEN gp_post_vte_dt
					ELSE INCIDENT_DT END; 
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					--csvt					
					WHEN	(pedw_post_csvt_dt 		IS NOT NULL) AND 
							(pedw_clearance_csvt_dt 	IS NULL 	AND gp_clearance_csvt_dt 	IS NULL)
					THEN pedw_post_csvt_dt
					WHEN	(gp_post_csvt_dt 			IS NOT NULL) AND 
							(pedw_clearance_csvt_dt 	IS NULL 	AND gp_clearance_csvt_dt 	IS NULL)
					THEN gp_post_csvt_dt					
					ELSE INCIDENT_DT END; 
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					--haemorrhage					
					WHEN	(pedw_post_haemorrhage_dt 		IS NOT NULL) AND 
							(pedw_clearance_haemorrhage_dt 	IS NULL 	AND gp_clearance_haemorrhage_dt 	IS NULL)
					THEN pedw_post_haemorrhage_dt
					WHEN	(gp_post_haemorrhage_dt 			IS NOT NULL) AND 
							(pedw_clearance_haemorrhage_dt 	IS NULL 	AND gp_clearance_haemorrhage_dt 	IS NULL)
					THEN gp_post_haemorrhage_dt				
					ELSE INCIDENT_DT END; 
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					--thrombocytopenia					
					WHEN	(pedw_post_thrombocytopenia_dt 		IS NOT NULL) AND 
							(pedw_clearance_thrombocytopenia_dt 	IS NULL 	AND gp_clearance_thrombocytopenia_dt 	IS NULL)
					THEN pedw_post_thrombocytopenia_dt
					WHEN	(gp_post_thrombocytopenia_dt 			IS NOT NULL) AND 
							(pedw_clearance_thrombocytopenia_dt 	IS NULL 	AND gp_clearance_thrombocytopenia_dt 	IS NULL)
					THEN gp_post_thrombocytopenia_dt					
					ELSE INCIDENT_DT END; 
										
					--ITP					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN	(pedw_post_ITP_dt 		IS NOT NULL ) AND 
							(pedw_clearance_ITP_dt 	IS NULL 	AND gp_clearance_ITP_dt 	IS NULL)
					THEN pedw_post_ITP_dt
					WHEN	(gp_post_ITP_dt 			IS NOT NULL) AND 
							(pedw_clearance_ITP_dt 	IS NULL 	AND gp_clearance_ITP_dt 	IS NULL)
					THEN gp_post_ITP_dt	
					ELSE INCIDENT_DT END; 
					
					--AT
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN	(pedw_post_AT_dt 		IS NOT NULL) AND 
							(pedw_clearance_AT_dt 	IS NULL 	AND gp_clearance_AT_dt 	IS NULL)
					THEN    pedw_post_AT_dt
					WHEN	(gp_post_AT_dt 			IS NOT NULL) AND 
							(pedw_clearance_AT_dt 	IS NULL 	AND gp_clearance_AT_dt 	IS NULL)
					THEN gp_post_AT_dt	
					ELSE INCIDENT_DT END; 
					
					--isch_stroke
					/*
					WHEN	(pedw_post_isch_stroke_dt 		IS NOT NULL AND gp_post_isch_stroke_dt 			IS NULL) AND 
							(pedw_clearance_isch_stroke_dt 	IS NULL 	AND gp_clearance_isch_stroke_dt 	IS NULL)
					THEN    pedw_post_isch_stroke_dt
					WHEN	(pedw_post_isch_stroke_dt 		IS NULL 	AND gp_post_isch_stroke_dt 			IS NOT NULL) AND 
							(pedw_clearance_isch_stroke_dt 	IS NULL 	AND gp_clearance_isch_stroke_dt 	IS NULL)
					THEN gp_post_isch_stroke_dt	
                    */
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN	pedw_post_isch_stroke_dt 		IS NOT NULL  AND 	pedw_clearance_isch_stroke_dt 	IS NULL THEN  pedw_post_isch_stroke_dt
					ELSE INCIDENT_DT END; 
	
					--MI
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN	(pedw_post_mi_dt 		IS NOT NULL) AND 
							(pedw_clearance_mi_dt 	IS NULL 	AND gp_clearance_mi_dt 	IS NULL)
					THEN    pedw_post_mi_dt
					WHEN	(gp_post_mi_dt 			IS NOT NULL) AND 
							(pedw_clearance_mi_dt 	IS NULL 	AND gp_clearance_mi_dt 	IS NULL)
					THEN gp_post_mi_dt	
					ELSE INCIDENT_DT END; 

					--coeliac: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN pedw_post_coliac_dt 			IS NOT NULL AND pedw_clearance_coliac_dt IS NULL 			THEN pedw_post_coliac_dt 
					ELSE INCIDENT_DT END; 
					--anaph: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN pedw_post_anaph_dt 			IS NOT NULL AND pedw_clearance_anaph_dt IS NULL				THEN pedw_post_anaph_dt 
					ELSE INCIDENT_DT END; 
					--hip fract: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN pedw_post_hipfract_dt 			IS NOT NULL AND pedw_clearance_hipfract_dt IS NULL			THEN pedw_post_hipfract_dt 
					ELSE INCIDENT_DT END; 
					--appendicitis: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_DT = CASE
					WHEN pedw_post_append_dt 			IS NOT NULL AND pedw_clearance_append_dt IS NULL			THEN pedw_post_append_dt 
					ELSE INCIDENT_DT END; 
				
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					--vte
					WHEN	(pedw_post_vte_dt 		IS NOT NULL) AND 
							(pedw_clearance_vte_dt 	IS NULL 	AND gp_clearance_vte_dt 	IS NULL)
					THEN 'Venous thromboembolic events (excluding CSVT)'
					WHEN	(gp_post_vte_dt 			IS NOT NULL) AND 
							(pedw_clearance_vte_dt 	IS NULL 	AND gp_clearance_vte_dt 	IS NULL)
					THEN 'Venous thromboembolic events (excluding CSVT)'
					ELSE INCIDENT_CAT END; 
					
					--csvt					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN	(pedw_post_csvt_dt 		IS NOT NULL) AND 
							(pedw_clearance_csvt_dt 	IS NULL 	AND gp_clearance_csvt_dt 	IS NULL)
					THEN 'CSVT'
					WHEN	(gp_post_csvt_dt 			IS NOT NULL) AND 
							(pedw_clearance_csvt_dt 	IS NULL 	AND gp_clearance_csvt_dt 	IS NULL)
					THEN 'CSVT'					
					ELSE  INCIDENT_CAT END;					
					--haemorrhage					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN	(pedw_post_haemorrhage_dt 		IS NOT NULL) AND 
							(pedw_clearance_haemorrhage_dt 	IS NULL 	AND gp_clearance_haemorrhage_dt 	IS NULL)
					THEN 'Hemorrhagic events'
					WHEN	(gp_post_haemorrhage_dt 			IS NOT NULL) AND 
							(pedw_clearance_haemorrhage_dt 	IS NULL 	AND gp_clearance_haemorrhage_dt 	IS NULL)
					THEN 'Hemorrhagic events'				
					ELSE  INCIDENT_CAT END;					
					--thrombocytopenia					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN	(pedw_post_thrombocytopenia_dt 		IS NOT NULL ) AND 
							(pedw_clearance_thrombocytopenia_dt 	IS NULL 	AND gp_clearance_thrombocytopenia_dt 	IS NULL)
					THEN 'Thrombocytopenia (excluding ITP)'
					WHEN	(gp_post_thrombocytopenia_dt 			IS NOT NULL) AND 
							(pedw_clearance_thrombocytopenia_dt 	IS NULL 	AND gp_clearance_thrombocytopenia_dt 	IS NULL)
					THEN 'Thrombocytopenia (excluding ITP)'					
					ELSE  INCIDENT_CAT END;										
					--ITP					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN	(pedw_post_ITP_dt 		IS NOT NULL) AND 
							(pedw_clearance_ITP_dt 	IS NULL 	AND gp_clearance_ITP_dt 	IS NULL)
					THEN 'Idiopathic thrombocytopenic purpura'
					WHEN	(gp_post_ITP_dt 			IS NOT NULL) AND 
							(pedw_clearance_ITP_dt 	IS NULL 	AND gp_clearance_ITP_dt 	IS NULL)
					THEN 'Idiopathic thrombocytopenic purpura'
					ELSE  INCIDENT_CAT END;
					--AT					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN	(pedw_post_AT_dt 		IS NOT NULL ) AND 
							(pedw_clearance_AT_dt 	IS NULL 	AND gp_clearance_AT_dt 	IS NULL)
					THEN 'Arterial Thrombosis'
					WHEN	(gp_post_AT_dt 			IS NOT NULL) AND 
							(pedw_clearance_AT_dt 	IS NULL 	AND gp_clearance_AT_dt 	IS NULL)
					THEN 'Arterial Thrombosis'					
					ELSE  INCIDENT_CAT END;					
					
					--isch_stroke
					/*
					WHEN	(pedw_post_isch_stroke_dt 		IS NOT NULL AND gp_post_isch_stroke_dt 			IS NULL) AND 
							(pedw_clearance_isch_stroke_dt 	IS NULL 	AND gp_clearance_isch_stroke_dt 	IS NULL)
					THEN  'Ischeamic Stroke'
					WHEN	(pedw_post_isch_stroke_dt 		IS NULL 	AND gp_post_isch_stroke_dt 			IS NOT NULL) AND 
							(pedw_clearance_isch_stroke_dt 	IS NULL 	AND gp_clearance_isch_stroke_dt 	IS NULL)
					THEN 'Ischeamic Stroke'	
                   */---matching to hippisley cox method only hospitalisation for stokr
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN	pedw_post_isch_stroke_dt 		IS NOT NULL  AND 	pedw_clearance_isch_stroke_dt 	IS NULL THEN  'Ischeamic Stroke'
					ELSE  INCIDENT_CAT END;					
					--MI
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN	(pedw_post_mi_dt 		IS NOT NULL ) AND 
							(pedw_clearance_mi_dt 	IS NULL 	AND gp_clearance_mi_dt 	IS NULL)
					THEN  'Myocardial Infarction'
					WHEN	(gp_post_mi_dt 			IS NOT NULL) AND 
							(pedw_clearance_mi_dt 	IS NULL 	AND gp_clearance_mi_dt 	IS NULL)
					THEN 'Myocardial Infarction'
					ELSE  INCIDENT_CAT END;					
					--coeliac: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN pedw_post_coliac_dt 			IS NOT NULL AND pedw_clearance_coliac_dt IS NULL 			THEN 'Coeliac disease'
					ELSE  INCIDENT_CAT END;					
					--anaph: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN pedw_post_anaph_dt 			IS NOT NULL AND pedw_clearance_anaph_dt IS NULL				THEN 'Anaphylactic shock'
					ELSE  INCIDENT_CAT END;					
					--hip fract: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN pedw_post_hipfract_dt 			IS NOT NULL AND pedw_clearance_hipfract_dt IS NULL			THEN 'Hip fracture'
					ELSE  INCIDENT_CAT END;					
					--appendicitis: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_CAT = CASE
					WHEN pedw_post_append_dt 			IS NOT NULL AND pedw_clearance_append_dt IS NULL			THEN 'Appendicitis' 
					ELSE  INCIDENT_CAT END; 


UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					--vte
					WHEN	(pedw_post_vte_dt 		IS NOT NULL ) AND 
							(pedw_clearance_vte_dt 	IS NULL AND gp_clearance_vte_dt 	IS NULL)
					THEN 1
					WHEN	(gp_post_vte_dt 			IS NOT NULL) AND 
							(pedw_clearance_vte_dt 	IS NULL 	AND gp_clearance_vte_dt 	IS NULL)
					THEN 1
					ELSE INCIDENT_TYPE END;					
					--csvt					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN	(pedw_post_csvt_dt 		IS NOT NULL) AND 
							(pedw_clearance_csvt_dt 	IS NULL 	AND gp_clearance_csvt_dt 	IS NULL)
					THEN 2
					WHEN	(gp_post_csvt_dt 			IS NOT NULL) AND 
							(pedw_clearance_csvt_dt 	IS NULL 	AND gp_clearance_csvt_dt 	IS NULL)
					THEN 2					
					ELSE INCIDENT_TYPE END;					
					--haemorrhage					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN	(pedw_post_haemorrhage_dt 		IS NOT NULL ) AND 
							(pedw_clearance_haemorrhage_dt 	IS NULL 	AND gp_clearance_haemorrhage_dt 	IS NULL)
					THEN 3
					WHEN	(gp_post_haemorrhage_dt 			IS NOT NULL) AND 
							(pedw_clearance_haemorrhage_dt 	IS NULL 	AND gp_clearance_haemorrhage_dt 	IS NULL)
					THEN 3					
					ELSE INCIDENT_TYPE END;					
					--thrombocytopenia					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN	(pedw_post_thrombocytopenia_dt 		IS NOT NULL) AND 
							(pedw_clearance_thrombocytopenia_dt 	IS NULL 	AND gp_clearance_thrombocytopenia_dt 	IS NULL)
					THEN 4
					WHEN	(gp_post_thrombocytopenia_dt 			IS NOT NULL) AND 
							(pedw_clearance_thrombocytopenia_dt 	IS NULL 	AND gp_clearance_thrombocytopenia_dt 	IS NULL)
					THEN 4					
					ELSE INCIDENT_TYPE END;										
					--ITP					
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN	(pedw_post_ITP_dt 		IS NOT NULL ) AND 
							(pedw_clearance_ITP_dt 	IS NULL 	AND gp_clearance_ITP_dt 	IS NULL)
					THEN 5
					WHEN	( gp_post_ITP_dt 			IS NOT NULL) AND 
							(pedw_clearance_ITP_dt 	IS NULL 	AND gp_clearance_ITP_dt 	IS NULL)
					THEN 5	
					ELSE INCIDENT_TYPE END;					
					--AT
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN	(pedw_post_AT_dt 		IS NOT NULL) AND 
							(pedw_clearance_AT_dt 	IS NULL 	AND gp_clearance_AT_dt 	IS NULL)
					THEN    6
					WHEN	(gp_post_AT_dt 			IS NOT NULL) AND 
							(pedw_clearance_AT_dt 	IS NULL 	AND gp_clearance_AT_dt 	IS NULL)
					THEN    6	
					ELSE INCIDENT_TYPE END;					
					--isch_stroke
					/*
					WHEN	(pedw_post_isch_stroke_dt 		IS NOT NULL AND gp_post_isch_stroke_dt 			IS NULL) AND 
							(pedw_clearance_isch_stroke_dt 	IS NULL 	AND gp_clearance_isch_stroke_dt 	IS NULL)
					THEN    7
					WHEN	(pedw_post_isch_stroke_dt 		IS NULL 	AND gp_post_isch_stroke_dt 			IS NOT NULL) AND 
							(pedw_clearance_isch_stroke_dt 	IS NULL 	AND gp_clearance_isch_stroke_dt 	IS NULL)
					THEN 	7	
                   */
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN	pedw_post_isch_stroke_dt 		IS NOT NULL  AND 	pedw_clearance_isch_stroke_dt 	IS NULL THEN  7
					ELSE INCIDENT_TYPE END;
					--MI
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN	(pedw_post_mi_dt 		IS NOT NULL ) AND 
							(pedw_clearance_mi_dt 	IS NULL 	AND gp_clearance_mi_dt 	IS NULL)
					THEN    8
					WHEN	(gp_post_mi_dt 			IS NOT NULL) AND 
							(pedw_clearance_mi_dt 	IS NULL 	AND gp_clearance_mi_dt 	IS NULL)
					THEN 	8
					ELSE INCIDENT_TYPE END;					
					--coeliac: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN pedw_post_coliac_dt 			IS NOT NULL AND pedw_clearance_coliac_dt IS NULL 			THEN 9
					ELSE INCIDENT_TYPE END;					
					--anaph: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN pedw_post_anaph_dt 			IS NOT NULL AND pedw_clearance_anaph_dt IS NULL				THEN 10
					ELSE INCIDENT_TYPE END;
					--hip fract: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN pedw_post_hipfract_dt 			IS NOT NULL AND pedw_clearance_hipfract_dt IS NULL			THEN 11
					ELSE INCIDENT_TYPE END;					
					--appendicitis: pedw only
UPDATE SAILW0911V.vac17_COHORT 
SET INCIDENT_TYPE = CASE
					WHEN pedw_post_append_dt 			IS NOT NULL AND pedw_clearance_append_dt IS NULL			THEN 12 
					ELSE INCIDENT_TYPE END; 
				


				
COMMIT; 

SELECT INCIDENT_TYPE ,incident_cat, count(DISTINCT alf_e) number_of_patients
FROM sailw0911v.vac17_cohort
GROUP BY INCIDENT_TYPE ,incident_cat;


