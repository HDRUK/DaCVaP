##########################################################
# Name of file: 01a_Input_Data.R
# Data release (if applicable):
# Original author(s): Chris Robertson chrisobertson@phs.scot
# Original date: 09 November 2021
# Latest update author (if not using version control) - Chris Robertson chrisobertson@nhs.net
# Latest update date (if not using version control) - 
# Latest update description (if not using version control)
# Type of script: Descriptive stats

# Written/run onL: R Studio SERVER
# Version of R that the script was most recently run on: R 3.6.1
# Description of content: reads in the cohort and merges in the Q Covid risk groups
#                         reads in vaccination and testing data
#                         selects only those records belonging to children and young people under 18
# Approximate run time: Unknown
##########################################################

# 01 Setup ####
#Libraries
library(tidyverse)
library(lubridate)
library(survival) 
library(dplyr)
#Load data

min_age = 5 # Minimum age of the cohort we are interested in
max_age = 17 # Maximum age of the cohort we are interested in

Location <- "/conf/"  # Server
setwd("/conf/EAVE/GPanalysis/progs/TM/dacvap_uptake/")
#Location <- "//isdsf00d03/"  # Desktop
a_begin = as.Date("2021-08-04")
a_end = as.Date("2022-04-18")
a_analysis_date <- a_end #change this to try and recreate historical analyses

#EAVE_endpoints <- readRDS(paste0(Location,"EAVE/GPanalysis/outputs/temp/severe_endpoints2021-12-14.rds")) #n=770,429rows
#EAVE_endpoints <- readRDS(paste0(Location,"EAVE/GPanalysis/outputs/temp/severe_endpoints2022-01-27.rds")) #n=770,429rows
#EAVE_endpoints <- readRDS(paste0(Location,"EAVE/GPanalysis/outputs/temp/severe_endpoints2022-04-12.rds")) #n=770,429rows
EAVE_endpoints <- readRDS(paste0(Location,"EAVE/GPanalysis/outputs/temp/severe_endpoints2022-06-23.rds")) #n=770,429rows

#EV - "the code below results in 0 rows so don't run it"
#EAVE_endpoints <- EAVE_endpoints %>% filter(duplicated(paste(EAVE_LINKNO, KEYDATE))) %>% arrange(EAVE_LINKNO, KEYDATE)
#z_id <- EAVE_endpoints %>% filter(duplicated(paste(EAVE_LINKNO, KEYDATE))) %>% pull(EAVE_LINKNO)
#z <- EAVE_endpoints %>% filter(EAVE_LINKNO %in% z_id) %>% arrange(EAVE_LINKNO, KEYDATE)

#table(table(EAVE_endpoints$EAVE_LINKNO))
#
#deaths within 28 days of a positive test (replace date_ecoss_specimen with SpecimenDate)
EAVE_endpoints <- EAVE_endpoints %>%
  mutate(SpecimenDate = as_date(SpecimenDate)) %>% 
  mutate(dead28 = if_else(!is.na(SpecimenDate) & !is.na(NRS.Date.Death) & NRS.Date.Death <= SpecimenDate+28 &
                          NRS.Date.Death >= SpecimenDate - 32, 1, 0 ))


table(EAVE_endpoints$dead28, is.na(EAVE_endpoints$NRS.Date.Death), exclude=NULL)
table(EAVE_endpoints$covid_cod, is.na(EAVE_endpoints$NRS.Date.Death), exclude=NULL)
table(EAVE_endpoints$covid_ucod, is.na(EAVE_endpoints$NRS.Date.Death), exclude=NULL)
table(EAVE_endpoints$covid_cod, EAVE_endpoints$covid_ucod, is.na(EAVE_endpoints$NRS.Date.Death), exclude=NULL)
table(EAVE_endpoints$covid_cod, EAVE_endpoints$dead28, is.na(EAVE_endpoints$NRS.Date.Death), exclude=NULL)
#for a covid death use death_covid==1 | covid_cod==1
#9 for covid_cod means no NRS info on cause of death
#for event date use NRS.Date.Death

