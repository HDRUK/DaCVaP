#z.df comes out of 05_SCCS.R


z <- z.df %>% group_by(StartDate) %>% dplyr::summarise(N=n())
z %>% ggplot(aes(x=StartDate,y=N))+ geom_col()+
  labs(x="Consultation Date", y="Number", title="Consultations in Study Period",
       subtitle = "All Cases")


z <- z.df %>% mutate(days=as.numeric(StartDate-Vacc.Date)) %>% group_by(days) %>% dplyr::summarise(N=n())
z %>% ggplot(aes(x=days,y=N))+ geom_col() +
  labs(x="Days after or before Vaccination", y="Number", title="Consultation Date relative to vaccination Date",
       subtitle = "Vaccinated Cases Only")


z <- z.df %>%  filter(!duplicated(EAVE_LINKNO)) %>% group_by(Age) %>% dplyr::summarise(N=n())
z %>% ggplot(aes(x=Age,y=N))+ geom_col()

z <- z.df %>%  filter(!duplicated(EAVE_LINKNO)) %>% group_by(Vacc.Date, Vacc.Type) %>% dplyr::summarise(N=n())
z %>% ggplot(aes(x=Vacc.Date,y=N, fill=Vacc.Type))+ geom_col()+
  labs(x="Date of Vaccination", y="Number", title="Cases Vaccinated", fill="Vaccine")


#this has to be done just as soon as z_event is created in 05:SCCS_Analysis.R
z <- z_event %>% filter(StartDate >= as.Date("2019-09-01"))%>% group_by(StartDate) %>%
  dplyr::summarise(N=n()) 

z_nd <- data.frame(StartDate = seq.Date(as.Date("2019-09-01"),a_end, by="days")) %>% 
  mutate(days = as.numeric(StartDate-min(StartDate)),
         months = months(StartDate)) %>% 
  left_join(z, by="StartDate") %>% 
  mutate(N=if_else(is.na(N), 0L, N)) %>% 
  mutate(post_PB_vacc = ifelse(StartDate >= as.Date("2020-12-08"), 1,0),
         post_AZ_vacc = ifelse(StartDate >= as.Date("2021-01-05"), 1,0))

z_nd %>% ggplot(aes(x=StartDate,y=N))+ geom_col()

z_m <- mgcv::gam(N ~ s(days) + months, data=z_nd, family=poisson)
anova(z_m) # no seasonal pattern with month
z_m <- mgcv::gam(N ~ s(days) , data=z_nd, family=poisson)
z_m <- mgcv::gam(N ~ s(days) + post_PB_vacc + post_AZ_vacc , data=z_nd, family=poisson)
z_m <- mgcv::gam(N ~ days + months + post_PB_vacc + post_AZ_vacc , data=z_nd, family=poisson)
summary(z_m)
plot(z_m)

z_p <- predict(z_m, type="response", se.fit=T, newdata=z_nd)

z_nd <- z_nd %>% mutate(fit = z_p$fit, lcl = fit - 1.96*z_p$se.fit, ucl = fit + 1.96*z_p$se.fit)

z_nd %>% ggplot(aes(x=StartDate,y=N))+ geom_point(stroke=0.3, alpha=0.3) +
  geom_line(aes(y=fit), size=1.2) + geom_line(aes(y=lcl))+geom_line(aes(y=ucl)) +
  labs(x="Date of Consultation",y="Number of Consultations",
#       title="Idiopathic thrombocytopenic purpura", subtitle = "Adults aged 16 or over")
   title="Thrombocytopenia", subtitle = "Adults aged 16 or over")


