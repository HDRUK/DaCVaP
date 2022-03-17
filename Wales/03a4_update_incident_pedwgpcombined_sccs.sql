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
/*
ALTER TABLE sailw0911v.vac17_cohort
ADD COLUMN INCIDENT_SCCS_DT  	date
ADD COLUMN INCIDENT_SCCS_CAT	varchar(225)
ADD COLUMN INCIDENT_SCCS_TYPE 	integer;
*/
UPDATE sailw0911v.vac17_cohort
SET
INCIDENT_SCCS_DT	=NULL, 
INCIDENT_SCCS_CAT	=NULL,  
INCIDENT_SCCS_TYPE	=NULL;

UPDATE sailw0911v.vac17_cohort
SET
INCIDENT_SCCS_DT	=INCIDENT_DT, 
INCIDENT_SCCS_CAT	=INCIDENT_CAT, 
INCIDENT_SCCS_TYPE	=INCIDENT_TYPE;


COMMIT;

--vte
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(vte) vte FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_VTE_DT AS vte, 'pedw' AS SOURCE,pre_clearance_vte_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_VTE_DT,PEDW_CLEARANCE_VTE_DT, INCIDENT_SCCS_DT,pre_clearance_vte_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_VTE_DT IS NOT NULL 
			)
				
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_VTE_DT AS vte, 'gp',pre_clearance_vte_dt AS SOURCE FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_VTE_DT,PEDW_CLEARANCE_VTE_DT, INCIDENT_SCCS_DT ,pre_clearance_vte_dt	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_VTE_DT IS NOT NULL 
			)
			)
			WHERE vte BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_clearance_vte_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.vte,
a.incident_sccs_cat='Venous thromboembolic events (excluding CSVT)',
a.incident_sccs_type=1;
	
--csvt
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(csvt) csvt FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_csvt_DT AS csvt, 'pedw' AS SOURCE,pre_clearance_csvt_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_csvt_DT,PEDW_CLEARANCE_csvt_DT, INCIDENT_SCCS_DT ,pre_clearance_csvt_dt	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_CSVT_DT IS NOT NULL 
			)
				
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_csvt_DT AS csvt, 'gp' AS SOURCE,pre_clearance_csvt_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_csvt_DT,PEDW_CLEARANCE_csvt_DT, INCIDENT_SCCS_DT ,pre_clearance_csvt_dt
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_csvt_DT IS NOT NULL 
			)
			)
			WHERE csvt BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_clearance_csvt_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.csvt,
a.incident_sccs_cat='CSVT',
a.incident_sccs_type=2;
	
--HAEMORRHAGE
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(HAEMORRHAGE) HAEMORRHAGE FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_HAEMORRHAGE_DT AS HAEMORRHAGE, 'pedw' AS SOURCE, pre_clearance_haemorrhage_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_HAEMORRHAGE_DT,PEDW_CLEARANCE_HAEMORRHAGE_DT, INCIDENT_SCCS_DT, pre_clearance_haemorrhage_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL 
			)
				
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_HAEMORRHAGE_DT AS HAEMORRHAGE, 'gp' AS SOURCE, pre_clearance_haemorrhage_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_HAEMORRHAGE_DT,PEDW_CLEARANCE_HAEMORRHAGE_DT, INCIDENT_SCCS_DT, pre_clearance_haemorrhage_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL 
			)
			)
			WHERE HAEMORRHAGE BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_clearance_haemorrhage_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.HAEMORRHAGE,
