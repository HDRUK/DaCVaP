##########################################################
# Name of file: 03a_CC_Analysis.R
# Data release (if applicable):
# Original author(s): Chris Robertson chris.robertson@nhs.scot
# Original date: 21 Jan 2021
# Latest update author (if not using version control) - Chris Robertson chris.robertson@nhs.scot
# Latest update date (if not using version control) - 
# Latest update description (if not using version control)
# Type of script: Descriptive stats
# Written/run onL: R Studio SERVER
# Version of R that the script was most recently run on: R 3.6.1
# Description of content: run 01a_Vaccinations_Input.R first
#                         run 02_CC.R to set up the cc study
#                         matching on Age, Sex
#                         this script fits the models
# Approximate run time: Unknown
##########################################################

print(z_event_endpoint)
df_cc <- readRDS(paste0(project_path,"/output/temp/df_cc_",z_event_endpoint,".RDS"))
print(table(df_cc$event))

z_combine_vacc_level <- FALSE # to combine the first 1 or 2 levels of vacc_status with uv

source("00_Functions.R")

cat("\n Fitting models to both vaccines\n")

  z_df <- df_cc #%>% filter(event_time <= as.Date("2021-02-21"))
  

df_res <- z_df %>% group_by(vs_type) %>% 
  dplyr::summarise(N=n(), R=sum(event)) %>% 
  mutate(Percent=R/N*100)
df_res 

#z_var <- "vacc_status"
z_var <- "vs_type"
z_fit <- clogit( event ~ get(z_var) + strata(EAVE_LINKNO_case), data=z_df, method="efron" )
summary(z_fit)
z.estimates.1 <- fun.ve.cox("z_var",z_fit)


z_fit <- clogit( event ~ get(z_var) + strata(EAVE_LINKNO_case)  + n_risk_gps ,
                   data=z_df , method="efron")
summary(z_fit)
z.estimates.2 <- fun.ve.cox("z_var",z_fit)

z_df_sub <- filter(z_df, simd2020_sc_quintile != "NA") %>% 
  mutate(simd2020_sc_quintile=factor(simd2020_sc_quintile))
z_fit <- try(clogit( event ~ get(z_var) + strata(EAVE_LINKNO_case)  + n_risk_gps + simd2020_sc_quintile + n_tests_gp,
                     data=z_df_sub, method="efron"))
summary(z_fit)
z.estimates.3 <- if ("clogit" %in% class(z_fit) ) fun.ve.cox("z_var",z_fit) else z.estimates.2


#merge the summary data and estimates

z_out <- df_res %>% left_join(z.estimates.1, by=c("vs_type" = "var")) %>% 
  left_join(z.estimates.2, by=c("vs_type" = "var"), suffix = c("_raw", "_adj_1"))%>% 
  left_join(z.estimates.3, by=c("vs_type" = "var"), suffix = c("", "_adj_2"))


z_out$group <- rep(output_list$endpoint, nrow(z_out))

output_list$estimates <- z_out

#Vaccine type analysis
cat("\n Fitting models to vaccine types separately\n")

#df_res <- z_df %>% group_by(vacc_status) %>% 
#  dplyr::summarise(N_PB=sum(vacc_type %in% c("uv","PB")) , R_PB=sum(event*(vacc_type %in% c("uv","PB"))),
#                   N_AZ=sum(vacc_type %in% c("uv","AZ")), R_AZ=sum(event*(vacc_type %in% c("uv","AZ")))) %>% 
#  mutate(P_PB=R_PB/N_PB*100, P_AZ=R_AZ/N_AZ*100) %>% 
#  dplyr::relocate(P_PB, .after=R_PB)
df_res <- z_df %>% group_by(vacc_type) %>% 
  dplyr::summarise(N=n(), R=sum(event)) %>% 
  mutate(Percent=R/N*100)
df_res 

#z_var <- "vacc_status"
z_var <- "vacc_type"

z_fit <- clogit( event ~ get(z_var) + strata(EAVE_LINKNO_case), data=z_df , method="efron")
summary(z_fit)
z.estimates.1 <- fun.ve.cox("z_var",z_fit)


z_fit <- clogit( event ~ get(z_var) + strata(EAVE_LINKNO_case)  + n_risk_gps ,
                 data=z_df , method="efron")
summary(z_fit)
z.estimates.2 <- fun.ve.cox("z_var",z_fit)

z_df_sub <- filter(z_df, simd2020_sc_quintile != "NA") %>% 
  mutate(simd2020_sc_quintile=factor(simd2020_sc_quintile))
z_fit <- try(clogit( event ~ get(z_var) + strata(EAVE_LINKNO_case)  + n_risk_gps + simd2020_sc_quintile + n_tests_gp,
                     data=z_df_sub, method="efron"))
summary(z_fit)
z.estimates.3 <- if ("clogit" %in% class(z_fit) ) fun.ve.cox("z_var",z_fit) else z.estimates.2


z_out <- df_res %>% left_join(z.estimates.1, by=c("vacc_type" = "var")) %>% 
  left_join(z.estimates.2, by=c("vacc_type" = "var"), suffix = c("_raw", "_adj_1"))%>% 
  left_join(z.estimates.3, by=c("vacc_type" = "var"), suffix = c("", "_adj_2"))
z_out$group <- rep(output_list$endpoint, nrow(z_out))

output_list$est_vt <- z_out

saveRDS(output_list,paste0(project_path,"/output/temp/CR_cc_safety_",z_event_endpoint,".RDS"))
