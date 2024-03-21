-- =============================================================================
-- Main outcomes used in typical vaccine-related analyses
-- =============================================================================
--
-- Each outcome has it's own table:
--  * Vaccinations: dose 1, 2, 3, and booster
--  * Positive PCR tests: 90 days apart
--  * Lateral flow tests
--  * Hospitalisation due to COVID-19: within 14 days of positive PCR or coded
--    with ICD-10 code for COVID-19
--  * All deaths
--
-- Feel free to run this script as often as any of the underlying data sources
-- are updated.
--
-- =============================================================================
-- Step 1: Check how up to date is everything
-- =============================================================================

SELECT 'vacc' AS src, max(vacc_date) AS end_date
	FROM sailw0911v.rrda_cvvd
UNION
SELECT 'cvvd' AS src, max(vacc_date_of_vaccine) AS end_date
	FROM sail0911v.cvvd_df_wis_outcomedatav2
UNION
SELECT 'pcr' AS src, max(spcm_collected_dt) AS end_date
	FROM sail0911v.patd_df_covid_lims_testresults
	WHERE spcm_collected_dt <= CURRENT DATE
UNION
SELECT 'lft' AS src, date(max(teststart_dt)) AS end_date
	FROM sail0911v.cvlf_df_lateral_flow_tests
	WHERE teststart_dt <= CURRENT DATE
UNION
SELECT 'mortality' AS src, max(dod) AS end_date
	FROM sailw0911v.c19_cohort20_mortality
UNION
SELECT 'pedw' AS src, max(admis_dt) AS end_date
	FROM sail0911v.pedw_spell
	WHERE admis_dt < CURRENT DATE;


-- Check total number of PEDW episodes by week
-- and whether they have a diag code
WITH
	pedw_epi AS
	(
		SELECT
			spell.prov_unit_cd,
			spell.spell_num_e,
			CAST(date_trunc('week', spell.admis_dt) AS DATE) AS admis_dt,
			CAST(date_trunc('week', epi.epi_str_dt) AS DATE) AS epi_str_week,
			epi.diag_cd_1234 IS NOT NULL AS has_diag
		FROM
			sail0911v.pedw_spell AS spell
		INNER JOIN
			sail0911v.pedw_episode AS epi
			ON spell.prov_unit_cd = epi.prov_unit_cd
			AND spell.spell_num_e = epi.spell_num_e
		WHERE
			spell.admis_dt BETWEEN '2021-01-01' AND CURRENT DATE
			AND epi.epi_str_dt BETWEEN '2021-01-01' AND CURRENT DATE
	)
SELECT epi_str_week, COUNT(*) AS epi_n, SUM(has_diag) AS epi_diag_n
FROM pedw_epi
GROUP BY epi_str_week
ORDER BY epi_str_week DESC;

-- =============================================================================
-- Step 2: Vaccinations
-- =============================================================================

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_vacc');

CREATE TABLE sailw1151v.sa_dacvap_vacc
(
	alf_e                   BIGINT NOT NULL,
	has_bad_vacc_record     SMALLINT NOT NULL,
-- first dose
	vacc_dose1_date         DATE,
	vacc_dose1_name         VARCHAR(50),
	vacc_dose1_reaction_ind SMALLINT,
	vacc_dose1_reaction_cd  SMALLINT,
-- second dose
	vacc_dose2_date         DATE,
	vacc_dose2_name         VARCHAR(50),
	vacc_dose2_reaction_ind SMALLINT,
	vacc_dose2_reaction_cd  SMALLINT,
-- third dose
	vacc_dose3_date         DATE,
	vacc_dose3_name         VARCHAR(50),
	vacc_dose3_reaction_ind SMALLINT,
	vacc_dose3_reaction_cd  SMALLINT,
-- booster dose
	vacc_doseb_date         DATE,
	vacc_doseb_name         VARCHAR(50),
	vacc_doseb_reaction_ind SMALLINT,
	vacc_doseb_reaction_cd  SMALLINT,
	PRIMARY KEY (alf_e)
);

INSERT INTO sailw1151v.sa_dacvap_vacc
SELECT
	cohort.alf_e,
	MAX(cvvd.alf_has_bad_vacc_record) AS alf_has_bad_vacc_record,
	-- first dose
	MAX(CASE WHEN cvvd.vacc_dose_seq = '1'  THEN cvvd.vacc_date END)                                         AS vacc_dose1_date,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '1'  THEN cvvd.vacc_name END)                                         AS vacc_dose1_name,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '1'  THEN CAST(cvvd.vacc_adverse_reaction_ind = 'Y' AS SMALLINT) END) AS vacc_dose1_reaction_ind,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '1'  THEN cvvd.vacc_adverse_reaction_cd END)                          AS vacc_dose1_reaction_cd,
	-- second dose
	MAX(CASE WHEN cvvd.vacc_dose_seq = '2'  THEN cvvd.vacc_date END)                                         AS vacc_dose2_date,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '2'  THEN cvvd.vacc_name END)                                         AS vacc_dose2_name,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '2'  THEN CAST(cvvd.vacc_adverse_reaction_ind = 'Y' AS SMALLINT) END) AS vacc_dose2_reaction_ind,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '2'  THEN cvvd.vacc_adverse_reaction_cd END)                          AS vacc_dose2_reaction_cd,
	-- third dose
	MAX(CASE WHEN cvvd.vacc_dose_seq = '3'  THEN cvvd.vacc_date END)                                         AS vacc_dose3_date,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '3'  THEN cvvd.vacc_name END)                                         AS vacc_dose3_name,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '3'  THEN CAST(cvvd.vacc_adverse_reaction_ind = 'Y' AS SMALLINT) END) AS vacc_dose3_reaction_ind,
	MAX(CASE WHEN cvvd.vacc_dose_seq = '3'  THEN cvvd.vacc_adverse_reaction_cd END)                          AS vacc_dose3_reaction_cd,
	-- booster dose
	MAX(CASE WHEN cvvd.vacc_dose_seq = 'B1' THEN cvvd.vacc_date END)                                         AS vacc_doseb_date,
	MAX(CASE WHEN cvvd.vacc_dose_seq = 'B1' THEN cvvd.vacc_name END)                                         AS vacc_doseb_name,
	MAX(CASE WHEN cvvd.vacc_dose_seq = 'B1' THEN CAST(cvvd.vacc_adverse_reaction_ind = 'Y' AS SMALLINT) END) AS vacc_doseb_reaction_ind,
	MAX(CASE WHEN cvvd.vacc_dose_seq = 'B1' THEN cvvd.vacc_adverse_reaction_cd END)                          AS vacc_doseb_reaction_cd
FROM
	sailw1151v.dacvap2_cyp AS cohort
INNER JOIN
	sailw0911v.rrda_cvvd AS cvvd
	ON cohort.alf_e = cvvd.alf_e
GROUP BY
	cohort.alf_e;

GRANT ALL ON TABLE sailw1151v.sa_dacvap_vacc
TO ROLE NRDASAIL_SAIL_1151_ANALYST;

-- =============================================================================
-- Step 3: PCR tests
-- =============================================================================

-- Summaries consist of:
--  * Number of PCR tests prior to vacc and booster programme start dates:
--  	+ vacc start date    2020-12-08
--  	+ booster start date 2021-09-16
--  * number of infections: consecutive positive tests 90 days apart count as
--    a new infection
--  * dates of infections: dates of positive tests that were at least 90 days
--    from the previous positive test

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_pcr_test');

CREATE TABLE sailw1151v.sa_dacvap_pcr_test
(
	alf_e                  BIGINT   NOT NULL,
-- pcr test history
	test_ever_flg          SMALLINT,
	test_pre08dec2020_n    SMALLINT,
	test_pre16sep2021_n    SMALLINT,
-- number of infections
	infection_n            SMALLINT,
-- positive tests 90 days apart
	infection1_test_date   DATE,
	infection2_test_date   DATE,
	infection3_test_date   DATE,
	infection4_test_date   DATE,
	PRIMARY KEY (alf_e)
);

