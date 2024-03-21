##########################################################
# Name of file: 00_Read_DV_Vaccinations.R
# Data release (if applicable):
# Original author(s): Chris Robertson chris.robertson@phs.scot
# Original date: 09 Nov 2021
# Latest update author (if not using version control) - Chris Robertson chris.robertson@phs.scot
# Latest update date (if not using version control) - 
# Latest update description (if not using version control)
# Type of script: Descriptive stats
# Written/run onL: R Studio SERVER
# Version of R that the script was most recently run on: R 3.6.1
# Description of content: reads in the vaccination data and tidies
# Approximate run time: Unknown
##########################################################

library(dplyr)
library(tidyverse)
library(lubridate)
library(survival)
library(labelled)
Location <- "/conf/"  # Server

project_path <- paste0(Location,"EAVE/GPanalysis/progs/TM/dacvap_uptake")
a_begin <- as.Date("2021-06-15")
a_analysis_date <- Sys.Date() #change this to try and recreate historical analyses

#read in the DVProd vaccination data
z <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/C19vaccine_dvprod_cleaned.rds"))
z <- z %>% mutate(vacc_occurence_time = as_date(vacc_occurence_time)) #%>% 

print(table(z$vacc_product_name, z$vacc_dose_number, exclude=NULL))

#take a sample to check the coding
#z_orig <- z
#z_ids <- unique(z$EAVE_LINKNO)
#z_ids_sample <- sample(z_ids, size=trunc(length(z_ids)*0.1))
#z <- z_orig %>% filter(EAVE_LINKNO %in% z_ids_sample)

if (!exists("a_analysis_date")) a_analysis_date <- Sys.Date() 
Vaccinations <- z %>% mutate(Date = as_date(vacc_occurence_time)) %>%
  filter(Date <= a_analysis_date) %>%
  mutate(vacc_type = case_when(vacc_product_name == "Covid-19 Vaccine AstraZeneca" ~ "AZ",
                               vacc_product_name == "Covid-19 mRNA Vaccine Pfizer" ~ "PB",
                               vacc_product_name == "Covid-19 mRNA Vaccine Moderna" ~ "Mo",
                               TRUE ~ "UNK") )  

v1 <- filter(Vaccinations, vacc_dose_number==1) %>% 
  select(EAVE_LINKNO, Date, vacc_type, vacc_dose_number, age) %>% mutate(age_at_vacc_1 = age) %>% select(-age)
#find duplicates
z <- filter(v1, duplicated(EAVE_LINKNO)) %>% pull(EAVE_LINKNO)
z_id_problem <- unique(z)
z <- filter(v1, EAVE_LINKNO %in% z)
z <- z %>% arrange(EAVE_LINKNO, Date) %>% group_by(EAVE_LINKNO) %>% mutate(diff = as.numeric(Date - first(Date)) ) %>% ungroup() 
z <- z %>% mutate(first_record = if_else(EAVE_LINKNO == lag(EAVE_LINKNO), 0,1)) %>% 
  mutate(first_record = if_else(is.na(first_record), 1, first_record))
z1 <- z %>%  filter(first_record==1 | first_record==0 & vacc_type != "UNK") # omit the unknowns in second place
z1 <- z1 %>% filter(first_record==1 | first_record==0 & diff > 18) # omit the short gaps
z_first <- z1 %>% filter(first_record==1) %>% dplyr::select(-diff, -first_record)
z_second <- z1 %>% filter(first_record==0) %>% dplyr::select(-diff, -first_record) %>% mutate(vacc_dose_number=2) # some duplicates in here
#from individuals with >= 1 first dose take the first one and add it back into v1
v1 <- v1 %>% filter(!(EAVE_LINKNO %in% z_first$EAVE_LINKNO) ) %>% bind_rows(z_first)

v2 <- filter(Vaccinations, vacc_dose_number==2) %>% 
  dplyr::select(EAVE_LINKNO, Date, vacc_type, vacc_dose_number) %>% 
  bind_rows(z_second) 

