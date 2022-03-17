-----------------------------------------------------------
--vac17:   Vaccine Safety
--BY:       fatemeh.torabi@swansea.ac.uk
--DT:       2021-04-08
--aim:      to get smoking cohort ready
-----------------------------------------------------------
--READ CODE LIST CHECK
/*
SELECT * FROM SAILW0911V.FT_GD_SMOKE_ALC_BMI20200730
WHERE CATEGORY='Smoking'
*/
-----------------------------------------------------------
--PRIMARY CARE EVENTS:
CALL FNC.DROP_IF_EXISTS ('SAILW0911V.vac17_GP_SMOKE');

CREATE TABLE sailw0911v.vac17_gp_smoke
(
        alf_e           BIGINT,
        alf_sts_cd      INTEGER,
        event_dt        DATE,
        event_cd        CHAR(6),
        description     VARCHAR(300),
        category        VARCHAR(25),
        smoker_type     VARCHAR(25)
 --       in_c20          INTEGER
)
DISTRIBUTE BY HASH (alf_e);
COMMIT;

--granting access to team mates
GRANT ALL ON TABLE SAILW0911V.vac17_GP_SMOKE TO ROLE NRDASAIL_SAIL_0911_ANALYST;

alter table SAILW0911V.vac17_GP_SMOKE activate not logged INITIALLY;

insert into SAILW0911V.vac17_GP_SMOKE
select
    distinct
        GP.ALF_E,
        GP.ALF_STS_CD,
        GP.EVENT_DT,
        GP.EVENT_CD,
        CD.DESCRIPTION,
        CD.CATEGORY,
        CD.SMOKER_TYPE
   --     CASE
   --       WHEN ALF_E IN (SELECT DISTINCT ALF_E FROM SAILW0911V.C19_COHORT20) THEN 1
   --       ELSE 0
   --   END AS IN_C20
FROM    SAIL0911V.WLGP_GP_EVENT_CLEANSED GP
RIGHT OUTER JOIN
(
    SELECT * FROM SAILW0911V.FT_GD_SMOKE_ALC_BMI20200730
    WHERE CATEGORY='Smoking'
) CD
    ON
    (GP.event_cd=CD.READ_CODE)
WHERE
    GP.ALF_E IS NOT NULL
AND
    GP.ALF_STS_CD IN ('1','4','39')
AND
    GP.event_cd is not NULL
AND
    GP.event_DT is not null
AND
    YEAR(GP.EVENT_DT) BETWEEN '2000' AND '2021';


CALL SYSPROC.ADMIN_CMD('runstats on table SAILW0911V.vac17_GP_SMOKE with distribution and detailed indexes all');

COMMIT;
