-----------------------------------------------------------
--vac17: 	Vaccine Safety
--BY:		fatemeh.torabi@swansea.ac.uk
--DT: 		2021-04-08
--aim:		to identify cases and control cohort
-----------------------------------------------------------
--READ CODE LIST CHECK
/*
CALL FNC.DROP_IF_EXISTS('SAILW0911V.dacvap_READ_THROMBOSIS');
CALL FNC.DROP_IF_EXISTS('SAILW0911V.dacvap_READ_CSVT');
CALL FNC.DROP_IF_EXISTS('SAILW0911V.dacvap_READ_HEMORRHAGE');
CALL FNC.DROP_IF_EXISTS('SAILW0911V.dacvap_READ_THROMBOCYTOPENIA');
CALL FNC.DROP_IF_EXISTS('SAILW0911V.dacvap_READ_ITP');
*/

/*
SELECT * FROM SAILW0911V.dacvap_READ_THROMBOSIS;
SELECT * FROM SAILW0911V.dacvap_READ_CSVT;
SELECT * FROM SAILW0911V.dacvap_READ_HEMORRHAGE;
SELECT * FROM SAILW0911V.dacvap_READ_THROMBOCYTOPENIA;
SELECT * FROM SAILW0911V.dacvap_READ_ITP;
SELECT * FROM SAILW0911V.dacvap_READ_ARTERIAL_THROMBOEMBOLIC;
SELECT * FROM SAILW0911V.dacvap_READ_ISCH_STROKE;
SELECT * FROM SAILW0911V.dacvap_read_MI;
*/
-----------------------------------------------------------
--PRIMARY CARE EVENTS:
CALL fnc.drop_if_exists ('SAILW0911V.vac17_GP_CASES');

CREATE TABLE sailw0911v.vac17_gp_cases
(
		alf_e			BIGINT,
		alf_sts_cd		INTEGER,
		event_dt		DATE,
		event_cd		CHAR(6),
		read_cd 		VARCHAR(6),
		read_desc		VARCHAR(300),
		read_cat		VARCHAR(225),
		read_id			INTEGER,
		in_c20			INTEGER
)
DISTRIBUTE BY HASH(alf_e);
COMMIT;

--granting access to team mates
GRANT ALL ON TABLE sailw0911v.vac17_gp_cases TO ROLE nrdasail_sail_0911_analyst;

ALTER TABLE sailw0911v.vac17_gp_cases ACTIVATE NOT LOGGED INITIALLY;

INSERT INTO sailw0911v.vac17_gp_cases
SELECT DISTINCT
	gp.alf_e,
	gp.alf_sts_cd,
	gp.event_dt,
	gp.event_cd,
	cd.read_cd,
	cd.read_desc,
	cd.read_cat,
	cd.read_id,
	CASE
		WHEN alf_e IN (SELECT DISTINCT alf_e FROM sailw0911v.C19_COHORT20_20210805) THEN 1
		ELSE 0
	END AS in_c20
FROM
	sail0911v.wlgp_gp_event_cleansed gp
RIGHT OUTER JOIN
(
	SELECT * FROM sailw0911v.dacvap_read_thrombosis
	UNION
	SELECT * FROM sailw0911v.dacvap_read_csvt
	UNION
	SELECT * FROM sailw0911v.dacvap_read_hemorrhage
	UNION
	SELECT * FROM sailw0911v.dacvap_read_thrombocytopenia
	UNION
	SELECT * FROM sailw0911v.dacvap_read_itp
	UNION 
	SELECT * FROM SAILW0911V.dacvap_READ_ARTERIAL_THROMBOEMBOLIC
	UNION 
	SELECT * FROM SAILW0911V.dacvap_READ_ISCH_STROKE 
	UNION 
	SELECT * FROM SAILW0911V.dacvap_read_MI 
) cd
ON
	gp.event_cd = cd.read_cd
WHERE
	gp.alf_e IS NOT NULL
AND
	gp.alf_sts_cd IN ('1','4','39')
AND
	gp.event_cd IS NOT NULL
AND
	gp.event_dt IS NOT NULL
AND
	year(gp.event_dt) BETWEEN '2016' AND '2021'
AND
	gp.event_dt <= '2021-12-31';

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW0911V.vac17_GP_CASES with distribution and detailed indexes all');

COMMIT;

SELECT * FROM (
				SELECT DISTINCT READ_CAT, READ_CD , READ_DESC, count(DISTINCT ALF_E ) PAT_CNT FROM 
				(					
				SELECT 
				DISTINCT ALF_E , EVENT_DT , READ_CD , READ_DESC , READ_CAT 
				FROM
				SAILw0911V.VAC17_gp_CASES
				WHERE
				EVENT_DT  BETWEEN '2019-09-01' AND '2021-12-31'
				) 
				GROUP BY read_CAT , READ_CD , READ_DESC   
				ORDER BY pat_cnt DESC 
				)
WHERE pat_cnt >= 5;