#find duplicates
z <- filter(v2, duplicated(EAVE_LINKNO)) %>% pull(EAVE_LINKNO)
z_id_problem <- c(z_id_problem, unique(z))
z <- filter(v2, EAVE_LINKNO %in% z)
z <- z %>% arrange(EAVE_LINKNO, Date) %>% group_by(EAVE_LINKNO) %>% mutate(diff = as.numeric(Date - first(Date)) ) %>% ungroup() 
z <- z %>% mutate(first_record = if_else(EAVE_LINKNO == lag(EAVE_LINKNO), 0,1)) %>% 
  mutate(first_record = if_else(is.na(first_record), 1, first_record))
z1 <- z %>%  filter(first_record==1 | first_record==0 & vacc_type != "UNK") # omit the unknowns in second place
z1 <- z1 %>% filter(first_record==1 | first_record==0 & diff > 18) # omit the short gaps
z_first <- z1 %>% filter(first_record==1) %>% dplyr::select(-diff, -first_record)
z_second <- z1 %>% filter(first_record==0) %>% dplyr::select(-diff, -first_record) %>% mutate(vacc_dose_number=3) # some duplicates in here
#from individuals with >= 1 second dose take the first one and add it back into v2
v2 <- v2 %>% filter(!(EAVE_LINKNO %in% z_first$EAVE_LINKNO) ) %>% bind_rows(z_first)

v3 <- filter(Vaccinations, vacc_dose_number==3) %>% 
  dplyr::select(EAVE_LINKNO, Date, vacc_type, vacc_dose_number, vacc_booster) %>% 
  mutate(vacc_booster = if_else(vacc_booster, "booster","dose_3"))
z_second$vacc_booster <- "unknown"
v3 <- v3 %>%   bind_rows(z_second) 
#find duplicates
z <- filter(v3, duplicated(EAVE_LINKNO)) %>% pull(EAVE_LINKNO)
z_id_problem <- c(z_id_problem, unique(z))
z <- filter(v3, EAVE_LINKNO %in% z)
z <- z %>% arrange(EAVE_LINKNO, Date) %>% group_by(EAVE_LINKNO) %>% mutate(diff = as.numeric(Date - first(Date)) ) %>% ungroup() 
z <- z %>% mutate(first_record = if_else(EAVE_LINKNO == lag(EAVE_LINKNO), 0,1)) %>% 
  mutate(first_record = if_else(is.na(first_record), 1, first_record))
z <- z %>% arrange(vacc_booster, EAVE_LINKNO, Date)  # get in order booster/dose 3 /unknown
z <- z %>% filter(!(vacc_type=="AZ" & vacc_booster =="booster"))  #there should not be AZ booster
z_first <- z %>% filter(!duplicated(EAVE_LINKNO))
v3 <- v3 %>% filter(!(EAVE_LINKNO %in% z_first$EAVE_LINKNO) ) %>% bind_rows(z_first)
v3 <- v3 %>% dplyr::select(-diff, -first_record)
#now find duplicates - none

#now check out those with multiple records
z <- Vaccinations %>% filter(EAVE_LINKNO %in% z_id_problem) %>% 
  dplyr::select(EAVE_LINKNO, Date, vacc_type, vacc_dose_number, vacc_booster) %>% arrange(EAVE_LINKNO, Date)

Vaccinations <- full_join(v1,v2, by="EAVE_LINKNO") %>% 
  mutate(date_vacc_1 = as.Date(Date.x), 
         date_vacc_2 = as.Date(Date.y) ) %>% 
  dplyr::rename(vacc_type=vacc_type.x,
                vacc_type_2=vacc_type.y) %>% 
  dplyr::select(-vacc_dose_number.x, -vacc_dose_number.y, -Date.x, -Date.y) %>% 
  mutate(z_sel = is.na(date_vacc_1)) %>% 
  mutate(vacc_type = if_else(z_sel, vacc_type_2, vacc_type),
         date_vacc_1 = if_else(z_sel, date_vacc_2, date_vacc_1),
         vacc_type_2 = if_else(z_sel, NA_character_, vacc_type_2),
         date_vacc_2 = if_else(z_sel, NA_Date_, date_vacc_2)) %>%  # move vacc2 to vacc1 for those with no vacc 1 and change vacc2 to missing
  dplyr::select(-z_sel)

