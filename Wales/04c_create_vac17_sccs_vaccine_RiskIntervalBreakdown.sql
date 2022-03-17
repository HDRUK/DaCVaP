-----------------------------------------------------------
--aim: 	to generate a draft of SCCS analysis table
--by: 	Fatemeh Torabi
--dt: 	2022-01-25
-----------------------------------------------------------
--chop all ingridients: see figure 1 for updated version of this
--all required fileds that I need to define each period:
--		pre_vac period: starts from 15 days before 7th of december carries on until vaccinated or ever
--		clearance: 		14 days before vaccination: we assume that for anyone having an event in this period their vaccination will be delayed
--		risk period: 	vaccination date + 28 days
--		end of observation: 	30th of June 2021
/*
SELECT count(DISTINCT ALF_E ) FROM SAILW0911V.VAC17_COHORT 
 WHERE IS_SAMPLE =1 AND INCIDENT_SCCS_DT IS NOT NULL ---17,748
 --AND VACC_FIRST_DATE IS NOT NULL AND VACC_SECOND_DATE IS NULL ---1,521
-- AND VACC_FIRST_DATE IS NOT NULL AND VACC_SECOND_DATE IS not NULL ---14,590
-- AND VACC_FIRST_DATE IS NULL AND VACC_SECOND_DATE IS NULL ---1,637
AND POSITIVE_TEST_DATE IS NOT NULL --2,474
*/

--Risk Interval Breakdown: RIB
--Breakdowns are: 
--				0-7 days
--				8-14
--				15-21
--				22-28
----------------------------------------------
--Risk INTERVAL Breakdowns
----------------------------------------------
/*
CREATE TABLE sailw0911v.vac17_analysis_SCCS_RIB_old AS (SELECT * FROM sailw0911v.vac17_analysis_SCCS_RIB) WITH NO DATA;
INSERT INTO sailw0911v.vac17_analysis_SCCS_RIB_old SELECT * FROM sailw0911v.vac17_analysis_SCCS_RIB;
*/

/*
CREATE TABLE sailw0911v.vac17_analysis_SCCS_RIB_20220131 AS (SELECT * FROM sailw0911v.vac17_analysis_SCCS_RIB) WITH NO DATA;
INSERT INTO sailw0911v.vac17_analysis_SCCS_RIB_20220131 SELECT * FROM sailw0911v.vac17_analysis_SCCS_RIB;
*/
CALL FNC.DROP_IF_EXISTS ('sailw0911v.vac17_analysis_SCCS_RIB');


CREATE TABLE sailw0911v.vac17_analysis_SCCS_RIB (
	alf_e 					bigint NOT NULL ,
	tstart					date, 
	tstop 					date,
	expgr					varchar(30), 
	expgr_seq				varchar(10), 
	vacc_type				varchar(20),
	vt 						varchar(10),
	vacc_status				varchar(30),
	INCIDENT_SCCS_dt		date,
	INCIDENT_SCCS_cat		varchar(100),
	event 					varchar(1),
	event_cat				varchar(225),
	intervals				integer,
	age 					smallint, 
	age_band				varchar(5),
	wimd_2019_quintile		smallint
	)distribute BY hash (alf_e); 

--granting access to team mates
GRANT ALL ON TABLE sailw0911v.vac17_ANALYSIS_SCCS_RIB TO ROLE NRDASAIL_SAIL_0911_ANALYST;

INSERT INTO sailw0911v.vac17_analysis_SCCS_RIB
SELECT
	ALF_E, 
	TSTART,
	TSTOP, 
	EXPGR, 
	EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	CASE WHEN INCIDENT_SCCS_DT BETWEEN TSTART AND TSTOP THEN 1 ELSE 0 END AS EVENT, 
	CASE WHEN INCIDENT_SCCS_DT BETWEEN TSTART AND TSTOP THEN INCIDENT_SCCS_CAT ELSE NULL END AS EVENT_CAT, 
	DAYS(TSTOP)-DAYS(TSTART)  AS INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
