CALL FNC.DROP_IF_EXISTS ('sailw0911v.vac17_gp_hypertension');

CREATE TABLE sailw0911v.vac17_gp_hypertension
(
        alf_e           BIGINT,
        alf_sts_cd      INTEGER,
        event_dt        DATE,
        event_cd        CHAR(5),
        read_cd         VARCHAR(5),
        read_cat        VARCHAR(255)
)
DISTRIBUTE BY HASH(ALF_E);

GRANT ALL ON TABLE sailw0911v.vac17_gp_hypertension
TO ROLE nrdasail_sail_0911_analyst;

INSERT INTO sailw0911v.vac17_gp_hypertension
(
    alf_e,
    alf_sts_cd,
    event_dt,
    event_cd,
    read_cd,
    read_cat
)
WITH
    /* chop read codes to just to 5 characters long */
    lkp_hypertension AS (
        SELECT DISTINCT
            SUBSTRING(readcode, 1, 5) AS read_cd,
            category AS read_cat
        FROM
            sailw0911v.calibre_read_hypertension
    ),
    /* pad 4-length read codes to 5 using dot */
    lkp_hypertension_pad AS (
        SELECT DISTINCT
            read_cd,
            read_cat,
            CASE
                WHEN read_cd = '6624' THEN '6624.'
                WHEN read_cd = '6627' THEN '6627.'
                WHEN read_cd = '6628' THEN '6628.'
                ELSE read_cd
            END AS read_cd_pad
        FROM
            lkp_hypertension
    )
SELECT DISTINCT
    gp.alf_e,
    gp.alf_sts_cd,
    gp.event_dt,
    gp.event_cd,
    lkp_hypertension_pad.read_cd_pad AS read_cd,
    lkp_hypertension_pad.read_cat
FROM
    sail0911v.wlgp_gp_event_cleansed AS gp
INNER JOIN
    lkp_hypertension_pad
    ON gp.event_cd = lkp_hypertension_pad.read_cd_pad
WHERE
    gp.alf_e IS NOT NULL
AND
    alf_e IN (SELECT DISTINCT alf_e FROM sailw0911v.c19_cohort20)
AND
    gp.alf_sts_cd IN ('1','4','39')
AND
    gp.event_cd IS NOT NULL
AND
    gp.event_dt IS NOT NULL
AND
    YEAR(gp.event_dt) BETWEEN '2016' AND '2021'
AND
    gp.event_dt <= '2021-12-31'
;
