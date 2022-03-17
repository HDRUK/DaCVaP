/* Contents:
 *  - Drop
 *  - Create
 *  - Grant
 *  - Insert C20, mortality, testing, vacc and qcovid info
 */
--

-------------------------------------------------------------------
--copy of current table with coverage up to end of June: 20210630
/*
CREATE TABLE sailw0911v.vac17_cohort_20210630 AS (
SELECT * FROM sailw0911v.vac17_cohort) WITH NO DATA; 
INSERT INTO sailw0911v.vac17_cohort_20210630 
SELECT * FROM sailw0911v.vac17_cohort; 
COMMIT; 
*/
-------------------------------------------------------------------

CALL FNC.DROP_IF_EXISTS('sailw0911v.vac17_cohort');

CREATE TABLE sailw0911v.vac17_cohort (
    alf_e                    BIGINT NOT NULL,
    c20_wob                  DATE,
    c20_gndr_cd              SMALLINT,
    c20_cohort_start_date    DATE,
    c20_move_out_date        DATE,
    c20_cohort_end_date      DATE,
    c20_gp_end_date          DATE,
    c20_gp_coverage_end_date DATE,
    age                      SMALLINT,
    age_matched              VARCHAR(7),
    lsoa2011_cd              VARCHAR(10),
    lsoa2011_nm              VARCHAR(26),
    msoa2011_cd              VARCHAR(10),
    msoa2011_nm              VARCHAR(25),
    wimd_2019_rank           INTEGER,
    wimd_2019_decile         SMALLINT,
    wimd_2019_quintile       SMALLINT,
    has_death                SMALLINT,
    death_date               DATE,
    is_death_covid           SMALLINT,
    prior_testing_n          SMALLINT,
    has_positive_test        SMALLINT,
    positive_test_date       DATE,
    has_vacc                 SMALLINT,
    has_bad_vacc_record      SMALLINT,
    vacc_first_date          DATE,
    vacc_first_name          VARCHAR(50),
    vacc_second_date         DATE,
    vacc_second_name         VARCHAR(50),
    vacc_booster_date		 DATE, 
    vacc_booster_name		 VARCHAR(50),
    has_qc                   SMALLINT,
    qc_b2_82                 SMALLINT,
    qc_b2_leukolaba          SMALLINT,
    qc_b2_prednisolone       SMALLINT,
    qc_b_af                  SMALLINT,
    qc_b_ccf                 SMALLINT,
    qc_b_asthma              SMALLINT,
    qc_b_bloodcancer         SMALLINT,
    qc_b_cerebralpalsy       SMALLINT,
    qc_b_chd                 SMALLINT,
    qc_b_cirrhosis           SMALLINT,
    qc_b_congenheart         SMALLINT,
    qc_b_copd                SMALLINT,
    qc_b_dementia            SMALLINT,
    qc_b_epilepsy            SMALLINT,
    qc_b_fracture4           SMALLINT,
    qc_b_neurorare           SMALLINT,
    qc_b_parkinsons          SMALLINT,
    qc_b_pulmhyper           SMALLINT,
    qc_b_pulmrare            SMALLINT,
    qc_b_pvd                 SMALLINT,
    qc_b_ra_sle              SMALLINT,
    qc_b_respcancer          SMALLINT,
    qc_b_semi                SMALLINT,
    qc_b_sicklecelldisease   SMALLINT,
    qc_b_stroke              SMALLINT,
    qc_diabetes_cat          SMALLINT,
    qc_b_vte                 SMALLINT,
    qc_bmi                   DECIMAL(31, 8),
    qc_chemo_cat             SMALLINT,
    qc_home_cat              SMALLINT,
    qc_learn_cat             SMALLINT,
    qc_p_marrow6             SMALLINT,
    qc_p_radio6              SMALLINT,
    qc_p_solidtransplant     SMALLINT,
    qc_renal_cat             SMALLINT,
    smoking_cat              VARCHAR(1),
    smoking_dt               DATE,
    is_sample                SMALLINT NOT NULL DEFAULT 0,
---START/ incident categories and dates 
--clearance: 2019-01-09 to 2020-12-06
    gp_clearance_vte_dt 							DATE,  
    gp_clearance_csvt_dt				 			DATE, 
	gp_clearance_haemorrhage_dt			 			DATE,
    gp_clearance_thrombocytopenia_dt	 			DATE, 
    gp_clearance_ITP_dt					 			DATE,
    gp_clearance_at_dt					 			DATE,    
    gp_clearance_mi_dt 								DATE,  
    gp_clearance_isch_stroke_dt						DATE,  
--post     2020-12-07 to 2021-06-30
  	gp_post_vte_dt				 					DATE,  
    gp_post_csvt_dt					 				DATE, 
    gp_post_haemorrhage_dt		 					DATE,    
    gp_post_thrombocytopenia_dt		 				DATE, 
    gp_post_ITP_dt 					 				DATE,
    gp_post_at_dt 					 				DATE,
    gp_post_mi_dt 									DATE,  
    gp_post_isch_stroke_dt							DATE,  

 --all in one
    gp_incident_dt              DATE,
    gp_incident_type            INTEGER,
    gp_incident_cat             VARCHAR(225),   
 --clearance: 2019-01-09 to 2020-12-06
    pedw_clearance_vte_dt 							DATE,  
    pedw_clearance_csvt_dt				 			DATE, 
	pedw_clearance_haemorrhage_dt			 		DATE,
    pedw_clearance_thrombocytopenia_dt	 			DATE, 
    pedw_clearance_ITP_dt					 		DATE,
    pedw_clearance_at_dt					 		DATE,    
	pedw_clearance_mi_dt 							DATE,  
    pedw_clearance_isch_stroke_dt					DATE,  
--post     2020-12-07 to 2021-06-30   
  	pedw_post_vte_dt				 				DATE,  
    pedw_post_csvt_dt					 			DATE, 
    pedw_post_haemorrhage_dt		 				DATE,    
    pedw_post_thrombocytopenia_dt		 			DATE, 
    pedw_post_ITP_dt 					 			DATE,
    pedw_post_at_dt 					 			DATE,    
	pedw_post_mi_dt 								DATE,  
    pedw_post_isch_stroke_dt						DATE,  
 --all in one
    pedw_incident_dt        DATE,
    pedw_incident_type      INTEGER,
    pedw_incident_cat       VARCHAR(225),   
 --all combined pedw and gp incidents
    incident_dt             DATE,
    incident_type           INTEGER,
    incident_cat            VARCHAR(225),  
 --no clearance outcome events
  	gp_outcome_dt			DATE, 
 	gp_outcome_type			INTEGER, 
    gp_outcome_cat			varchar(225), 
--pedw
    pedw_outcome_dt			DATE, 
 	pedw_outcome_type		INTEGER, 
    pedw_outcome_cat		varchar(225), 
  --combined  
  	outcome_dt				DATE, 
 	outcome_type			INTEGER, 
    outcome_cat				varchar(225), 
 ---END/incident categories and dates  
 	pre_vacc_followup        INTEGER,
 	post_vacc_followup		 INTEGER,
    person_days_exposed      INTEGER,
    hypertension_event       SMALLINT,
    hypertension_dt          DATE,
    hypertension_cat         VARCHAR(255),
    PRIMARY KEY (alf_e)
) DISTRIBUTE BY HASH (alf_e);