FROM 
(
	SELECT DISTINCT * FROM sailw0911v.vac17_analysis_SCCS
	WHERE 
	EXPGR_SEQ NOT IN (3,6,9,12)
UNION 
-----------
--risk first dose
-----------

--0-7 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART,
	TSTART+ 7 DAYS TSTOP, 
	'3a-RISK_FIRST 1-7D' AS EXPGR, 
	'3A' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 3 
UNION 
--8-14 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 8 DAYS TSTART,
	TSTART+ 14 DAYS TSTOP, 
	'3b-RISK_FIRST 8-14D' AS EXPGR, 
	'3B' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 3 
UNION 
--15-21 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 15 DAYS TSTART,
	TSTART+ 21 DAYS TSTOP, 
	'3c-RISK_FIRST 15-21D' AS EXPGR, 
	'3C' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 3 
UNION 
--22-28 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 22 DAYS TSTART,
	TSTART+ 28 DAYS TSTOP, 
	'3d-RISK_FIRST 22-28D' AS EXPGR, 
	'3D' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 3 

UNION 
-----------
--risk second dose
-----------

--0-7 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART,
	TSTART+ 7 DAYS TSTOP, 
	'6a-RISK_SECOND 1-7D' AS EXPGR, 
	'6A' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 6
UNION 
--8-14 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 8 DAYS TSTART,
	TSTART+ 14 DAYS TSTOP, 
	'6b-RISK_SECOND 8-14D' AS EXPGR, 
	'6B' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 6
UNION 
--15-21 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 15 DAYS TSTART,
	TSTART+ 21 DAYS TSTOP, 
	'6c-RISK_SECOND 15-21D' AS EXPGR, 
	'6C' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 6
UNION 
--22-28 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 22 DAYS TSTART,
	TSTART+ 28 DAYS TSTOP, 
	'6d-RISK_SECOND 22-28D' AS EXPGR, 
	'6D' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 6

UNION 
-----------
--risk third dose
-----------
--0-7 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART,
	TSTART+ 7 DAYS TSTOP, 
	'9a-RISK_third 1-7D' AS EXPGR, 
	'9A' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 9
UNION 
--8-14 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 8 DAYS TSTART,
	TSTART+ 14 DAYS TSTOP, 
	'9b-RISK_third 8-14D' AS EXPGR, 
	'9B' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 9
UNION 
--15-21 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 15 DAYS TSTART,
	TSTART+ 21 DAYS TSTOP, 
	'9c-RISK_third 15-21D' AS EXPGR, 
	'9C' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 9
UNION 
--22-28 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 22 DAYS TSTART,
	TSTART+ 28 DAYS TSTOP, 
	'9d-RISK_third 22-28D' AS EXPGR, 
	'9D' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 9

UNION 

------------
--risk booster = 12
------------
--0-7 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART,
	TSTART+ 7 DAYS TSTOP, 
	'12a-RISK_BOOSTER 1-7D' AS EXPGR, 
	'12A' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 12
UNION 
--8-14 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 8 DAYS TSTART,
	TSTART+ 14 DAYS TSTOP, 
	'12b-RISK_BOOSTER 8-14D' AS EXPGR, 
	'12B' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 12
UNION 
--15-21 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 15 DAYS TSTART,
	TSTART+ 21 DAYS TSTOP, 
	'12c-RISK_BOOSTER 15-21D' AS EXPGR, 
	'12C' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 12
UNION 
--22-28 d
	SELECT DISTINCT 
	ALF_E, 
	TSTART + 22 DAYS TSTART,
	TSTART+ 28 DAYS TSTOP, 
	'12d-RISK_BOOSTER 22-28D' AS EXPGR, 
	'12D' AS EXPGR_SEQ,
	VACC_TYPE, 
	VT, 
	VACC_STATUS, 
	INCIDENT_SCCS_DT, 
	INCIDENT_SCCS_CAT, 
	EVENT, 
	EVENT_CAT, 
	INTERVALS,
	AGE, 
	AGE_BAND, 
	WIMD_2019_QUINTILE
	FROM sailw0911v.vac17_analysis_SCCS
	WHERE EXPGR_SEQ = 12
)
ORDER BY ALF_E, TSTART;

SELECT * FROM sailw0911v.vac17_analysis_SCCS_RIB
ORDER BY ALF_E, TSTART;


SELECT COUNT(DISTINCT alf_e) FROM sailw0911v.vac17_analysis_SCCS_RIB;