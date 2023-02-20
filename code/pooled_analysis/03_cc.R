######################################################################
## Title: Meta-analysis of first dose ChAdOx1 and BNT162b2 COVID-19 vaccinations and thrombocytopenic, venous thromboembolic
##        and haemorrhagic events in the UK
##
## Short title: Vaccine safety meta-analysis
##
## Code author: Steven Kerr
##
## Description: This 'rehydrates' count data from England and Wales with synthetic
#               and combines with Scottish data, generating synthetic IDs
######################################################################

library(readxl)
library(tidyverse)
library(finalfit)
library(survival)

# Set working directory on PHS for SRK
setwd('/conf/EAVE/GPanalysis/progs/SRK/Covid-vaccine-safety-MA')




wales <- read_csv('./data/pooled_analyses/cc_cvst_2.csv')

wales_vacs <-read_csv('./data/pooled_analyses/age_vaccine_aggregated_cohort_count.csv') 

wales_vac_totals <- group_by(wales_vacs, FIRST_VACC) %>% summarise( total = sum(NUMBER_OF_INDIVIDUALS)) 



