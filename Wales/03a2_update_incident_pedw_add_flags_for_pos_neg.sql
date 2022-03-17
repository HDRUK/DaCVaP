-----------------------------------------------------------
--vac17: 	Vaccine Safety
--BY:		fatemeh.torabi@swansea.ac.uk
--DT: 		2021-11-02
--aim:		to add columns for first incident after cohort start
-----------------------------------------------------------
--deactivating transaction log for this part of script to avoid errors on long updates:
alter table sailw0911v.vac17_cohort activate not logged INITIALLY;

-----------------------------------------------------------
--clearance-vaccination flags
-----------------------------------------------------------
--clearance window:		06-Dec_2019 to 06-Dec-2020
--clearance : 2019-12-06
-----------------------------------------------------------

ALTER TABLE sailw0911v.vac17_cohort
ADD COLUMN pedw_clearance_append_dt date
ADD COLUMN pedw_clearance_hipfract_dt date
ADD COLUMN pedw_clearance_coliac_dt date
ADD COLUMN pedw_clearance_anaph_dt date;

UPDATE sailw0911v.vac17_cohort
SET
pedw_clearance_append_dt 			=NULL, 
pedw_clearance_hipfract_dt 			=NULL, 
pedw_clearance_coliac_dt 			=NULL,  
pedw_clearance_anaph_dt				=NULL;
COMMIT;

SELECT
DISTINCT icd_cat, icd_id
FROM
SAILw0911V.VAC17_pedw_pos_neg_controls;
		
--coeliac---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_pos_neg_controls
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =8 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_coliac_dt 		= B.FIRST_INCD;
COMMIT;

--anaphylactic---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT
	DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD FROM (
				(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) admis_dt
				FROM
					SAILw0911V.VAC17_pedw_pos_neg_controls
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =9
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
				)
			UNION
				(
				SELECT 
				DISTINCT ALF_E , VACC_DATE 
				FROM 
				sailw0911v.RRDA_CVVD_20211231 
				WHERE 
				VACC_ADVERSE_REACTION_IND IN ('Y')
				AND 
				vacc_adverse_reaction_cd IN ('4','5')
				and
				VACC_DATE  BETWEEN '2019-12-06' AND '2020-12-06'
				)	
	)GROUP BY alf_e
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_anaph_dt 		= B.FIRST_INCD;
COMMIT;

--hip fracture---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_pos_neg_controls
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =10
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_hipfract_dt 		= B.FIRST_INCD;
COMMIT;
--append---------------------------
--we added the actual reaction to each vaccine recorded at the vaccination centers to this anaphylaxis group as positive control
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_pos_neg_controls
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =11 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_append_dt 		= B.FIRST_INCD;
COMMIT;

/*

	SELECT 'COL' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE pedw_clearance_coliac_dt IS NOT NULL 
	union 
	SELECT 'ANAPH' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE pedw_CLEARANCE_anaph_DT IS NOT NULL 

*/

-----------------------------------------------------------
--single flags: post vacc: any event after 2020-12-07
-----------------------------------------------------------

ALTER TABLE sailw0911v.vac17_cohort
ADD COLUMN pedw_post_append_dt date
ADD COLUMN pedw_post_hipfract_dt date
ADD COLUMN pedw_post_coliac_dt date
ADD COLUMN pedw_post_anaph_dt date;


UPDATE sailw0911v.vac17_cohort
SET
pedw_post_append_dt  			=NULL,
pedw_post_hipfract_dt  			=NULL,
pedw_post_coliac_dt 			=NULL,  
pedw_post_anaph_dt				=NULL;
COMMIT;

/*
 * 9	Anaphylactic
 * 8	Coeliac disease
 */
---coliac
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					icd_id,
					MIN(admis_dt) FIRST_INCD
					FROM
					SAILw0911V.vac17_pedw_pos_neg_controls
					WHERE
						admis_dt >= '2020-12-07'
					AND 
						icd_ID =8 
					GROUP BY ALF_E, icd_ID  
					ORDER BY ALF_E
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_coliac_dt 	= b.FIRST_INCD;
COMMIT;

