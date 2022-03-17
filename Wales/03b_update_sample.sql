/* who is eligible to be in the cohort?
 *
 * criteria are:
 *  - in c20
 *  - in c20 at cohort start
 *  - has wob and sex
 *  - has lsoa at cohort start
 *  - is registered with a GP at cohort start
 *  - has no bad vacc records
 *  - has qcovid measures
 *  - aged 15 years or older
 */

/* update is_sample in cohort table with those that meet the criteria */

UPDATE sailw0911v.vac17_cohort
SET is_sample = 1
WHERE
    c20_cohort_end_date > '2020-12-07'
    AND c20_wob IS NOT NULL
    AND c20_gndr_cd IS NOT NULL
    AND lsoa2011_cd IS NOT NULL
    AND c20_gp_end_date > '2020-12-07'
--    AND has_qc = 1
    AND (has_bad_vacc_record IS NULL OR has_bad_vacc_record = 0)
    AND age >= 16
			--excludin MD vaccines
			    AND 
				(
				VACC_SECOND_NAME NOT IN ('COVID-19 (MODERNA)')
				or
				VACC_FIRST_NAME NOT IN ('COVID-19 (MODERNA)')
				OR 
				VACC_FIRST_DATE IS NULL 
				)    
;

COMMIT;
