##########################################################
# Name of file: 01a_Vaccinations_Input.R
# Data release (if applicable):
# Original author(s): Chris Robertson chris.robertson@nhs.scot
# Original date: 20 Jan 2021
# Latest update author (if not using version control) - Chris Robertson chris.robertson@nhs.scot
# Latest update date (if not using version control) - 
# Latest update description (if not using version control)
# Type of script: Descriptive stats
# Written/run onL: R Studio SERVER
# Version of R that the script was most recently run on: R 3.6.1
# Description of content: reads in the cohort and merges in vaccination data 
# Approximate run time: Unknown
##########################################################

# 01 Setup ####
#Libraries
library(plyr)
library(tidyverse)
library(survival)
library(lubridate)
#Load data

Location <- "/conf/"  # Server
#Location <- "//isdsf00d03/"  # Desktop

#Read in the cohrt from 01a_Vaccination_Input.R in Vaccine folder
project_path <- paste0(Location,"EAVE/GPanalysis/progs/CR/Vaccine")
df_cohort <- readRDS(paste0(project_path,"/output/temp/df_cohort.rds"))
project_path <- paste0(Location,"EAVE/GPanalysis/progs/CR/Vaccine_Safety")

#read in the Date of Death
z  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/all_deaths.rds"))
all_deaths <- z %>% dplyr::select(EAVE_LINKNO, NRS.Date.Death)

#read in all hospitalisations
hosp_adm_nov01 <- readRDS(paste0(Location,"EAVE/GPanalysis/data/any_hospitalisation_post_01112020.rds")) %>% 
  filter(!is.na(EAVE_LINKNO))


#read in the GP vaccination data
z  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/C19vaccine.rds"))

print(unique(z$type))
print(unique(z$stage))

Vaccinations <- z %>% mutate(Date = as.Date(occurrence_time)) %>% 
  mutate(vacc_type = case_when(grepl("COURAGEOUS", type) ~ "PB",
                               grepl("TALENT", type) ~ "AZ",
                               type == "39114911000001105" ~ "AZ",
                               type == "39115611000001103" ~ "PB",
#                              type == "39115611000001105" ~ "PB",
                               TRUE ~ "UNK"), 
         dose_number = if_else(stage %in% c(0,3), 1L, stage))

v1 <- filter(Vaccinations, dose_number==1) %>% 
  dplyr::select(EAVE_LINKNO, Date, vacc_type, dose_number) %>% 
  arrange(EAVE_LINKNO, Date) %>% 
  filter(!duplicated(EAVE_LINKNO))
v2 <- filter(Vaccinations, dose_number==2) %>% 
  dplyr::select(EAVE_LINKNO, Date, vacc_type, dose_number) %>% 
  arrange(EAVE_LINKNO, Date) %>% 
  filter(!duplicated(EAVE_LINKNO))

Vaccinations <- left_join(v1,v2, by="EAVE_LINKNO") %>% 
  mutate(date_vacc_1 = as.Date(Date.x), 
         date_vacc_2 = as.Date(Date.y) ) %>% 
  dplyr::rename(vacc_type=vacc_type.x,
                vacc_type_2=vacc_type.y) %>% 
  dplyr::select(-dose_number.x, -dose_number.y, -Date.x, -Date.y)
rm(z,v1,v2)

print(table(Vaccinations$vacc_type, Vaccinations$vacc_type_2, exclude=NULL))
#omit inconsistent records
Vaccinations <- Vaccinations %>% filter(vacc_type %in% c("AZ","PB")) %>% 
  filter(vacc_type_2 %in% c("AZ","PB") | is.na(vacc_type_2)) %>% 
  filter( !(!is.na(vacc_type_2) & (vacc_type_2 != vacc_type)))

#second on same day as first - make one dose
Vaccinations <- Vaccinations %>% 
  mutate(vacc_type_2 = if_else(!is.na(date_vacc_2) & (date_vacc_2 == date_vacc_1), NA_character_, vacc_type_2 ) ) %>% 
  mutate(date_vacc_2 = as.Date(ifelse(!is.na(date_vacc_2) & (date_vacc_2 == date_vacc_1), NA, date_vacc_2 ), origin=as.Date("1970-01-01")) )
#omit records with second dose too close to first
Vaccinations <- filter(Vaccinations, is.na(date_vacc_2) | !is.na(date_vacc_2)&(date_vacc_2 > date_vacc_1 + 18))


rm(z,z1,z2, z_vacc)
#Vaccinations <- filter(Vaccinations, date_vacc_1 <= as.Date("2021-02-20"))
#saveRDS(Vaccinations, paste0(project_path,"/output/temp/Vaccinations_20210308.rds"))
#Vaccinations <- readRDS(paste0(project_path,"/output/temp/Vaccinations_20210222.rds"))

#df  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/AZ_safety_CODECHECKS2021-03-31.rds"))
#df  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/AZ_safety_2021-03-29.rds"))
#df  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/AZ_safety_2021-03-31.rds"))
#df  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/AZ_safety_2021-04-08.rds"))
df  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/AZ_safety_2021-04-12.rds"))

df <- df %>% mutate(YEAR = ifelse(StartDate < as.Date("2020-09-01"), "Year1", "Year2"))
df <- df %>% mutate(month = lubridate::month(StartDate, label =T) )
df <- df %>% mutate(period = case_when(month %in% c("Sep",  "Oct",   "Nov") ~ "P1",
                                       month %in% c("Dec",  "Jan",   "Feb", "Mar") ~ "P2",
                                       TRUE ~ "P3") )


table(df$YEAR, df$Quick_groups)
table(df$YEAR, df$month, df$period)
df <- df %>% mutate(Age = as.numeric(Age))


df <- df %>% mutate(AgeGrp = case_when(Age <15 ~ "0-15", 
                                       Age >= 15 & Age < 20 ~ "15-19",
                                       Age >= 20 & Age < 40 ~ "20-39",
                                       Age >= 40 & Age < 60 ~ "40-59",
                                       Age >= 60 & Age < 80 ~ "60-79",
                                       Age >= 80  ~ "80+"))
table(df$AgeGrp, df$Quick_groups, df$YEAR)
df <- filter(df, StartDate <= Sys.Date())
#df <- filter(df, ExtractDate <= as.Date("2021-03-29") | Quick_groups %in% c("CVT","SVT"))

GP_Consultations <- df

Household <- readRDS(paste0(Location,"EAVE/GPanalysis/outputs/temp/Cohort_Household.rds"))

#get testing data
z  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/ECOSSdeduped_linked_2021-04-07.rds"))
Pos_Test <- z %>% filter(NCOV_RESULT=="Positive") %>% filter(SpecimenDate >= as.Date("2020-03-01"))
  
  