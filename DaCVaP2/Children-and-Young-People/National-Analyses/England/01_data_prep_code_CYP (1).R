# Purpose: This script is to prepare the data for CYP analysis
# Author: Utkarsh Agrawal
# Project: DaCVaP

# Set working directory
setwd("~/DaCVaP CYP/cohort_curation/")

# Load packages
library(RODBC)
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(lubridate)

###########
# write queries to extract relevant data
cohort_query <- "SELECT [StudyID]
                  ,[PracticeStudyID]
                  ,[LatestExtractDate]
                  ,[RegistrationDate]
                  ,[DeRegistrationDateNoNulls]
                  ,[DateOfBirth]
                  ,[DateOfDeath]
                  ,[Sex]
                  ,[FirstVaccinationDoseDate]
                  ,[FirstVaccinationBrand]
                  ,[SecondVaccinationDoseDate]
                  ,[SecondVaccinationBrand]
                  ,[ThirdVaccinationDoseDate]
                  ,[ThirdVaccinationBrand]
                  ,[NumberOfFurtherVaccinationDoses]
                  ,[HouseholdKey]
                  FROM [OtherSurveillance].[DaCVaP].[Cohort_20221020]"

hosp_query <- "SELECT *
                FROM [OtherSurveillance].[DaCVaP].[HospitalAdmissions]"

covid_tests_query <- "SELECT *
                        FROM [OtherSurveillance].[DaCVaP].[PositiveTests]"

###########

###########
# Connect to server and load data
con <- odbcConnect("MSSQL", uid="orchid\\cig-uagrawal",
                   pwd=rstudioapi::askForPassword("password: "))
odbcGetInfo(con)

cohort <- sqlQuery(con, cohort_query)
str(cohort)

hosp <- sqlQuery(con, hosp_query)
str(hosp)

covid <- sqlQuery(con, covid_tests_query)
str(covid)

# clean environment: remove queries
rm(cohort_query, hosp_query, covid_tests_query)
###########

###########
cohort_start_date <- as.Date("2021-08-04")
cohort_end_date <- as.Date("2022-05-31")
###########

###########
# Since the household key is currently available for the Wellbeing data,
# we filter out all the individuals for whom this key is not present
cohort <- cohort %>%
  filter(!is.na(HouseholdKey))

# Adding number of household in the house
cohort <- cohort %>%
  group_by(HouseholdKey) %>%
  mutate(household_n = n()) %>%
  ungroup()

# Adding age
cohort <- cohort %>%
  mutate(AgeAtIndex = as.period(interval(DateOfBirth, ymd(cohort_start_date)))$year,
         AgeAtEnd = as.period(interval(DateOfBirth, ymd(cohort_end_date)))$year)

# Cleaning household variable
cohort <- cohort %>%
  filter(household_n<10 & household_n>=2)

# Adding flag that each household has atleast 1 adult
cohort <- cohort %>%
  mutate(IsAdult = ifelse(AgeAtIndex>=18,1,0))

cohort <- cohort %>%
  group_by(HouseholdKey) %>%
  mutate(sum_age_flag = sum(IsAdult)) %>%
  ungroup()

cohort <- filter(cohort, sum_age_flag>=1)

# Remove unwanted variables
cohort$sum_age_flag <- NULL
cohort$IsAdult <- NULL

# Adult vaccinated status curation
cohort <- cohort %>%
  mutate(household_id = as.integer(factor(HouseholdKey)))
adult_cohort <- filter(cohort, AgeAtIndex>=18)
adult_cohort <- adult_cohort %>%
  mutate(IsVaccinated = ifelse(!is.na(FirstVaccinationDoseDate),1,0))
adult_cohort <- adult_cohort %>%
  group_by(HouseholdKey) %>%
  mutate(num_adults = n()) %>%
  ungroup()
adult_cohort <- adult_cohort %>%
  group_by(HouseholdKey) %>%
  mutate(sum_vaccinated_flag = sum(IsVaccinated)) %>%
  ungroup()
household_vacc_status <- adult_cohort %>%
  select(household_id, num_adults, sum_vaccinated_flag) %>%
  distinct(household_id, .keep_all = TRUE)
household_vacc_status <- household_vacc_status %>%
  mutate(hh_vaccinated = ifelse(sum_vaccinated_flag==0,"Unvaccinated",
                                ifelse(sum_vaccinated_flag!=0 & 
                                         sum_vaccinated_flag<num_adults,
                                       "Partially vaccinated",
                                       ifelse(sum_vaccinated_flag!=0 & 
                                                sum_vaccinated_flag==num_adults,
                                              "Fully vaccinated", "Unknown"))))

