##########################################################
# Name of file: 01b_Rates.R
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
a_begin <- as.Date("2020-12-08") # beginning vaccination
#z_event_endpoint <- "itp" # set in 03a_CC_Control.R
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
z_prior_event <- z_event %>% filter(StartDate < a_begin) %>% 
  mutate(AgeGrp = case_when(Age <15 ~ "0-15", 
                            Age >= 15 & Age < 40 ~ "16-39",
                            Age >= 40 & Age < 60 ~ "40-59",
                            Age >= 60 & Age < 80 ~ "60-79",
                            Age >= 80  ~ "80+"))
  

#get the events in the study period
#note Age here is age at event from the GP record
z_event <- z_event %>% filter(StartDate >= a_begin) %>% 
  filter(StartDate <= max(GP_Consultations$StartDate) - 7) %>%  #drop of reports in the last week as incomplete and may be biased towards vaccination
  filter( !(EAVE_LINKNO %in% unique(z_prior_event$EAVE_LINKNO))) %>% 
  filter(Age>= 16) 


a_end <- max(z_event$StartDate)


#merge to the vaccination data but only use vaccinations up to the last event data
#make anyone vaccinated after the maximum endpoint time unvaccinated
z_vaccinations <- filter(Vaccinations, date_vacc_1 < a_end) %>% 
  mutate(vacc_type_2 = if_else(date_vacc_2 >= a_end, NA_character_ , vacc_type_2),
         date_vacc_2 = as.Date(ifelse(date_vacc_2 >= a_end, NA, date_vacc_2), origin=as.Date("1970-01-01")) )

#match events to vaccinations to get those incident events which ocurred post vaccination
#within 7, 14 and 28 days of vaccination
z_e <- z_event %>% left_join(z_vaccinations, by="EAVE_LINKNO") %>% 
  filter((StartDate > date_vacc_1)& !is.na(date_vacc_1)) %>% 
  mutate(days_1 = as.numeric(StartDate- date_vacc_1 )) %>% 
  mutate(days_07 = if_else(days_1 <= 7, 1, 0),
         days_14 = if_else(days_1 <= 14, 1, 0),
         days_21 = if_else(days_1 <= 21, 1, 0),
         days_28 = if_else(days_1 <= 28, 1, 0)) %>% 
  arrange(EAVE_LINKNO, days_1) %>% 
  filter(!duplicated(EAVE_LINKNO)) %>% 
  mutate(event=1)
#count the number of events by age group and vacc_type in the 3 periods
#z_age_event_tab <- z %>% group_by(AgeGrp, vacc_type) %>% 
#  dplyr::summarise(N_07 = sum(days_07) ,N_14 = sum(days_14), N_21 = sum(days_21), N_28 = sum(days_28))
#z_age_event_tab <- z_age_event_tab %>% pivot_longer(cols=N_07:N_28)

#for all vaccinated get the denominators 
#sum of those observed for 7, 14, 28 days
z <- z_vaccinations %>% left_join(dplyr::select(df_cohort, EAVE_LINKNO, ageYear)) %>% 
  dplyr::select(EAVE_LINKNO, ageYear, date_vacc_1, vacc_type) %>% 
  mutate(AgeGrp = case_when(ageYear <15 ~ "0-15", 
                            ageYear >= 15 & ageYear < 40 ~ "16-39",
                            ageYear >= 40 & ageYear < 60 ~ "40-59",
                            ageYear >= 60 & ageYear < 80 ~ "60-79",
                            ageYear >= 80  ~ "80+")) %>% 
  mutate(days_1 = as.numeric(a_end - date_vacc_1)) 

#join the events to the denominator and amend the follow up time
z <- z %>% left_join(dplyr::select(z_e, EAVE_LINKNO, days_1, event), by="EAVE_LINKNO", suffix=c("","_e") )
z <- z %>% mutate(event = if_else(is.na(event),0,event)) %>% 
           mutate(days_1 = if_else(event==1, days_1_e, days_1) ) 

z.yr <- tcut(rep(0,nrow(z)), c(-1,7,14,21,28,max(z$days_1) ))
#aggregate for overall
z.agg <- pyears(Surv(days_1,event) ~ z.yr + vacc_type +AgeGrp, data=z , scale=1, data.frame=TRUE)