a.incident_sccs_cat='Hemorrhagic events',
a.incident_sccs_type=3;

	
--thrombocytopenia
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(thrombocytopenia) thrombocytopenia FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_thrombocytopenia_DT AS thrombocytopenia, 'pedw' AS SOURCE, pre_clearance_thrombocytopenia_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_thrombocytopenia_DT,PEDW_CLEARANCE_thrombocytopenia_DT, INCIDENT_SCCS_DT, pre_clearance_thrombocytopenia_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_thrombocytopenia_DT IS NOT NULL 
			)
				
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_thrombocytopenia_DT AS thrombocytopenia, 'gp' AS SOURCE, pre_clearance_thrombocytopenia_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_thrombocytopenia_DT,PEDW_CLEARANCE_thrombocytopenia_DT, INCIDENT_SCCS_DT,pre_clearance_thrombocytopenia_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_thrombocytopenia_DT IS NOT NULL 
			)
			)
			WHERE thrombocytopenia BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_clearance_thrombocytopenia_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.thrombocytopenia,
a.incident_sccs_cat='Thrombocytopenia (excluding ITP)',
a.incident_sccs_type=4;

--itp
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(itp) itp FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_itp_DT AS itp, 'pedw' AS SOURCE, pre_clearance_ITP_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_itp_DT,PEDW_CLEARANCE_itp_DT, INCIDENT_SCCS_DT,pre_clearance_ITP_dt
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_itp_DT IS NOT NULL 
			)
				
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_itp_DT AS itp, 'gp' AS SOURCE,pre_clearance_ITP_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_itp_DT,PEDW_CLEARANCE_itp_DT, INCIDENT_SCCS_DT,pre_clearance_ITP_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_itp_DT IS NOT NULL 
			)
			)
			WHERE itp BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_clearance_ITP_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.itp,
a.incident_sccs_cat='Idiopathic thrombocytopenic purpura',
a.incident_sccs_type=5;
	
--at
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(at) at FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_at_DT AS at, 'pedw' AS SOURCE,pre_clearance_at_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_at_DT,PEDW_CLEARANCE_at_DT, INCIDENT_SCCS_DT,pre_clearance_at_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_at_DT IS NOT NULL 
			)
				
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_at_DT AS at, 'gp' AS SOURCE,pre_clearance_at_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_at_DT,PEDW_CLEARANCE_at_DT, INCIDENT_SCCS_DT,pre_clearance_at_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_at_DT IS NOT NULL 
			)
			)
			WHERE at BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_clearance_at_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.at,
a.incident_sccs_cat='Arterial Thrombosis',
a.incident_sccs_type=6;

--isch_stroke
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(isch_stroke) isch_stroke FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_isch_stroke_DT AS isch_stroke, 'pedw' AS SOURCE,pre_CLEARANCE_ISCH_STROKE_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_isch_stroke_DT,PEDW_CLEARANCE_isch_stroke_DT, INCIDENT_SCCS_DT,pre_CLEARANCE_ISCH_STROKE_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_isch_stroke_DT IS NOT NULL 
			)
			/*	
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_isch_stroke_DT AS isch_stroke, 'gp' AS SOURCE FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_isch_stroke_DT,PEDW_CLEARANCE_isch_stroke_DT, INCIDENT_SCCS_DT 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_isch_stroke_DT IS NOT NULL 
			)
			*/
			)
			WHERE isch_stroke BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_CLEARANCE_ISCH_STROKE_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.isch_stroke,
a.incident_sccs_cat='Ischeamic Stroke',
a.incident_sccs_type=7;


--mi
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(mi) mi FROM (
			SELECT ALF_E ,Pedw_CLEARANCE_mi_DT AS mi, 'pedw' AS SOURCE,pre_CLEARANCE_mi_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_mi_DT,PEDW_CLEARANCE_mi_DT, INCIDENT_SCCS_DT,pre_CLEARANCE_mi_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_mi_DT IS NOT NULL 
			)
				
			UNION 
			
			SELECT ALF_E ,GP_CLEARANCE_mi_DT AS mi, 'gp' AS SOURCE,pre_CLEARANCE_mi_dt FROM 
			(
			SELECT DISTINCT ALF_E , GP_CLEARANCE_mi_DT,PEDW_CLEARANCE_mi_DT, INCIDENT_SCCS_DT,pre_CLEARANCE_mi_dt 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			GP_CLEARANCE_mi_DT IS NOT NULL 
			)
			)
			WHERE mi BETWEEN '2020-08-25' AND '2020-12-06'
			AND 
			pre_CLEARANCE_mi_dt IS NULL 
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.mi,
a.incident_sccs_cat='Myocardial Infarction',
a.incident_sccs_type=8;

