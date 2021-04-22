##########################################################
# Name of file: 02_CC.R
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
#                         matching on Age, Sex, location and risk groups
#                         
# Approximate run time: Unknown
##########################################################

#library(Epi)

#output_list <- list()
#z_event_endpoint <- "any_haem" # set in 03a_CC_Control.R
#output_list$endpoint <- z_event_endpoint
#output_list$match <- "Event Date"   #"Event Date" 
print(z_event_endpoint)

if (z_event_endpoint %in% names(endpoint_groups)) {
  #combination of groups
  z_values <- as.character(unlist(endpoint_groups[z_event_endpoint]))
  z_event <- filter(GP_Consultations, Quick_groups %in% z_values)
      }  else {
 #single group
  z_event <- filter(GP_Consultations, Quick_groups == z_event_endpoint)
} 

#events before vaccination began
z_prior_event <- z_event %>% filter(StartDate < a_begin)
#get the events in the study period
#note Age here is age at event from the GP record
z_event <- z_event %>% filter(StartDate >= a_begin) %>% 
  filter(StartDate <= max(GP_Consultations$StartDate) - 7) %>%  #drop of reports in the last week as incomplete and may be biased towards vaccination
  filter( !(EAVE_LINKNO %in% unique(z_prior_event$EAVE_LINKNO))) %>% 
  filter(Age>= 16) 
output_list$total_events <- nrow(z_event)
z_event <- z_event %>%   mutate(random_id = runif(length(period))) %>% 
  arrange(EAVE_LINKNO, StartDate) %>%   #select first event in study period for incidence
  filter(!duplicated(EAVE_LINKNO)) 
output_list$total_unique_events <- nrow(z_event)
  

a_end <- max(z_event$StartDate)

#get the cohort to sample from - 
z_df_cohort <- dplyr::select(df_cohort, EAVE_LINKNO, Sex, ageYear, n_risk_gps, InterZone) %>% 
  mutate(ageYear = ageYear+1)  #adding 1 year to the ages to get get age as at March 2021
z_df_cohort <- z_df_cohort %>% mutate(ageYear = if_else(ageYear >= 100,100, ageYear)) %>% 
  mutate(ageYear = if_else(ageYear >= 95 & ageYear <= 99,97, ageYear)) %>% 
  mutate(ageYear = if_else(ageYear >= 90 & ageYear <= 94,92, ageYear)) %>% 
  mutate(ageYear = if_else(ageYear >= 80 & ageYear <= 89, trunc(ageYear/2)*2, ageYear)) 
z_df_cohort <- z_df_cohort %>% 
  left_join(all_deaths, by="EAVE_LINKNO") %>% 
  filter(is.na(NRS.Date.Death) | ( NRS.Date.Death >= a_begin))

#merge in the data from EAVE

z <- dplyr::select(z_event, EAVE_LINKNO, StartDate, Quick_groups, Age, Sex) %>% 
  dplyr::rename(sex_gp = Sex) %>% 
  left_join(z_df_cohort, by="EAVE_LINKNO")

#how many don't link
print(table(is.na(z$ageYear)))
output_list$no_link_to_cohort <- sum(is.na(z$ageYear))

z_cases <- z %>% filter(!is.na(ageYear)) %>% 
  dplyr::select(-Age, -sex_gp) %>% 
  mutate(event=1)

#controls are all then filter out ineleigible
z_cont <- z_df_cohort %>% 
  filter( !(EAVE_LINKNO %in% unique(z_prior_event$EAVE_LINKNO))) %>% #omit anyone with a prior event
  mutate(event = if_else(EAVE_LINKNO %in% z_cases$EAVE_LINKNO,1,0))

#for the matched case control study
#do it by merging and selecting 10 controls
z_merge <- left_join(z_cont, z_cases, by=c("ageYear","Sex", "InterZone"), suffix=c("_cont","_case")) %>% 
  filter(!is.na(EAVE_LINKNO_case)) %>% 
  filter(EAVE_LINKNO_case != EAVE_LINKNO_cont)
#omit potential controls who died before the event date in the case
z_merge <- z_merge %>% filter(is.na(NRS.Date.Death_cont) | NRS.Date.Death_cont > StartDate)


#select 5 here
z_merge_10 <- z_merge %>%  mutate(random_id = runif(nrow(z_merge))) %>% 
  arrange(random_id) %>% #to make sure that the same controls are not always selected
  group_by(EAVE_LINKNO_case) %>% 
  mutate(id = row_number()) %>% ungroup() %>% 
  filter(id <= 10) %>% arrange(EAVE_LINKNO_case) 

print(table(table(z_merge_10$EAVE_LINKNO_cont)))#duplicate controls
print(table(table(z_merge_10$EAVE_LINKNO_case))) # controls per case
print(table(z_merge_10$event_cont)) # controls could be cases in future
#z <- filter(z_merge_10, event_cont==1)