GRANT ALL ON TABLE sailw0911v.vac17_cohort TO ROLE NRDASAIL_SAIL_0911_ANALYST;

/* initial insert of c20, mortality and vaccination info */

INSERT INTO sailw0911v.vac17_cohort (
    alf_e,
    c20_wob,
    c20_gndr_cd,
    c20_cohort_start_date,
    c20_move_out_date,
    c20_cohort_end_date,
    c20_gp_end_date,
    c20_gp_coverage_end_date,
    age,
    lsoa2011_cd,
    lsoa2011_nm,
    msoa2011_cd,
    msoa2011_nm,
    wimd_2019_rank,
    wimd_2019_decile,
    wimd_2019_quintile,
    has_death,
    death_date,
    is_death_covid,
    prior_testing_n,
    has_positive_test,
    positive_test_date,
    has_vacc,
    has_bad_vacc_record,
    vacc_first_date,
    vacc_first_name,
    vacc_second_date,
    vacc_second_name,
    vacc_third_date,
    vacc_third_name,
    vacc_booster_date,
    vacc_booster_name,
    has_qc,
    qc_b2_82,
    qc_b2_leukolaba,
    qc_b2_prednisolone,
    qc_b_af,
    qc_b_ccf,
    qc_b_asthma,
    qc_b_bloodcancer,
    qc_b_cerebralpalsy,
    qc_b_chd,
    qc_b_cirrhosis,
    qc_b_congenheart,
    qc_b_copd,
    qc_b_dementia,
    qc_b_epilepsy,
    qc_b_fracture4,
    qc_b_neurorare,
    qc_b_parkinsons,
    qc_b_pulmhyper,
    qc_b_pulmrare,
    qc_b_pvd,
    qc_b_ra_sle,
    qc_b_respcancer,
    qc_b_semi,
    qc_b_sicklecelldisease,
    qc_b_stroke,
    qc_diabetes_cat,
    qc_b_vte,
    qc_bmi,
    qc_chemo_cat,
    qc_home_cat,
    qc_learn_cat,
    qc_p_marrow6,
    qc_p_radio6,
    qc_p_solidtransplant,
    qc_renal_cat
)
WITH
    /* event: any vaccinated */
    alf_vacc_flg AS (
        SELECT
            vacc.alf_e,
            MAX(vacc.alf_has_bad_vacc_record) AS alf_has_bad_vacc_record
        FROM
            sailw0911v.RRDA_CVVD_20211231 AS vacc
        GROUP BY
        	vacc.alf_e
    ),
    /* event: first vaccination */
    alf_vacc_first AS (
        SELECT
            vacc.alf_e,
            vacc.vacc_date,
            vacc.vacc_dose_seq,
            vacc.vacc_name
        FROM
            sailw0911v.RRDA_CVVD_20211231  AS vacc
        WHERE
            alf_has_bad_vacc_record = 0 AND
            vacc_dose_seq  IN  ('1')
    ),
    /* event: second vaccination */
    alf_vacc_second AS (
        SELECT
            vacc.alf_e,
            vacc.vacc_date,
            vacc.vacc_dose_seq,
            vacc.vacc_name
        FROM
            sailw0911v.RRDA_CVVD_20211231  AS vacc
        WHERE
            alf_has_bad_vacc_record = 0 AND
            vacc_dose_seq  IN  ('2')
    ),
    /* event: third vaccination */
    alf_vacc_third AS (
        SELECT  DISTINCT
            vacc.alf_e,
            min(vacc.vacc_date) vacc_date,
            vacc_dose_seq,
            vacc.vacc_name
        FROM
            sailw0911v.RRDA_CVVD_20211231  AS vacc
        WHERE
            alf_has_bad_vacc_record = 0 AND
            vacc_dose_seq  IN  ('3')
        GROUP BY 
        vacc_name, vacc_dose_seq, alf_e
    ),    
    /* event: booster vaccination */
    alf_vacc_booster AS (
        SELECT  DISTINCT
            vacc.alf_e,
            min(vacc.vacc_date) vacc_date,
            vacc_dose_seq,
            vacc.vacc_name
        FROM
            sailw0911v.RRDA_CVVD_20211231  AS vacc
        WHERE
            alf_has_bad_vacc_record = 0 AND
            vacc_dose_seq  IN  ('B1')
        GROUP BY 
        vacc_name, vacc_dose_seq, alf_e
    ),
    /* summary: number of tests prior to cohort start date */
    alf_test_summary AS (
        SELECT
            test.alf_e,
            COUNT(distinct spcm_collected_dt) AS n
        FROM
            sail0911v.patd_df_covid_lims_testresults AS test
        WHERE
        	/* this the same number of days (282) as the Scottish work, they
        	 * went with 2020-03-01 <= x < 2020-12-08
        	 */
	        test.spcm_collected_dt >= '2020-02-29' AND
            test.spcm_collected_dt <  '2020-12-07' AND
            test.alf_e IS NOT NULL
        GROUP BY
            test.alf_e
    ),
    /* event: positive covid test */
    alf_positive_test AS (
        SELECT
            test.alf_e,
            MIN(test.spcm_collected_dt) AS positive_test_date
        FROM
            sail0911v.patd_df_covid_lims_testresults AS test
        WHERE
            test.covid19testresult = 'Positive' AND
            test.alf_e IS NOT NULL
        GROUP BY
            test.alf_e
    ),
    /* event: covid and non-covid deaths */
    alf_death AS (
        SELECT
            mortality.alf_e,
            mortality.dod,
            CASE
                WHEN mortality.covid_yn_underlying              = 'y' THEN 1
                WHEN mortality.covid_yn_secondary               = 'y' THEN 1
                WHEN mortality.covid_yn_underlying_or_secondary = 'y' THEN 1
                WHEN mortality.cdds_positive_covid_19_flg       =  1  THEN 1
                ELSE 0
            END AS is_death_covid,
            ROW_NUMBER() OVER (PARTITION BY mortality.alf_e ORDER BY mortality.dod) AS seq
        FROM
            sailw0911v.c19_cohort20_mortality AS mortality
        WHERE
            mortality.dod   IS NOT NULL AND
            mortality.alf_e IS NOT NULL
    ),
    alf_death_dedup AS (
        SELECT
            alf_e,
            dod AS death_date,
            is_death_covid
        FROM
            alf_death
        WHERE
            seq = 1
    ),
    /* WDSD clean table for ALFs at start of vaccination programme */
    alf_area AS (
	SELECT
		*
	FROM
		sail0911v.wdsd_clean_add_geog_char_lsoa2011
	WHERE
        start_date <= '2020-12-07' AND
        end_date   >= '2020-12-07'
	)