INSERT INTO sailw1151v.sa_dacvap_pcr_test
WITH
	test_clean AS
	(
		-- if good, use spcm_collected_dt, else try spcm_recieved_dt
		SELECT
			cohort.alf_e,
			CASE
				WHEN test.spcm_collected_dt BETWEEN '2020-01-01' AND CURRENT DATE THEN test.spcm_collected_dt
				ELSE test.SPCM_RECEIVED_DT
			END AS test_date,
			test.covid19testresult AS test_result
		FROM
			sailw1151v.dacvap2_cyp AS cohort
		INNER JOIN
			sail0911v.patd_df_covid_lims_testresults AS test
			ON cohort.alf_e = test.alf_e
		WHERE
			test.alf_e IS NOT NULL
			AND test.alf_sts_cd IN (1, 4, 39)
			AND test.spcm_collected_dt IS NOT NULL
			AND test.covid19testresult IS NOT NULL
	),
	test_history AS
	(
		-- count number of tests before vacc programme and booster
		-- programme start dates
		SELECT
			alf_e,
			1 AS test_ever_flg,
			SUM(test_date < '2020-12-08') AS test_pre08dec2020_n,
			SUM(test_date < '2021-09-16') AS test_pre16sep2021_n
		FROM
			test_clean
		GROUP BY
			alf_e
	),
	test_lag AS
	(
		-- looking at positive tests only, find previous positive test for an
		-- alf and diff the days between the previous and current tests
		SELECT
			alf_e,
			test_date,
			LAG(test_date) OVER (PARTITION BY alf_e ORDER BY test_date) AS prev_test_date,
			DAYS_BETWEEN(test_date, LAG(test_date) OVER (PARTITION BY alf_e ORDER BY test_date)) AS diff_days
		FROM
			test_clean
		WHERE
			test_result = 'Positive'
	),
	new_infection AS
	(
		-- filter rows so we are looking at first positive test and
		-- positive tests 90 days apart
		SELECT
			alf_e,
			test_date,
			ROW_NUMBER() OVER (PARTITION BY alf_e ORDER BY test_date) AS infection_seq
		FROM test_lag
		WHERE
			prev_test_date IS NULL
			OR diff_days >= 90
	),
	infection_wide AS
	(
		-- reshape from long to wide table
		-- check MAX(infection_n) is 4
		SELECT
			alf_e,
			COUNT(*) AS infection_n,
			MAX(CASE WHEN infection_seq = 1 THEN test_date END) AS infection1_test_date,
			MAX(CASE WHEN infection_seq = 2 THEN test_date END) AS infection2_test_date,
			MAX(CASE WHEN infection_seq = 3 THEN test_date END) AS infection3_test_date,
			MAX(CASE WHEN infection_seq = 4 THEN test_date END) AS infection4_test_date
		FROM new_infection
		GROUP BY alf_e
	)
-- final join everything back together
SELECT
	cohort.alf_e,
-- pcr test history
	CASE
		WHEN test_history.alf_e IS NULL THEN 0
		ELSE test_history.test_ever_flg
	END AS test_ever_flg,
	CASE
		WHEN test_history.alf_e IS NULL THEN 0
		ELSE test_history.test_pre08dec2020_n
	END AS test_pre08dec2020_n,
	CASE
		WHEN test_history.alf_e IS NULL THEN 0
		ELSE test_history.test_pre16sep2021_n
	END AS test_pre16sep2021_n,
-- number of infections
	CASE
		WHEN infection_wide.alf_e IS NULL THEN 0
		ELSE infection_wide.infection_n
	END AS infection_n,
-- positive tests 90 days apart
	infection_wide.infection1_test_date,
	infection_wide.infection2_test_date,
	infection_wide.infection3_test_date,
	infection_wide.infection4_test_date
FROM sailw1151v.dacvap2_cyp AS cohort
LEFT JOIN infection_wide
	ON cohort.alf_e = infection_wide.alf_e
LEFT JOIN test_history
	ON cohort.alf_e = test_history.alf_e;

GRANT ALL ON TABLE sailw1151v.sa_dacvap_pcr_test
TO ROLE NRDASAIL_SAIL_1151_ANALYST;


-- =============================================================================
-- Step 4: PCR and lateral flow tests
-- =============================================================================

-- This table is similar to the PCR test table, except it uses both LFT and PCR
-- tests from which to derive testing counts and dates of infections:
--  * Number of LFT and PCR tests prior to start of vacc and booster programmes:
--  	+ vacc start date    2020-12-08
--  	+ booster start date 2021-09-16
--  * Number of infections: consecutive positive LFT and PCR tests which are
--    90 days apart count as a new infection
--  * Dates of infections: dates of positive tests that were at least 90 days
--    from the previous positive test

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_lft_pcr_test');

CREATE TABLE sailw1151v.sa_dacvap_lft_pcr_test
(
	alf_e                  BIGINT   NOT NULL,
-- pcr test history
	pcr_ever_flg           SMALLINT,
	pcr_pre08dec2020_n     SMALLINT,
	pcr_pre16sep2021_n     SMALLINT,
-- lft history
	lft_ever_flg           SMALLINT,
	lft_pre08dec2020_n     SMALLINT,
	lft_pre16sep2021_n     SMALLINT,
-- number of infections
	infection_n            SMALLINT,
-- positive tests 90 days apart
	infection1_test_date   DATE,
	infection2_test_date   DATE,
	infection3_test_date   DATE,
	infection4_test_date   DATE,
	PRIMARY KEY (alf_e)
);

INSERT INTO sailw1151v.sa_dacvap_lft_pcr_test
WITH
	pcr_clean AS
	(
		SELECT
			cohort.alf_e,
			CASE
				WHEN pcr.spcm_collected_dt BETWEEN '2020-01-01' AND CURRENT DATE THEN pcr.spcm_collected_dt
				ELSE pcr.SPCM_RECEIVED_DT
			END AS test_date,
			CAST(pcr.covid19testresult = 'Positive' AS SMALLINT) AS is_positive_test,
			'pcr' AS test_type
		FROM
			sailw1151v.dacvap2_cyp AS cohort
		INNER JOIN
			sail0911v.patd_df_covid_lims_testresults AS pcr
			ON cohort.alf_e = pcr.alf_e
		WHERE
			pcr.alf_e IS NOT NULL
			AND pcr.alf_sts_cd IN (1, 4, 39)
			AND pcr.spcm_collected_dt IS NOT NULL
			AND pcr.covid19testresult IS NOT NULL
	),
	lft_clean AS
	(
		SELECT
			cohort.alf_e,
			appt_dt AS test_date,
			CAST(testresult IN ('SCT:1240581000000104', 'SCT:1322781000000102') AS SMALLINT) AS is_positive_test,
			'lft' AS test_type
		FROM
			sailw1151v.dacvap2_cyp AS cohort
		INNER JOIN
			sail0911v.CVLF_DF_LATERAL_FLOW_TESTS AS lft
			ON cohort.alf_e = lft.alf_e
		WHERE
			lft.alf_e IS NOT NULL
			AND lft.alf_sts_cd IN (1, 4, 39)
			AND lft.appt_dt IS NOT NULL
			AND lft.testresult IS NOT NULL
	),
	test_stack AS
	(
		SELECT * FROM pcr_clean
		UNION
		SELECT * FROM lft_clean
	),
	test_history AS
	(
		-- count number of tests before vacc programme and booster
		-- programme start dates
		SELECT
			alf_e,
			MAX(CAST(test_type = 'pcr' AS SMALLINT))            AS pcr_ever_flg,
			SUM(test_type = 'pcr' AND test_date < '2020-12-08') AS pcr_pre08dec2020_n,
			SUM(test_type = 'pcr' AND test_date < '2021-09-16') AS pcr_pre16sep2021_n,
			MAX(CAST(test_type = 'lft' AS SMALLINT))            AS lft_ever_flg,
			SUM(test_type = 'lft' AND test_date < '2020-12-08') AS lft_pre08dec2020_n,
			SUM(test_type = 'lft' AND test_date < '2021-09-16') AS lft_pre16sep2021_n
		FROM
			test_stack
		GROUP BY
			alf_e
	),
	test_lag AS
	(
		-- looking at positive tests only, find previous positive test for an
		-- alf and diff the days between the previous and current tests
		SELECT
			alf_e,
			test_date,
			LAG(test_date) OVER (PARTITION BY alf_e ORDER BY test_date) AS prev_test_date,
			DAYS_BETWEEN(test_date, LAG(test_date) OVER (PARTITION BY alf_e ORDER BY test_date)) AS diff_days
		FROM
			test_stack
		WHERE
			is_positive_test = 1
	),
	new_infection AS
	(
		-- filter rows so we are looking at first positive test and
		-- positive tests 90 days apart
		SELECT
			alf_e,
			test_date,
			ROW_NUMBER() OVER (PARTITION BY alf_e ORDER BY test_date) AS infection_seq
		FROM test_lag
		WHERE
			prev_test_date IS NULL
			OR diff_days >= 90
	),
	-- check if the following matches the number of sequences listed in the next block:
	-- SELECT MAX(infection_seq) FROM new_infection;
	infection_wide AS
	(
		-- reshape from long to wide table
		SELECT
			alf_e,
			COUNT(*) AS infection_n,
			MAX(CASE WHEN infection_seq = 1 THEN test_date END) AS infection1_test_date,
			MAX(CASE WHEN infection_seq = 2 THEN test_date END) AS infection2_test_date,
			MAX(CASE WHEN infection_seq = 3 THEN test_date END) AS infection3_test_date,
			MAX(CASE WHEN infection_seq = 4 THEN test_date END) AS infection4_test_date
		FROM new_infection
		GROUP BY alf_e
	)