#cases not matched
z_sel <- !(z_cases$EAVE_LINKNO %in% unique(z_merge_10$EAVE_LINKNO_case))
print(table(z_sel))#cases not matched
output_list$no_match <- sum(z_sel)
z_no_match <- filter(z_cases, z_sel)
#elderly do not always match

#put the cases and controls together
z_cc_case <- z_merge_10 %>% dplyr::select(Sex, ageYear, event_case, StartDate, EAVE_LINKNO_case) %>% 
  filter(!duplicated(EAVE_LINKNO_case)) %>% 
  mutate(EAVE_LINKNO = EAVE_LINKNO_case) %>% 
  relocate(EAVE_LINKNO, .before=Sex) %>% 
  dplyr::rename(event=event_case, event_time = StartDate) 
z_cc_cont <- z_merge_10 %>% dplyr::select(EAVE_LINKNO_cont, Sex, ageYear, event_cont, StartDate, EAVE_LINKNO_case) %>% 
  dplyr::rename(EAVE_LINKNO = EAVE_LINKNO_cont, event=event_cont, 
                event_time = StartDate) %>% 
  mutate(event=if_else(event==1,0,event)) 
#some controls will become cases in the future - set event ==0 for them 
#but keep the exit time as the time of the event

print(nrow(z_cc_case))

z_cc <- bind_rows(z_cc_case, z_cc_cont) %>% 
  arrange(EAVE_LINKNO_case, desc(event))  
#  filter(SpecimenDate_case >= a_begin - 28) #omit cases from a long time ago
print(table(z_cc$event))

#merge to the vaccination data but only use vaccinations up to the last event data
#make anyone vaccinated after the maximum endpoint time unvaccinated
z_vaccinations <- filter(Vaccinations, date_vacc_1 < a_end) %>% 
  mutate(vacc_type_2 = if_else(date_vacc_2 >= a_end, NA_character_ , vacc_type_2),
         date_vacc_2 = as.Date(ifelse(date_vacc_2 >= a_end, NA, date_vacc_2), origin=as.Date("1970-01-01")) )

#using the time of event

df_cc <- z_cc %>% left_join(z_vaccinations, by="EAVE_LINKNO") %>%
  mutate(day_1 = as.numeric(event_time - date_vacc_1),
         day_2 = as.numeric(event_time - date_vacc_2)) %>% 
  arrange(EAVE_LINKNO_case)
z_min_day_2 <- min(c(min(df_cc$day_1, na.rm=T)-1), -100) #just in case there are no second vaccs
df_cc <- df_cc %>%   mutate(vacc_1_gp = cut(day_1, breaks= c((min(day_1, na.rm=T)-1), 0, 6, 13, 20, 27, 34, 41, max(day_1, na.rm=T)),
                         labels=c("uv","v1_0:6","v1_7:13","v1_14:20","v1_21:27","v1_28:34","v1_35:41", "v1_42+")),
         vacc_2_gp = cut(day_2, breaks= c(z_min_day_2, 0, 6,  max(day_2, na.rm=T)) ,
                         labels=c("v2_uv" , "v2_0:6","v2_7+")) ) %>% 
  mutate(vacc_status = as.character(vacc_1_gp)) %>% 
  mutate(vacc_status = case_when( is.na(date_vacc_1) ~ "uv",
                                  !is.na(vacc_2_gp) &(vacc_2_gp %in% c("v2_0:6","v2_7+")) ~ as.character(vacc_2_gp),
                                  TRUE ~ vacc_status)) %>% 
  mutate(vacc_status = factor(vacc_status, levels = c("uv","v1_0:6","v1_7:13","v1_14:20",
                                                      "v1_21:27","v1_28:34","v1_35:41", "v1_42+", "v2_0:6","v2_7+")) )
#correct vacc_type.  When linking the date of vaccination may be after the date of event.  
#vacc_status is uv which is correct but vacc_type is refers to date of vaccination - make uv also
df_cc <- df_cc %>% mutate(vacc_type = if_else(vacc_status=="uv", "uv", vacc_type)) 

df_cc <- df_cc %>% mutate(vs = as.character(vacc_status)) %>% 
  mutate(vs = if_else(vs %in% c("v1_28:34","v1_35:41","v1_42+","v2_0:6","v2_7+"), "v1_28+_v2", vs)) %>% 
  mutate(vs = factor(vs, levels=c("uv","v1_0:6", "v1_7:13", "v1_14:20", "v1_21:27", "v1_28+_v2")) ) %>% 
  mutate(vs_type = paste(vacc_type, vs, sep="_")  ) %>% 
  mutate(vs_type = if_else(vs_type=="uv_uv", "uv", vs_type)) %>% 
  mutate(vs_type = factor(vs_type, levels = c( "uv" , "AZ_v1_0:6", "AZ_v1_7:13" , "AZ_v1_14:20",
              "AZ_v1_21:27","AZ_v1_28+_v2", "PB_v1_0:6",  "PB_v1_7:13" ,"PB_v1_14:20",
              "PB_v1_21:27", "PB_v1_28+_v2" )))


