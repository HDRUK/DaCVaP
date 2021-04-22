##########################################################
# Name of file: 03_CC_Investigations.R
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

z_event_endpoint <- "itp"
print(z_event_endpoint)
df_cc <- readRDS(paste0(project_path,"/output/temp/df_cc_",z_event_endpoint,".RDS"))
print(table(df_cc$event))
print(table(df_cc$vacc_type , df_cc$event))

z_combine_vacc_level <- FALSE # to combine the first 1 or 2 levels of vacc_status with uv

source("00_Functions.R")

cat("\n Fitting models to both vaccines\n")

  z_df <- df_cc
  

df_res <- z_df %>% group_by(vs_type) %>% 
  dplyr::summarise(N=n(), R=sum(event)) %>% 
  mutate(Percent=R/N*100)
df_res 

z_var <- "vacc_status"
z_df$vacc_status <- factor(z_df$vacc_status)

z_df$vs <- as.character(z_df$vacc_status)
z_df$vs <- if_else(z_df$vs %in% c("v1_28:34","v1_35:41","v1_42+","v2_0:6","v2_7+"), "v1_28+_v2", z_df$vs)
z_df$vs <- factor(z_df$vs, levels=c("uv","v1_0:6", "v1_7:13", "v1_14:20", "v1_21:27", "v1_28+_v2"))

z_df <- z_df %>%  mutate(days = as.numeric(event_time - min(event_time))) %>% 
  mutate(days_gp = cut(days, breaks =c(-1, 25, 50, 75, 110)))

z_fit <- try(clogit( event ~ vacc_type + strata(EAVE_LINKNO_case)  + n_risk_gps + 
                       simd2020_sc_quintile + n_tests_gp,
                 data=z_df, method="efron" )) 
summary(z_fit)

#z_df <- mutate(z_df, bmi_impute = if_else(is.na(bmi_impute), mean(bmi_impute,na.rm=T), bmi_impute))
z_df <- mutate(z_df, bmi_gp = cut(bmi_impute, breaks=c(10, 19, 24,29,34,39, 50)))
z_vars <- names(z_df)[c(17:46,56, 57, 61)] #any_throm
z_vars <- names(z_df)[c(17:20, 22:38,40,41,56)] #itp_gen
z_vars <- names(z_df)[c(17:20, 22:30, 32:36,38,40,41,56, 42:46, 61)] #itp
#z_vars <- names(z_df)[c(42:46, 59)]
rm(z_out)

for ( i in z_vars){
  #i <- z_vars[1]
  
  z_fit <- try(clogit( event ~ vacc_type + strata(EAVE_LINKNO_case)  + n_risk_gps + simd2020_sc_quintile +
                        n_tests_gp + as.factor(get(i)), # + vacc_type:as.factor(get(i)),
                       data=z_df , method="efron"))
  
  print(i)
  #print(summary(z_fit))
  z <- as.data.frame(summary(z_fit)$conf.int)
  z$var <- rep(i, nrow(z))
  z$names <- row.names(z)
  row.names(z) <- NULL
  
  
  z_out <- if (exists("z_out")) bind_rows(z_out, z) else z
}

z <-  filter(z_out, grepl("get", names))

z_az <- filter(z_out, grepl("vacc_typeAZ", names))
write_csv(z_az, paste0("output/AZ_1_", z_event_endpoint,".csv"))

z_az <- filter(z_out, grepl("vacc_typeAZ:as", names))
write_csv(z_az, paste0("output/AZ_2_int_", z_event_endpoint,".csv"))

z_pb <- filter(z_out, grepl("vacc_typePB", names))
z_pb <- filter(z_out, grepl("vacc_typePB:as", names))

#AF E[ilepsy, dementia stroke all positive association with event
#stroke only potential confounder as OR goes down 

z_fit <- clogit( event ~ vacc_type + strata(EAVE_LINKNO_case)  + n_risk_gps + simd2020_sc_quintile +
                       n_tests_gp + Q_DIAG_CHD ,
                     data=z_df )
summary(z_fit)

z_fit <- clogit( event ~ vs + strata(EAVE_LINKNO_case)  + n_risk_gps + simd2020_sc_quintile +
                   n_tests_gp + Q_DIAG_STROKE,
                 data=z_df )
summary(z_fit)

#############################################################################

#hospitalisations and positive before hand
z_fit <- clogit( event ~ vacc_type + strata(EAVE_LINKNO_case)  + n_risk_gps + 
                       simd2020_sc_quintile + n_tests_gp,
                     data=z_df, method="efron" ) 
summary(z_fit)

table(z_df$hosp, z_df$event, z_df$vacc_type)
z_fit <- clogit( event ~ vacc_type + strata(EAVE_LINKNO_case)  + n_risk_gps + 
                   simd2020_sc_quintile + n_tests_gp +hosp,
                 data=z_df, method="efron" ) 

z_fit <- clogit( event ~ vacc_type + strata(EAVE_LINKNO_case)  + n_risk_gps + 
                   simd2020_sc_quintile + n_tests_gp,
                 data=z_df, method="efron" , subset=positive_before_event=="never") 

