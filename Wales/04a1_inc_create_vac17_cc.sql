-----------------------------------------------------------
--vac17: 	Vaccine Safety
--BY:		fatemeh.torabi@swansea.ac.uk
--DT: 		2021-04-08
--aim:		match cases to controls
-----------------------------------------------------------

---------------------------------------------------------------
-- stage 1: get all eligible controls by doing separate inserts
--          for each type of incident
---------------------------------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW0911V.vac17_CC_STAGE1');

CREATE TABLE sailw0911v.vac17_cc_stage1 (
	case_alf             BIGINT NOT NULL,
	control_alf          BIGINT NOT NULL,
	incident_dt          DATE,
	sex                  SMALLINT,
	age_match            VARCHAR(7),
	msoa2011_cd          VARCHAR(10),
	random               DOUBLE,
	rand_row_seq         INTEGER,
	PRIMARY KEY (CASE_ALF, CONTROL_ALF)
) DISTRIBUTE BY HASH (CASE_ALF, CONTROL_ALF);

-- granting access to team mates
GRANT ALL ON TABLE SAILW0911V.vac17_CC_STAGE1 TO ROLE NRDASAIL_SAIL_0911_ANALYST;

--all incident types 

INSERT INTO SAILW0911V.vac17_CC_STAGE1
(
	case_alf,
	control_alf,
	incident_dt,
	sex,
	age_match,
	msoa2011_cd
)
SELECT
	tbl_case.alf_e AS case_alf,
	tbl_control.alf_e AS control_alf,
	tbl_case.incident_dt,
	tbl_control.sex,
	tbl_control.age_matched,
	tbl_control.msoa2011_cd
FROM
( --CASE TABLE
	SELECT DISTINCT
		alf_e,
		incident_dt,
		c20_gndr_cd AS sex,
		age_matched,
		msoa2011_cd
	FROM
		sailw0911v.vac17_cohort
	WHERE
		is_sample = 1
		AND incident_dt IS NOT NULL
--excludin MD vaccines
        AND 
		(
		VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
		or
		VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
		OR 
		VACC_FIRST_DATE IS NULL 
		)
		
) AS tbl_case
INNER JOIN
( -- CONTROL TABLE
	SELECT DISTINCT
		alf_e,
		incident_dt,
		INCIDENT_CAT,
		c20_gndr_cd AS sex,
		age_matched,
		msoa2011_cd
	FROM
		sailw0911v.vac17_cohort
	WHERE
		is_sample = 1
		AND incident_dt IS NULL
) AS tbl_control
ON
	tbl_case.alf_e          != tbl_control.alf_e
	AND tbl_case.sex         = tbl_control.sex
	AND	tbl_case.age_matched = tbl_control.age_matched
	AND	tbl_case.msoa2011_cd = tbl_control.msoa2011_cd
	;


-- give controls a random integer grouped by their case alf

UPDATE SAILW0911V.vac17_CC_STAGE1
SET
	RANDOM = RAND(),
	RAND_ROW_SEQ = ROW_NUMBER() OVER(PARTITION BY case_alf ORDER BY RANDOM);


--SELECT count(DISTINCT case_alf) ALFS_WITH_LESS_THAN_10_CONT FROM (
--				SELECT DISTINCT case_alf, max(rand_row_seq) CONT_NUM
--				FROM SAILW0911V.vac17_CC_STAGE1
--				GROUP BY case_alf
--				)
--WHERE cont_num <= 10;
-------------------------------------------
----CHECKS
--
--SELECT count(DISTINCT case_alf) case_alf, count(*) all_rows FROM SAILW0911V.vac17_CC_STAGE1;
--
----WHO DIDN'T MATCHED
/*
SELECT
	DISTINCT alf_e, C20_GNDR_CD AS SEX, AGE,
	age_matched,MSOA2011_CD ,INCIDENT_DT
FROM
	SAILW0911V.vac17_COHORT
WHERE
IS_SAMPLE=1
AND
INCIDENT_dT IS NOT NULL
AND
CLEARANCE_INCIDENT_DT IS NULL
AND
alf_e NOT IN (SELECT DISTINCT case_alf FROM SAILW0911V.vac17_CC_STAGE1);
*/
---------------------------------------------------------------
-- stage 2: rows are cases and 10 randomly picked controls
---------------------------------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW0911V.vac17_CC');

CREATE TABLE SAILW0911V.vac17_CC (
	alf_e        BIGINT NOT NULL,
	groups       INTEGER NOT NULL,
	alf_type     VARCHAR(7),
	incident_dt  DATE,
	sex          SMALLINT,
	age_match    VARCHAR(7),
	msoa2011_cd  VARCHAR(10),
	PRIMARY KEY (alf_e, groups)
);

--granting access to team mates
GRANT ALL ON TABLE SAILW0911V.vac17_CC TO ROLE NRDASAIL_SAIL_0911_ANALYST;

INSERT INTO SAILW0911V.vac17_CC
WITH
	t_case AS (
		SELECT DISTINCT
			case_alf AS alf_e,
			DENSE_RANK() OVER(ORDER BY case_alf) AS groups,
			'CASE' AS alf_type,
			incident_dt,
			sex,
			age_match,
			msoa2011_cd
		FROM
		(
			SELECT *
			FROM SAILW0911V.vac17_CC_STAGE1
			WHERE RAND_ROW_SEQ BETWEEN 0 AND 10
		)
	),
	t_control AS (
		SELECT DISTINCT
			control_alf AS alf_e,
			DENSE_RANK() OVER(ORDER BY case_alf) AS groups,
			'CONTROL' AS alf_type,
			incident_dt,
			sex,
			age_match,
			msoa2011_cd
		FROM
		(
			SELECT *
			FROM SAILW0911V.vac17_CC_STAGE1
			WHERE RAND_ROW_SEQ BETWEEN 0 AND 10
		)
	)
SELECT * FROM t_case
UNION
SELECT * FROM t_control;

DROP TABLE SAILW0911V.vac17_CC_STAGE1;

--Q/A
SELECT DISTINCT c Numbers_in_matched_group, count(*) Total_groups
FROM 	(
		SELECT DISTINCT GROUPS , count(*) c
		FROM SAILW0911V.vac17_CC
		GROUP BY GROUPS
		)
GROUP BY c
ORDER BY 2;