print(table(df_cc$vacc_1_gp, df_cc$vacc_2_gp, exclude=NULL))
print(table(df_cc$vs, df_cc$event, exclude=NULL))
print(table(df_cc$vacc_type, df_cc$event, exclude=NULL))
print(table(df_cc$event, exclude=NULL))

df_cc <- df_cc %>% dplyr::select(-(date_vacc_1:vacc_2_gp))
  
df_cc <- df_cc %>% left_join(dplyr::select(df_cohort, -Sex, -ageYear, -InterZone ), by="EAVE_LINKNO")

#add in the vacccination type - already in add value for uv and get rid of vacc type 2 as it is the same
df_cc <- df_cc %>% mutate(vacc_type = if_else(is.na(vacc_type), "uv", vacc_type)) %>% 
  mutate(vacc_type=factor(vacc_type,levels=c("uv","AZ","PB"))) %>% 
  dplyr::select(-vacc_type_2)

#add in the hospitalisation status at specimen date
#little point in doing this at the date of death
#get all admissions in the period 14 days before to get historical adm
#cc indivs plus specimen date of case for timing
z_cc <- df_cc %>% filter(!duplicated(EAVE_LINKNO)) %>% 
  dplyr::select(EAVE_LINKNO, event_time)

z_hosp <- hosp_adm_nov01 %>% filter (is.na(discharge_date) | discharge_date >= a_begin-14) %>% 
  filter(EAVE_LINKNO %in% z_cc$EAVE_LINKNO) #omit individuals not in the selected data

z_cc_h <- left_join(z_cc, z_hosp, by="EAVE_LINKNO") %>% 
  mutate(hosp = case_when(is.na(admission_date) & is.na(discharge_date) ~ "no_adm",
    !is.na(discharge_date) & (discharge_date < event_time-14) ~ "no_adm",
    !is.na(discharge_date) & (discharge_date >= event_time-14) & (discharge_date < event_time) ~ "before",
    !is.na(discharge_date) & (discharge_date >= event_time) & !is.na(admission_date) & (admission_date <= event_time) ~ "in_hosp",
    !is.na(admission_date) & is.na(discharge_date) & (admission_date <= event_time)  ~ "in_hosp",
    !is.na(admission_date) & (admission_date > event_time)  ~ "after",
    TRUE ~ "check") ) %>% 
  mutate(value=1)
z_cc_h_indiv <- z_cc_h %>% dplyr::select(-(event_time:discharge_date)) %>% 
  pivot_wider(id_cols=EAVE_LINKNO, names_from=hosp, values_from=value, values_fill = 0 , values_fn=sum)
if (!("in_hosp" %in% names(z_cc_h_indiv))) z_cc_h_indiv$in_hosp=0
if (!("before" %in% names(z_cc_h_indiv))) z_cc_h_indiv$before=0
z_cc_h_indiv <- z_cc_h_indiv %>% mutate(hosp = case_when(in_hosp > 0 ~ "in_hosp",
                          in_hosp==0 & before > 0  ~ "before",
                          TRUE ~ "no_adm"))
 
df_cc <- df_cc %>% left_join(dplyr::select(z_cc_h_indiv,EAVE_LINKNO, hosp ), by="EAVE_LINKNO") 
df_cc$hosp <- factor(df_cc$hosp, levels=c("no_adm","before","in_hosp"))
print(table(df_cc$hosp))
print(table(df_cc$event))
print(table(df_cc$hosp, df_cc$event))
print(table(df_cc$vacc_status, df_cc$hosp))
print(table(df_cc$vacc_status, df_cc$event, df_cc$hosp))
print(table(df_cc$vacc_type, df_cc$event))
print(table(df_cc$vacc_status, df_cc$event))
print(table(df_cc$vacc_status, df_cc$vacc_type))

df_cc <- df_cc %>% left_join(dplyr::select(Household, EAVE_LINKNO, care_home_elderly), by="EAVE_LINKNO" )

z <- df_cc %>% left_join(Pos_Test, by="EAVE_LINKNO") %>% 
  mutate(days_test_event = as.numeric(event_time - SpecimenDate)) %>% 
  mutate(positive_before_event = case_when(is.na(SpecimenDate) ~ "never",
     days_test_event >= 28 ~ "28+ days",
     days_test_event < 28 & days_test_event >= 14 ~ "14-27 days",
     days_test_event < 14 & days_test_event >= 0 ~ "0-13 days",
     days_test_event < 0 & days_test_event >= -6 ~ "1-6 post event",
     days_test_event <= -7 ~ "7+ post event")) %>% 
  dplyr::select(-NCOV_RESULT, -SpecimenDate, -days_test_event)
df_cc <- z

df_cc <- df_cc %>% left_join(dplyr::select(z_event, EAVE_LINKNO, Quick_groups), by="EAVE_LINKNO")

saveRDS(df_cc, paste0(project_path,"/output/temp/df_cc_",z_event_endpoint,".RDS"))
