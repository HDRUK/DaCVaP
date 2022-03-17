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
--clearance window:		06-Dec_2019 to 06-Dec-2020
--pre vac clearance: 	2020-08-25
-----------------------------------------------------------
UPDATE sailw0911v.vac17_cohort
SET
gp_clearance_vte_dt 			=NULL,  
gp_clearance_csvt_dt			=NULL, 
gp_clearance_haemorrhage_dt		=NULL,
gp_clearance_thrombocytopenia_dt=NULL, 
gp_clearance_ITP_dt				=NULL,
gp_clearance_at_dt				=NULL,
gp_clearance_ISCH_STROKE_dt		=NULL,
gp_clearance_mi_dt				=NULL;
--for mi we only look at hospitalisations
COMMIT;

--VTE---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =1 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_vte_dt 		= B.FIRST_INCD;
COMMIT;

--CSVT---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =2 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_csvt_dt 		= B.FIRST_INCD;
COMMIT;

--Hemorrhage---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =3
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_haemorrhage_dt	= B.FIRST_INCD;
COMMIT;

--Thrombocytopenia---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =4
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_thrombocytopenia_dt	= B.FIRST_INCD;
COMMIT;

--ITP---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =5
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_ITP_dt	= B.FIRST_INCD;
COMMIT;

--AT---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =6
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_at_dt	= B.FIRST_INCD;
COMMIT;

--ISCH_STROKE---------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =7
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_isch_stroke_dt	= B.FIRST_INCD;
COMMIT;

--MI---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT  BETWEEN '2019-12-06' AND '2020-12-06'
				AND 
 					READ_ID =8
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.gp_clearance_mi_dt	= B.FIRST_INCD;
COMMIT;

/*
	SELECT 'VTE' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE gp_clearance_vte_dt IS NOT NULL 
	UNION 
	SELECT 'CSVT' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_CSVT_DT IS NOT NULL 
	UNION 
	SELECT 'HEM' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL 
	UNION 
	SELECT 'TCP' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_THROMBOCYTOPENIA_DT IS NOT NULL 
	UNION 
	SELECT 'ITP' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_ITP_DT IS NOT NULL 
	UNION 
	SELECT 'ISCH_ST' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_ISCH_STROKE_DT IS NOT NULL 
	UNION 
	SELECT 'MI' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE GP_CLEARANCE_MI_DT IS NOT NULL 

*/

-----------------------------------------------------------
--single flags: post vacc: any event after 2020-12-07
-----------------------------------------------------------
UPDATE sailw0911v.vac17_cohort
SET 
	gp_post_vte_dt 								= NULL ,
	gp_post_csvt_dt					 			= NULL ,
	gp_post_haemorrhage_dt			 			= NULL ,
	gp_post_thrombocytopenia_dt		 			= NULL ,
	gp_post_ITP_dt 					 			= NULL ,
	gp_post_AT_dt 					 			= NULL ,
	gp_post_ISCH_STROKE_dt						= NULL ,
	gp_post_mi_dt								= NULL ;
COMMIT;

---venous thromboembolic events (excluding csvt)   --------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
					FROM
					SAILw0911V.vac17_GP_CASES
					WHERE
						EVENT_DT >= '2020-12-07'
					AND 
						READ_ID =1 
					GROUP BY ALF_E, READ_ID  
					ORDER BY ALF_E
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_vte_dt 	= b.FIRST_INCD;
COMMIT;

---csvt   -------------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
					FROM
					SAILw0911V.vac17_GP_CASES
					WHERE
						EVENT_DT >= '2020-12-07'
					AND 
						READ_ID =2 
					GROUP BY ALF_E, READ_ID 
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_csvt_dt 	= b.FIRST_INCD;
COMMIT;

---haemorrhage   ------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
					FROM
					SAILw0911V.vac17_GP_CASES
					WHERE
						EVENT_DT >= '2020-12-07'
					AND 
						READ_ID =3 
					GROUP BY ALF_E, READ_ID  
					ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_haemorrhage_dt 	= b.FIRST_INCD;
COMMIT;
---Thrombocytopenia (excluding ITP)   ---------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
				FROM
				SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT >= '2020-12-07'
				AND 
					READ_ID =4 
				GROUP BY ALF_E, READ_ID 
				ORDER BY ALF_E
		) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_thrombocytopenia_dt 	= b.FIRST_INCD;
COMMIT;

---ITP   --------------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
				FROM
				SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT >= '2020-12-07'
				AND 
					READ_ID =5
				GROUP BY ALF_E, READ_ID 
				ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_ITP_dt 	= b.FIRST_INCD;
COMMIT;

---AT   --------------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
				FROM
				SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT >= '2020-12-07'
				AND 
					READ_ID =6
				GROUP BY ALF_E, READ_ID 
				ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_AT_dt 	= b.FIRST_INCD;
COMMIT;

---ISCH STROKE   --------------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
				FROM
				SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT >= '2020-12-07'
				AND 
					READ_ID =7
				GROUP BY ALF_E, READ_ID 
				ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_ISCH_STROKE_dt 	= b.FIRST_INCD;
COMMIT;

---MI   --------------------------------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
--check on row duplication
--SELECT COUNT(DISTINCT ALF_E), COUNT(*) FROM
		(
				SELECT
					DISTINCT ALF_E , 
					read_id,
					MIN(EVENT_DT) FIRST_INCD
				FROM
				SAILw0911V.vac17_GP_CASES
				WHERE
					EVENT_DT >= '2020-12-07'
				AND 
					READ_ID =8
				GROUP BY ALF_E, READ_ID 
				ORDER BY ALF_E
	) B