---anaph   -------------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
			SELECT DISTINCT ALF_E , min(record_dt) first_incd FROM (
		      (
				SELECT
					DISTINCT ALF_E , 
				--	icd_id,
					MIN(admis_dt) record_dt
					FROM
					SAILw0911V.vac17_pedw_pos_neg_controls
					WHERE
						admis_dt >= '2020-12-07'
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
				sailw0911v.RRDA_CVVD_20211231 
				WHERE 
				VACC_ADVERSE_REACTION_IND IN ('Y')
				AND 
				vacc_adverse_reaction_cd IN ('4','5')
				and
				VACC_DATE   >= '2020-12-07'
				)	
					)GROUP BY alf_e
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_anaph_dt 	= b.FIRST_INCD;
COMMIT;

---hip fracture
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					icd_id,
					MIN(admis_dt) FIRST_INCD
					FROM
					SAILw0911V.vac17_pedw_pos_neg_controls
					WHERE
						admis_dt >= '2020-12-07'
					AND 
						icd_ID =10
					GROUP BY ALF_E, icd_ID  
					ORDER BY ALF_E
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_hipfract_dt 	= b.FIRST_INCD;
COMMIT;

---append   -------------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					icd_id,
					MIN(admis_dt) FIRST_INCD
					FROM
					SAILw0911V.vac17_pedw_pos_neg_controls
					WHERE
						admis_dt >= '2020-12-07'
					AND 
						icd_ID =11
					GROUP BY ALF_E, icd_ID  
					ORDER BY ALF_E
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_append_dt 	= b.FIRST_INCD;
COMMIT;

--adding a column of all type clearance incident events:
--the rest of event were done in 3a2-pedw script so here only adding the controls:
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_coliac_dt 			IS NOT NULL AND pedw_clearance_coliac_dt IS NULL 			THEN pedw_post_coliac_dt
					ELSE pedw_INCIDENT_DT END; 
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_anaph_dt 			IS NOT NULL AND pedw_clearance_anaph_dt IS NULL				THEN pedw_post_anaph_dt
					ELSE pedw_INCIDENT_DT  END; 
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_hipfract_dt 			IS NOT NULL AND pedw_clearance_hipfract_dt IS NULL			THEN pedw_post_hipfract_dt					
					ELSE pedw_INCIDENT_DT  END; 
UPDATE SAILW0911V.vac17_COHORT 

SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_append_dt 			IS NOT NULL AND pedw_clearance_append_dt IS NULL			THEN pedw_post_append_dt					
					ELSE pedw_INCIDENT_DT  END; 
				
				
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_coliac_dt 			IS NOT NULL AND pedw_clearance_coliac_dt IS NULL 			THEN 9
					ELSE pedw_INCIDENT_TYPE  END; 

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_anaph_dt 			IS NOT NULL AND pedw_clearance_anaph_dt IS NULL				THEN 10
					ELSE pedw_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_hipfract_dt 			IS NOT NULL AND pedw_clearance_hipfract_dt IS NULL			THEN 11
					ELSE pedw_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_append_dt 			IS NOT NULL AND pedw_clearance_append_dt IS NULL			THEN 12					
					ELSE pedw_INCIDENT_TYPE END; 
				
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_coliac_dt 			IS NOT NULL AND pedw_clearance_coliac_dt IS NULL 			THEN 'Coeliac disease'
					ELSE pedw_INCIDENT_CAT END;

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_anaph_dt 			IS NOT NULL AND pedw_clearance_anaph_dt IS NULL				THEN 'Anaphylactic shock'
					ELSE pedw_INCIDENT_CAT END;
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_hipfract_dt 			IS NOT NULL AND pedw_clearance_hipfract_dt IS NULL			THEN 'Hip fracture'
					ELSE pedw_INCIDENT_CAT END;
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_append_dt 			IS NOT NULL AND pedw_clearance_append_dt IS NULL			THEN 'Appendecitis'	
					ELSE pedw_INCIDENT_CAT END;
				
COMMIT; 


SELECT pedw_incident_cat, count(DISTINCT alf_e) number_of_patients
FROM sailw0911v.vac17_cohort
GROUP BY pedw_incident_cat;

SELECT pedw_incident_type, count(DISTINCT alf_e) number_of_patients
FROM sailw0911v.vac17_cohort
GROUP BY pedw_incident_type;