-- final join everything back together
SELECT
	cohort.alf_e,
-- pcr test history
	CASE WHEN test_history.alf_e IS NULL THEN 0 ELSE pcr_ever_flg       END AS pcr_ever_flg,
	CASE WHEN test_history.alf_e IS NULL THEN 0 ELSE pcr_pre08dec2020_n END AS pcr_pre08dec2020_n,
	CASE WHEN test_history.alf_e IS NULL THEN 0 ELSE pcr_pre16sep2021_n END AS pcr_pre16sep2021_n,
-- lateral flow test history
	CASE WHEN test_history.alf_e IS NULL THEN 0 ELSE lft_ever_flg       END AS lft_ever_flg,
	CASE WHEN test_history.alf_e IS NULL THEN 0 ELSE lft_pre08dec2020_n END AS lft_pre08dec2020_n,
	CASE WHEN test_history.alf_e IS NULL THEN 0 ELSE lft_pre16sep2021_n END AS lft_pre16sep2021_n,
-- number of infections
	CASE
		WHEN infection_wide.alf_e IS NULL THEN 0
		ELSE infection_wide.infection_n
	END AS infection_n,
-- positive tests 90 days apart
	infection_wide.infection1_test_date,
	infection_wide.infection2_test_date,
	infection_wide.infection3_test_date,
	infection_wide.infection4_test_date
FROM sailw1151v.dacvap2_cyp AS cohort
LEFT JOIN infection_wide
	ON cohort.alf_e = infection_wide.alf_e
LEFT JOIN test_history
	ON cohort.alf_e = test_history.alf_e;


-- =============================================================================
-- Step 5: Hospitalisation due to COVID-19
-- =============================================================================

-- The criteria used to identify a COVID-19 related hospital admission is:
--   * Hospital spell in which the cause for admission is COVID-19
--   * Or, hospital spell in which they were admitted with COVID-19
--   * Or, hospital episode in which they became infected with COVID-19
-- 	 * Or, hospital spell starting between -1 and 14 days of a positive PCR test
--
-- We make flags identifying which of the three above criteria were met, and
-- add info on whether and when they entered critical care within the current or
-- subsequent spell, thanks to RRDA_CCID_ICCD

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_hosp_long');

CREATE TABLE sailw1151v.sa_dacvap_hosp_long (
	alf_e                                BIGINT     NOT NULL,
	prov_unit_cd                         VARCHAR(3) NOT NULL,
	spell_num_e                          BIGINT     NOT NULL,
	person_spell_num_e					 BIGINT		NOT NULL,
	spell_admis_date                     DATE,
	spell_admis_method                   VARCHAR(19),
	spell_disch_date                     DATE,
	spell_duration_days                  SMALLINT,
	epi_num                              VARCHAR(2) NOT NULL,
	epi_start_date                       DATE,
	diag_cd1                             VARCHAR(4),
	diag_cd2                             VARCHAR(4),
	diag_cd3                             VARCHAR(4),
	diag_cd4                             VARCHAR(4),
	diag_cd5                             VARCHAR(4),
	diag_cd6                             VARCHAR(4),
	diag_cd7                             VARCHAR(4),
	diag_cd8                             VARCHAR(4),
	diag_cd9                             VARCHAR(4),
	diag_cd10                            VARCHAR(4),
	critical_care_flg                    SMALLINT,
	critical_care_date                   DATE,
	admis_covid19_cause_flg              SMALLINT,
	admis_with_covid19_flg               SMALLINT,
	covid19_during_admis_flg             SMALLINT,
	within_14days_positive_pcr_flg       SMALLINT,
	PRIMARY KEY (alf_e, prov_unit_cd, spell_num_e, person_spell_num_e, epi_num)
);

-- prepare a table of non-R and non-Z diagnoses codes with two additional features
-- that we can use to find relevant covid-19 spells:
--	* a new rank to act in replace diag_num, since we exclude diags starting
--    within R or Z
--  * a flag for whether the diag code is for covid-19

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_hosp_prep');

CREATE TABLE sailw1151v.sa_dacvap_hosp_prep (
	prov_unit_cd        VARCHAR(3) NOT NULL,
	spell_num_e         BIGINT     NOT NULL,
	person_spell_num_e	BIGINT	   NOT NULL,
	epi_num             VARCHAR(2) NOT NULL,
	epi_str_dt          DATE       NOT NULL,
	diag_num			SMALLINT   NOT NULL,
	diag_cd_1234        VARCHAR(4) NOT NULL,
	rank_non_rz         SMALLINT   NOT NULL,
	is_covid19          SMALLINT   NOT NULL,
	PRIMARY KEY (prov_unit_cd, spell_num_e, person_spell_num_e, epi_num, diag_num)
);

INSERT INTO sailw1151v.sa_dacvap_hosp_prep
SELECT 
	spell.prov_unit_cd,
	spell.spell_num_e,
	person_spell_num_e,
	epi.epi_num,
	epi.epi_str_dt,
	diag.diag_num,
	diag.diag_cd_1234,
	-- diagnosis rank within episode
	ROW_NUMBER () OVER (
		PARTITION BY
			diag.prov_unit_cd,
			diag.spell_num_e,
			person_spell_num_e,
			diag.epi_num
		ORDER BY
			diag.diag_num
	) AS rank_non_rz,
	-- is diagnosis covid?
	CAST(diag.diag_cd_1234 IN ('U071', 'U072') AS SMALLINT) AS is_covid19
FROM
	sail0911v.pedw_spell AS spell
INNER JOIN sail0911v.pedw_superspell AS superspell
    ON  spell.prov_unit_cd = superspell.prov_unit_cd
    AND spell.spell_num_e  = superspell.spell_num_e
INNER JOIN
	sail0911v.pedw_episode AS epi
	ON spell.prov_unit_cd = epi.prov_unit_cd
	AND spell.spell_num_e = epi.spell_num_e
	AND epi.epi_num = superspell.epi_num
INNER JOIN
	sail0911v.pedw_diag AS diag
	ON epi.prov_unit_cd = diag.prov_unit_cd
	AND epi.spell_num_e = diag.spell_num_e
	AND epi.epi_num     = diag.epi_num
WHERE
	-- reduce the size of our search by on looking for spells from this date
	spell.admis_dt >= '2020-01-01'
	-- exclude diag codes that start with R or Z
	AND LEFT(diag.diag_cd_1234, 1) NOT IN ('R', 'Z');

CALL sysproc.admin_cmd('runstats on table sailw1151v.sa_dacvap_hosp_prep with distribution and detailed indexes all');

-- Find spells in which the *cause* for admission is COVID-19:
-- 	* epi_num = 1
--  * first non-R and non-Z diag cd is for COVID-19