ON
A.ALF_E=B.ALF_E
WHEN MATCHED THEN
UPDATE SET
a.gp_post_MI_dt 	= b.FIRST_INCD;
COMMIT;

--adding a column of all type clearance incident events:
-----------------------------------
--date
-----------------------------------
UPDATE SAILW0911V.vac17_COHORT 
SET 
gp_INCIDENT_DT = NULL,
GP_INCIDENT_CAT= NULL,
GP_INCIDENT_TYPE = NULL;

UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 
					WHEN gp_post_vte_dt 				IS NOT NULL AND gp_clearance_vte_dt IS NULL THEN gp_post_vte_dt
					ELSE gp_INCIDENT_DT END; 

UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 			
					WHEN gp_post_csvt_dt				IS NOT NULL AND gp_clearance_csvt_dt IS NULL THEN gp_post_csvt_dt
					ELSE gp_INCIDENT_DT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 					
					WHEN gp_post_haemorrhage_dt			IS NOT NULL AND gp_clearance_haemorrhage_dt IS NULL THEN gp_post_haemorrhage_dt
					ELSE gp_INCIDENT_DT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 					
					WHEN gp_post_thrombocytopenia_dt	IS NOT NULL AND gp_clearance_thrombocytopenia_dt IS NULL THEN gp_post_thrombocytopenia_dt
					ELSE gp_INCIDENT_DT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 					
					WHEN gp_post_ITP_dt 				IS NOT NULL AND gp_clearance_ITP_dt IS NULL THEN gp_post_ITP_dt
					ELSE gp_INCIDENT_DT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 					
					WHEN gp_post_AT_dt	 				IS NOT NULL AND gp_clearance_AT_dt IS NULL THEN gp_post_AT_dt
					ELSE gp_INCIDENT_DT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 					
					WHEN gp_post_ISCH_STROKE_dt	 		IS NOT NULL AND gp_clearance_ISCH_STROKE_dt IS NULL THEN gp_post_ISCH_STROKE_dt
					ELSE gp_INCIDENT_DT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_DT = CASE 					
					WHEN gp_post_MI_dt	 				IS NOT NULL AND gp_clearance_MI_dt IS NULL THEN gp_post_MI_dt
					ELSE gp_INCIDENT_DT END; 
-----------------------------------
--type
-----------------------------------
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_vte_dt 				IS NOT NULL AND gp_clearance_vte_dt IS NULL 				THEN 1
					ELSE gp_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_csvt_dt				IS NOT NULL AND gp_clearance_csvt_dt IS NULL 				THEN 2
					ELSE gp_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_haemorrhage_dt			IS NOT NULL AND gp_clearance_haemorrhage_dt IS NULL 		THEN 3
					ELSE gp_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_thrombocytopenia_dt	IS NOT NULL AND gp_clearance_thrombocytopenia_dt IS NULL	THEN 4
					ELSE gp_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_ITP_dt 				IS NOT NULL AND gp_clearance_ITP_dt IS NULL 				THEN 5 
					ELSE gp_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_AT_dt	 				IS NOT NULL AND gp_clearance_AT_dt IS NULL 					THEN 6
					ELSE gp_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_ISCH_STROKE_dt	 		IS NOT NULL AND gp_clearance_ISCH_STROKE_dt IS NULL 		THEN 7
					ELSE gp_INCIDENT_TYPE END; 
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_TYPE = CASE 
					WHEN gp_post_MI_dt	 				IS NOT NULL AND gp_clearance_MI_dt IS NULL 					THEN 8					
					ELSE gp_INCIDENT_TYPE END; 
-----------------------------------
--cat
-----------------------------------
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN gp_post_vte_dt 				IS NOT NULL AND gp_clearance_vte_dt IS NULL 				THEN 'Venous thromboembolic events (excluding CSVT)'
					ELSE gp_INCIDENT_CAT END;					
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN gp_post_csvt_dt				IS NOT NULL AND gp_clearance_csvt_dt IS NULL				THEN 'CSVT'
					ELSE gp_INCIDENT_CAT END;					
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN gp_post_haemorrhage_dt			IS NOT NULL AND gp_clearance_haemorrhage_dt IS NULL			THEN 'Hemorrhagic events'
					ELSE gp_INCIDENT_CAT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN gp_post_thrombocytopenia_dt	IS NOT NULL AND gp_clearance_thrombocytopenia_dt IS NULL	THEN 'Thrombocytopenia (excluding ITP)'
					ELSE gp_INCIDENT_CAT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN gp_post_ITP_dt 				IS NOT NULL AND gp_clearance_ITP_dt IS NULL 				THEN 'Idiopathic thrombocytopenic purpura'
					ELSE gp_INCIDENT_CAT END;					
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN gp_post_AT_dt 				    IS NOT NULL AND gp_clearance_AT_dt IS NULL 				    THEN 'Arterial Thrombosis'
					ELSE gp_INCIDENT_CAT END;					
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN GP_POST_ISCH_STROKE_DT 		IS NOT NULL AND GP_CLEARANCE_ISCH_STROKE_DT IS NULL			THEN 'Ischeamic Stroke'
					ELSE gp_INCIDENT_CAT END;
UPDATE SAILW0911V.vac17_COHORT 
SET gp_INCIDENT_CAT = CASE 
					WHEN gp_post_MI_dt 				    IS NOT NULL AND gp_clearance_MI_dt IS NULL 				    THEN 'Myocardial Infarction'
					ELSE gp_INCIDENT_CAT END;
					
COMMIT; 

SELECT gp_incident_cat, count(DISTINCT alf_e) number_of_patients
FROM sailw0911v.vac17_cohort
GROUP BY gp_incident_cat;