table(EAVE_endpoints$icu28, is.na(EAVE_endpoints$ICU_admit_date), exclude=NULL)
table(EAVE_endpoints$covid_mcoa_icu, is.na(EAVE_endpoints$ICU_admit_date), exclude=NULL)
table(EAVE_endpoints$icu28,EAVE_endpoints$covid_mcoa_icu, is.na(EAVE_endpoints$ICU_admit_date), exclude=NULL)
#for covid_icu use icu28==1 | covid_mcao_icu==1
#for event date use ICU_admit_date - present for all ICU admissions
#for the combined covid_death_icu use death_covid==1 | covid_icu==1 
#for event date use ICU_admit_date for covid_icu==1 or NRS.Date.Death for the others

table(EAVE_endpoints$hosp28, is.na(EAVE_endpoints$hosp_admit_date), exclude=NULL)
table(EAVE_endpoints$covid_mcoa_hosp, is.na(EAVE_endpoints$hosp_admit_date), exclude=NULL)
table(EAVE_endpoints$hosp28,EAVE_endpoints$covid_mcoa_hosp, is.na(EAVE_endpoints$hosp_admit_date), exclude=NULL)
#covid hosp is hosp28==1 | covid_mcoa_hosp==1
#for event date use hosp_admit_date - present for all admissions
#emergency for emergency admissions

#adjust inconsistencies in the endpoints and times - all hosp have an admission date
#single endpoints
EAVE_endpoints <- EAVE_endpoints %>% 
  mutate(covid_death = case_when(!is.na(dead28) & dead28==1 ~ 1L,
                                 !is.na(covid_cod) & covid_cod==1 ~ 1L,
                                 TRUE ~ 0L)) %>%
  mutate(covid_icu = case_when(!is.na(icu28) & icu28==1 ~ 1L,
                               !is.na(covid_mcoa_icu) & covid_mcoa_icu==1 ~ 1L,
                               TRUE ~ 0L)) %>%
  mutate(covid_hosp = case_when(!is.na(hosp28) & hosp28==1 ~ 1L,
                                !is.na(covid_mcoa_hosp) & covid_mcoa_hosp==1 ~ 1L,
                                TRUE ~ 0L)) %>% 
  mutate(covid_hosp_confirmed = case_when(!is.na(covid_mcoa_hosp) & covid_mcoa_hosp==1 ~ 1L,
                                          TRUE ~ 0L)) %>% 
  mutate(covid_hosp = if_else(covid_hosp==0 & covid_icu==1, 1L, covid_hosp))


#dates for single endpoints
EAVE_endpoints <- EAVE_endpoints %>% 
  mutate(covid_death_date = if_else(covid_death==1, NRS.Date.Death, as.Date(NA)),
         covid_icu_date = if_else(covid_icu==1, ICU_admit_date, as.Date(NA)),
         covid_hosp_date = if_else(covid_hosp==1 & !is.na(hosp_admit_date), hosp_admit_date, as.Date(NA)), 
         covid_hosp_confirmed_date = if_else(covid_hosp_confirmed==1 & !is.na(hosp_admit_date), hosp_admit_date, as.Date(NA)))



table(EAVE_endpoints$covid_hosp, EAVE_endpoints$covid_icu, exclude=NULL)
table(EAVE_endpoints$covid_hosp, is.na(EAVE_endpoints$covid_hosp_date), exclude=NULL)
table(EAVE_endpoints$covid_icu, is.na(EAVE_endpoints$covid_icu_date), exclude=NULL)
table(EAVE_endpoints$covid_death, is.na(EAVE_endpoints$covid_death_date), exclude=NULL)

#get individual endpoints separately
covid_death <- EAVE_endpoints %>% filter(covid_death==1) %>% 
  dplyr::select(EAVE_LINKNO, SpecimenDate, covid_death_date)
table(table(covid_death$EAVE_LINKNO))  #all unique

covid_icu <- EAVE_endpoints %>% filter(covid_icu==1) %>% 
  dplyr::select(EAVE_LINKNO, SpecimenDate, covid_icu_date) %>% 
  arrange(paste(EAVE_LINKNO, covid_icu_date)) %>% 
  filter(!duplicated(paste(EAVE_LINKNO, covid_icu_date)))
table(table(covid_icu$EAVE_LINKNO))  #a few have 2+ ICU admissions

