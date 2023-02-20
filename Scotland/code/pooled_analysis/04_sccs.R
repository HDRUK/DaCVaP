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
setwd("/conf/EAVE/GPanalysis/analyses/Covid-vaccine-safety-MA")

###################### FUNCTIONS ##################################

rehydrate <- function(df){
  
  output <- data.frame()
  
  for(row in 1:nrow(df)){
    
    #row <-1
    
    period_of_event <- df[row, 'period']
    
    N <- df[row, 'N']
    
    if(period_of_event == 'Reference'){event_col <- c(1,0,0)} else 
      if (period_of_event == 'Pre-risk'){event_col <- c(0,1,0)}else 
      if (period_of_event == 'Risk'){event_col <- c(0,0,1)}
    
    template <- data.frame( period = c('Reference', 'Pre-risk', 'Risk'),
                            interval = c(90, 14, 28),
                            event = event_col,
                            vaccine_type = rep(df[row, 'vaccine_type'], 3))
    
    block <- bind_rows(replicate(N, template, simplify = FALSE))
    
    output <- bind_rows(output, block)
  }
  return(output)
}


######################## LOAD DATA ############################

dataset = 'hosp_only'

if (dataset == 'old'){
# Old date with ~April 14th 2021 end date
# Values here are taken from data/pooled_analyses/sccs.analysis.html
wales <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                      vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                      N =c(6,0,1,1,1,1))

# Values here are taken from data/pooled_analyses/RCGP_CVST_SCCS_eventcounts.xlsx
eng <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                     vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                     N =c(3,1,9,4,0,0))


scot <- readRDS('./data/pooled_analyses/scot_sccs_data_cvst.rds') %>%
  dplyr::rename(period = expgr, vaccine_type = Vacc.Type) %>%
  select(period, interval, event, vaccine_type) %>%
  mutate(period = gsub("Pre.Vacc","Reference", period)) %>%
  mutate(period = gsub("Clearance","Pre-risk", period))

} else if (dataset == 'new'){
  
  scot <- readRDS('./data/pooled_analyses/scot_sccs_data_cvst_both.rds') %>%
    dplyr::rename(period = expgr, vaccine_type = Vacc.Type) %>%
    select(period, interval, event, vaccine_type) %>%
    mutate(period = gsub("Pre.Vacc","Reference", period)) %>%
    mutate(period = gsub("Clearance","Pre-risk", period))

# Values here are taken from data/pooled_analyses/CVST_requirements_England.docx  
  eng <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                     vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                     N =c(13,5,9,14,3,1))
  
# Values here are taken from data/pooled_analyses/wales_updated_2/sccs.analysisV2.html  
  wales <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                       vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                       N =c(12,2,4,3,1,1))
  
  
  
} else if (dataset == 'exclude_deaths'){
  
  scot <- readRDS('./data/pooled_analyses/scot_sccs_data_cvst_both_exclude_deaths.rds') %>%
    dplyr::rename(period = expgr, vaccine_type = Vacc.Type) %>%
    select(period, interval, event, vaccine_type) %>%
    mutate(period = gsub("Pre.Vacc","Reference", period)) %>%
    mutate(period = gsub("Clearance","Pre-risk", period))

  
  # English data is the same - there are no deaths in the 90 days period following event
  eng <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                     vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                     N =c(13,5,9,14,3,1))
  
  # Welsh data is the same - there are no deaths in the 90 days period following event  
  wales <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                       vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                       N =c(12,2,4,3,1,1))
  
  
} else if (dataset == 'hosp_only'){
  
  scot <- readRDS('./data/pooled_analyses/scot_sccs_data_cvst_hosp.rds') %>%
    dplyr::rename(period = expgr, vaccine_type = Vacc.Type) %>%
    select(period, interval, event, vaccine_type) %>%
    mutate(period = gsub("Pre.Vacc","Reference", period)) %>%
    mutate(period = gsub("Clearance","Pre-risk", period))
  
  
  eng <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                     vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                     N =c(0,0,1,0,0,0))
  
  wales <- data.frame( 'period' = rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                       vaccine_type = c( rep('AZ', 3), rep('PB', 3)),
                       N =c(1,2,0,0,0,0))

}



wales <- rehydrate(wales)

eng <- rehydrate(eng)

df <- rbind(eng, scot)
df<- rbind(df, wales)

# Artificial IDs
df$ID <- ceiling(as.numeric(rownames(df))/3)

# Filter out people who didn't have an event in either Reference, Pre-risk or risk periods
# This isn't actually necessary - the package filters them out.
df <- group_by(df, ID) %>% filter( sum(event) == 1)

# We are counting incident events only. That is, the first time the person had the event.
# We are also estimating a conditional Poisson model, but using the fact that the
# likelihood function is identical to correponding logistic regression. Effectively the
# dependent variable is the count per day of new CVST events in the time period.
# The offset means it is a rate we are estimating, rather than a count
df <- mutate(df, ind = case_when( period == 'Risk' ~ 28,
                                  period == 'Reference' ~ 90,
                                  period == 'Pre-risk' ~ 14))



event_count <- group_by(df, vaccine_type, period) %>% filter(event == 1) %>% tally

event_count_n <- event_count$n[c(2,1,3, 5,4,6)]
  
########################## RESULTS ############################

# Ensure Reference is the baseline level 
df$period <- factor(df$period, levels = c("Reference", "Pre-risk", "Risk"))

sccs_AZ <- clogit(event ~ period+ strata(ID) + offset(log(interval)),data=df, subset=vaccine_type=="AZ")

sccs_PB <- clogit(event ~ period + strata(ID) + offset(log(interval)),data=df, subset=vaccine_type=="PB")



sccs_results <- data.frame( vaccine_type = rep( c('AZ', 'PB'), each = 3),
                            period= rep( c('Reference', 'Pre-risk', 'Risk'), 2),
                            IRR = c(1,  round(exp(sccs_AZ$coef), 2), 1, round(exp(sccs_PB$coef), 2)), 
                            `CI` = '', stringsAsFactors = FALSE, check.names = FALSE)

lower <- sprintf('%.2f', exp( c( confint(sccs_AZ)[,1], confint(sccs_PB)[,1] )))
upper <- sprintf('%.2f', exp( c( confint(sccs_AZ)[,2], confint(sccs_PB)[,2] )))

CI <- paste0('[', lower, '-', upper, ']'     )

sccs_results[c(2,3,5,6), 'CI'] <- CI

names(sccs_results)[4] <- '95% CI'

sccs_results <- left_join(sccs_results, event_count) %>%
                replace_na(list(n=0))

write.csv(sccs_results, paste0('./output/pooled_analysis/sccs_cvst_', dataset, '.csv'), row.names = FALSE)


#df <-  df[1:3, ]

#write_csv(df, '/conf/EAVE/GPanalysis/progs/SRK/ssc5a/ssc5a_expanded_data_example.csv')

