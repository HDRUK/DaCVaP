-----------------------------------------------------------
--vac17: 	Vaccine Safety
--BY:		fatemeh.torabi@swansea.ac.uk
--DT: 		2021-04-08
--aim:		to add columns for first incident after cohort start
-----------------------------------------------------------
--deactivating transaction log for this part of script to avoid errors on long updates:
alter table sailw0911v.vac17_cohort activate not logged INITIALLY;

-----------------------------------------------------------
--clearance-vaccination flags
-----------------------------------------------------------
--clearance window:		01-Sep_2019 to 06-Dec-2020
-----------------------------------------------------------
UPDATE sailw0911v.vac17_cohort
SET
pedw_clearance_vte_dt 				=NULL,  
pedw_clearance_csvt_dt				=NULL, 
pedw_clearance_haemorrhage_dt		=NULL,
pedw_clearance_thrombocytopenia_dt	=NULL, 
pedw_clearance_ITP_dt				=NULL,
pedw_clearance_at_dt				=NULL,
PEDW_CLEARANCE_ISCH_STROKE_dt		=NULL,
pedw_clearance_mi_dt				=NULL;
COMMIT;

--VTE---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =1 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_vte_dt 		= B.FIRST_INCD;
COMMIT;

--CSVT---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =2 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_csvt_dt 		= B.FIRST_INCD;
COMMIT;

--Hemorrhage---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =3
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_haemorrhage_dt	= B.FIRST_INCD;
COMMIT;

--Thrombocytopenia---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =4
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_thrombocytopenia_dt	= B.FIRST_INCD;
COMMIT;

--ITP---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =5
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_ITP_dt	= B.FIRST_INCD;
COMMIT;

--at---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =6
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pedw_clearance_at_dt	= B.FIRST_INCD;
COMMIT;

--isch stroke---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					icd_ID =7
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.PEDW_CLEARANCE_ISCH_STROKE_DT = B.FIRST_INCD;
COMMIT;

--mi---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.vac17_pedw_CASES
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
	A.PEDW_CLEARANCE_MI_DT = B.FIRST_INCD;
COMMIT;

/*
	SELECT 'VTE' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_Vte_DT IS NOT NULL 
	UNION 
	SELECT 'CSVT' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_CSVT_DT IS NOT NULL 
	UNION 
	SELECT 'HEM' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL 
	UNION 
	SELECT 'TCP' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_THROMBOCYTOPENIA_DT IS NOT NULL 
	UNION 
	SELECT 'ITP' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_ITP_DT IS NOT NULL 
	UNION 
	SELECT 'ISCH_STROKE' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_ISCH_STROKE_DT IS NOT NULL 
	UNION 
	SELECT 'MI' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE gp_CLEARANCE_MI_DT IS NOT NULL 

*/

-----------------------------------------------------------
--single flags: post vacc: any event after 2020-12-07
-----------------------------------------------------------
UPDATE sailw0911v.vac17_cohort
SET 
	pedw_post_vte_dt 								= NULL ,
	pedw_post_csvt_dt					 			= NULL ,
	pedw_post_haemorrhage_dt			 			= NULL ,
	pedw_post_thrombocytopenia_dt		 			= NULL ,
	pedw_post_ITP_dt 					 			= NULL ,
	pedw_post_AT_dt 					 			= NULL ,
	PEDW_POST_ISCH_STROKE_DT 			 			= NULL ,
	pedw_post_mi_dt 					 			= NULL ;
COMMIT;

---venous thromboembolic events (excluding csvt)   --------
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
					SAILw0911V.vac17_pedw_CASES
					WHERE
						admis_dt >= '2020-12-07'
					AND 
						icd_ID =1 
					GROUP BY ALF_E, icd_ID  
					ORDER BY ALF_E
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_vte_dt 	= b.FIRST_INCD;
COMMIT;