covid_hosp <- EAVE_endpoints %>% filter(covid_hosp==1) %>% 
  dplyr::select(EAVE_LINKNO, SpecimenDate, covid_hosp_date, hosp_disc_date) %>% 
  arrange(paste(EAVE_LINKNO, covid_hosp_date)) %>% 
  filter(!duplicated(paste(EAVE_LINKNO, covid_hosp_date)))
table(table(covid_hosp$EAVE_LINKNO))  #a few have 2+ hosp admissions

covid_hosp_confirmed <- EAVE_endpoints %>% filter(covid_hosp_confirmed==1) %>%
  dplyr::select(EAVE_LINKNO, SpecimenDate, covid_hosp_date) %>%
  arrange(paste(EAVE_LINKNO, covid_hosp_date)) %>%
  filter(!duplicated(paste(EAVE_LINKNO, covid_hosp_date)))
table(table(covid_hosp_confirmed$EAVE_LINKNO))  #a few have 2+ hosp admissions

Positive_Tests_90 <- EAVE_endpoints %>% filter(test_result=="POSITIVE") %>% 
  dplyr::select(EAVE_LINKNO, SpecimenDate) %>% 
  arrange(paste(EAVE_LINKNO, SpecimenDate)) %>% 
  filter(!duplicated(paste(EAVE_LINKNO, SpecimenDate)))
table(table(Positive_Tests_90$EAVE_LINKNO))  

hosps = EAVE_endpoints %>% filter(!is.na(hosp_admit_date)) %>%
  select(EAVE_LINKNO, hosp_admit_date, hosp_disc_date)

#plot the trends for checking
z_t <- Positive_Tests_90 %>% group_by(SpecimenDate) %>% dplyr::summarise(N=n())
z_t %>% ggplot(aes(x=SpecimenDate,y=N))+geom_point() +labs(title="Covid Positive Cases")

z_t <- covid_hosp %>% group_by(covid_hosp_date) %>% dplyr::summarise(N=n())
z_t %>% ggplot(aes(x=covid_hosp_date,y=N))+geom_point() +labs(title="Covid Hospitalisations (28 Days)")

z_t <- covid_icu %>% group_by(covid_icu_date) %>% dplyr::summarise(N=n())
z_t %>% ggplot(aes(x=covid_icu_date,y=N))+geom_point() +labs(title="Covid ICU Admissions")

z_t <- covid_death %>% group_by(covid_death_date) %>% dplyr::summarise(N=n())
z_t %>% ggplot(aes(x=covid_death_date,y=N))+geom_point() +labs(title="Covid Deaths")

remove(list=ls(pa="^z"))

#get the full cohort list - use the 28 July endpoints file but just keep the demographics
EAVE_cohort <- readRDS(paste0(Location,"EAVE/GPanalysis/outputs/temp/Cohort_Demog_Endpoints_Times2021-07-28.rds"))
EAVE_cohort <- filter(EAVE_cohort, !duplicated(EAVE_LINKNO)) %>% 
 dplyr::select(EAVE_LINKNO:ur6_2016_name) %>% 
   mutate(ageYear=ageYear+2)   #get age at March 2022

print("EAVE cohort size")
z_x = nrow(EAVE_cohort)
print(z_x)

#remove all who have died before the beginning
all_deaths  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/all_deaths.rds")) %>% 
  filter(!duplicated(EAVE_LINKNO))
summary(all_deaths)
z <- all_deaths %>% dplyr::select(EAVE_LINKNO, NRS.Date.Death) %>% 
  right_join(EAVE_cohort, by="EAVE_LINKNO")
EAVE_cohort <- filter(z, is.na(NRS.Date.Death) | (!is.na(NRS.Date.Death) & NRS.Date.Death > a_begin)) %>% 
  dplyr::relocate(NRS.Date.Death, .after=last_col())

print("Removing anyone who died before the start of the study")
print(z_x - nrow(EAVE_cohort))

EAVE_Weights <- readRDS(paste0(Location,"EAVE/GPanalysis/outputs/temp/CR_Cohort_Weights.rds"))
EAVE_cohort  <- EAVE_cohort %>% left_join(EAVE_Weights, by="EAVE_LINKNO")
EAVE_cohort$eave_weight[is.na(EAVE_cohort$eave_weight)] <- mean(EAVE_cohort$eave_weight, na.rm=T)

