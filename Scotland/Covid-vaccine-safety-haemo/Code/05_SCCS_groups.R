#run 05_SCCS_Analysis.R to get z.df this has both uv and vacc in it
#z.df has all the events but htere are multiple events for some people
#also unvaccinated with events are in z.df
print(nrow(z.df))
print(length(unique(z.df$EAVE_LINKNO)))
print(table(table(z.df$EAVE_LINKNO)))

#deal with the vaccinated  first - they get time split by calendar period
#and risk group in relation to vaccination
z_period_length <- round(as.numeric(max(z.df$DV.rp2end,na.rm=T) - min(z.df$DV.rp0start,na.rm=T))/5,0)
print(z_period_length)
z <- z.df %>% 
  filter(Vacc.Type != "uv") %>% #only do this on the vaccinated
  dplyr::select(EAVE_LINKNO, DV.rp0start, DV.rp0end, DV.rp1start, DV.rp1end) %>%
  filter(!duplicated(EAVE_LINKNO)) %>% 
  mutate(event=1) %>% 
  mutate(p1_date=min(z.df$DV.rp0start, na.rm=T)+z_period_length,
         p2_date=p1_date+z_period_length,
         p3_date=p2_date+z_period_length,
         p4_date=p3_date+z_period_length)
#z <- z %>%   mutate(id=1:nrow(z))

z1 <- tmerge(z,z,id=EAVE_LINKNO, endpt = event(DV.rp1end, event), tstart=DV.rp0start, tstop=DV.rp1end)
z1 <- tmerge(z1,z, id=EAVE_LINKNO, day1=tdc(DV.rp0end))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, day2=tdc(DV.rp1start))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per1=tdc(p1_date))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per2=tdc(p2_date))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per3=tdc(p3_date))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per4=tdc(p4_date))

z1 <- z1 %>% mutate(expgr = day1+day2,
                    period = per1+per2+per3+per4)

#z2 <- z1 %>% dplyr::select(EAVE_LINKNO, id, tstart, tstop, expgr, period)

z2_e <- dplyr::select(z.df, EAVE_LINKNO, StartDate) %>% 
  filter(EAVE_LINKNO %in% unique(z1$EAVE_LINKNO)) %>% 
  arrange(EAVE_LINKNO, StartDate) %>% mutate(event=1) %>% 
  filter(!duplicated(paste(EAVE_LINKNO, StartDate)))

z3 <- tmerge(z1,z2_e, id=EAVE_LINKNO, endpt1 = event(StartDate, event))
print(nrow(z2_e))
print(sum(z3$endpt1))

if (output_list$censor_deaths){
  z1 <- unique(z3$EAVE_LINKNO)
  z2 <- z1[z1 %in% all_deaths$EAVE_LINKNO]
  if (length(z2) >0){ #merge in all deaths and censor the periods
    z2 <- filter(all_deaths, EAVE_LINKNO %in% z2) %>% mutate(dth=1)
    z3 <- tmerge(z3, z2, id=EAVE_LINKNO, dth =tdc(NRS.Date.Death) )
    z3 <- filter(z3, dth ==0)
  }  # end if any deaths
} # end if censor deaths 


#this pick up all events in study period - ones that are dropped are on first day
#or occurr after the end of the risk period
#z <- z3 %>% group_by(EAVE_LINKNO) %>% dplyr::summarise(N=sum(endpt1))
#zz <- z2_e %>% group_by(EAVE_LINKNO) %>% dplyr::summarise(N=n())
#zzz <- z %>% left_join(zz, by="EAVE_LINKNO") %>% 
#  filter(N.x != N.y)
#filter(z2_e, EAVE_LINKNO %in% zzz$EAVE_LINKNO)
z3 <- z3 %>% dplyr::select(EAVE_LINKNO, tstart, tstop, endpt1, expgr, period)

z3_vacc <- z3
#z3_vacc has the data for the vaccinated 


#now do the unvaccinated
z <- z.df %>% 
  filter(Vacc.Type == "uv") %>% #only do this on the vaccinated
  dplyr::select(EAVE_LINKNO) %>%
  filter(!duplicated(EAVE_LINKNO)) %>% 
  mutate(event=1) %>% 
  mutate(p1_date=min(z.df$DV.rp0start, na.rm=T)+z_period_length,
         p2_date=p1_date+z_period_length,
         p3_date=p2_date+z_period_length,
         p4_date=p3_date+z_period_length,
         DV.rp0start=min(z.df$DV.rp0start, na.rm=T),
         DV.rp1end=a_end)

z1 <- tmerge(z,z,id=EAVE_LINKNO, endpt = event(DV.rp1end, event), tstart=DV.rp0start, tstop=DV.rp1end)
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per1=tdc(p1_date))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per2=tdc(p2_date))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per3=tdc(p3_date))
z1 <- tmerge(z1,z, id=EAVE_LINKNO, per4=tdc(p4_date))