z_age_vacc_tab <- z.agg$data
names(z_age_vacc_tab)[names(z_age_vacc_tab)=="z.yr"] <- "period"
levels(z_age_vacc_tab$period) <- c("0-7","8-14","15-21","22-28","29+")


#z1<- filter(z, event==1)
#%>% #days from vacc to end of follow
#  mutate(obs_07 = if_else(days_1 >= 7, 1,0), 
#         obs_14 = if_else(days_1 >= 14, 1,0),
#        obs_28 = if_else(days_1 >= 28, 1,0))
#z_age_vacc_tab <- z %>% group_by(AgeGrp, vacc_type) %>% 
#  dplyr::summarise(N_07 = sum(obs_07) ,N_14 = sum(obs_14), N_28 = sum(obs_28)) %>% 
#  filter(!is.na(AgeGrp))
#z_age_vacc_tab <- z_age_vacc_tab %>% pivot_longer(cols=N_07:N_28)
#join the two tables together
#z_age_vacc_tab <- left_join(z_age_vacc_tab, z_age_event_tab, by=c("AgeGrp", "vacc_type", "name"), suffix=c("_v","_e")) %>% 
#  dplyr::rename(Vaccinated = value_v, Events=value_e) %>% 
#  mutate(Events = if_else(is.na(Events), 0,Events)) %>% 
#  mutate(Per_10000 = Events/Vaccinated*10000)

#get incident events in a non vaccination period
#28 days in October 2020
#first get the ids of those with a consultation prior to Oct 01 2020 so they can be omitted
z <- unique(filter(z_prior_event, StartDate < a_begin - 68)$EAVE_LINKNO)
z_events_non_vacc_period <- z_prior_event %>% 
  filter(StartDate >= a_begin - 68 & StartDate <= a_begin - 40) %>% 
  filter(!EAVE_LINKNO %in% z) %>% 
  filter(!duplicated(EAVE_LINKNO)) %>% 
  filter(Age >= 16) %>% 
  group_by(AgeGrp) %>% 
  dplyr::summarise(N=n())

z <- df_cohort %>% dplyr::select( EAVE_LINKNO, ageYear, eave_weight) %>% 
  mutate(AgeGrp = case_when(ageYear <15 ~ "0-15", 
                            ageYear >= 15 & ageYear < 40 ~ "16-39",
                            ageYear >= 40 & ageYear < 60 ~ "40-59",
                            ageYear >= 60 & ageYear < 80 ~ "60-79",
                            ageYear >= 80  ~ "80+"))%>% 
  group_by(AgeGrp) %>% 
  dplyr::summarise(N=round(sum(eave_weight)))

z_events_non_vacc_period <- z_events_non_vacc_period %>% 
  left_join(z, by="AgeGrp") %>% 
  dplyr::rename(Events_Pre_Vacc_28=N.x, Population = N.y)

#z_age_vacc_tab <- z_age_vacc_tab %>% left_join(z_events_non_vacc_period, by="AgeGrp") %>% 
#  mutate(Exp_Events = case_when(name=="N_07" ~ Vaccinated*(Events_Pre_Vacc_28*7/28)/Population,
#                                name=="N_14" ~ Vaccinated*(Events_Pre_Vacc_28*14/28)/Population,
#                                name=="N_28" ~ Vaccinated*(Events_Pre_Vacc_28)/Population) )


z_age_vacc_tab <- z_age_vacc_tab %>% left_join(z_events_non_vacc_period, by="AgeGrp") %>%
  mutate(Events_Pre_Vacc_28= if_else(is.na(Events_Pre_Vacc_28), 0L, Events_Pre_Vacc_28),
         Population= if_else(is.na(Population), 1 , Population)) %>% 
  mutate(Exp_Events = pyears*(Events_Pre_Vacc_28/28)/Population )

#note n in the 0-7 period in z_age_vacc_tab is the number vaccinated by the study end

output_list$oe_tab <- z_age_vacc_tab

#z_age_vacc_tab %>% group_by(vacc_type, AgeGrp) %>% 
#  dplyr::summarise(event=sum(event), Exp_Events=sum(Exp_Events))
                   