INSERT INTO sailw1151v.sa_dacvap_hosp_long
WITH
	pcr_positive AS
	(
		SELECT
			alf_e,
			alf_sts_cd,
			spcm_collected_dt AS pcr_date
		FROM
			sail0911v.patd_df_covid_lims_testresults
		WHERE
			alf_sts_cd IN (1, 4, 39)
			AND spcm_collected_dt IS NOT NULL
			AND covid19testresult = 'Positive'
	),
	epi_covid AS
	(
		-- here we are making use of the table we just prepared
		-- to find hospital admissions caused by covid-19
		SELECT
			prov_unit_cd,
			spell_num_e,
			person_spell_num_e,
			epi_num,
			min(epi_str_dt) AS epi_str_dt
		FROM
			sailw1151v.sa_dacvap_hosp_prep
		WHERE
			epi_num = '01'
			AND is_covid19 = 1
			AND rank_non_rz = 1
		GROUP BY
			prov_unit_cd,
			spell_num_e,
			person_spell_num_e,
			epi_num
	)
SELECT
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	max(spell.admis_dt)                                          AS spell_admis_date,
	max(CASE
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '1' THEN 'Elective admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '2' THEN 'Emergency admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '3' THEN 'Maternity admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '8' THEN 'Other'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '9' THEN 'Other'
	END)                                                         AS spell_admis_method,
	max(spell.disch_dt)                                          AS spell_disch_date,
	max(spell.spell_dur)                                         AS spell_duration_days,
	epi.epi_num,
	max(epi.epi_str_dt)                                          AS epi_start_date,
	max(CASE WHEN diag.diag_num =  1 THEN diag.diag_cd_1234 END) AS diag_cd1,
	max(CASE WHEN diag.diag_num =  2 THEN diag.diag_cd_1234 END) AS diag_cd2,
	max(CASE WHEN diag.diag_num =  3 THEN diag.diag_cd_1234 END) AS diag_cd3,
	max(CASE WHEN diag.diag_num =  4 THEN diag.diag_cd_1234 END) AS diag_cd4,
	max(CASE WHEN diag.diag_num =  5 THEN diag.diag_cd_1234 END) AS diag_cd5,
	max(CASE WHEN diag.diag_num =  6 THEN diag.diag_cd_1234 END) AS diag_cd6,
	max(CASE WHEN diag.diag_num =  7 THEN diag.diag_cd_1234 END) AS diag_cd7,
	max(CASE WHEN diag.diag_num =  8 THEN diag.diag_cd_1234 END) AS diag_cd8,
	max(CASE WHEN diag.diag_num =  9 THEN diag.diag_cd_1234 END) AS diag_cd9,
	max(CASE WHEN diag.diag_num = 10 THEN diag.diag_cd_1234 END) AS diag_cd10,
	max(crit_care.alf_e IS NOT NULL)                             AS critical_care_flg,
	min(crit_care.cc_admis_dt)                                   AS critical_care_date,
	1                                                            AS admis_covid19_cause_flg,
	0                                                            AS admis_with_covid19_flg,
	0                                                            AS covid19_during_admis_flg,
	max(cast(pcr_positive.alf_e IS NOT NULL AS SMALLINT))        AS within_14days_positive_pcr_flg
FROM
	-- all spells
	sail0911v.pedw_spell AS spell
INNER JOIN sail0911v.pedw_superspell AS superspell
    ON  spell.prov_unit_cd = superspell.prov_unit_cd
    AND spell.spell_num_e  = superspell.spell_num_e
INNER JOIN
	-- covid episode
	epi_covid AS epi
	ON  spell.prov_unit_cd = epi.prov_unit_cd
	AND spell.spell_num_e  = epi.spell_num_e
	AND epi.epi_num = superspell.epi_num
INNER JOIN
	-- all the ICD-10 codes associated with the episode
	sail0911v.pedw_diag AS diag
	ON  epi.prov_unit_cd = diag.prov_unit_cd
	AND epi.spell_num_e  = diag.spell_num_e
	AND epi.epi_num      = diag.epi_num
LEFT JOIN
	-- critical care information from Rowena G
	sailw0911v.rrda_ccid_iccd AS crit_care
	ON spell.alf_e = crit_care.alf_e
	AND (
		spell.admis_dt =  crit_care.hosp_admis_dt
		OR spell.admis_dt =  crit_care.icnarc_hosp_admis_dt
	)
LEFT JOIN
	pcr_positive
	ON spell.alf_e = pcr_positive.alf_e
	AND spell.admis_dt BETWEEN pcr_positive.pcr_date - 1 DAY AND pcr_positive.pcr_date + 14 DAYS
WHERE
	spell.alf_sts_cd IN (1, 4, 39)
GROUP BY
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	epi.epi_num
	;



-- Find spells in which the patient is admitted *with* COVID-19:
--  * we did not pick up the spell from the last step
-- 	* epi_num = 1
--  * any diag cd is for COVID-19

INSERT INTO sailw1151v.sa_dacvap_hosp_long
WITH
	pcr_positive AS
	(
		SELECT
			alf_e,
			alf_sts_cd,
			spcm_collected_dt AS pcr_date
		FROM
			sail0911v.patd_df_covid_lims_testresults
		WHERE
			alf_sts_cd IN (1, 4, 39)
			AND spcm_collected_dt IS NOT NULL
			AND covid19testresult = 'Positive'
	),
	epi_covid AS
	(
		-- here we are making use of the table we just prepared
		-- to find hospital admissions *with* covid-19
		SELECT
			prov_unit_cd,
			spell_num_e,
			person_spell_num_e,
			epi_num,
			MIN(epi_str_dt) AS epi_str_dt
		FROM
			sailw1151v.sa_dacvap_hosp_prep
		WHERE
			epi_num = '01'
			AND is_covid19 = 1
			AND rank_non_rz > 1
		GROUP BY
			prov_unit_cd,
			spell_num_e,
			person_spell_num_e,
			epi_num
	)
SELECT
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	max(spell.admis_dt)                                          AS spell_admis_date,
	max(CASE
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '1' THEN 'Elective admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '2' THEN 'Emergency admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '3' THEN 'Maternity admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '8' THEN 'Other'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '9' THEN 'Other'
	END)                                                         AS spell_admis_method,
	max(spell.disch_dt)                                          AS spell_disch_date,
	max(spell.spell_dur)                                         AS spell_duration_days,
	epi.epi_num,
	max(epi.epi_str_dt)                                          AS epi_start_date,
	max(CASE WHEN diag.diag_num =  1 THEN diag.diag_cd_1234 END) AS diag_cd1,
	max(CASE WHEN diag.diag_num =  2 THEN diag.diag_cd_1234 END) AS diag_cd2,
	max(CASE WHEN diag.diag_num =  3 THEN diag.diag_cd_1234 END) AS diag_cd3,
	max(CASE WHEN diag.diag_num =  4 THEN diag.diag_cd_1234 END) AS diag_cd4,
	max(CASE WHEN diag.diag_num =  5 THEN diag.diag_cd_1234 END) AS diag_cd5,
	max(CASE WHEN diag.diag_num =  6 THEN diag.diag_cd_1234 END) AS diag_cd6,
	max(CASE WHEN diag.diag_num =  7 THEN diag.diag_cd_1234 END) AS diag_cd7,
	max(CASE WHEN diag.diag_num =  8 THEN diag.diag_cd_1234 END) AS diag_cd8,
	max(CASE WHEN diag.diag_num =  9 THEN diag.diag_cd_1234 END) AS diag_cd9,
	max(CASE WHEN diag.diag_num = 10 THEN diag.diag_cd_1234 END) AS diag_cd10,
	max(crit_care.alf_e IS NOT NULL)                             AS critical_care_flg,
	min(crit_care.cc_admis_dt)                                   AS critical_care_date,
	0                                                            AS admis_covid19_cause_flg,
	1                                                            AS admis_with_covid19_flg,
	0                                                            AS covid19_during_admis_flg,
	max(cast(pcr_positive.alf_e IS NOT NULL AS SMALLINT))        AS within_14days_positive_pcr_flg
FROM
	-- all spells
	sail0911v.pedw_spell AS spell