#Get the children Only
#df_cohort is the main analysis data frame
z_x = nrow(EAVE_cohort)
df_cohort <- EAVE_cohort %>% filter(ageYear >= min_age & ageYear <= max_age) 

print("Removing anyone not in the age range")
print(z_x - nrow(df_cohort))

#risk groups
rg <- readRDS( "/conf/EAVE/GPanalysis/progs/CR/Vaccine/output/temp/Qcovid_all.rds")
rg <- filter(rg,!duplicated(EAVE_LINKNO))

#individuals with no values in rg have no risk conditions
z <- df_cohort %>% 
  left_join(dplyr::select(rg,-(Sex:simd2020_sc_quintile), -DataZone, -ur6_2016_name) , by="EAVE_LINKNO")
z <- z %>% mutate_at(vars(Q_DIAG_AF:Q_DIAG_CKD_LEVEL), ~replace(., is.na(.), 0))
z <- z %>% mutate_at(vars(Q_DIAG_AF:Q_DIAG_CKD_LEVEL), ~as.numeric(.))
z <- z %>% mutate(n_risk_gps = fct_explicit_na(n_risk_gps, na_level="0"))
df_cohort <- z

df_cohort <- df_cohort %>% dplyr::select(-bmi_impute)

#get the vaccination data (already run this script so skip line 172)
#source("00_Read_DV_Vaccinations.R")  #using local version to select ages  12-18

#read in the data sets to update the weights
#those with a pis records over the last 12 months before March 2020
bnf <- readRDS(paste0(Location,"EAVE/GPanalysis/data/BNF_paragraphs.rds"))
#those with a covid test
cdw_full  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/CDW_full.rds"))
cdw_full <- cdw_full %>% mutate(date_ecoss_specimen = as_date(date_ecoss_specimen)) %>% 
  filter(date_ecoss_specimen <= a_analysis_date)
z <- cdw_full %>% filter(test_result=="POSITIVE") %>% 
  dplyr::select(EAVE_LINKNO, date_ecoss_specimen) %>% 
  arrange(EAVE_LINKNO, date_ecoss_specimen) %>%
  filter(!duplicated(paste(EAVE_LINKNO, date_ecoss_specimen)))  #get one positive test per person per day
Positive_Tests <- z #can have duplicate values here
#all deaths
all_hospitalisations  <- readRDS(paste0(Location,"EAVE/GPanalysis/data/automated_any_hospitalisation_post_01022020.rds"))
summary(all_hospitalisations)

#asthma pis data is used to ascertain if a child exists
pis_asthma <- readRDS(paste0(Location,"EAVE/GPanalysis/data/PIS_ASTHMA_2021-09-03.rds"))
#there's an error with the mutate function below so ignore lines 193-194 and just directly remove IDs below
pis_asthma <- pis_asthma %>% mutate(dispensed_full_date = as_date(dispensed_full_date, format="%Y%m%d")) %>% 
  filter(dispensed_full_date >= as_date("2019-03-01"))
summary(pis_asthma)

#all known to exist - give a weight of 1 and downweight the rest
z_ids <- c(Vaccinations$EAVE_LINKNO, all_deaths$EAVE_LINKNO, 
           cdw_full$EAVE_LINKNO, all_hospitalisations$EAVE_LINKNO, bnf$EAVE_LINKNO, pis_asthma$EAVE_LINKNO) %>% unique()
#summary(filter(EAVE_cohort, !(EAVE_LINKNO %in% z_ids))$eave_weight)
z_N <- round(sum(df_cohort$eave_weight) )
z_k <- sum(df_cohort$EAVE_LINKNO %in% z_ids)
z_m <- round(sum(filter(df_cohort, (EAVE_LINKNO %in% z_ids))$eave_weight))
z <- df_cohort %>% mutate(ew = if_else(EAVE_LINKNO %in% z_ids, 1, eave_weight*(z_N - z_k)/(z_N - z_m)) )
df_cohort <- z %>% dplyr::select(-eave_weight) %>% dplyr::rename(eave_weight=ew)