#add in booster
z <- full_join(Vaccinations,v3, by="EAVE_LINKNO") %>% 
  mutate(date_vacc_3 = as.Date(Date)) %>% 
  dplyr::rename(vacc_type_3 = vacc_type.y, vacc_type=vacc_type.x) %>% 
  dplyr::select(-vacc_dose_number, -Date) %>% 
  # move vacc3 to vacc1 for those with no vacc 1 (and hence no vacc_2) and change vacc2/3 to missing
  mutate(z_sel = is.na(date_vacc_1)) %>% 
  mutate(vacc_type = if_else(z_sel, vacc_type_3, vacc_type),
         date_vacc_1 = if_else(z_sel, date_vacc_3, date_vacc_1),
         vacc_type_2 = if_else(z_sel, NA_character_, vacc_type_2),
         date_vacc_2 = if_else(z_sel, NA_Date_, date_vacc_2),
         vacc_type_3 = if_else(z_sel, NA_character_, vacc_type_3),
         date_vacc_3 = if_else(z_sel, NA_Date_, date_vacc_3)) %>% 
  # move vacc3 to vacc1 for those with no vacc 1 (and hence no vacc_2) and change vacc2/3 to missing
  mutate(z_sel = is.na(date_vacc_2)) %>% 
  mutate(vacc_type_2 = if_else(z_sel, vacc_type_3, vacc_type),
         date_vacc_2 = if_else(z_sel, date_vacc_3, date_vacc_2),
         vacc_type_3 = if_else(z_sel, NA_character_, vacc_type_3),
         date_vacc_3 = if_else(z_sel, NA_Date_, date_vacc_3)) %>% 
  dplyr::select(-z_sel)        
Vaccinations <- z

# Sort of the age at first vaccination
Vaccinations = Vaccinations %>% mutate(age_at_vacc_1 = age_at_vacc_1.x) %>% select(-age_at_vacc_1.x, -age_at_vacc_1.y)

rm(z,v1,v2,v3, z1 ,z_first, z_second)

print(table(Vaccinations$vacc_type, Vaccinations$vacc_type_2, exclude=NULL))
#flag inconsistent records
Vaccinations <- Vaccinations %>%
  mutate(flag_incon = if_else(EAVE_LINKNO %in% z_id_problem, 1,0)) %>% 
  mutate(flag_incon = case_when(vacc_type %in% c("AZ","PB", "Mo", "Ja") & is.na(vacc_type_2) ~ flag_incon,
                                vacc_type %in% c("AZ","PB", "Mo", "Ja") & !is.na(vacc_type_2) & vacc_type==vacc_type_2 ~ flag_incon,
                                TRUE ~ 1 ))
print(table(Vaccinations$vacc_type, Vaccinations$vacc_type_2, Vaccinations$flag_incon, exclude=NULL))
print(table(Vaccinations$vacc_type, Vaccinations$vacc_type_3, Vaccinations$flag_incon, exclude=NULL))

#second on same day as first - make one dose
Vaccinations <- Vaccinations %>% 
  mutate(vacc_type_2 = if_else(!is.na(date_vacc_2) & (date_vacc_2 == date_vacc_1), NA_character_, vacc_type_2 ) ) %>% 
  mutate(date_vacc_2 = as.Date(ifelse(!is.na(date_vacc_2) & (date_vacc_2 == date_vacc_1), NA, date_vacc_2 ), origin=as.Date("1970-01-01")) )
#mark inconsistent records with second dose too close to first
Vaccinations <- Vaccinations %>% 
  mutate(flag_incon = if_else(!is.na(date_vacc_2)&(date_vacc_2 <= date_vacc_1 + 18), 1, flag_incon))
#z <- Vaccinations %>% filter(date_vacc_1 < as.Date("2020-12-07"))

Vaccinations <- Vaccinations %>% 
  mutate(flag_incon = if_else(date_vacc_1 <= as.Date("2020-12-08"), 1, flag_incon),
         flag_incon = if_else(!is.na(date_vacc_2)&date_vacc_2 <= as.Date("2020-12-08")+18, 1, flag_incon),
         flag_incon = if_else(!is.na(date_vacc_3) & date_vacc_3 <= as.Date("2021-09-13"), 1, flag_incon) )

print(table(is.na(Vaccinations$date_vacc_1)))
print(table(is.na(Vaccinations$date_vacc_1), is.na(Vaccinations$date_vacc_2)))
print(table(is.na(Vaccinations$date_vacc_2), is.na(Vaccinations$date_vacc_3)))