INNER JOIN sail0911v.pedw_superspell AS superspell
    ON  spell.prov_unit_cd = superspell.prov_unit_cd
    AND spell.spell_num_e  = superspell.spell_num_e
INNER JOIN
	-- covid episode
	epi_covid AS epi
	ON  spell.prov_unit_cd = epi.prov_unit_cd
	AND spell.spell_num_e  = epi.spell_num_e
	AND epi.epi_num = superspell.epi_num
INNER JOIN
	-- all the ICD-10 codes associated with the episode
	sail0911v.pedw_diag AS diag
	ON  epi.prov_unit_cd = diag.prov_unit_cd
	AND epi.spell_num_e  = diag.spell_num_e
	AND epi.epi_num      = diag.epi_num
LEFT JOIN
	-- critical care information from Rowena G
	sailw0911v.rrda_ccid_iccd AS crit_care
	ON spell.alf_e = crit_care.alf_e
	AND (
		spell.admis_dt = crit_care.hosp_admis_dt
		OR spell.admis_dt = crit_care.icnarc_hosp_admis_dt
	)
LEFT JOIN
	pcr_positive
	ON spell.alf_e = pcr_positive.alf_e
	AND spell.admis_dt BETWEEN pcr_positive.pcr_date - 1 DAY AND pcr_positive.pcr_date + 14 days
LEFT JOIN
	sailw1151v.sa_dacvap_hosp_long AS hosp_long
	ON  spell.alf_e        = hosp_long.alf_e
	AND spell.prov_unit_cd = hosp_long.prov_unit_cd
	AND spell.spell_num_e  = hosp_long.spell_num_e
	AND superspell.person_spell_num_e = hosp_long.person_spell_num_e
	AND epi.epi_num        = hosp_long.epi_num
WHERE
	spell.alf_sts_cd IN (1, 4, 39)
	-- exlcude records we found previously
	AND hosp_long.alf_e IS NULL
GROUP BY
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	epi.epi_num;

-- Find spells in which the patient becomes infected with COVID-19 during admission:
--  * we did not pick up the spell from previous steps
-- 	* epi_num is 2 or more
--  * any diag cd is for COVID-19

INSERT INTO sailw1151v.sa_dacvap_hosp_long
WITH
	pcr_positive AS
	(
		SELECT
			alf_e,
			alf_sts_cd,
			spcm_collected_dt AS pcr_date
		FROM
			sail0911v.patd_df_covid_lims_testresults
		WHERE
			alf_sts_cd IN (1, 4, 39)
			AND spcm_collected_dt IS NOT NULL
			AND covid19testresult = 'Positive'
	),
	epi_covid AS
	(
		-- here we are making use of the table we just prepared
		-- to find hospital episodes after the first that have
		-- been coded for covid-19
		SELECT
			prov_unit_cd,
			spell_num_e,
			person_spell_num_e,
			min(epi_num) AS epi_num,
			min(epi_str_dt) AS epi_str_dt
		FROM
			sailw1151v.sa_dacvap_hosp_prep
		WHERE
			epi_num != '01'
			AND is_covid19 = 1
		GROUP BY
			prov_unit_cd,
			spell_num_e,
			person_spell_num_e
	)
SELECT
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	max(spell.admis_dt)                                          AS spell_admis_date,
	max(CASE
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '1' THEN 'Elective admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '2' THEN 'Emergency admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '3' THEN 'Maternity admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '8' THEN 'Other'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '9' THEN 'Other'
	END)                                                         AS spell_admis_method,
	max(spell.disch_dt)                                          AS spell_disch_date,
	max(spell.spell_dur)                                         AS spell_duration_days,
	epi.epi_num                                                  AS epi_num,
	min(epi.epi_str_dt)                                          AS epi_start_date,
	max(CASE WHEN diag.diag_num =  1 THEN diag.diag_cd_1234 END) AS diag_cd1,
	max(CASE WHEN diag.diag_num =  2 THEN diag.diag_cd_1234 END) AS diag_cd2,
	max(CASE WHEN diag.diag_num =  3 THEN diag.diag_cd_1234 END) AS diag_cd3,
	max(CASE WHEN diag.diag_num =  4 THEN diag.diag_cd_1234 END) AS diag_cd4,
	max(CASE WHEN diag.diag_num =  5 THEN diag.diag_cd_1234 END) AS diag_cd5,
	max(CASE WHEN diag.diag_num =  6 THEN diag.diag_cd_1234 END) AS diag_cd6,
	max(CASE WHEN diag.diag_num =  7 THEN diag.diag_cd_1234 END) AS diag_cd7,
	max(CASE WHEN diag.diag_num =  8 THEN diag.diag_cd_1234 END) AS diag_cd8,
	max(CASE WHEN diag.diag_num =  9 THEN diag.diag_cd_1234 END) AS diag_cd9,
	max(CASE WHEN diag.diag_num = 10 THEN diag.diag_cd_1234 END) AS diag_cd10,
	max(crit_care.alf_e IS NOT NULL)                             AS critical_care_flg,
	min(crit_care.cc_admis_dt)                                   AS critical_care_date,
	0                                                            AS admis_covid19_cause_flg,
	0                                                            AS admis_with_covid19_flg,
	1                                                            AS covid19_during_admis_flg,
	max(cast(pcr_positive.alf_e IS NOT NULL AS SMALLINT))        AS within_14days_positive_pcr_flg
FROM
	-- all spells
	sail0911v.pedw_spell AS spell
INNER JOIN sail0911v.pedw_superspell AS superspell
    ON  spell.prov_unit_cd = superspell.prov_unit_cd
    AND spell.spell_num_e  = superspell.spell_num_e
INNER JOIN
	-- covid episode
	epi_covid AS epi
	ON  spell.prov_unit_cd = epi.prov_unit_cd
	AND spell.spell_num_e  = epi.spell_num_e
	AND epi.epi_num = superspell.epi_num
INNER JOIN
	-- all the ICD-10 codes associated with the episode
	sail0911v.pedw_diag AS diag
	ON  epi.prov_unit_cd = diag.prov_unit_cd
	AND epi.spell_num_e  = diag.spell_num_e
	AND epi.epi_num      = diag.epi_num
LEFT JOIN
	-- critical care information from Rowena G
	sailw0911v.rrda_ccid_iccd AS crit_care
	ON spell.alf_e = crit_care.alf_e
	AND (
		spell.admis_dt = crit_care.hosp_admis_dt
		OR spell.admis_dt = crit_care.icnarc_hosp_admis_dt
	)
LEFT JOIN
	pcr_positive
	ON spell.alf_e = pcr_positive.alf_e
	AND spell.admis_dt BETWEEN pcr_positive.pcr_date - 1 DAY AND pcr_positive.pcr_date + 14 days
LEFT JOIN
	sailw1151v.sa_dacvap_hosp_long AS hosp_long
	ON  spell.alf_e        = hosp_long.alf_e
	AND spell.prov_unit_cd = hosp_long.prov_unit_cd
	AND spell.spell_num_e  = hosp_long.spell_num_e
	AND superspell.person_spell_num_e = hosp_long.person_spell_num_e
	AND epi.epi_num        = hosp_long.epi_num
WHERE
	spell.alf_sts_cd IN (1, 4, 39)
	-- exlcude records we found previously
	AND hosp_long.alf_e IS NULL
GROUP BY
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	epi.epi_num;


-- Find spells in which admission date is between -1 and 14 days of a positive PCR test
-- and is not already in the dacvap_hosp_long


INSERT INTO sailw1151v.sa_dacvap_hosp_long

