/* update smoking status in dacvap_cohort given dacvap_gp_smoke */

MERGE INTO sailw0911v.vac17_cohort AS cohort
USING
	(
		/* latest smoking record */
		SELECT
			alf_e,
			smoker_type,
			event_dt
		FROM
			/* subquery just adds rownumber which we can then filter by */
			(
				SELECT
					*,
		            ROW_NUMBER() OVER (PARTITION BY alf_e ORDER BY event_dt DESC, event_cd DESC) AS alf_event_seq
				FROM
					sailw0911v.vac17_gp_smoke
				ORDER BY
					alf_e, event_dt, event_cd
			) AS t
		WHERE
			alf_event_seq = 1
	) AS alf_smoke_dedup
ON cohort.alf_e = alf_smoke_dedup.alf_e
WHEN MATCHED THEN
UPDATE SET
	cohort.smoking_cat = alf_smoke_dedup.smoker_type,
	cohort.smoking_dt  = alf_smoke_dedup.event_dt
;

COMMIT;