---csvt   -------------------------------------------------
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
					SAILw0911V.vac17_pedw_CASES
					WHERE
						admis_dt >= '2020-12-07'
					AND 
						icd_ID =2 
					GROUP BY ALF_E, icd_ID 
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_csvt_dt 	= b.FIRST_INCD;
COMMIT;

---haemorrhage   ------------------------------------------
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
					SAILw0911V.vac17_pedw_CASES
					WHERE
						admis_dt >= '2020-12-07'
					AND 
						icd_ID =3 
					GROUP BY ALF_E, icd_ID  
					ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_haemorrhage_dt 	= b.FIRST_INCD;
COMMIT;

---Thrombocytopenia (excluding ITP)   ---------------------
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
				SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt >= '2020-12-07'
				AND 
					icd_ID =4 
				GROUP BY ALF_E, icd_ID 
				ORDER BY ALF_E
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_thrombocytopenia_dt 	= b.FIRST_INCD;
COMMIT;

---ITP   --------------------------------------------------
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
				SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt >= '2020-12-07'
				AND 
					icd_ID =5
				GROUP BY ALF_E, icd_ID 
				ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_ITP_dt 	= b.FIRST_INCD;
COMMIT;


---AT   --------------------------------------------------
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
				SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt >= '2020-12-07'
				AND 
					icd_ID =6
				GROUP BY ALF_E, icd_ID 
				ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.pedw_post_AT_dt 	= b.FIRST_INCD;
COMMIT;

---ischmic stroke   --------------------------------------------------
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
				SAILw0911V.vac17_pedw_CASES
				WHERE
					admis_dt >= '2020-12-07'
				AND 
					icd_ID =7
				GROUP BY ALF_E, icd_ID 
				ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.PEDW_POST_ISCH_STROKE_DT 	= b.FIRST_INCD;
COMMIT;

---mi   --------------------------------------------------
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
				SAILw0911V.vac17_pedw_CASES
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
a.PEDW_POST_MI_DT  	= b.FIRST_INCD;
COMMIT;

--adding a column of all type clearance incident events:
UPDATE sailw0911v.vac17_cohort
SET
pedw_INCIDENT_DT 			=NULL,  
PEDW_INCIDENT_CAT 			=NULL, 
PEDW_INCIDENT_TYPE  		=NULL;

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_vte_dt 				IS NOT NULL AND pedw_clearance_vte_dt IS NULL THEN pedw_post_vte_dt
					ELSE pedw_INCIDENT_DT END; 

				
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_csvt_dt				IS NOT NULL AND pedw_clearance_csvt_dt IS NULL THEN pedw_post_csvt_dt
					ELSE pedw_INCIDENT_DT END; 

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_haemorrhage_dt		IS NOT NULL AND pedw_clearance_haemorrhage_dt IS NULL THEN pedw_post_haemorrhage_dt
					ELSE pedw_INCIDENT_DT END; 

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_thrombocytopenia_dt	IS NOT NULL AND pedw_clearance_thrombocytopenia_dt IS NULL THEN pedw_post_thrombocytopenia_dt
					ELSE pedw_INCIDENT_DT END; 

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_ITP_dt 				IS NOT NULL AND pedw_clearance_ITP_dt IS NULL THEN pedw_post_ITP_dt
					ELSE pedw_INCIDENT_DT END; 

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_AT_dt 				IS NOT NULL AND pedw_clearance_AT_dt IS NULL THEN pedw_post_AT_dt
					ELSE pedw_INCIDENT_DT END; 

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN PEDW_POST_ISCH_STROKE_DT 		IS NOT NULL AND pedw_clearance_ISCH_STROKE_DT IS NULL THEN PEDW_POST_ISCH_STROKE_DT
					ELSE pedw_INCIDENT_DT END; 
				
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_DT = CASE 
					WHEN pedw_post_mi_dt 				IS NOT NULL AND pedw_clearance_mi_dt IS NULL THEN pedw_post_mi_dt
					ELSE pedw_INCIDENT_DT END; 				