SELECT
    /* c19 cohort2020 */
    c20.alf_e,
    c20.wob                                              AS c20_wob,
    c20.gndr_cd                                          AS c20_gndr_cd,
    c20.cohort_start_date                                AS c20_cohort_start_date,
    c20.move_out_date                                    AS c20_move_out_date,
    c20.cohort_end_date                                  AS c20_cohort_end_date,
    c20.gp_end_date                                      AS c20_gp_end_date,
    c20.gp_coverage_end_date                             AS c20_gp_coverage_end_date,
    /* calculate age */
    FLOOR((DAYS('2021-02-28') - DAYS(c20.wob)) / 365.25) AS age,
    /* area at 7th December */
    alf_area.lsoa2011_cd                                 AS lsoa2011_cd,
    lkp_msoa.lsoa11nm                                    AS lsoa2011_nm,
    lkp_msoa.msoa11cd                                    AS msoa2011_cd,
    lkp_msoa.msoa11nm                                    AS msoa2011_nm,
    alf_area.wimd_2019_rank                              AS wimd_2019_rank,
    alf_area.wimd_2019_decile                            AS wimd_2019_decile,
    alf_area.wimd_2019_quintile                          AS wimd_2019_decile,
    /* death */
    CAST(
        alf_death_dedup.alf_e IS NOT NULL AS INTEGER
    )                                                    AS has_death,
    alf_death_dedup.death_date,
    alf_death_dedup.is_death_covid,
    /* prior testing */
    CASE
        WHEN alf_test_summary.n IS NULL THEN 0
        ELSE alf_test_summary.n
    END                                                  AS prior_testing_n,
    /* positive test */
    CAST(
        alf_positive_test.alf_e IS NOT NULL AS INTEGER
    )                                                    AS has_positive_test,
    alf_positive_test.positive_test_date,
    /* vaccination */
    CAST(
        alf_vacc_flg.alf_e IS NOT NULL AS INTEGER
    )                                                    AS has_vacc,
    alf_vacc_flg.alf_has_bad_vacc_record                 AS has_bad_vacc_record,
    alf_vacc_first.vacc_date                             AS vacc_first_date,
    alf_vacc_first.vacc_name                             AS vacc_first_name,
    alf_vacc_second.vacc_date                            AS vacc_second_date,
    alf_vacc_second.vacc_name                            AS vacc_second_name,
    alf_vacc_booster.vacc_date                           AS vacc_booster_date,
    alf_vacc_booster.vacc_name                           AS vacc_booster_name,
    /* qcovid */
    CAST(
        qcovid.alf_e IS NOT NULL AS INTEGER
    )                                                    AS has_qc,
    qcovid.b2_82                                         AS qc_b2_82,
    qcovid.b2_leukolaba                                  AS qc_b2_leukolaba,
    qcovid.b2_prednisolone                               AS qc_b2_prednisolone,
    qcovid.b_af                                          AS qc_b_af,
    qcovid.b_ccf                                         AS qc_b_ccf,
    qcovid.b_asthma                                      AS qc_b_asthma,
    qcovid.b_bloodcancer                                 AS qc_b_bloodcancer,
    qcovid.b_cerebralpalsy                               AS qc_b_cerebralpalsy,
    qcovid.b_chd                                         AS qc_b_chd,
    qcovid.b_cirrhosis                                   AS qc_b_cirrhosis,
    qcovid.b_congenheart                                 AS qc_b_congenheart,
    qcovid.b_copd                                        AS qc_b_copd,
    qcovid.b_dementia                                    AS qc_b_dementia,
    qcovid.b_epilepsy                                    AS qc_b_epilepsy,
    qcovid.b_fracture4                                   AS qc_b_fracture4,
    qcovid.b_neurorare                                   AS qc_b_neurorare,
    qcovid.b_parkinsons                                  AS qc_b_parkinsons,
    qcovid.b_pulmhyper                                   AS qc_b_pulmhyper,
    qcovid.b_pulmrare                                    AS qc_b_pulmrare,
    qcovid.b_pvd                                         AS qc_b_pvd,
    qcovid.b_ra_sle                                      AS qc_b_ra_sle,
    qcovid.b_respcancer                                  AS qc_b_respcancer,
    qcovid.b_semi                                        AS qc_b_semi,
    qcovid.b_sicklecelldisease                           AS qc_b_sicklecelldisease,
    qcovid.b_stroke                                      AS qc_b_stroke,
    qcovid.diabetes_cat                                  AS qc_diabetes_cat,
    qcovid.b_vte                                         AS qc_b_vte,
    qcovid.bmi                                           AS qc_bmi,
    qcovid.chemocat                                      AS qc_chemo_cat,
    qcovid.homecat                                       AS qc_home_cat,
    qcovid.learncat                                      AS qc_learn_cat,
    qcovid.p_marrow6                                     AS qc_p_marrow6,
    qcovid.p_radio6                                      AS qc_p_radio6,
    qcovid.p_solidtransplant                             AS qc_p_solidtransplant,
    qcovid.renalcat                                      AS qc_renal_cat