# Remove unwanted variables
household_vacc_status$num_adults<-NULL
household_vacc_status$sum_vaccinated_flag <- NULL
rm(adult_cohort)
###########

###########
# Data cleaning
# cyp <- cohort %>%
#   filter(RegistrationDate <= ymd(cohort_start_date))
cyp <- cohort %>%
  filter(RegistrationDate <= ymd(cohort_start_date) &
           DeRegistrationDateNoNulls >= ymd(cohort_start_date))

cyp <- cyp %>%
  filter(AgeAtIndex >= 5 & AgeAtIndex <= 17 & AgeAtEnd >= 5 & AgeAtEnd <= 17)

cyp <- cyp %>%
  filter(is.na(DateOfDeath) | (!is.na(DateOfDeath) &
                                 DateOfDeath >= ymd(cohort_start_date)))

cyp <- cyp %>%
  filter((!is.na(FirstVaccinationDoseDate) &
            (FirstVaccinationBrand == "Pfizer-BioNTech" |
               FirstVaccinationBrand == "Pfizer-BioNTech(Children)" |
               FirstVaccinationBrand == "Pfizer-BioNTech(Bivalent)" |
               FirstVaccinationBrand == "AstraZeneca" |
               FirstVaccinationBrand == "Moderna(Bivalent)" |
               FirstVaccinationBrand == "Moderna")) |
           is.na(FirstVaccinationDoseDate))

cyp <- cyp %>%
  filter((!is.na(SecondVaccinationDoseDate) &
            (SecondVaccinationBrand == "Pfizer-BioNTech" |
               SecondVaccinationBrand == "Pfizer-BioNTech(Children)" |
               SecondVaccinationBrand == "Pfizer-BioNTech(Bivalent)" |
               SecondVaccinationBrand == "AstraZeneca" |
               SecondVaccinationBrand == "Moderna(Bivalent)" |
               SecondVaccinationBrand == "Moderna")) |
           is.na(SecondVaccinationDoseDate))

cyp <- cyp %>%
  filter((!is.na(ThirdVaccinationDoseDate) &
            (ThirdVaccinationBrand == "Pfizer-BioNTech" |
               ThirdVaccinationBrand == "Pfizer-BioNTech(Children)" |
               ThirdVaccinationBrand == "Pfizer-BioNTech(Bivalent)" |
               ThirdVaccinationBrand == "AstraZeneca" |
               ThirdVaccinationBrand == "Moderna(Bivalent)" |
               ThirdVaccinationBrand == "Moderna")) |
           is.na(ThirdVaccinationDoseDate))

# filter CYP with interval between V1 & V2 and V2 & V3 dose less than 28 days
cyp <- cyp %>%
  mutate(vacint.1 = trunc(as.numeric(difftime(SecondVaccinationDoseDate,
                                              FirstVaccinationDoseDate,
                                              unit = "days"))),
         vacint.2 = trunc(as.numeric(difftime(ThirdVaccinationDoseDate,
                                              SecondVaccinationDoseDate,
                                              unit = "days"))))
cyp <- cyp %>%
  filter(is.na(vacint.1)|vacint.1>=28)
cyp <- cyp %>%
  filter(is.na(vacint.2)|vacint.2>=28)
###########

###########
# Creating age groups
cyp <- cyp %>%
  mutate(age_cat = cut(AgeAtEnd, breaks = c(5, 12, 16, 18), right = FALSE))

cyp$age_cat <- recode(cyp$age_cat, "[5,12)" = "5-11",
                       "[12,16)" = "12-15",
                       "[16,18)" = "16-17")

###########

###########
# first vaccine dose start date setting for different age groups
# cyp <- cyp %>%
#   filter(is.na(FirstVaccinationDoseDate) |
#            FirstVaccinationDoseDate >= ymd("2021-08-04"))
cyp <- cyp %>%
  mutate(early_vacc = ifelse((age_cat == "16-17" &
                               FirstVaccinationDoseDate >= ymd("2021-08-04")) |
                              (age_cat == "12-15" &
                                 FirstVaccinationDoseDate >= ymd("2021-09-14")) |
                              (age_cat == "5-11" &
                                 FirstVaccinationDoseDate >= ymd("2022-02-15")) |
                               is.na(FirstVaccinationDoseDate),
                            0, 1))