-------------------------------------
--type: 				
-------------------------------------
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_vte_dt 				IS NOT NULL AND pedw_clearance_vte_dt IS NULL 				THEN 1
					ELSE pedw_INCIDENT_TYPE END; 

			
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_csvt_dt				IS NOT NULL AND pedw_clearance_csvt_dt IS NULL 				THEN 2
					ELSE pedw_INCIDENT_TYPE END; 
			
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_haemorrhage_dt		IS NOT NULL AND pedw_clearance_haemorrhage_dt IS NULL 		THEN 3
					ELSE pedw_INCIDENT_TYPE END; 
			
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_thrombocytopenia_dt	IS NOT NULL AND pedw_clearance_thrombocytopenia_dt IS NULL	THEN 4
					ELSE pedw_INCIDENT_TYPE END; 
			
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_ITP_dt 				IS NOT NULL AND pedw_clearance_ITP_dt IS NULL 				THEN 5 
					ELSE pedw_INCIDENT_TYPE END; 
			
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_AT_dt 				IS NOT NULL AND pedw_clearance_AT_dt IS NULL 				THEN 6 
					ELSE pedw_INCIDENT_TYPE END; 
			
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN PEDW_POST_ISCH_STROKE_DT 		IS NOT NULL AND pedw_clearance_ISCH_STROKE_DT IS NULL 		THEN 7
					ELSE pedw_INCIDENT_TYPE END; 

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_TYPE = CASE 
					WHEN pedw_post_mi_dt 				IS NOT NULL AND pedw_clearance_mi_dt IS NULL 				THEN 8
					ELSE pedw_INCIDENT_TYPE END; 				
-----------------------------------------
--cat
-----------------------------------------				
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_vte_dt 				IS NOT NULL AND pedw_clearance_vte_dt IS NULL 				THEN 'Venous thromboembolic events (excluding CSVT)'
					ELSE  pedw_INCIDENT_CAT END;
				
UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_csvt_dt				IS NOT NULL AND pedw_clearance_csvt_dt IS NULL				THEN 'CSVT'
					ELSE  pedw_INCIDENT_CAT END;				

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_haemorrhage_dt		IS NOT NULL AND pedw_clearance_haemorrhage_dt IS NULL		THEN 'Hemorrhagic events'
					ELSE  pedw_INCIDENT_CAT END;				

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_thrombocytopenia_dt	IS NOT NULL AND pedw_clearance_thrombocytopenia_dt IS NULL	THEN 'Thrombocytopenia (excluding ITP)'
					ELSE  pedw_INCIDENT_CAT END;				

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_ITP_dt 				IS NOT NULL AND pedw_clearance_ITP_dt IS NULL 				THEN 'Idiopathic thrombocytopenic purpura'
					ELSE  pedw_INCIDENT_CAT END;				

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_AT_dt 				IS NOT NULL AND pedw_clearance_AT_dt IS NULL 			    THEN 'Arterial Thrombosis'
					ELSE  pedw_INCIDENT_CAT END;				

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN PEDW_POST_ISCH_STROKE_DT 		IS NOT NULL AND pedw_clearance_ISCH_STROKE_DT IS NULL  		THEN 'Ischeamic Stroke'
					ELSE  pedw_INCIDENT_CAT END;				

UPDATE SAILW0911V.vac17_COHORT 
SET pedw_INCIDENT_CAT = CASE 
					WHEN pedw_post_mi_dt 				IS NOT NULL AND pedw_clearance_mi_dt IS NULL 				THEN 'Myocardial Infarction'
					ELSE  pedw_INCIDENT_CAT END;				
				
COMMIT; 

SELECT PEDW_INCIDENT_TYPE , PEDW_INCIDENT_CAT , count(DISTINCT alf_e) number_of_patients
FROM sailw0911v.vac17_cohort
GROUP BY PEDW_INCIDENT_TYPE, PEDW_INCIDENT_CAT  ;