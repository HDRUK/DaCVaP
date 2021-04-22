##########################################################
# Name of file: 03a_CC_Control.R
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
#                         sets up a loop to run through
#                         run 02_CC.R to set up the cc study
#                         03_CC_Analysis.R to fit the models
#                         
# Approximate run time: Unknown
##########################################################

#remove all temporary structures
remove(list=ls(pa="^z"))
a_begin <- as.Date("2020-12-08") # beginning vaccination

endpoint_groups <- list()
endpoint_groups$any_throm_haem <- c("haem","dv_throm","pulm_emb","throm", "cereb_haem","pv_throm" ,
                                      "sub_arach_haem", "CVT","itp","SVT")
endpoint_groups$any_throm <- c("dv_throm","pulm_emb","throm", "pv_throm")
endpoint_groups$throm_cvst <- c("dv_throm","pulm_emb","throm", "pv_throm", "CVT","SVT")
endpoint_groups$any_haem <- c("haem","cereb_haem","sub_arach_haem", "th_haem" )
#endpoint_groups$all_haem <- c("haem","cereb_haem","sub_arach_haem", "haem_gigu")
endpoint_groups$CVT_SVT <- c("CVT","SVT")
endpoint_groups$any_itp <- c("itp", "itp_gen")


#endpoint_names <- c("any_throm_haem", "any_throm", "any_haem" , "cereb_haem" ,"CVT_SVT", "itp", 
#                      "haem","sub_arach_haem", "dv_throm","throm", "pv_throm", "pulm_emb" )
#endpoint_names <- c("any_throm", "any_haem" ,"itp_gen", "itp" )
endpoint_names <- c("throm_cvst", "any_throm", "any_haem", "any_itp", "itp_gen","itp")

for (i in endpoint_names) {
  #i <- endpoint_names[4]
  z_event_endpoint <- i
  # z_event_endpoint <- "CVT_SVT"
  print(z_event_endpoint)
  output_list <- list()
  output_list$endpoint <- z_event_endpoint
  output_list$match <- "Event Date"   #"Event Date" 
  
  
  source("01b_Rates.R")
  
  #source("02_CC.R")  #comment out and uncomment reading in df_cc in Analysis
  
  source("03a_CC_Analysis.R")
  
}