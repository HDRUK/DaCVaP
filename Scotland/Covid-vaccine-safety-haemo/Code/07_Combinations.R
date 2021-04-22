##########################################################
# Name of file: 07_Combinations.R
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
#                         run the head of 03a_CC_Control.R to set up endpoint groups
#                         down to the for loop
#                         this looks at two endpoints ocurring together
# Approximate run time: Unknown
##########################################################

z_event_endpoint <- "any_itp" # this is the primary endpoint
output_list <- list()
output_list$endpoint <- z_event_endpoint
output_list$a_begin <- a_begin
output_list$other_endpoint <- "throm_cvst"


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
output_list$a_end <- a_end

#get the other event data - this should not bve incident ones
if (output_list$other_endpoint %in% names(endpoint_groups)) {
  #combination of groups
  z_values <- as.character(unlist(endpoint_groups[output_list$other_endpoint]))
  z_other <- filter(GP_Consultations, Quick_groups %in% z_values)
}  else {
  #single group
  z_other <- filter(GP_Consultations, Quick_groups == output_list$other_endpoint)
} 
output_list$total_other <- nrow(z_other)
z_other <- z_other %>%   
  arrange(EAVE_LINKNO, StartDate) %>%   #select first event in study period for incidence
  filter(!duplicated(EAVE_LINKNO)) 
output_list$total_unique_other <- nrow(z_other)

z_merge <- z_event %>% 
  dplyr::select(EAVE_LINKNO, Age, AgeGrp, Sex, StartDate) %>% 
  left_join(dplyr::select(z_other, EAVE_LINKNO, StartDate), by="EAVE_LINKNO", suffix=c("_event","_other"))

z <- z_merge %>% 
  mutate(other_week = case_when(is.na(StartDate_other) ~ "no_other_event",
    !is.na(StartDate_other)&(StartDate_other < StartDate_event) ~ "before",
    !is.na(StartDate_other)&(StartDate_other >= StartDate_event)&(StartDate_other <= StartDate_event+7)~ "other_1_week",
    !is.na(StartDate_other)&(StartDate_other >= StartDate_event+8)&(StartDate_other <= StartDate_event+14)~ "other_2_weeks",
    !is.na(StartDate_other)&(StartDate_other >= StartDate_event+15)&(StartDate_other <= StartDate_event+21)~ "other_3_weeks",
    !is.na(StartDate_other)&(StartDate_other >= StartDate_event+22) ~ "other_later",
    TRUE ~ "unknown"  ))

#merge to the vaccination data but only use vaccinations up to the last event data
#make anyone vaccinated after the maximum endpoint time unvaccinated
z_vaccinations <- filter(Vaccinations, date_vacc_1 < a_end) %>% 
  mutate(vacc_type_2 = if_else(date_vacc_2 >= a_end, NA_character_ , vacc_type_2),
         date_vacc_2 = as.Date(ifelse(date_vacc_2 >= a_end, NA, date_vacc_2), origin=as.Date("1970-01-01")) )

#using the time of event

z <- z %>% left_join(z_vaccinations, by="EAVE_LINKNO") %>%
  mutate(day_1 = as.numeric(StartDate_event - date_vacc_1),
         day_2 = as.numeric(StartDate_event - date_vacc_2)) 
z_min_day_2 <- min(c(min(z$day_1, na.rm=T)-1), -100) #just in case there are no second vaccs
z <- z %>%   mutate(vacc_1_gp = cut(day_1, breaks= c((min(day_1, na.rm=T)-1), 0, 6, 13, 20, 27, 34, 41, max(day_1, na.rm=T)),
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
z <- z %>% mutate(vacc_type = if_else(vacc_status=="uv", "uv", vacc_type)) 

df <- z

cat("\n Primary event - ", output_list$endpoint, " Secondary (other) - ",output_list$other_endpoint,"\n")
table(df$other_week)
table(df$vacc_status, df$other_week)
table(df$vacc_status, df$other_week, df$vacc_type)
