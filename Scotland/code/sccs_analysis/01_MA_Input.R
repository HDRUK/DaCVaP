######################################################################
## Title: Meta-analysis of first dose ChAdOx1 and BNT162b2 COVID-19 vaccinations and thrombocytopenic, venous thromboembolic
##        and haemorrhagic events in the UK
##
## Short title: Vaccine safety meta-analysis
##
## Code author: Chris Robertson, Steven Kerr
##
## Description: This prepares the data for the sccs meta-analysis
######################################################################

library(readxl)
library(tidyverse)

# Set working directory on PHS for SRK
setwd('/conf/EAVE/GPanalysis/progs/SRK/Covid-vaccine-safety-MA')

############################ FUNCTIONS ###############################

# Convert cols to numeric type
convert_to_numeric <- function(df, cols){
  for (col in cols){
    df[ ,col] <- as.numeric(pull(df,col))
  }
  return(df)
}

# This reads in English data, with no weighting as in read_eng_avg
# file is the name of the file in data folder
# Needs changed depending on whether doing case-control analysis, or SCCS.
read_eng <- function(file){
  
  # For SCCS
  sheets <- c( "Arterial_thromb" = 1, "any_haem" = 2, "itp" = 3, "itp_gen" = 4, "throm_cvst" = 5)

  for (i in sheets) { 
    #i <- 1
    
    if(i == 1){ output <- read_xlsx( paste0("./data/", file) , sheet=1)
                output$group <- names(sheets)[1] }
    else{
    
    new_block <- read_xlsx( paste0("./data/", file) , sheet=i)
    new_block$group <- names(sheets)[i]

    output <- bind_rows(output, new_block)
    }
  }

  return(output)
}

##################### IMPORT DATA ##################################

# Scottish data
scot <- read.csv("./data/scotland_sccs_results.csv")

# English data
eng <- read_eng('SCCS-sensitivity-analysis-Table_3.xlsx')

# Welsh data
wales <- read.csv("./data/wales_sccs_ma_results.csv")

####################### PREPARE DATA ###################################

scot <-dplyr::rename(scot, vaccine_type = Vacc.Type, `Time period` = exposure, OR = Est, group = outcome) 

scot <- mutate(scot, log_OR = log(OR),  se_log_OR =(UCL - LCL)/3.92, 
                     `Time period` = gsub("Pre.Vacc","Pre-risk", `Time period`),
                     country = 'Scotland' )


eng <- dplyr::rename(eng, OR = RI)

eng <- mutate(eng, `vaccine_type` = case_when( grepl('AZ', `Time period` ) ~ 'AZ',
                                               grepl('Pfizer', `Time period` ) ~ 'PB'),
                   `Time period` = case_when( grepl('pre-vaccination', `Time period` ) ~ 'Pre-risk',
                                              grepl('1-14', `Time period` ) ~ 'Clearance',
                                              grepl('0-28', `Time period` ) ~ 'Risk'),
                    log_OR = log(OR),
                    se_log_OR =(UCL - LCL)/3.92,
                    country = 'England - RCGP')



wales$group <- c( rep('itp', 6), rep('itp_gen', 6), rep('any_haem', 6), rep('throm_cvst', 6), rep('Arterial_thromb', 6))

wales <- dplyr::rename(wales, `Time period` = Time.period)

wales <- mutate(wales, `vaccine_type` = case_when( grepl('ChAdOx1', `Time period` ) ~ 'AZ',
                                               grepl('BNT162b2', `Time period` ) ~ 'PB'),
              `Time period` = case_when( grepl('Pre-vaccination', `Time period` ) ~ 'Pre-risk',
                                         grepl('1-14', `Time period` ) ~ 'Clearance',
                                         grepl('0-28', `Time period` ) ~ 'Risk'),
              log_OR = log(OR),
              se_log_OR =(UCL - LCL)/3.92,
              country = 'Wales')

######################## COMBINE DATA ################################

df <- bind_rows(eng, scot)
df <- bind_rows(df, wales)

df <- select(df, country, `Time period`, vaccine_type, group, log_OR, se_log_OR)
