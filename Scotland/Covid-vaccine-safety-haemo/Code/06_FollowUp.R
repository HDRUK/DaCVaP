##########################################################
# Name of file: 06_FollowUp.R
# Data release (if applicable):
# Original author(s): Chris Robertson chris.robertson@nhs.scot
# Original date: 21 Jan 2021
# Latest update author (if not using version control) - Chris Robertson chris.robertson@nhs.scot
# Latest update date (if not using version control) - 
# Latest update description (if not using version control)
# Type of script: Descriptive stats
# Written/run onL: R Studio SERVER
# Version of R that the script was most recently run on: R 3.6.1
# Description of content: run 05_SCCS_Analysis.R first
#                         down to about line 84 just before
#                         if (!output_list$include_uv) { #remove the unvaccinated
#                         to get z.df
#      This has all the events from 104 days before 0th Dec for anyone with an event post 8th Dec
#     plus vacc type and date vaccination if there is one
# Approximate run time: Unknown
##########################################################

output_list<-list()
output_list$event <- z_event_endpoint
#z.df is the original data - keep it; z_df is the working data 
#only keep events when vaccination was around
z_df  <- z.df %>% 
  filter(StartDate >= a_begin)
output_list$tab_events_indiv <- table(table(z_df$EAVE_LINKNO))

#get the first event post dec 8th
z1 <- z_df %>% 
  arrange(EAVE_LINKNO, StartDate) %>% 
  filter(!duplicated(EAVE_LINKNO)) %>% 
  mutate(Vacc.Type = if_else(!is.na(Vacc.Date) & (Vacc.Date <= StartDate), Vacc.Type, "uv" ) ) %>% 
  mutate(days_vacc_event = if_else(Vacc.Type=="uv",0,as.numeric(StartDate-Vacc.Date)) ) %>% 
  mutate(AgeGrp = case_when(Age <15 ~ "0-15", 
                            Age >= 15 & Age < 40 ~ "16-39",
                            Age >= 40 & Age < 60 ~ "40-59",
                            Age >= 60 & Age < 80 ~ "60-79",
                            Age >= 80  ~ "80+"))
z_df <- z1
#read in the endpoint data 
z <- readRDS("/conf/EAVE/GPanalysis/data/all_deaths.rds")
summary(z)
z <- filter(z, !duplicated(EAVE_LINKNO))

z1 <- z_df %>%  left_join(z, by="EAVE_LINKNO")
z_df <- z1 %>% dplyr::select(-NRS.Reg.Date, -(CAUSE_OF_DEATH_CODE_1 : source))

z <- readRDS("/conf/EAVE/GPanalysis/data/any_hospitalisation_post_01022020.rds") %>% 
  filter(is.na(discharge_date) | discharge_date > a_begin) %>% 
  filter(emergency) %>% 
  dplyr::select(-emergency, - validchi)
summary(z)

z1 <- z_df %>%  left_join(z, by="EAVE_LINKNO") %>% 
  mutate(days_adm = as.numeric(admission_date - StartDate))

z1 <- z1 %>% #dplyr::select(EAVE_LINKNO, StartDate, Vacc.Type, Vacc.Date, admission_date, discharge_date, days_adm) %>% 
  mutate(days_adm = if_else(!is.na(days_adm) & (days_adm < -7), NA_real_, days_adm)) %>% 
  mutate(days_adm = if_else(!is.na(days_adm) & (days_adm < 0), 0, days_adm)) %>% 
  mutate(dis_status = case_when(is.na(admission_date) & is.na(discharge_date) ~ "no_adm",
                  !is.na(discharge_date) &(discharge_date < StartDate) ~ "dis_before_event" ,
                  !is.na(discharge_date) &(discharge_date >= StartDate) ~ "dis_on_after_event" ,
                  !is.na(admission_date) & is.na(discharge_date) ~ "in_hosp",
                  TRUE ~ "rest")) %>% 
  mutate(adm_status = case_when(is.na(admission_date) & is.na(discharge_date) ~ "no_adm",
                  !is.na(admission_date) &(admission_date < StartDate-7) ~ "adm_before_event" ,
                  !is.na(admission_date) &(admission_date >= StartDate-7) & (admission_date <= StartDate+7) ~ "adm_on_event" ,
                  !is.na(admission_date) &(admission_date > StartDate+7) ~ "adm_after_event" ,
                  TRUE ~ "rest")) %>% 
    arrange(EAVE_LINKNO, days_adm)

z <- z1 %>% dplyr::select(EAVE_LINKNO, StartDate, admission_date, discharge_date, dis_status, adm_status)
#keep the first record - arranging keeps the earliest record
z1 <- z1 %>% # filter(!(!is.na(admission_date) & is.na(days_adm))) %>% 
  filter(!duplicated(EAVE_LINKNO))

z_df <- z1

table(z_df$adm_status, z_df$dis_status, z_df$Vacc.Type)
table(z_df$adm_status, z_df$dis_status)
table(z_df$Vacc.Type, z_df$days_vacc_event)
table(z_df$Vacc.Type, z_df$days_adm, exclude=NULL)