--on the final run negative control is: HIP fracture and positive control is: Anaphylaxis so didn't update details of the rest
--coliac
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(coliac) coliac FROM (
			SELECT DISTINCT ALF_E , PEDW_CLEARANCE_coliac_DT coliac , INCIDENT_SCCS_DT 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_coliac_DT IS NOT NULL 
			)
			WHERE coliac BETWEEN '2020-08-25' AND '2020-12-06'
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.coliac,
a.incident_sccs_cat='Coeliac disease',
a.incident_sccs_type=9;

--anaph
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(record_dt) anaph FROM 
			(
		      (
				SELECT
				DISTINCT ALF_E , 
				MIN(admis_dt) record_dt
				FROM
				SAILw0911V.vac17_pedw_pos_neg_controls
				WHERE
				admis_dt BETWEEN '2020-08-25' AND '2020-12-06'
				AND 
				icd_ID =9
				GROUP BY ALF_E, icd_ID  
				ORDER BY ALF_E
			  )
				UNION
			  (
				SELECT 
					DISTINCT ALF_E , VACC_DATE 
				FROM 
--				SELECT DISTINCT VACC_ADVERSE_REACTION_IND , VACC_ADVERSE_REACTION_CD, count(DISTINCT ALF_E)
					sailw0911v.RRDA_CVVD_20210731
				WHERE 
				VACC_ADVERSE_REACTION_IND IN ('Y')-- , VACC_ADVERSE_REACTION_CD
				and
				VACC_DATE  BETWEEN '2020-08-25' AND '2020-12-06'
			  )	
			)GROUP BY alf_e
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.anaph,
a.incident_sccs_cat='Anaphylactic shock',
a.incident_sccs_type=10;

--taking apahylactic days 1 day forward as it's recorded on vacc date:
UPDATE SAILW0911V.vac17_COHORT SET 
incident_sccs_dt=CASE 
				WHEN incident_sccs_type=10 
				THEN incident_sccs_dt + 1 DAY 
				ELSE incident_sccs_dt END; 
--hipfract
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(hipfract) hipfract FROM 
			(
			SELECT DISTINCT ALF_E ,PEDW_CLEARANCE_hipfract_DT hipfract, INCIDENT_SCCS_DT 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_hipfract_DT IS NOT NULL 
	
			)
			WHERE hipfract BETWEEN '2020-08-25' AND '2020-12-06'
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.hipfract,
a.incident_sccs_cat='Hip fracture',
a.incident_sccs_type=11;

--append
MERGE INTO SAILW0911V.vac17_COHORT a 
USING 
	(
			SELECT ALF_E , min(append) append FROM 
			(
			SELECT DISTINCT ALF_E ,PEDW_CLEARANCE_append_DT append, INCIDENT_SCCS_DT 	
			FROM SAILW0911V.vac17_COHORT  
			WHERE
			PEDW_CLEARANCE_append_DT IS NOT NULL 
	
			)
			WHERE append BETWEEN '2020-08-25' AND '2020-12-06'
			GROUP BY ALF_E 
	) b 
ON 
a.alf_e=b.alf_e
WHEN MATCHED THEN 
UPDATE SET 
a.incident_sccs_dt=b.append,
a.incident_sccs_cat='Appendicitis',
a.incident_sccs_type=12;

SELECT count(DISTINCT ALF_E ) FROM sailw0911v.VAC17_COHORT vc 			
WHERE INCIDENT_SCCS_DT ='2020-08-25';

COMMIT; 

SELECT INCIDENT_sccs_TYPE ,incident_sccs_cat, count(DISTINCT alf_e) number_of_patients
FROM sailw0911v.vac17_cohort
GROUP BY INCIDENT_sccs_TYPE ,incident_sccs_cat;
