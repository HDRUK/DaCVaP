----------------------------------------
--Note: if re-running then you can skip this stage as it is already built into the main cohort but due to SAIL DB2 challenges we avoid a full re-run via merge
--Run Date: 2022-02-02
--fatemeh.torabi@swansea.ac.uk
----------------------------------------
ALTER TABLE  SAILW0911V.VAC17_COHORT 
ADD COLUMN vacc_third_date date 
ADD COLUMN vacc_third_name varchar(50);


MERGE INTO SAILW0911V.VAC17_COHORT AS A
USING 
	(
        SELECT
            vacc.alf_e,
            vacc.vacc_date,
            vacc.vacc_dose_seq,
            vacc.vacc_name
        FROM
            sailw0911v.RRDA_CVVD_20211231  AS vacc
        WHERE
            alf_has_bad_vacc_record = 0 AND
            vacc_dose_seq  IN  ('3')
	) AS B 
ON 
A.alf_e=b.alf_e
WHEN MATCHED THEN UPDATE SET 
a.vacc_third_date=b.vacc_date,
a.vacc_third_name=b.vacc_name;