SELECT
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	max(spell.admis_dt)                                          AS spell_admis_date,
	max(CASE
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '1' THEN 'Elective admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '2' THEN 'Emergency admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '3' THEN 'Maternity admission'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '8' THEN 'Other'
		WHEN LEFT(spell.ADMIS_MTHD_CD, 1) = '9' THEN 'Other'
	END)                                                         AS spell_admis_method,
	max(spell.disch_dt)                                          AS spell_disch_date,
	max(spell.spell_dur)                                         AS spell_duration_days,
	epi.epi_num,
	min(epi.epi_str_dt)                                          AS epi_start_date,
	max(CASE WHEN diag.diag_num =  1 THEN diag.diag_cd_1234 END) AS diag_cd1,
	max(CASE WHEN diag.diag_num =  2 THEN diag.diag_cd_1234 END) AS diag_cd2,
	max(CASE WHEN diag.diag_num =  3 THEN diag.diag_cd_1234 END) AS diag_cd3,
	max(CASE WHEN diag.diag_num =  4 THEN diag.diag_cd_1234 END) AS diag_cd4,
	max(CASE WHEN diag.diag_num =  5 THEN diag.diag_cd_1234 END) AS diag_cd5,
	max(CASE WHEN diag.diag_num =  6 THEN diag.diag_cd_1234 END) AS diag_cd6,
	max(CASE WHEN diag.diag_num =  7 THEN diag.diag_cd_1234 END) AS diag_cd7,
	max(CASE WHEN diag.diag_num =  8 THEN diag.diag_cd_1234 END) AS diag_cd8,
	max(CASE WHEN diag.diag_num =  9 THEN diag.diag_cd_1234 END) AS diag_cd9,
	max(CASE WHEN diag.diag_num = 10 THEN diag.diag_cd_1234 END) AS diag_cd10,
	MAX(crit_care.alf_e IS NOT NULL)                             AS critical_care_flg,
	MIN(crit_care.cc_admis_dt)                                   AS critical_care_date,
	0                                                            AS admis_covid19_cause_flg,
	0                                                            AS admis_with_covid19_flg,
	0                                                            AS covid19_during_admis_flg,
	1                                                            AS within_14days_positive_pcr_flg
FROM
	-- positive PCR tests
	sail0911v.patd_df_covid_lims_testresults AS pcr_test
INNER JOIN
	-- spells within 14 days of the positive PCR test
	sail0911v.pedw_spell AS spell
	ON pcr_test.alf_e = spell.alf_e
	AND spell.alf_sts_cd in (1, 4, 39)
	AND spell.admis_dt BETWEEN pcr_test.spcm_collected_dt - 1 DAY AND pcr_test.spcm_collected_dt + 14 DAYS
INNER JOIN sail0911v.pedw_superspell AS superspell
    ON  spell.prov_unit_cd = superspell.prov_unit_cd
    AND spell.spell_num_e  = superspell.spell_num_e
INNER JOIN
	-- first episode of the spell
	sail0911v.pedw_episode AS epi
	ON spell.prov_unit_cd = epi.prov_unit_cd
	AND spell.spell_num_e = epi.spell_num_e
	AND superspell.epi_num = epi.epi_num
	AND epi.epi_num = '01'	
INNER JOIN
	-- all ICD-10 codes
	sail0911v.pedw_diag AS diag
	ON  epi.prov_unit_cd = diag.prov_unit_cd
	AND epi.spell_num_e  = diag.spell_num_e
	AND epi.epi_num      = diag.epi_num
LEFT JOIN
	-- critical care information from Rowena G
	sailw0911v.rrda_ccid_iccd AS crit_care
	ON spell.alf_e = crit_care.alf_e
	AND (
		spell.admis_dt    = crit_care.hosp_admis_dt
		OR spell.admis_dt = crit_care.icnarc_hosp_admis_dt
	)
LEFT JOIN
	sailw1151v.sa_dacvap_hosp_long AS hosp_long
	ON  spell.alf_e        = hosp_long.alf_e
	AND spell.prov_unit_cd = hosp_long.prov_unit_cd
	AND spell.spell_num_e  = hosp_long.spell_num_e
	AND epi.epi_num        = hosp_long.epi_num
WHERE
	pcr_test.alf_sts_cd IN (1, 4, 39)
	AND pcr_test.spcm_collected_dt IS NOT NULL
	AND pcr_test.covid19testresult = 'Positive'
	-- exlcude records we found previously
	AND hosp_long.alf_e IS NULL
GROUP BY
	spell.alf_e,
	spell.prov_unit_cd,
	spell.spell_num_e,
	superspell.person_spell_num_e,
	epi.epi_num;

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_hosp_prep');

-- =============================================================================
-- Step 6: Prepare area and household info at 2021-08-04
-- =============================================================================

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_hh');

CREATE TABLE sailw1151v.sa_dacvap_hh (
	alf_e                  bigint   not null,
	res_date               date     not null,
	ralf_e                 bigint,
	ralf_sts_cd            varchar(1),
-- area
	lsoa2011_cd            varchar(10),
	wimd2019_quintile      smallint,
	lad2011_nm             varchar(48),
	health_board           varchar(48),
	urban_rural_class      varchar(56),
-- all household members
	household_n            smallint,
	household_age_min      smallint,
	household_age_avg      decimal(5,1),
	household_age_max      smallint,
-- children
	child_n                smallint,
	child_age_min          smallint,
	child_age_avg          decimal(5,1),
	child_age_max          smallint,
-- other adults
	adult_n                smallint,
	adult_age_min          smallint,
	adult_age_avg          decimal(5,1),
	adult_age_max          smallint,
-- adult/ household vaccination status
--	hh_min_vacc_date	   DATE,
--	hh_max_vacc_date	   DATE,
	hh_vaccinated		   VARCHAR(20),	
	PRIMARY KEY (alf_e)
);

