rm(list=ls())
gc()
source("01_load.r")

# Summary of the case-control group sizes ======================================
d_analysis <- qread(project_dir("data/d2_analysis_clean.qs"))

t_cc_n <-
    d_analysis %>%
    group_by(groups) %>%
    summarise(
        case_n    = sum(alf_type == "CASE"),
        control_n = sum(alf_type == "CONTROL")
    ) %>%
    ungroup() %>%
    count(case_n, control_n, name = "n_groups")

write_csv(
    t_cc_n,
    file = "results/t_desc_cc_group_n.csv"
)

# Summarise the clearance and post incident counts =============================


conn <- sail_connect()

sql_clearance_post_gp <- "
    SELECT
        'csvt'                                                AS event_type,
        cohort.gp_clearance_csvt_dt IS NOT NULL               AS clearance_event,
        cohort.gp_post_csvt_dt      IS NOT NULL               AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.gp_clearance_csvt_dt IS NOT NULL,
        cohort.gp_post_csvt_dt      IS NOT NULL
UNION
    SELECT
        'haemorrhage'                                         AS event_type,
        cohort.GP_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL        AS clearance_event,
        cohort.GP_POST_HAEMORRHAGE_DT     IS NOT NULL         AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.GP_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL,
        cohort.GP_POST_HAEMORRHAGE_DT      IS NOT NULL
UNION
    SELECT
        'itp'                                                 AS event_type,
        cohort.gp_clearance_itp_dt IS NOT NULL                   AS clearance_event,
        cohort.gp_post_itp_dt      IS NOT NULL                   AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.gp_clearance_itp_dt IS NOT NULL,
        cohort.gp_post_itp_dt      IS NOT NULL
UNION
    SELECT
        'thrombocytopenia'                                    aS event_type,
        cohort.gp_clearance_thrombocytopenia_dt IS NOT NULL      AS clearance_event,
        cohort.gp_post_thrombocytopenia_dt      IS NOT NULL      AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.gp_clearance_thrombocytopenia_dt IS NOT NULL,
        cohort.gp_post_thrombocytopenia_dt      IS NOT NULL
UNION
    SELECT
        'venous_thromboembolic'                               AS event_type,
        cohort.gp_clearance_vte_dt IS NOT NULL AS clearance_event,
        cohort.gp_post_vte_dt      IS NOT NULL AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.gp_clearance_vte_dt IS NOT NULL,
        cohort.gp_post_vte_dt      IS NOT NULL
UNION
    SELECT
        'arterial thrombosis'                 AS event_type,
        cohort.gp_clearance_at_dt IS NOT NULL AS clearance_event,
        cohort.gp_post_at_dt      IS NOT NULL AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.gp_clearance_at_dt IS NOT NULL,
        cohort.gp_post_at_dt      IS NOT NULL        ";

d_clearance_post <-
    sail_query(conn, sql_clearance_post_gp) %>%
    arrange(event_type, clearance_event, post_event)

t_clearance_post_gp <-
    d_clearance_post %>%
    mutate(
        pattern = str_c("x", clearance_event, "-", post_event)
    ) %>%
    select(-clearance_event, -post_event) %>%
    pivot_wider(
        names_from = pattern,
        values_from = n,
        values_fill = 0
    )

write_csv(
    t_clearance_post_gp,
    file = "results/t_summary_clearance_post_events_gp.csv"
)

###pedw

sql_clearance_post_pedw <- "
    SELECT
        'csvt'                                                AS event_type,
        cohort.pedw_clearance_csvt_dt IS NOT NULL               AS clearance_event,
        cohort.pedw_post_csvt_dt      IS NOT NULL               AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.pedw_clearance_csvt_dt IS NOT NULL,
        cohort.pedw_post_csvt_dt      IS NOT NULL
UNION
    SELECT
        'haemorrhage'                                         AS event_type,
        cohort.pedw_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL        AS clearance_event,
        cohort.pedw_POST_HAEMORRHAGE_DT     IS NOT NULL         AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.pedw_CLEARANCE_HAEMORRHAGE_DT IS NOT NULL,
        cohort.pedw_POST_HAEMORRHAGE_DT      IS NOT NULL
UNION
    SELECT
        'itp'                                                 AS event_type,
        cohort.pedw_clearance_itp_dt IS NOT NULL                   AS clearance_event,
        cohort.pedw_post_itp_dt      IS NOT NULL                   AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.pedw_clearance_itp_dt IS NOT NULL,
        cohort.pedw_post_itp_dt      IS NOT NULL
UNION
    SELECT
        'thrombocytopenia'                                    aS event_type,
        cohort.pedw_clearance_thrombocytopenia_dt IS NOT NULL      AS clearance_event,
        cohort.pedw_post_thrombocytopenia_dt      IS NOT NULL      AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.pedw_clearance_thrombocytopenia_dt IS NOT NULL,
        cohort.pedw_post_thrombocytopenia_dt      IS NOT NULL
UNION
    SELECT
        'venous_thromboembolic'                               AS event_type,
        cohort.pedw_clearance_vte_dt IS NOT NULL AS clearance_event,
        cohort.pedw_post_vte_dt      IS NOT NULL AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.pedw_clearance_vte_dt IS NOT NULL,
        cohort.pedw_post_vte_dt      IS NOT NULL
UNION
    SELECT
        'arterial thrombosis'                 AS event_type,
        cohort.pedw_clearance_at_dt IS NOT NULL AS clearance_event,
        cohort.pedw_post_at_dt      IS NOT NULL AS post_event,
        count(*)                                              AS n
    FROM
        sailw0911v.vac17_cohort AS cohort
    WHERE
        is_sample = 1
    GROUP BY
        cohort.pedw_clearance_at_dt IS NOT NULL,
        cohort.pedw_post_at_dt      IS NOT NULL        ";

d_clearance_post <-
    sail_query(conn, sql_clearance_post_pedw) %>%
    arrange(event_type, clearance_event, post_event)

t_clearance_post_pedw <-
    d_clearance_post %>%
    mutate(
        pattern = str_c("x", clearance_event, "-", post_event)
    ) %>%
    select(-clearance_event, -post_event) %>%
    pivot_wider(
        names_from = pattern,
        values_from = n,
        values_fill = 0
    )

write_csv(
    t_clearance_post_pedw,
    file = "results/t_summary_clearance_post_events_pedw.csv"
)