z1 <- z1 %>% mutate(expgr = 0,
                    period = per1+per2+per3+per4)

z2_e <- dplyr::select(z.df, EAVE_LINKNO, StartDate) %>% 
  filter(EAVE_LINKNO %in% unique(z1$EAVE_LINKNO)) %>% 
  arrange(EAVE_LINKNO, StartDate) %>% mutate(event=1) %>% 
  filter(!duplicated(paste(EAVE_LINKNO, StartDate)))


z3 <- tmerge(z1,z2_e, id=EAVE_LINKNO, endpt1 =event(StartDate, event))
print(nrow(z2_e))
print(sum(z3$endpt1))

if (output_list$censor_deaths){
  z1 <- unique(z3$EAVE_LINKNO)
  z2 <- z1[z1 %in% all_deaths$EAVE_LINKNO]
  if (length(z2) >0){ #merge in all deaths and censor the periods
    z2 <- filter(all_deaths, EAVE_LINKNO %in% z2) %>% mutate(dth=1)
    z3 <- tmerge(z3, z2, id=EAVE_LINKNO, dth =tdc(NRS.Date.Death) )
    z3 <- filter(z3, dth ==0)
  }  # end if any deaths
} # end if censor deaths 


z3 <- z3 %>% dplyr::select(EAVE_LINKNO, tstart, tstop, endpt1, expgr, period)


z3_unvacc <- z3
#z3_unvacc has data for unvacc


df_sccs <- bind_rows(z3_vacc, z3_unvacc)
print(sum(df_sccs$endpt1))
z4 <- z.df %>% filter(!duplicated(EAVE_LINKNO)) %>% dplyr::select(EAVE_LINKNO, Vacc.Type)

df_sccs <- df_sccs %>% left_join(z4, by="EAVE_LINKNO")
df_sccs <- df_sccs %>% mutate(VT = if_else(expgr==0, "uv", Vacc.Type)) %>% 
  mutate(expgr = factor(expgr, levels=0:2, labels=c("Pre.Vacc","Clearance","Risk"))) %>% 
  mutate(period2=ifelse(period>=1,period-1,period)) %>% 
  mutate(period2=factor(period2, levels=0:3)) %>% 
  mutate(period=factor(period, levels=0:4)) %>% 
  dplyr::rename(event=endpt1) %>% 
  mutate(interval=as.numeric(tstop-tstart))         

df_sccs <- df_sccs %>% mutate(VT_expgr = as.character(expgr)) %>% 
  mutate(VT_expgr = case_when(expgr != "Pre.Vacc" ~ paste(VT,expgr,sep="_"),
                              TRUE ~ VT_expgr)) %>% 
  mutate(VT_expgr = factor(VT_expgr, levels=c("Pre.Vacc","PB_Clearance","PB_Risk",
                                              "AZ_Clearance","AZ_Risk")))
  


###############################################


z.agg <- df_sccs %>% group_by(expgr, VT_expgr) %>% 
  dplyr::summarise(event=sum(event), interval=sum(interval))
z.agg$rate_week<- z.agg$event/z.agg$interval*7
names(z.agg)[names(z.agg)=="expgr"] <- "exposure"

z.aggp <- df_sccs %>% group_by(VT, period, expgr) %>% 
  dplyr::summarise(event=sum(event), interval=sum(interval))
z.aggp$rate_week<- z.aggp$event/z.aggp$interval*7

#event rates among those never vaccinated
z.agg_uv <- df_sccs %>% filter(Vacc.Type=="uv") %>% group_by(period) %>% 
  dplyr::summarise(event=sum(event), interval=sum(interval))
z.agg_uv$rate_week<- z.agg_uv$event/z.agg_uv$interval*7

z.mod <- clogit(event ~ expgr + strata(EAVE_LINKNO) + offset(log(interval)), data=df_sccs, 
                subset=VT %in% c("uv","AZ") )
summary(z.mod)

z.mod <- clogit(event ~ expgr + strata(EAVE_LINKNO) + offset(log(interval)), data=df_sccs, 
                subset=VT %in% c("uv","PB") )
summary(z.mod)

z.mod <- clogit(event ~ period + strata(EAVE_LINKNO) + offset(log(interval)), data=df_sccs, 
                subset=Vacc.Type %in% c("uv") )
summary(z.mod)

z.mod <- clogit(event ~ VT_expgr + period + strata(EAVE_LINKNO) + offset(log(interval)), data=df_sccs )
summary(z.mod)
z.mod1 <- clogit(event ~ VT_expgr + strata(EAVE_LINKNO) + offset(log(interval)), data=df_sccs )
anova(z.mod, z.mod1)
summary(z.mod1)

z.mod <- clogit(event ~ expgr +period2*Vacc.Type +strata(id) + offset(log(interval)),data=z3)
summary(z.mod)