INSERT INTO sailw1151v.sa_dacvap_hh
WITH
	cohort AS
	(
		SELECT
			alf_e,
			DATE '2021-08-04' AS res_date
		FROM
			sailw0911v.c19_cohort20
	),
	cohort_ralf AS
	(
		SELECT
			cohort.alf_e,
			cohort.res_date,
			wds_add.ralf_e,
			wds_add.ralf_sts_cd,
			wds_add.from_dt,
			wds_add.to_dt,
			wds_add.lsoa2011_cd,
			ROW_NUMBER() OVER (PARTITION BY cohort.alf_e, cohort.res_date ORDER BY wds_add.from_dt, wds_add.to_dt DESC) AS ralf_seq
		FROM
			cohort
		INNER JOIN
			sail0911v.wdsd_ar_pers AS wds_prs
			ON wds_prs.alf_e = cohort.alf_e
		INNER JOIN
			sail0911v.wdsd_ar_pers_add AS wds_add
			ON  wds_add.pers_id_e = wds_prs.pers_id_e
			AND wds_add.from_dt <= cohort.res_date
			AND wds_add.to_dt >= cohort.res_date
	),
	cohort_ralf_uniq AS
	(
		SELECT
			cohort_ralf.*,
			lkp_wimd.overall_quintile                               AS wimd2019_quintile,
			lkp_health_board.ua_desc                                AS lad2011_nm,
			lkp_health_board.lhb19nm                                AS health_board,
			lkp_urban_rural.ruc11cd || ' ' || lkp_urban_rural.ruc11 AS urban_rural_class
		FROM cohort_ralf
		LEFT JOIN sailrefrv.wimd2019_index_and_domain_ranks_by_small_area AS lkp_wimd
			ON cohort_ralf.lsoa2011_cd = lkp_wimd.lsoa2011_cd
		LEFT JOIN sailw0911v.st_lsoa_hb_lookup_200424 AS lkp_health_board
			ON cohort_ralf.lsoa2011_cd = lkp_health_board.lsoa2011_cd
		LEFT JOIN sailrefrv.rural_urban_class_2011_of_llsoareas_in_eng_and_wal AS lkp_urban_rural
			ON cohort_ralf.lsoa2011_cd = lkp_urban_rural.lsoa11cd
		WHERE ralf_seq = 1
	),
	hh_member_all AS
	(
		SELECT
		-- person of interest
			cohort.alf_e,
			cohort.res_date,
			cohort.ralf_e,
			cohort.ralf_sts_cd,
		-- other household member
			wds_prs.alf_e   AS hh_alf_e,
			ROW_NUMBER() OVER (PARTITION BY cohort.alf_e, cohort.res_date, wds_prs.alf_e ORDER BY wds_add.from_dt, wds_add.to_dt DESC) AS ralf_seq,
			wds_prs.gndr_cd,
			floor((days(cohort.res_date) - days(wds_prs.wob)) / 365.25) AS age
		FROM
			cohort_ralf_uniq AS cohort
		INNER JOIN
			sail0911v.wdsd_ar_pers_add AS wds_add
			ON cohort.ralf_e = wds_add.ralf_e
			AND cohort.res_date >= wds_add.from_dt
			AND cohort.res_date <= wds_add.to_dt
		INNER JOIN
			sail0911v.wdsd_ar_pers AS wds_prs
			ON wds_prs.pers_id_e = wds_add.pers_id_e
		WHERE
			cohort.ralf_e IS NOT NULL
		ORDER BY ralf_e
		),
	hh_adult_n AS 
	(
		SELECT 
			ralf_e,
			count(*)																		AS hh_adult_n
		FROM 
			hh_member_all
		WHERE age >= 18
		GROUP BY ralf_e, alf_e
		ORDER BY ralf_e	
	),		
	hh_vacc_stat_pre AS 
	(
		SELECT
			hh_alf_e,
			cohort.ralf_e,
			max(cvvd.alf_has_bad_vacc_record)												AS alf_has_bad_vacc_record,
			max(CASE WHEN cvvd.vacc_dose_seq = '1'
				AND vacc_date <= '2021-08-04' THEN 1 ELSE 0 END)							AS vaccinated,
			hh_adult_n
		FROM
			hh_member_all AS cohort
		LEFT JOIN
			sailw0911v.rrda_cvvd AS cvvd
			ON cohort.hh_alf_e = cvvd.alf_e
		LEFT JOIN 
			hh_adult_n 
			ON hh_adult_n.ralf_e = cohort.ralf_e
		WHERE age >= 18 
		GROUP BY hh_alf_e, cohort.ralf_e, hh_adult_n
		ORDER BY cohort.ralf_e, hh_alf_e
		),
	hh_vacc_stat AS 
	(
		SELECT
			ralf_e,
			CASE WHEN (SUM(vaccinated) = 0) THEN 'Unvaccinated'
				WHEN (SUM(vaccinated) > 0 AND SUM(vaccinated) <hh_adult_n) THEN 'Partially vaccinated'
				WHEN (SUM(vaccinated) = hh_adult_n) THEN 'Fully vaccinated'
			END 																				AS hh_vaccinated 			
--			CASE WHEN ((SUM(vaccinated)) >= 1) THEN 1 ELSE NULL END  							AS hh_vaccinated
		FROM 
			hh_vacc_stat_pre
		GROUP BY ralf_e, hh_adult_n
		ORDER BY ralf_e
		),
	hh_member_ind AS 
	(
		SELECT
			alf_e, res_date, mem_all.ralf_e, ralf_sts_cd, hh_alf_e, ralf_seq, gndr_cd, age, hh_vaccinated,
			-- make indicators used to summarise household members
			CAST(age >= 0 AND age <= 17                  AS smallint) AS is_child,
			CAST(age >= 18                               AS smallint) AS is_adult
		FROM
			hh_member_all mem_all
		LEFT JOIN
			hh_vacc_stat vacc
			ON mem_all.ralf_e = vacc.ralf_e
		WHERE
			-- remove any duplicated rows (there should on be a small number of duplicates)
			ralf_seq = 1
		ORDER BY alf_e
	),
	hh_summary AS
	(
		SELECT
			alf_e,
			res_date,
			ralf_e,
		-- all household members
			COUNT(*)                                           AS household_n,
			MIN(age)                                           AS household_age_min,
			AVG(age)                                           AS household_age_avg,
			MAX(age)                                           AS household_age_max,
		-- children
			SUM(is_child)                                      AS child_n,
			MIN(CASE WHEN is_child = 1 THEN age ELSE NULL END) AS child_age_min,
			AVG(CASE WHEN is_child = 1 THEN age ELSE NULL END) AS child_age_avg,
			MAX(CASE WHEN is_child = 1 THEN age ELSE NULL END) AS child_age_max,
		-- adults
			SUM(is_adult)                                      AS adult_n,
			MIN(CASE WHEN is_adult = 1 THEN age ELSE NULL END) AS adult_age_min,
			AVG(CASE WHEN is_adult = 1 THEN age ELSE NULL END) AS adult_age_avg,
			MAX(CASE WHEN is_adult = 1 THEN age ELSE NULL END) AS adult_age_max,
		-- adult household vaccination status
			MAX(hh_vaccinated)								   AS hh_vaccinated
		FROM
			hh_member_ind
		GROUP BY
			alf_e, res_date, ralf_e
	)
SELECT
	cohort_ralf_uniq.alf_e,
	cohort_ralf_uniq.res_date,
	cohort_ralf_uniq.ralf_e,
	cohort_ralf_uniq.ralf_sts_cd,
-- area
	cohort_ralf_uniq.lsoa2011_cd,
	cohort_ralf_uniq.wimd2019_quintile,
	cohort_ralf_uniq.lad2011_nm,
	cohort_ralf_uniq.health_board,
	cohort_ralf_uniq.urban_rural_class,
-- all household members
	hh_summary.household_n,
	hh_summary.household_age_min,
	hh_summary.household_age_avg,
	hh_summary.household_age_max,
-- children
	hh_summary.child_n,
	hh_summary.child_age_min,
	hh_summary.child_age_avg,
	hh_summary.child_age_max,
-- adults
	hh_summary.adult_n,
	hh_summary.adult_age_min,
	hh_summary.adult_age_avg,
	hh_summary.adult_age_max,
-- adult/ household vaccination status
	hh_vaccinated
FROM cohort_ralf_uniq
LEFT JOIN hh_summary
	ON 	hh_summary.alf_e    = cohort_ralf_uniq.alf_e
	AND hh_summary.res_date = cohort_ralf_uniq.res_date
	AND hh_summary.ralf_e   = cohort_ralf_uniq.ralf_e;

SELECT * FROM sailw1151v.sa_dacvap_hh;

SELECT * FROM sailw0911v.rrda_cvvd;

-- =============================================================================
-- Step 7: Death
-- =============================================================================

CALL FNC.DROP_IF_EXISTS('sailw1151v.sa_dacvap_death');

CREATE TABLE sailw1151v.sa_dacvap_death (
	alf_e           BIGINT NOT NULL,
	death_date      DATE,
	death_covid_flg SMALLINT,
	PRIMARY KEY (alf_e)
);

INSERT INTO sailw1151v.sa_dacvap_death
SELECT
	death.alf_e,
	death.dod,
	CAST(death.covid_yn_underlying_or_secondary_qcovid = 'y' AS SMALLINT) AS covid_flg
FROM
	sailw1151v.dacvap2_cyp AS cohort
INNER JOIN
	sailw0911v.c19_cohort20_mortality AS death
	ON death.alf_e = cohort.alf_e
WHERE
	death.dod IS NOT NULL
	AND death.alf_e IS NOT NULL;

GRANT ALL ON TABLE sailw1151v.sa_dacvap_death
TO ROLE NRDASAIL_SAIL_1151_ANALYST;

-- =============================================================================
-- Step 8: Check simple counts for outcomes
-- =============================================================================

