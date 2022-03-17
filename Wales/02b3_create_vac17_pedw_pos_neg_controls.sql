-----------------------------------------------------------
--DacVap: 	Vaccine Safety
--BY:		fatemeh.torabi@swansea.ac.uk
--DT: 		2021-04-08
--aim:		to identify cases and control cohort
-----------------------------------------------------------
--READ CODE LIST CHECK
/*

*/

-----------------------------------------------------------
--PRIMARY CARE EVENTS:
CALL fnc.drop_if_exists ('sailw0911v.vac17_pedw_pos_neg_controls');

CREATE TABLE sailw0911v.vac17_pedw_pos_neg_controls
(
		alf_e			BIGINT,
		alf_sts_cd		INTEGER,
		admis_dt		date,
		disch_dt		date,
		epi_num 		VARCHAR(6),
		epi_str_dt		Date,
		epi_end_dt		Date,
		epi_diag_1234	varchar(225),
		
		diag_cd_1234	varchar(5),

		icd10			varchar(6),
		icd_desc		varchar(255),
		icd_cat			varchar(255),
		icd_id			varchar(255),
		in_c20			integer
		)
DISTRIBUTE BY HASH(alf_e);
COMMIT;

--granting access to team mates
GRANT ALL ON TABLE sailw0911v.vac17_pedw_pos_neg_controls TO ROLE nrdasail_sail_0911_analyst;

ALTER TABLE sailw0911v.vac17_pedw_pos_neg_controls ACTIVATE NOT LOGGED INITIALLY;


insert into sailw0911v.vac17_pedw_pos_neg_controls
		select 
		sp.alf_e, 
		sp.alf_sts_cd, 
		sp.admis_dt, 
		sp.disch_dt, 

		ep.epi_num, 
		ep.epi_str_dt,
		ep.epi_end_dt, 

		ep.diag_cd_1234 epi_diag1234,
		
		diag.diag_cd_1234,

		icd.icd10,
		icd.icd_desc,
		icd.icd_cat,
		icd.icd_id,
		CASE
		WHEN alf_e IN (SELECT DISTINCT alf_e FROM sailw0911v.c19_cohort20) THEN 1
		ELSE 0
		END AS in_c20
		from 
		SAIL0911V.PEDW_SPELL sp
		left join
		SAIL0911V.PEDW_EPISODE ep
		on 
		sp.prov_unit_cd=ep.prov_unit_cd
		AND 
		sp.SPELL_NUM_E=ep.SPELL_NUM_E
		AND 
		sp.alf_sts_cd in ('1','4','39')
		AND
		year(sp.admis_dt) BETWEEN '2016' AND '2021'
		AND 
		sp.admis_dt <= '2021-12-31'
		left join
		SAIL0911V.PEDW_DIAG diag
		on
		diag.prov_unit_cd=sp.prov_unit_cd
		and
		diag.SPELL_NUM_E=sp.SPELL_NUM_E
		and
		diag.epi_num=ep.epi_num
		right outer join
				(
			SELECT DISTINCT alt_code AS icd10, description AS icd_desc, 'Coeliac disease' AS ICD_CAT, 8 AS icd_id FROM SAILUKHDV.ICD10_CODES_AND_TITLES_AND_METADATA icatam 
			WHERE alt_code LIKE '%K900%'
			UNION
			SELECT DISTINCT alt_code AS icd10, description AS icd_desc, 'Anaphylactic' AS ICD_CAT, 9 AS icd_id FROM SAILUKHDV.ICD10_CODES_AND_TITLES_AND_METADATA icatam 
			WHERE alt_code IN ('T780','T782','T805','T886')
			UNION
			SELECT DISTINCT alt_code AS icd10, description AS icd_desc, 'hip fracture' AS ICD_CAT, 10 AS icd_id FROM SAILUKHDV.ICD10_CODES_AND_TITLES_AND_METADATA icatam 
			WHERE alt_code IN ('S72','S720','S7200','S7201','S721',
			'S7210','S7211','S722','S7220','S7221','S723','S7230','S7231',
			'S724','S7240','S7241','S727','S7270','S7271','S728','S7280',
			'S7281','S729','S7290','S7291')			
			UNION
			SELECT DISTINCT alt_code AS icd10, description AS icd_desc, 'Appendicitis' AS ICD_CAT, 11 AS icd_id FROM SAILUKHDV.ICD10_CODES_AND_TITLES_AND_METADATA icatam 
			WHERE alt_code IN ('K35','K350','K351','K352','K353','K358','K359','K36X','K37X ')
			
				) icd
		on
		diag.diag_cd_1234=icd.icd10;
		
COMMIT;


CALL SYSPROC.ADMIN_CMD('runstats on table sailw0911v.vac17_pedw_pos_neg_controls with distribution and detailed indexes all');

COMMIT;

--checks:
/*
SELECT DISTINCT read_cat, count(DISTINCT alf_e) FROM SAILW0911V.vac17_gp_CASES
WHERE year(event_dt) >= '2020'
GROUP BY read_cat;

SELECT DISTINCT icd_cat, count(DISTINCT alf_e) FROM SAILW0911V.vac17_PEDW_CASES
WHERE year(admis_dt) >= '2020'
GROUP BY icd_cat;

SELECT * FROM SAILW0911V.vac17_PEDW_CASES
WHERE year(admis_dt) >= '2020'
AND icd_cat='CSVT';
*/

SELECT * FROM (
				SELECT DISTINCT icd_cat, icd10, ICD_DESC , count(DISTINCT ALF_E ) PAT_CNT FROM 
				(					
				SELECT 
				DISTINCT ALF_E , ADMIS_DT , icd10, ICD_DESC , icd_cat
				FROM
				sailw0911v.vac17_pedw_pos_neg_controls
				WHERE
				admis_dt  BETWEEN '2019-09-01' AND '2021-12-31'
			--	AND ICD_ID =6
				) 
				GROUP BY ICD_CAT , ICD10, ICD_DESC  
				ORDER BY pat_cnt DESC 
				)
WHERE pat_cnt >= 5;