z <- read_csv(paste0(Location,"/EAVE/GPanalysis/data/restored/map_files/Datazone2011Lookup.csv")) %>% 
  dplyr::select(DataZone, InterZone, Council, HB)
df_cohort <- df_cohort %>% left_join(z, by="DataZone") %>% 
  mutate(HB = if_else(is.na(HB),"Unknown", HB),
         InterZone = if_else(is.na(InterZone),"Unknown", InterZone),
         Council = if_else(is.na(Council),"Unknown", Council))


sgene <- readRDS(paste0(Location,"/EAVE/GPanalysis/data/omicron_ctvals.rds"))
shielding <- readRDS(paste0(Location,"EAVE/GPanalysis/data/Shielding_list.rds"))
immuno <- readRDS(paste0(Location,"EAVE/GPanalysis/data/cleaned_data/Imm_supp_cohort_Nov2021.rds"))
ethnicity = readRDS(paste0(Location, "EAVE/GPanalysis/data/lookups/EAVE_Ethnicity_2022.rds"))

#NOT USED FOR CHILDREN AS THE LIST FOR CHILDREN IS INCOMPLETE
#read in the phs vax eleigible population and remove individuals not in this list
#vax_eligible_pop <- readRDS("/conf/EAVE/GPanalysis/data/vax_eligible.rds") %>% 
#  filter(!duplicated(EAVE_LINKNO))
#z <- df_cohort %>% left_join(dplyr::select(vax_eligible_pop, EAVE_LINKNO, validchi), by="EAVE_LINKNO")
# <- z %>% mutate(new_w = if_else(!is.na(validchi), eave_weight, 0))
#df_cohort <- z %>% filter(new_w >0) %>% dplyr::select(-new_w, -validchi)

#remove data sets not needed
rm(bnf, pis_asthma, z)
remove(list=ls(pa="^z"))

##########################################

#combined endpoints
EAVE_endpoints <- EAVE_endpoints %>% 
  mutate(covid_icu_death = case_when(covid_death==1 ~ 1L,
                                     covid_icu==1 ~ 1L,
                                     TRUE ~ 0L) ) %>%
  mutate(covid_icu_death_date = case_when(covid_icu==1   ~ covid_icu_date,
                                          covid_death==1 & covid_icu==0  ~ NRS.Date.Death,
                                          TRUE ~ as.Date(NA)) )

#get combined covid_hosp_death
EAVE_endpoints <- EAVE_endpoints %>% mutate(covid_hosp_death = if_else(covid_hosp==1|covid_death==1,1L,0L)) %>% 
  mutate(covid_hosp_death_date = case_when(covid_hosp==1 ~ covid_hosp_date,
                                           covid_hosp==0 & covid_death==1 ~ covid_death_date,
                                           TRUE ~ as.Date(NA)))

# Merge the endpoints into the EAVE_cohort
z_events_df = EAVE_endpoints %>% select(EAVE_LINKNO, covid_death, covid_hosp, covid_death_date, covid_hosp_date) %>%
  group_by(EAVE_LINKNO) %>%
  summarise(covid_death = sum(covid_death), covid_hosp = sum(covid_hosp), 
            covid_death_date = max(covid_death_date, na.rm = TRUE), covid_hosp_date = max(covid_hosp_date, na.rm = TRUE))

EAVE_cohort = EAVE_cohort %>% left_join(z_events_df, by='EAVE_LINKNO')

#lines below don't run as these endpoints do not exist in the EAVE_cohort datset
# Do we need the death for this dataset?
table(EAVE_cohort$covid_death, is.na(EAVE_cohort$covid_death_date), exclude=NULL)
#table(EAVE_cohort$covid_icu_death, is.na(EAVE_cohort$covid_icu_death_date), exclude=NULL)
table(EAVE_cohort$covid_hosp, is.na(EAVE_cohort$covid_hosp_date), exclude=NULL)
#table(EAVE_cohort$covid_hosp_death, is.na(EAVE_cohort$covid_hosp_death_date), exclude=NULL)

hid_data = readRDS("/conf/EAVE/GPanalysis/data/HID_MarSept_20210222.rds")

remove(list=ls(pa="^z"))