WITH
	death_tidy AS
	(
		SELECT
			CASE
				WHEN death_covid_flg IS NULL THEN 'Still alive, probably'
				WHEN death_covid_flg = 1     THEN 'COVID-19 related death'
				WHEN death_covid_flg = 0     THEN 'Standard death'
			END AS cat
		FROM sailw1151v.dacvap2_cyp AS cohort
		LEFT JOIN sailw1151v.sa_dacvap_death AS death
			ON cohort.alf_e = death.alf_e
	),
	pcr_tidy AS
	(
		SELECT
			CASE
				WHEN test_ever_flg = 0                                  THEN 'Never been tested'
				WHEN test_ever_flg = 1 AND infection1_test_date IS NULL THEN 'Never tested positive'
				WHEN infection4_test_date IS NOT NULL                   THEN 'Infected 4 times'
				WHEN infection3_test_date IS NOT NULL                   THEN 'Infected 3 times'
				WHEN infection2_test_date IS NOT NULL                   THEN 'Infected 2 times'
				WHEN infection1_test_date IS NOT NULL                   THEN 'Infected 1 time'
			END	AS cat
		FROM sailw1151v.dacvap2_cyp AS cohort
		LEFT JOIN sailw1151v.sa_dacvap_pcr_test AS pcr_test
			ON cohort.alf_e = pcr_test.alf_e
	),
	lft_pcr_tidy AS
	(
		SELECT
			CASE
				WHEN pcr_ever_flg = 0 AND lft_ever_flg = 0
					THEN 'Never been tested'
				WHEN (pcr_ever_flg = 1 OR lft_ever_flg = 1) AND infection1_test_date IS NULL
					THEN 'Never tested positive'
				WHEN infection4_test_date IS NOT NULL
					THEN 'Infected 4 times'
				WHEN infection3_test_date IS NOT NULL
					THEN 'Infected 3 times'
				WHEN infection2_test_date IS NOT NULL
					THEN 'Infected 2 times'
				WHEN infection1_test_date IS NOT NULL
					THEN 'Infected 1 time'
			END	AS cat
		FROM sailw1151v.dacvap2_cyp AS cohort
		LEFT JOIN sailw1151v.sa_dacvap_lft_pcr_test AS test
			ON cohort.alf_e = test.alf_e
	),
	vacc_tidy AS
	(
		SELECT
			CASE
				WHEN vacc_doseb_date IS NOT NULL THEN 'Booster dose'
				WHEN vacc_dose3_date IS NOT NULL THEN '3rd dose'
				WHEN vacc_dose2_date IS NOT NULL THEN '2nd dose'
				WHEN vacc_dose1_date IS NOT NULL THEN '1st dose'
				WHEN vacc_dose1_date IS     NULL THEN 'Unvaccinated'
			END AS cat
		FROM sailw1151v.dacvap2_cyp AS cohort
		LEFT JOIN sailw1151v.sa_dacvap_vacc AS vacc
			ON cohort.alf_e = vacc.alf_e
	),
	hosp_tidy AS
	(
		SELECT
			CASE
				WHEN MAX(hosp_long.alf_e IS NOT NULL AND admis_covid19_cause_flg        = 1) THEN 'Admitted due to COVID-19'
				WHEN MAX(hosp_long.alf_e IS NOT NULL AND admis_with_covid19_flg         = 1) THEN 'Admitted with COVID-19'
				WHEN MAX(hosp_long.alf_e IS NOT NULL AND covid19_during_admis_flg       = 1) THEN 'Infected with COVID-19 during admission'
				WHEN MAX(hosp_long.alf_e IS NOT NULL AND within_14days_positive_pcr_flg = 1) THEN 'Admitted within 14 days of positive PCR'
				WHEN MAX(hosp_long.alf_e IS     NULL)                                        THEN 'Never admitted to hospital'
			END AS cat
		FROM sailw1151v.dacvap2_cyp AS cohort
		LEFT JOIN sailw1151v.sa_dacvap_hosp_long AS hosp_long
			ON cohort.alf_e = hosp_long.alf_e
		GROUP BY cohort.alf_e
	),
	hh_n_tidy AS 
	(
		SELECT 
			CASE 
				WHEN household_n = 1 THEN 'Houshold_1'
				WHEN household_n = 2 THEN 'Houshold_2'
				WHEN household_n = 3 THEN 'Houshold_3'
				WHEN household_n = 4 THEN 'Houshold_4'
				WHEN household_n = 5 THEN 'Houshold_5'
				WHEN household_n = 6 THEN 'Houshold_6'
				WHEN household_n >= 7 THEN 'Houshold_7+'
				WHEN household_n IS NULL THEN 'Household_is_null'
			END AS cat
		FROM sailw1151v.dacvap2_cyp AS cohort
		LEFT JOIN sailw1151v.sa_dacvap_hh AS hh
			ON cohort.alf_e = hh.alf_e
	),
	hh_v_tidy AS 
	(
		SELECT 
			CASE 
				WHEN hh_vaccinated = 'Fully vaccinated' THEN 'Household = Vaccinated'
				WHEN hh_vaccinated = 'Partially vaccinated' THEN 'Household = Partially Vaccinated'
				WHEN hh_vaccinated = 'Unvaccinated' THEN 'Household = Unvaccinated'
				WHEN hh_vaccinated IS NULL THEN 'Household vaccination status unknown'
			END AS cat
		FROM sailw1151v.dacvap2_cyp AS cohort
		LEFT JOIN sailw1151v.sa_dacvap_hh AS hh
			ON cohort.alf_e = hh.alf_e
	)
SELECT 'death'        AS outcome, cat, COUNT(*) AS n FROM death_tidy   GROUP BY cat
UNION
SELECT 'pcr_test'     AS outcome, cat, COUNT(*) AS n FROM pcr_tidy     GROUP BY cat
UNION
SELECT 'lft_pcr_test' AS outcome, cat, COUNT(*) AS n FROM lft_pcr_tidy GROUP BY cat
UNION
SELECT 'vacc'         AS outcome, cat, COUNT(*) AS n FROM vacc_tidy    GROUP BY cat
UNION
SELECT 'hosp'         AS outcome, cat, COUNT(*) AS n FROM hosp_tidy    GROUP BY cat
UNION 
SELECT 'hhn'		  AS outcome, cat, COUNT(*) AS n FROM hh_n_tidy	   GROUP BY cat
UNION 
SELECT 'hhv'		  AS outcome, cat, COUNT(*) AS n FROM hh_v_tidy	   GROUP BY cat
ORDER BY outcome, cat;




SELECT
-- main id
    cohort.alf_e,
-- c19 cohort 20
    cohort.pers_id_e,
    cohort.wob,
    cohort.gndr_cd,
    cohort.wds_start_date,
    cohort.wds_end_date,
    cohort.gp_start_date,
    cohort.gp_end_date,
    cohort.c20_start_date,
    cohort.c20_end_date,
-- ethnicity
    cohort.ethn_cat,
-- area and household info at 2020-12-07
    cohort.ralf_e,
    cohort.ralf_sts_cd,
    cohort.lsoa2011_cd,
    cohort.wimd2019_quintile,
    cohort.health_board,
    cohort.urban_rural_class,
    hh.household_n,
    hh.adult_n,
    hh_vaccinated,
-- shielded patient
    cohort.shielded_flg,
-- vaccine data quality
    vacc.has_bad_vacc_record,
-- first dose
    vacc.vacc_dose1_date,
    vacc.vacc_dose1_name,
    vacc.vacc_dose1_reaction_ind,
    vacc.vacc_dose1_reaction_cd,
-- second dose
    vacc.vacc_dose2_date,
    vacc.vacc_dose2_name,
    vacc.vacc_dose2_reaction_ind,
    vacc.vacc_dose2_reaction_cd,
-- third dose
    vacc.vacc_dose3_date,
    vacc.vacc_dose3_name,
    vacc.vacc_dose3_reaction_ind,
    vacc.vacc_dose3_reaction_cd,
-- booster dose
    vacc.vacc_doseb_date,
    vacc.vacc_doseb_name,
    vacc.vacc_doseb_reaction_ind,
    vacc.vacc_doseb_reaction_cd,
-- pcr test history
    lft_pcr_test.pcr_ever_flg,
    lft_pcr_test.pcr_pre08dec2020_n,
    lft_pcr_test.pcr_pre16sep2021_n,
-- lft test history
    lft_pcr_test.lft_ever_flg,
    lft_pcr_test.lft_pre08dec2020_n,
    lft_pcr_test.lft_pre16sep2021_n,
-- number of infections
    lft_pcr_test.infection_n,
-- positive tests 90 days apart
    lft_pcr_test.infection1_test_date,
    lft_pcr_test.infection2_test_date,
    lft_pcr_test.infection3_test_date,
    lft_pcr_test.infection4_test_date,
-- death
    death.death_date,
    death.death_covid_flg
FROM sailw1151v.dacvap2_cyp AS cohort
LEFT JOIN sailw1151v.sa_dacvap_vacc AS vacc
    ON cohort.alf_e = vacc.alf_e
LEFT JOIN sailw1151v.sa_dacvap_lft_pcr_test AS lft_pcr_test
    ON cohort.alf_e = lft_pcr_test.alf_e
LEFT JOIN sailw1151v.sa_dacvap_death AS death
    ON cohort.alf_e = death.alf_e
LEFT JOIN sailw1151v.sa_dacvap_hh  AS hh
    ON cohort.alf_e = hh.alf_e
