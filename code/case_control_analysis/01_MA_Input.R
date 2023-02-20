######################################################################
## Title: Meta-analysis of first dose ChAdOx1 and BNT162b2 COVID-19 vaccinations and thrombocytopenic, venous thromboembolic
##        and haemorrhagic events in the UK
##
## Short title: Vaccine safety meta-analysis
##
## Code author: Chris Robertson, Steven Kerr
##
## Description: This prepares the data for the case-control meta-analysis
######################################################################

library(readxl)
library(tidyverse)

# Set working directory on PHS for SRK
setwd('/conf/EAVE/GPanalysis/progs/SRK/Covid-vaccine-safety-MA')

############################ FUNCTIONS ###############################

# This calculates odds ratios for 0-27 days for the English data taking a weighted average
fun_calc_0_27 <- function(df){
  df <- df %>% mutate(rlrr = R*log_rr, rvlrr = R*(se_log_rr^2) ) %>% 
    dplyr::summarise_at(vars("N","R","rlrr","rvlrr"), ~sum(.) )
  df <- df %>% mutate(log_rr=rlrr/R, se_log_rr = sqrt(rvlrr/R), 
                      log_lcl = log_rr - 1.96*se_log_rr, log_ucl = log_rr + 1.96*se_log_rr ) %>% 
    mutate(RR= exp(log_rr), LCL = exp(log_lcl), UCL = exp(log_ucl)  ) %>% 
    dplyr::select(N, R, RR, LCL, UCL, log_rr, log_lcl, log_ucl, se_log_rr)
  df
}

# Convert cols to numeric type
convert_to_numeric <- function(df, cols){
  for (col in cols){
    df[ ,col] <- as.numeric(pull(df,col))
  }
  return(df)
}

# This reads in English data, taking weighted average of RRs for day 0-27
# file is the name of the file in data folder
read_eng_avg <- function(file){
  group_names <- c("throm_cvst","any_throm","any_haem","any_itp","itp_gen","itp", )
  
  for (i in 1:6) { 
    i <- 1
    z_in <- read_xlsx( paste0("./data/", file) , sheet=i)
    
    cols <- names(z_in)[4:length(z_in)]
    z_in <- convert_to_numeric(z_in, cols)
    
    names(z_in) <- c(names(z_in)[1:5],"RR","LCL","UCL", "log_rr","se_log_rr")
    df <- filter(z_in, Status %in% paste0("AstraZeneca_v1_", c("0:6","7:13","14:20","21:27")))
    
    df <- fun_calc_0_27(df)
    df_az <- bind_cols(data.frame(Endpoint=unique(z_in$Endpoint), Country="England (RGCP)", Status = "AstraZeneca_v1_0:27"), df)
    df <- filter(z_in, Status %in% paste0("Pfizer_v1_", c("0:6","7:13","14:20","21:27")))
    
    # cols <- names(df)[4:length(df)]
    # df <- convert_to_numeric(df, cols)
    
    df <- fun_calc_0_27(df)
    df_pb <- bind_cols(data.frame(Endpoint=unique(z_in$Endpoint), Country="England (RGCP)", Status = "Pfizer_v1_0:27"), df)
    z_in <- bind_rows(z_in, df_az, df_pb)
    z_in$group <- group_names[i]
    if (exists("z")) z <- bind_rows(z, z_in) else z <- z_in
  }
  return(z)
}

# This reads in English data, with no weighting as in read_eng_avg
# file is the name of the file in data folder
read_eng <- function(file){

  sheets <- c( "Arterial_thromb" = 1, "any_haem" = 2, "itp" = 3, "itp_gen" = 4, "throm_cvst" = 5)
  
  output <- data.frame()
  
  for (i in sheets) { 
    #i <- 1
    new_block <- read_xlsx( paste0("./data/", file) , sheet=i)
    new_block$group <- names(sheets[i])
    
    new_block <- convert_to_numeric(new_block, names(new_block)[4:10])
    
    output <- bind_rows(output, new_block)
  }
  
  return(output)
}

##################### IMPORT DATA ##################################

study <- 'case_control_FE'

if(grepl('sensitivity', study, fixed = TRUE) ){
  scot <- read.csv("./data/scotland_ma_results_Feb21_sensitivity.csv")
  
  eng <- read_eng('RCGP-SENSITIVITY-Feb-21-SAFETY.xlsx')
  
  wales <- read_csv("./data/t_n_coef_all_long_sensitivity.csv")
} else {
  scot <- read.csv("./data/scotland_ma_results_combined.csv") 
  
  eng <- read_eng('RCGP-UPDATED-DACVAP-SAFETY.xlsx')
  
  wales <- read_csv("./data/t_n_coef_all_long.csv")
}

####################### PREPARE DATA ###################################

