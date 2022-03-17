# save local copy of the analysis table ========================================

usr <- Sys.info()["user"]

# Stu ==========================================================================
if (usr == "bedstons") {
    conn <- sail_connect()

    q_analysis <- "SELECT * FROM sailw0911v.vac17_analysis;"

    d_analysis <- sail_query(conn, q_analysis)

    qsave(d_analysis, file = project_dir("data/d1_analysis_raw.qs"))

    q_analysis <- "SELECT * FROM sailw0911v.vac17_analysis_sccs;"
    
    d_analysis <- sail_query(conn, q_analysis)
    
    qsave(d_analysis, file = project_dir("data/d1_analysis_raw_sccs.qs"))
    
    q_analysis <- "SELECT * FROM sailw0911v.vac17_analysis_sccs_test;"
    
    d_analysis <- sail_query(conn, q_analysis)
    
    qsave(d_analysis, file = project_dir("data/d1_analysis_raw_sccs_test.qs"))
    
    sail_close(conn)
}

# Fatemeh ======================================================================
if (usr == "torabif") {
    library(RODBC);
    library(data.table)
    source("S:/0000 - Analysts Shared Resources/r-share/login_box.r");
    login = getLogin();
    sql = odbcConnect('PR_SAIL',login[1],login[2]);
    login = 0

    d_analysis <- sqlQuery(sql,"SELECT * FROM sailw0911v.vac17_analysis;")
    setnames(d_analysis, tolower(names(d_analysis[1:ncol(d_analysis)])))
    qsave(d_analysis, file = "data/d1_analysis_raw.qs")
    
    d_analysis <- sqlQuery(sql,"SELECT * FROM sailw0911v.vac17_analysis_sccs;")
    setnames(d_analysis, tolower(names(d_analysis[1:ncol(d_analysis)])))
    qsave(d_analysis, file = "data/d1_analysis_raw_sccs.qs")
    
    d_analysis <- sqlQuery(sql,"SELECT * FROM sailw0911v.vac17_analysis_sccs_test;")
    setnames(d_analysis, tolower(names(d_analysis[1:ncol(d_analysis)])))
    qsave(d_analysis, file = "data/d1_analysis_raw_sccs_test.qs")
    
}
