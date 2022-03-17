
MERGE INTO sailw0911v.vac17_cohort AS cohort
USING (
	/* last known hypertension event */
	SELECT
		alf_e,
		read_cat,
		event_dt
	FROM
		/* add row number to hypertension table */
		(
			SELECT
				*,
		        ROW_NUMBER() OVER (PARTITION BY alf_e ORDER BY event_dt DESC, event_cd DESC) AS event_seq
			FROM
				sailw0911v.vac17_gp_hypertension
			ORDER BY
				alf_e, event_dt, event_cd
		) AS t
	WHERE
		event_seq = 1
) AS gp_ht
ON cohort.alf_e = gp_ht.alf_e
WHEN MATCHED THEN
UPDATE SET
	cohort.hypertension_event = 1,
	cohort.hypertension_dt    = gp_ht.event_dt,
	cohort.hypertension_cat	  = gp_ht.read_cat
;

COMMIT;