FROM
    sailw0911v.C19_COHORT20_20220117 AS c20
LEFT JOIN
    alf_death_dedup
    ON c20.alf_e = alf_death_dedup.alf_e
LEFT JOIN
    alf_test_summary
    ON c20.alf_e = alf_test_summary.alf_e
LEFT JOIN
    alf_positive_test
    ON c20.alf_e = alf_positive_test.alf_e
LEFT JOIN
    alf_vacc_flg
    ON c20.alf_e = alf_vacc_flg.alf_e
LEFT JOIN
    alf_vacc_first
    ON c20.alf_e = alf_vacc_first.alf_e
LEFT JOIN
    alf_vacc_second
    ON c20.alf_e = alf_vacc_second.alf_e
LEFT JOIN
    alf_vacc_third
    ON c20.alf_e = alf_vacc_second.alf_e
LEFT JOIN
    alf_vacc_booster
    ON c20.alf_e = alf_vacc_booster.alf_e    
LEFT JOIN
    alf_area
    ON c20.alf_e = alf_area.alf_e
LEFT JOIN
    sailw0911v.jl_dacvap AS qcovid
    ON c20.alf_e = qcovid.alf_e
LEFT JOIN
    sailw0911v.dacvap_lkp_lsoa_to_msoa AS lkp_msoa
    ON 
    alf_area.lsoa2011_cd = lkp_msoa.lsoa11cd
;
