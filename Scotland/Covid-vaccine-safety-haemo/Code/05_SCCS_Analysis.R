##########################################################
# Name of file: 05_SCCS_Analysis.R
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
#                         this script gets the data and fits the models
# Approximate run time: Unknown
##########################################################

#remove all temporary structures
remove(list=ls(pa="^z"))

#endpoint_groups and endpoint_names set in 03a_CC_Control.R

for (i in endpoint_names) {

z_event_endpoint <- i
# z_event_endpoint <- "CVT_SVT"
print(z_event_endpoint)
  
output_list <- list()
a_begin <- as.Date("2020-12-08") # beginning vaccination
#z_event_endpoint <- "itp" # set in 03a_CC_Control.R
output_list$endpoint <- z_event_endpoint
print(z_event_endpoint)
output_list$fixed_period <- FALSE
output_list$include_uv <- FALSE
output_list$censor_deaths <- FALSE

if (z_event_endpoint %in% names(endpoint_groups)) {
  #combination of groups
  z_values <- as.character(unlist(endpoint_groups[z_event_endpoint]))
  z_event <- filter(GP_Consultations, Quick_groups %in% z_values)
}  else {
  #single group
  z_event <- filter(GP_Consultations, Quick_groups == z_event_endpoint)
} 
#number of days before start of vaccination to begin counting cases
z.rp0.begin <- 104 #AE.Hosp.df[z.ae.index,"Pre.Risk.Period.Start"] 90+14=104  42+14=56

#get the events in the study period
#note Age here is age at event from the GP record
z_event_sp <- z_event %>% filter(StartDate >= a_begin-z.rp0.begin) %>% 
  filter(StartDate <= max(GP_Consultations$StartDate) - 7) %>%  #drop of reports in the last week as incomplete and may be biased towards vaccination
  filter(Age>= 16) 
output_list$total_events <- nrow(z_event_sp)

z <- z_event_sp %>% group_by(StartDate) %>% 
  dplyr::summarise(N=n())
z %>% ggplot(aes(x=StartDate,y=N))+ geom_col()


#get all events for those with an event in study period
#don't need this as we are already going back 104 days for the period estimation in z_event_sp
#z_event <- z_event %>% filter(EAVE_LINKNO %in% unique(z_event_sp$EAVE_LINKNO)) %>% 
#  arrange(EAVE_LINKNO, StartDate) %>% 
#  filter(!duplicated(paste(EAVE_LINKNO,StartDate))) %>% 
#  filter(StartDate <= max(GP_Consultations$StartDate) - 7)  #drop of reports in the last week as incomplete and may be biased towards vaccination

z_event <- z_event_sp

a_end <- max(z_event$StartDate)
z.ae <- z_event_endpoint #as.character(AE.Hosp.df[z.ae.index,"Reason"])
z.rp0.end <- 14 # AE.Hosp.df[z.ae.index,"Pre.Risk.Period.End"]
z.rp1.begin <- 0 # AE.Hosp.df[z.ae.index,"Risk.Period.Start"]
z.rp1.end <- 28 # AE.Hosp.df[z.ae.index,"Risk.Period.End"]
z.rp2.begin <- 29 # AE.Hosp.df[z.ae.index,"Post.Risk.Period.Start"]
z.rp2.end <-  119 # AE.Hosp.df[z.ae.index,"Post.Risk.Period.End"]


#merge all records 
z.df <- z_event %>% dplyr::select(EAVE_LINKNO, Age, Sex, StartDate) %>% 
  left_join(dplyr::select(Vaccinations, EAVE_LINKNO, vacc_type, date_vacc_1), by="EAVE_LINKNO") %>% 
#  filter(!is.na(vacc_type)) %>% 
  dplyr::rename(Vacc.Date = date_vacc_1, Vacc.Type=vacc_type) %>% 
  mutate(Vacc.Type = if_else(is.na(Vacc.Date),"uv",Vacc.Type))

if (!output_list$include_uv) { #remove the unvaccinated
  z.df <- filter(z.df, Vacc.Type!= "uv")
}

if (!output_list$fixed_period) {
#code for a traditional SCCS with vaccinated observed from 
#a period before vacc to a period after
#unvaccinated observed for the whole period
#remove records outside the risk periods - Vacc.Date in relation to Admission_date
z.df$DV.rp0start <- z.df$Vacc.Date - z.rp0.begin
z.df$DV.rp0end <- z.df$Vacc.Date - z.rp0.end
z.df$DV.rp1start <- z.df$Vacc.Date + z.rp1.begin
z.df$DV.rp1end <- z.df$Vacc.Date + z.rp1.end
z.df$DV.rp2start <- z.df$Vacc.Date + z.rp2.begin
z.df$DV.rp2end <- z.df$Vacc.Date + z.rp2.end
z.df <- filter (z.df,((StartDate >= DV.rp0start) & (StartDate <=  DV.rp2end))|is.na(Vacc.Date) )
z.df <- filter (z.df,(Vacc.Date < a_end) | is.na(Vacc.Date))
z.df <- z.df %>% mutate(DV.rp1end = if_else(DV.rp1end > a_end, a_end, DV.rp1end),
               DV.rp2start = if_else(DV.rp2start > a_end, a_end, DV.rp2start),
               DV.rp2end = if_else(DV.rp2end > a_end, a_end, DV.rp2end))
}

if (output_list$fixed_period) { 
#code for a static observation period 
z.df$DV.rp0start <- a_begin - z.rp0.begin
z.df$DV.rp0end <- z.df$Vacc.Date - z.rp0.end
z.df$DV.rp1start <- z.df$Vacc.Date + z.rp1.begin
z.df$DV.rp1end <- z.df$Vacc.Date + z.rp1.end
z.df$DV.rp2start <- z.df$Vacc.Date + z.rp2.begin
z.df$DV.rp2end <- z.df$Vacc.Date + z.rp2.end
z.df <- z.df %>% mutate(DV.rp1start = if_else(DV.rp1start > a_end, a_end, DV.rp1start),
                         DV.rp1end = if_else(DV.rp1end > a_end, a_end, DV.rp1end),
                        DV.rp2start = if_else(DV.rp2start > a_end, a_end, DV.rp2start),
                        DV.rp2end = if_else(DV.rp2end > a_end, a_end, DV.rp2end))
z.df$DV.rp2end <- a_end
}



if (!output_list$include_uv & !output_list$fixed_period) { #no unvaccinated and standard SCCS
#new identifier for repeats
z.df$ind <- 1:nrow(z.df)

z.names <- names(z.df)[grepl("DV",names(z.df))]
z.names <- z.names[1:4]
expo <- as.matrix(z.df[,z.names])
#expolev <- c(0,1,0,2,3,3)  #specify this as there is a gap of 1 day after
#ncuts <- 6
expolev <- c(0,1,2,3)  #specify this as there is a gap of 1 day after
ncuts <- 4
ind <- rep(z.df$ind, times=ncuts)
cutp <- as.Date(c(expo), format="%Y-%m-%d")
o <- order(ind,cutp) #reorder to get the dates increase within a patient
ind <- as.factor(ind[o])
cutp <- cutp[o]
interval <- c(0,cutp[2:length(ind)] - cutp[1:(length(ind)-1)])
z.sel <- c(TRUE,ind[2:length(ind)] != ind[1:(length(ind)-1)])
interval[z.sel] <- 0 #rest interval to zero when there is a change of patient

event <- ifelse(z.df$StartDate[ind] > cutp-interval,1,0)  #1 for event happening before period
event <- ifelse(z.df$StartDate[ind] <= cutp,event,0) # correcting all the early 1s

#get exposure groups
expgr <- rep(0,length(ind))
for (i in 1:ncol(expo)){
  expgr <- ifelse(cutp >= expo[,i][ind],expolev[i],expgr)
}

DF <- cbind.data.frame(ind,interval,cutp,event,expgr)
DF <- subset(DF,interval > 0)
#DF <- subset(DF,expgr > 0) #omit exposure intervals not considered - week before vaccination , for example

DF <- merge(DF,z.df[,c("ind","EAVE_LINKNO","Vacc.Type")], by="ind",all.x=T)
#DF$Vacc <- ifelse(DF$Vacc.Type=="UnVacc",0,1)
#DF$expgr <- factor(DF$expgr,labels=c("Pre.Vacc","Risk","Post.Risk"))
DF$expgr <- factor(DF$expgr,labels=c("Pre.Vacc","Clearance","Risk"))
DF$expgr.vacc <- DF$expgr
#DF$expgr.vacc[DF$Vacc==0] <- "Pre.Vacc"
#DF$expgr.risk  <- DF$expgr
#DF$expgr.risk[DF$expgr.risk=="Post.Risk"] <- "Pre.Vacc"
#DF$expgr.risk <- factor(DF$expgr.risk)

rm(cutp, expgr, expo, expolev, ind, interval, o, ncuts, event)
}


###########################################################################
#model fitting and summary for the SCCS with no unvaccinated
z.agg <- DF %>% group_by(Vacc.Type, expgr) %>% 
  dplyr::summarise(event=sum(event), interval=sum(interval))
z.agg$rate_week<- z.agg$event/z.agg$interval*7
names(z.agg)[names(z.agg)=="expgr"] <- "exposure"
z.agg
#z.mod <- clogit(event ~ expgr + expgr*Vacc.Type + strata(ind) + offset(log(interval)),data=DF)
#summary(z.mod)
#z.out <- cbind(z$conf.int,P=z$coefficients[,"Pr(>|z|)"],Wald=c(z$waldtest["pvalue"],NA),model=rep(1,nrow(z$conf.int)))
z.mod <- clogit(event ~ expgr + strata(ind) + offset(log(interval)),data=DF, subset=Vacc.Type=="AZ")
z_az <- summary(z.mod)$conf.int
z_az <- rbind(z_az[1,],z_az)
z_az[1,] <- c(1,NA,NA,NA)
z.mod <- clogit(event ~ expgr + strata(ind) + offset(log(interval)),data=DF, subset=Vacc.Type=="PB")
summary(z.mod)
z_pb <- summary(z.mod)$conf.int
z_pb <- rbind(z_pb[1,],z_pb)
z_pb[1,] <- c(1,NA,NA,NA)
z <- rbind(z_az,z_pb)
z <- z[,c(1,3,4)]
dimnames(z) <- list(1:nrow(z), c("Est","LCL", "UCL"))

z <- cbind(as.data.frame(z.agg),z)
z$outcome <- rep(z_event_endpoint, nrow(z))

z_out <- if (exists("z_out")) rbind(z_out,z) else z

}