scot <- scot %>% mutate(log_rr = log(RR), log_lcl = log(LCL), log_ucl = log(UCL)) %>% 
                 mutate(se_log_rr = (log_ucl - log_lcl)/3.92)


eng <- dplyr::rename(eng, c(RR = OR, log_rr = `log(OR)`, se_log_rr = `SE log(OR)`, country = Country))

eng <- eng %>% dplyr::relocate(group, .after=Endpoint) %>% dplyr::relocate(se_log_rr, .after=last_col())

eng <- eng %>% mutate(Status = gsub("AstraZeneca", "AZ",Status)) %>%
  mutate(Status = gsub("Pfizer", "PB",Status))

eng$country <- 'England - RCGP'



wales <- wales %>% filter(model_type %in% c("fully_adjusted", "reference")) %>% dplyr::select(-p_event, -statistic, -p.value, -model_type)
names(wales) <- c("Endpoint", "Status","N","R","log_rr","se_log_rr","RR","LCL","UCL")

wales<- mutate(wales, Endpoint = gsub("Atrial Thrombosis", "Arterial Thrombosis", Endpoint) )
wales <- wales %>% mutate( group = c( rep("any",13), rep("Arterial_thromb", 13), rep("throm_cvst", 13), rep("any_haem",13), 
                            rep("any_itp", 13), rep("any_throm", 13), rep("itp",13),  rep("itp_gen",13)  ))
wales <- wales %>% dplyr::select(Endpoint, group, Status, N, R, RR:UCL, log_rr, se_log_rr) 
wales <- wales %>% mutate(Status = gsub("UV","uv",Status)) %>%
                   mutate(Status = gsub(" Dose 1 Day ","_v1_",Status)) %>%
                   mutate(Status = gsub("00-06","0:6",Status)) %>%
                   mutate(Status = gsub("07-13","7:13",Status)) %>%
                   mutate(Status = gsub("14-20","14:20",Status)) %>%
                   mutate(Status = gsub("21-27","21:27",Status)) %>%
                   mutate(Status = gsub("00-28","0:27",Status))
wales <- wales %>%  mutate(country = "Wales") %>% 
  dplyr::relocate(country, .after=group)

######################## COMBINE DATA ################################
df <- bind_rows(eng, dplyr::select(scot, -log_lcl, -log_ucl) ,wales)
df <- df %>% mutate(Status = factor(Status, levels =
      c("uv", "AZ_v1_0:6","AZ_v1_7:13","AZ_v1_14:20", "AZ_v1_21:27", "AZ_v1_28+" ,"AZ_v1_0:27", "AZ_v2",
      "PB_v1_0:6", "PB_v1_7:13",   "PB_v1_14:20", "PB_v1_21:27", "PB_v1_28+", "PB_v1_0:27","PB_v2"))) %>% 
  arrange(Endpoint, country, Status)

df <- df %>% mutate(vaccine = case_when(grepl("AZ", Status) ~ "AZ",
                                        grepl("PB", Status) ~ "PB",
                                        TRUE ~ "uv")) %>% 
  mutate(time = as.character(Status)) %>% 
  mutate(time = gsub("AZ_","",time)) %>% 
  mutate(time=gsub("PB_", "", time)) %>% 
  mutate(time=factor(time, levels =c("uv","v1_0:6","v1_7:13","v1_14:20","v1_21:27","v1_0:27","v1_28+" ,  "v2")))

df$percent <- round (df$R * 100 / df$N, 1)

df <- mutate(df, percent = case_when( N < 5 & N > 0 & R!= 0 ~ '',
                                      R < 5 & R > 0 ~ paste0('(<', sprintf('%.1f',5*100/N), '%)' ),
                                      TRUE ~  paste0('(', sprintf('%.1f',R*100/N), '%)')) )


# Create a csv that has event rates per million by country
event_count <- filter(df, Status %in% c("uv", "AZ_v1_28+", "AZ_v1_0:27", "PB_v1_28+", "PB_v1_0:27") 
                      & group %in% names(endpoints)) %>%
               group_by(country, group) %>% summarise(R = sum(R) ) %>% 
              pivot_wider(id_cols = group, names_from = country, values_from = R)
  

names(event_count) <- c('Event', 'England', 'Scotland', 'Wales')

event_count <- event_count %>% mutate(Total = select(., England:Wales) %>% rowSums(na.rm = TRUE),
                                      Event = endpoints[event_count$Event])

event_count <- mutate(event_count, England = England/1.912442 ,
                                   Scotland = Scotland/1.653974 ,
                                   Wales = Wales/0.635228 , 
                                  Total = Total/4.201643 ) %>%
              mutate_if(is.numeric, ~formatC(round(.), format = "f", big.mark = ",", drop0trailing = TRUE))
                         

write_csv(event_count, './output/event_count.csv')

