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
/*
ALTER TABLE sailw0911v.vac17_cohort
ADD COLUMN pre_clearance_vte_dt 			DATE  
ADD COLUMN pre_clearance_csvt_dt			DATE
ADD COLUMN pre_clearance_haemorrhage_dt		DATE
ADD COLUMN pre_clearance_thrombocytopenia_dt DATE
ADD COLUMN pre_clearance_ITP_dt				DATE
ADD COLUMN pre_clearance_at_dt				DATE
ADD COLUMN pre_CLEARANCE_ISCH_STROKE_dt		DATE
ADD COLUMN pre_clearance_mi_dt				DATE
ADD COLUMN pre_clearance_hip_dt				DATE
ADD COLUMN pre_clearance_anaph_dt			DATE;
*/
UPDATE sailw0911v.vac17_cohort
SET
pre_clearance_vte_dt 				=NULL,  
pre_clearance_csvt_dt				=NULL, 
pre_clearance_haemorrhage_dt		=NULL,
pre_clearance_thrombocytopenia_dt	=NULL, 
pre_clearance_ITP_dt				=NULL,
pre_clearance_at_dt					=NULL,
pre_CLEARANCE_ISCH_STROKE_dt		=NULL,
pre_clearance_mi_dt					=NULL,
pre_clearance_hip_dt				=NULL,
pre_clearance_anaph_dt				=NULL;

COMMIT;

--VTE---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =1 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =1 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_vte_dt 		= B.FIRST_INCD;
COMMIT;

--CSVT---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =2 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =2 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_csvt_dt 		= B.FIRST_INCD;
COMMIT;

--Hemorrhage---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =3
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =3 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_haemorrhage_dt 		= B.FIRST_INCD;
COMMIT;

--Thrombocytopenia---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =4
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =4 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_thrombocytopenia_dt		= B.FIRST_INCD;
COMMIT;

--ITP---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =5
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =5
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_ITP_dt		= B.FIRST_INCD;
COMMIT;

--at---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =6
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =6
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_at_dt	= B.FIRST_INCD;
COMMIT;

--isch stroke---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =7
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =7
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_CLEARANCE_ISCH_STROKE_dt	= B.FIRST_INCD;
COMMIT;

--mi---------------------------
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
		(
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_pedw_CASES
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =8
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
		)
	UNION 
		(
				SELECT
					DISTINCT ALF_E , MIN(EVENT_DT) FIRST_INCD
				FROM
					SAILw0911V.VAC17_GP_CASES
				WHERE
					EVENT_DT  < '2020-08-25'
				AND 
 					READ_ID =8
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E		
		)
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_mi_dt	= B.FIRST_INCD;
COMMIT;

--Anaphylactic---------------------------
/*
Anaphylactic	9
Coeliac disease	8
Appendicitis	11
hip fracture	10
*/
MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_PEDW_POS_NEG_CONTROLS 
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =9 
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_anaph_dt	= B.FIRST_INCD;
COMMIT;

MERGE INTO sailw0911v.vac17_cohort A
USING
	(
	SELECT DISTINCT ALF_E , MIN(FIRST_INCD)	FIRST_INCD
	FROM 
	(	
				SELECT
					DISTINCT ALF_E , MIN(admis_dt) FIRST_INCD
				FROM
					SAILw0911V.VAC17_PEDW_POS_NEG_CONTROLS 
				WHERE
					admis_dt  < '2020-08-25' 
				AND 
 					icd_ID =10
				GROUP BY
					ALF_E
				ORDER BY
					ALF_E
	)GROUP BY ALF_E 
	) B
ON
	A.ALF_E = B.ALF_E
WHEN MATCHED THEN
UPDATE SET
	A.pre_clearance_hip_dt	= B.FIRST_INCD;
COMMIT;

/*
	SELECT 'VTE' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_Vte_DT IS NOT NULL 
	UNION 
	SELECT 'CSVT' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_CSVT_DT IS NOT NULL 
	UNION 
	SELECT 'HEM' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL 
	UNION 
	SELECT 'TCP' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_THROMBOCYTOPENIA_DT IS NOT NULL 
	UNION 
	SELECT 'ITP' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_ITP_DT IS NOT NULL 
	UNION 
	SELECT 'ISCH_STROKE' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_ISCH_STROKE_DT IS NOT NULL 
	UNION 
	SELECT 'MI' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_MI_DT IS NOT NULL 
	UNION 
	SELECT 'HIP' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_HIP_DT IS NOT NULL 
	UNION 
	SELECT 'ANAPH' EVENT, COUNT(DISTINCT ALF_E) ALF_CNT  FROM SAILW0911V.vac17_COHORT WHERE PRE_CLEARANCE_ANAPH_DT IS NOT NULL 

*/