cyp <- filter(cyp, early_vacc==0)
cyp$early_vacc <- NULL
###########

###########
# Filter out hospital stay more than 1 week
cyp_hosp_long_stay <- hosp %>%
  filter(StudyID %in% cyp$StudyID) %>%
  filter(AdmissionDate >= ymd(cohort_start_date) &
           AdmissionDate <= ymd("2022-05-31")) %>%
  mutate(LengthOfStay = as.numeric(difftime(DischargeDate, AdmissionDate,
                                            units = "days"))) %>%
  filter(LengthOfStay > 7) %>%
  distinct(StudyID, .keep_all = TRUE)

cyp <- subset(cyp, !(StudyID %in% cyp_hosp_long_stay$StudyID))
rm(cyp_hosp_long_stay)
###########

###########
# Number of infections in the study period
cyp_inf <- covid %>%
  filter(StudyID %in% cyp$StudyID & TestDate >= ymd("2021-07-01") &
           TestDate <= ymd(cohort_end_date)) %>%
  select(c(StudyID, TestDate)) %>%
  arrange(StudyID, TestDate)

agegroup <- cyp %>%
  select(c(StudyID, age_cat))
cyp_inf <- left_join(cyp_inf, agegroup)
cyp_inf <- cyp_inf %>%
  mutate(TestWeek = floor_date(TestDate, unit = "week", week_start = 1))

# Clean up infection data - drop repeated tests for same episode (90 days)
f <- function(d, ind=1) {
  ind.next <- first(which(difftime(d, d[ind], units="days") >= 90))
  if (is.na(ind.next))
    return(ind)
  else
    return(c(ind, f(d, ind.next)))
}

cyp_inf_clean <- cyp_inf %>%
  group_by(StudyID) %>%
  slice(f(as.Date(TestDate, format="%Y-%m-%d")))

# Spread the data in the wider format
cyp_inf_clean <- cyp_inf_clean %>%
  group_by(StudyID) %>%
  mutate(V=row_number()) %>%
  ungroup %>%
  pivot_wider(
    id_cols = StudyID,
    names_prefix = "infection_",
    names_from = V,
    values_from = TestDate,
    values_fill = NA
  )

cyp_inf_clean <- cyp_inf_clean %>%
  mutate(cyp_inf_clean, infection_4 = as.Date(NA_character_))
###########

###########
# Creating the final cohort
cyp <- left_join(cyp, cyp_inf_clean, by="StudyID")
cyp <- left_join(cyp, household_vacc_status, by="household_id")
rm(household_vacc_status, cyp_inf, cyp_inf_clean, agegroup)

cyp$household_n[cyp$household_n>=5]="5+"
cyp$household_n <- as.factor(cyp$household_n)

# cyp<-mutate(cyp, DeRegistrationDateNoNulls_n = 
#                ifelse(DeRegistrationDateNoNulls>"2022-05-31",
#                       as.Date(NA_character_), 
#                       DeRegistrationDateNoNulls))
cyp<-mutate(cyp, DeRegistrationDateNoNulls_n = DeRegistrationDateNoNulls)
cyp$DeRegistrationDateNoNulls_n[cyp$DeRegistrationDateNoNulls_n>"2022-05-31"]<-NA

cyp_cohort <- select(cyp, StudyID, Sex, age_cat, household_n, hh_vaccinated,
                     FirstVaccinationDoseDate, SecondVaccinationDoseDate,
                     ThirdVaccinationDoseDate, infection_1, infection_2,
                     infection_3, infection_4, DeRegistrationDateNoNulls_n,
                     DateOfDeath)

# Rename column variables
colnames(cyp_cohort)[colnames(cyp_cohort) %in% c("Sex", 
                                     "FirstVaccinationDoseDate", 
                                     "SecondVaccinationDoseDate", 
                                     "ThirdVaccinationDoseDate", 
                                     "infection_1", "infection_2",
                                     "infection_3", "infection_4", 
                                     "DeRegistrationDateNoNulls_n", 
                                     "DateOfDeath")] <- c("sex",
                                     "vacc_dose1_date", "vacc_dose2_date", 
                                     "vacc_doseb_date", "infection1_test_date", 
                                     "infection2_test_date", 
                                     "infection3_test_date", 
                                     "infection4_test_date", "move_out_date",
                                     "death_date")
###########

###########
setwd("~/DaCVaP CYP/")
saveRDS(cyp_cohort, "cyp_analysis_cohort_11-10-2022.rds")
rm(list = ls())
cat("\014")
###########