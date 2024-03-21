
# Load data ====================================================================

c1 <- qread("results/c1.qs")
ms_vacc_a <- qread(s_drive("d_ms_vacc_a.qs"))

tmat <- transMat(x = list(c(2,3,6),c(1,3,4,6), c(2,4,6), c(2,5,6), c(6), c()),
                 names = c("unvacc","infection","dose_1", "dose_2", "dose_3", "death"
                 ))

# ------------------------------------------------------------------------------
# prediction 
# ------------------------------------------------------------------------------
cat("Generating cumulative hazard curves\n")

newd <- data.frame(sex = rep(0,14), age_cat = rep(0,14), hh_vaccinated = rep(0,14), household_n = rep(0,14),  trans = 1:14)
newd$age_cat <- factor(newd$age_cat, levels = 0:2, labels = c("16_17","12_15", "05_11"))
newd$hh_vaccinated <- factor(newd$hh_vaccinated, levels = 0:2, labels = c("pv", "uv", "fv"))
newd$household_n <- factor(newd$household_n, levels = 0:3, labels = c("3", "2", "4", "5+"))
newd$sex <- factor(newd$sex, levels = 0:1, labels = c("Female", "Male"))
attr(newd, "trans") <- tmat
class(newd) <- c("msdata", "data.frame")
newd <- expand.covs(newd, covs = c("sex", "age_cat", "hh_vaccinated", "household_n"))
newd$strata = 1:14
msf1 <- msfit(c1, newdata = newd, trans = tmat)

summary(msf1)
# ==============================================================================
# display cumulative hazard curves

par(mfrow = c(1,1))
pta <-probtrans(msf1, predt = 0)
plot(pta, ord = c(3,4,5,6,1,2) , lwd = 2, cex = 0.75)
#plot(pta, ord = c(1,2,3,4,5) , lwd = 2, cex = 0.75)


# ==============================================================================
# display survival plots for vaccines
cat("Generating survival curves\n")

surv<- exp(-msf1$Haz$Haz)
plot(msf1$Haz$time[msf1$Haz$trans==2],surv[msf1$Haz$trans==2],
     type = "l", lty = 1, lwd = 2,  ylim = c(0,1), xlab = "Time since eligibility",
     ylab = "Survival???")
lines(msf1$Haz$time[msf1$Haz$trans==9],surv[msf1$Haz$trans==9],
      lwd = 2, lty = 2)
lines(msf1$Haz$time[msf1$Haz$trans==12],surv[msf1$Haz$trans==12],
      lwd = 2, lty = 3)
legend("bottomleft",
       c("unvaccinated --> 1st vaccine","1st vaccine --> 2nd vaccine","2nd vaccine --> 3rd vaccine"),
       lty = c(1:3))

# ==============================================================================
# cumulative plots for vaccines by sex
cat("Generating cumulative incidence curves by sex\n")

msf.f <- msf1
newd1 <- newd[,1:5]
newd2 <- newd1
newd2$sex <- 1
newd2$sex <- factor(newd2$sex, levels = 0:1, labels = c("Female","Male"))
attr(newd2, "trans") <- tmat
class(newd2) <- c("msdata", "data.frame")
newd2 <- expand.covs(newd2, covs = c("sex", "age_cat", "hh_vaccinated", "household_n"))
newd2$strata = 1:14
msf.m <- msfit(c1, newdata = newd2, trans = tmat)


summ.msf.f<- summary(msf.f)
summ.msf.m<- summary(msf.m)
survf2<- 1-(exp(-summ.msf.f[[2]]$Haz))
survm2<- 1-exp(-summ.msf.m[[2]]$Haz)
lowf2<- 1-exp(-summ.msf.f[[2]]$lower)
lowm2<- 1-exp(-summ.msf.m[[2]]$lower)
uppf2<- 1-exp(-summ.msf.f[[2]]$upper)
uppm2<- 1-exp(-summ.msf.m[[2]]$upper)
survf9<- 1-(exp(-summ.msf.f[[9]]$Haz))
survm9<- 1-exp(-summ.msf.m[[9]]$Haz)
lowf9<- 1-exp(-summ.msf.f[[9]]$lower)
lowm9<- 1-exp(-summ.msf.m[[9]]$lower)
uppf9<- 1-exp(-summ.msf.f[[9]]$upper)
uppm9<- 1-exp(-summ.msf.m[[9]]$upper)
survf12<- 1-(exp(-summ.msf.f[[12]]$Haz))
survm12<- 1-exp(-summ.msf.m[[12]]$Haz)
lowf12<- 1-exp(-summ.msf.f[[12]]$lower)
lowm12<- 1-exp(-summ.msf.m[[12]]$lower)
uppf12<- 1-exp(-summ.msf.f[[12]]$upper)
uppm12<- 1-exp(-summ.msf.m[[12]]$upper)

ch1 <- data.frame(time = summ.msf.f[[2]]$time, cov = "age", group = "Female", transition = "unvacc -> vacc1", 
                  surv = survf2, low = lowf2, upp = uppf2) %>%
  add_row(time = summ.msf.m[[2]]$time, cov = "age", group = "Male", transition = "unvacc -> vacc1", 
          surv = survm2, low = lowm2, upp = uppm2) %>%
  add_row(time = summ.msf.f[[9]]$time, cov = "age", group = "Female", transition = "vacc1 -> vacc2", 
          surv = survf9, low = lowf9, upp = uppf9) %>%
  add_row(time = summ.msf.m[[9]]$time, cov = "age", group = "Male", transition = "vacc1 -> vacc2", 
          surv = survm9, low = lowm9, upp = uppm9) %>%
  add_row(time = summ.msf.f[[12]]$time, cov = "age", group = "Female", transition = "vacc2 -> vacc3", 
          surv = survf12, low = lowf12, upp = uppf12) %>%
  add_row(time = summ.msf.m[[12]]$time, cov = "age", group = "Male", transition = "vacc2 -> vacc3", 
          surv = survm12, low = lowm12, upp = uppm12)

p_ch1 <- ggplot(ch1,(aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), size = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  ylim(0,1) +
  labs(linetype = "Transition", fill = "Sex", colour = "Sex", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)")


# ==============================================================================
# cumulative plots for vaccines by age
cat("Generating cumulative incidence curves for ages\n")

msf.16_17 <- msf1
newd1 <- newd[,1:5]
newd2 <- newd1
newd2$age_cat <- 1
newd2$age_cat <- factor(newd2$age_cat, levels = 0:2, labels = c("16_17","12_15", "05_11"))
attr(newd2, "trans") <- tmat
class(newd2) <- c("msdata", "data.frame")
newd2 <- expand.covs(newd2, covs = c("sex", "age_cat", "hh_vaccinated", "household_n"))
newd2$strata = 1:14
msf.12_15 <- msfit(c1, newdata = newd2, trans = tmat)

newd3 <- newd1
newd3$age_cat <- 2
newd3$age_cat <- factor(newd3$age_cat, levels = 0:2, labels = c("16_17","12_15", "05_11"))
attr(newd3, "trans") <- tmat
class(newd3) <- c("msdata", "data.frame")
newd3 <- expand.covs(newd3, covs = c("sex", "age_cat", "hh_vaccinated", "household_n"))
newd3$strata = 1:14
msf.05_11 <- msfit(c1, newdata = newd3, trans = tmat)


summ.msf.16_17<- summary(msf.16_17)
summ.msf.12_15<- summary(msf.12_15)
summ.msf.05_11<- summary(msf.05_11)
surv16_172<- 1-(exp(-summ.msf.16_17[[2]]$Haz))
surv12_152<- 1-exp(-summ.msf.12_15[[2]]$Haz)
surv05_112<- 1-exp(-summ.msf.05_11[[2]]$Haz)
low16_172<- 1-exp(-summ.msf.16_17[[2]]$lower)
low12_152<- 1-exp(-summ.msf.12_15[[2]]$lower)
low05_112<- 1-exp(-summ.msf.05_11[[2]]$lower)
upp16_172<- 1-exp(-summ.msf.16_17[[2]]$upper)
upp12_152<- 1-exp(-summ.msf.12_15[[2]]$upper)
upp05_112<- 1-exp(-summ.msf.05_11[[2]]$upper)
surv16_179<- 1-(exp(-summ.msf.16_17[[9]]$Haz))
surv12_159<- 1-exp(-summ.msf.12_15[[9]]$Haz)
surv05_119<- 1-exp(-summ.msf.05_11[[9]]$Haz)
low16_179<- 1-exp(-summ.msf.16_17[[9]]$lower)
low12_159<- 1-exp(-summ.msf.12_15[[9]]$lower)
low05_119<- 1-exp(-summ.msf.05_11[[9]]$lower)
upp16_179<- 1-exp(-summ.msf.16_17[[9]]$upper)
upp12_159<- 1-exp(-summ.msf.12_15[[9]]$upper)
upp05_119<- 1-exp(-summ.msf.05_11[[9]]$upper)
surv16_1712<- 1-(exp(-summ.msf.16_17[[12]]$Haz))
surv12_1512<- 1-exp(-summ.msf.12_15[[12]]$Haz)
surv05_1112<- 1-exp(-summ.msf.05_11[[12]]$Haz)
low16_1712<- 1-exp(-summ.msf.16_17[[12]]$lower)
low12_1512<- 1-exp(-summ.msf.12_15[[12]]$lower)
low05_1112<- 1-exp(-summ.msf.05_11[[12]]$lower)
upp16_1712<- 1-exp(-summ.msf.16_17[[12]]$upper)
upp12_1512<- 1-exp(-summ.msf.12_15[[12]]$upper)
upp05_1112<- 1-exp(-summ.msf.05_11[[12]]$upper)

ch2 <- data.frame(time = summ.msf.16_17[[2]]$time, cov = "age", group = "16-17", transition = "unvacc -> vacc1", 
                  surv = surv16_172, low = low16_172, upp = upp16_172) %>%
  add_row(time = summ.msf.12_15[[2]]$time, cov = "age", group = "12-15", transition = "unvacc -> vacc1", 
          surv = surv12_152, low = low12_152, upp = upp12_152) %>%
  add_row(time = summ.msf.05_11[[2]]$time, cov = "age", group = "05-11", transition = "unvacc -> vacc1", 
          surv = surv05_112, low = low05_112, upp = upp05_112) %>%
  add_row(time = summ.msf.16_17[[9]]$time, cov = "age", group = "16-17", transition = "vacc1 -> vacc2", 
          surv = surv16_179, low = low16_179, upp = upp16_179) %>%
  add_row(time = summ.msf.12_15[[9]]$time, cov = "age", group = "12-15", transition = "vacc1 -> vacc2", 
          surv = surv12_159, low = low12_159, upp = upp12_159) %>%
  add_row(time = summ.msf.05_11[[9]]$time, cov = "age", group = "05-11", transition = "vacc1 -> vacc2", 
          surv = surv05_119, low = low05_119, upp = upp05_119) %>%
  add_row(time = summ.msf.16_17[[12]]$time, cov = "age", group = "16-17", transition = "vacc2 -> vacc3", 
          surv = surv16_1712, low = low16_1712, upp = upp16_1712) %>%
  add_row(time = summ.msf.12_15[[12]]$time, cov = "age", group = "12-15", transition = "vacc2 -> vacc3", 
          surv = surv12_1512, low = low12_1512, upp = upp12_1512) %>%
  add_row(time = summ.msf.05_11[[12]]$time, cov = "age", group = "05-11", transition = "vacc2 -> vacc3", 
          surv = surv05_1112, low = low05_1112, upp = upp05_1112)

p_ch2 <- ggplot(ch2,(aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), size = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  ylim(0,1) +
  labs(linetype = "Transition", fill = "Age category", colour = "Age category", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)")


# ==============================================================================
# cumulative plots for vaccines by hh vaccine status
cat("Generating cumulative incidence curves for household vaccination status\n")

msf.pv <- msf1

newd1 <- newd[,1:5]
newd2 <- newd1
newd2$hh_vaccinated <- 1
newd2$hh_vaccinated <- factor(newd2$hh_vaccinated, levels = 0:2, labels = c("pv","uv", "fv"))
attr(newd2, "trans") <- tmat
class(newd2) <- c("msdata", "data.frame")
newd2 <- expand.covs(newd2, covs = c("sex", "age_cat", "hh_vaccinated", "household_n"))
newd2$strata = 1:14
msf.uv <- msfit(c1, newdata = newd2, trans = tmat)

newd3 <- newd1
newd3$hh_vaccinated <- 2
newd3$hh_vaccinated <- factor(newd3$hh_vaccinated, levels = 0:2, labels = c("pv","uv", "fv"))
attr(newd3, "trans") <- tmat
class(newd3) <- c("msdata", "data.frame")
newd3 <- expand.covs(newd3, covs = c("sex", "age_cat", "hh_vaccinated","household_n"))
newd3$strata = 1:14
msf.fv <- msfit(c1, newdata = newd3, trans = tmat)

summ.msf.uv<- summary(msf.uv)
summ.msf.pv<- summary(msf.pv)
summ.msf.fv<- summary(msf.fv)
survuv2<- 1-(exp(-summ.msf.uv[[2]]$Haz))
survpv2<- 1-exp(-summ.msf.pv[[2]]$Haz)
survfv2<- 1-exp(-summ.msf.fv[[2]]$Haz)
lowuv2<- 1-exp(-summ.msf.uv[[2]]$lower)
lowpv2<- 1-exp(-summ.msf.pv[[2]]$lower)
lowfv2<- 1-exp(-summ.msf.fv[[2]]$lower)
uppuv2<- 1-exp(-summ.msf.uv[[2]]$upper)
upppv2<- 1-exp(-summ.msf.pv[[2]]$upper)
uppfv2<- 1-exp(-summ.msf.fv[[2]]$upper)
survuv9<- 1-(exp(-summ.msf.uv[[9]]$Haz))
survpv9<- 1-exp(-summ.msf.pv[[9]]$Haz)
survfv9<- 1-exp(-summ.msf.fv[[9]]$Haz)
lowuv9<- 1-exp(-summ.msf.uv[[9]]$lower)
lowpv9<- 1-exp(-summ.msf.pv[[9]]$lower)
lowfv9<- 1-exp(-summ.msf.fv[[9]]$lower)
uppuv9<- 1-exp(-summ.msf.uv[[9]]$upper)
upppv9<- 1-exp(-summ.msf.pv[[9]]$upper)
uppfv9<- 1-exp(-summ.msf.fv[[9]]$upper)
survuv12<- 1-(exp(-summ.msf.uv[[12]]$Haz))
survpv12<- 1-exp(-summ.msf.pv[[12]]$Haz)
survfv12<- 1-exp(-summ.msf.fv[[12]]$Haz)
lowuv12<- 1-exp(-summ.msf.uv[[12]]$lower)
lowpv12<- 1-exp(-summ.msf.pv[[12]]$lower)
lowfv12<- 1-exp(-summ.msf.fv[[12]]$lower)
uppuv12<- 1-exp(-summ.msf.uv[[12]]$upper)
upppv12<- 1-exp(-summ.msf.pv[[12]]$upper)
uppfv12<- 1-exp(-summ.msf.fv[[12]]$upper)

ch3 <- data.frame(time = summ.msf.uv[[2]]$time, cov = "household vaccination status", group = "Unvaccinated", transition = "unvacc -> vacc1", 
                  surv = survuv2, low = lowuv2, upp = uppuv2) %>%
  add_row(time = summ.msf.pv[[2]]$time, cov = "household vaccination status", group = "Partially vaccinated", transition = "unvacc -> vacc1", 
          surv = survpv2, low = lowpv2, upp = upppv2) %>%
  add_row(time = summ.msf.fv[[2]]$time, cov = "household vaccination status", group = "Fully vaccinated", transition = "unvacc -> vacc1", 
          surv = survfv2, low = lowfv2, upp = uppfv2) %>%
  add_row(time = summ.msf.uv[[9]]$time, cov = "household vaccination status", group = "Unvaccinated", transition = "vacc1 -> vacc2", 
          surv = survuv9, low = lowuv9, upp = uppuv9) %>%
  add_row(time = summ.msf.pv[[9]]$time, cov = "household vaccination status", group = "Partially vaccinated", transition = "vacc1 -> vacc2", 
          surv = survpv9, low = lowpv9, upp = upppv9) %>%
  add_row(time = summ.msf.fv[[9]]$time, cov = "household vaccination status", group = "Fully vaccinated", transition = "vacc1 -> vacc2", 
          surv = survfv9, low = lowfv9, upp = uppfv9) %>%
  add_row(time = summ.msf.uv[[12]]$time, cov = "household vaccination status", group = "Unvaccinated", transition = "vacc2 -> vacc3", 
          surv = survuv12, low = lowuv12, upp = uppuv12) %>%
  add_row(time = summ.msf.pv[[12]]$time, cov = "household vaccination status", group = "Partially vaccinated", transition = "vacc2 -> vacc3", 
          surv = survpv12, low = lowpv12, upp = upppv12) %>%
  add_row(time = summ.msf.fv[[12]]$time, cov = "household vaccination status", group = "Fully vaccinated", transition = "vacc2 -> vacc3", 
          surv = survfv12, low = lowfv12, upp = uppfv12)

p_ch3 <- ggplot(ch3,(aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), size = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  ylim(0,1) +
  labs(linetype = "Transition", fill = "Household vaccination status", colour = "Household vaccination status", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)")


# ==============================================================================
# cumulative plots for vaccines by household n
cat("Generating cumulative incidence curves for hosuehold n\n")

msf.hh3 <- msf1

newd1 <- newd[,1:5]
newd2 <- newd1
newd2$household_n <- 1
newd2$household_n <- factor(newd2$household_n, levels = 0:3, labels = c("3","2", "4", "5+"))
attr(newd2, "trans") <- tmat
class(newd2) <- c("msdata", "data.frame")
newd2 <- expand.covs(newd2, covs = c("sex", "age_cat", "hh_vaccinated", "household_n"))
newd2$strata = 1:14
msf.hh2 <- msfit(c1, newdata = newd2, trans = tmat)

newd3 <- newd1
newd3$household_n <- 2
newd3$household_n <- factor(newd3$household_n, levels = 0:3, labels = c("3","2", "4", "5+"))
attr(newd3, "trans") <- tmat
class(newd3) <- c("msdata", "data.frame")
newd3 <- expand.covs(newd3, covs = c("sex", "age_cat", "hh_vaccinated","household_n"))
newd3$strata = 1:14
msf.hh4 <- msfit(c1, newdata = newd3, trans = tmat)

newd4 <- newd1
newd4$household_n <- 3
newd4$household_n <- factor(newd4$household_n, levels = 0:3, labels = c("3","2", "4", "5+"))
attr(newd4, "trans") <- tmat
class(newd4) <- c("msdata", "data.frame")
newd4 <- expand.covs(newd4, covs = c("sex", "age_cat", "hh_vaccinated","household_n"))
newd4$strata = 1:14
msf.hh5 <- msfit(c1, newdata = newd4, trans = tmat)

summ.msf.hh2<- summary(msf.hh2)
summ.msf.hh3<- summary(msf.hh3)
summ.msf.hh4<- summary(msf.hh4)
summ.msf.hh5<- summary(msf.hh5)
survhh22<- 1-(exp(-summ.msf.hh2[[2]]$Haz))
survhh32<- 1-exp(-summ.msf.hh3[[2]]$Haz)
survhh42<- 1-exp(-summ.msf.hh4[[2]]$Haz)
survhh52<- 1-exp(-summ.msf.hh5[[2]]$Haz)
lowhh22<- 1-exp(-summ.msf.hh2[[2]]$lower)
lowhh32<- 1-exp(-summ.msf.hh3[[2]]$lower)
lowhh42<- 1-exp(-summ.msf.hh4[[2]]$lower)
lowhh52<- 1-exp(-summ.msf.hh5[[2]]$lower)
upphh22<- 1-exp(-summ.msf.hh2[[2]]$upper)
upphh32<- 1-exp(-summ.msf.hh3[[2]]$upper)
upphh42<- 1-exp(-summ.msf.hh4[[2]]$upper)
upphh52<- 1-exp(-summ.msf.hh5[[2]]$upper)
survhh29<- 1-(exp(-summ.msf.hh2[[9]]$Haz))
survhh39<- 1-exp(-summ.msf.hh3[[9]]$Haz)
survhh49<- 1-exp(-summ.msf.hh4[[9]]$Haz)
survhh59<- 1-exp(-summ.msf.hh5[[9]]$Haz)
lowhh29<- 1-exp(-summ.msf.hh2[[9]]$lower)
lowhh39<- 1-exp(-summ.msf.hh3[[9]]$lower)
lowhh49<- 1-exp(-summ.msf.hh4[[9]]$lower)
lowhh59<- 1-exp(-summ.msf.hh5[[9]]$lower)
upphh29<- 1-exp(-summ.msf.hh2[[9]]$upper)
upphh39<- 1-exp(-summ.msf.hh3[[9]]$upper)
upphh49<- 1-exp(-summ.msf.hh4[[9]]$upper)
upphh59<- 1-exp(-summ.msf.hh5[[9]]$upper)
survhh212<- 1-(exp(-summ.msf.hh2[[12]]$Haz))
survhh312<- 1-exp(-summ.msf.hh3[[12]]$Haz)
survhh412<- 1-exp(-summ.msf.hh4[[12]]$Haz)
survhh512<- 1-exp(-summ.msf.hh5[[12]]$Haz)
lowhh212<- 1-exp(-summ.msf.hh2[[12]]$lower)
lowhh312<- 1-exp(-summ.msf.hh3[[12]]$lower)
lowhh412<- 1-exp(-summ.msf.hh4[[12]]$lower)
lowhh512<- 1-exp(-summ.msf.hh5[[12]]$lower)
upphh212<- 1-exp(-summ.msf.hh2[[12]]$upper)
upphh312<- 1-exp(-summ.msf.hh3[[12]]$upper)
upphh412<- 1-exp(-summ.msf.hh4[[12]]$upper)
upphh512<- 1-exp(-summ.msf.hh5[[12]]$upper)

ch4 <- data.frame(time = summ.msf.hh2[[2]]$time, cov = "household n", group = "2", transition = "unvacc -> vacc1", 
                  surv = survhh22, low = lowhh22, upp = upphh22) %>%
  add_row(time = summ.msf.hh3[[2]]$time, cov = "household n", group = "3", transition = "unvacc -> vacc1", 
          surv = survhh32, low = lowhh32, upp = upphh32) %>%
  add_row(time = summ.msf.hh4[[2]]$time, cov = "household n", group = "4", transition = "unvacc -> vacc1", 
          surv = survhh42, low = lowhh42, upp = upphh42) %>%
  add_row(time = summ.msf.hh5[[2]]$time, cov = "household n", group = "5", transition = "unvacc -> vacc1", 
          surv = survhh52, low = lowhh52, upp = upphh52) %>%
  add_row(time = summ.msf.hh2[[9]]$time, cov = "household n", group = "2", transition = "vacc1 -> vacc2", 
          surv = survhh29, low = lowhh29, upp = upphh29) %>%
  add_row(time = summ.msf.hh3[[9]]$time, cov = "household n", group = "3", transition = "vacc1 -> vacc2", 
          surv = survhh39, low = lowhh39, upp = upphh39) %>%
  add_row(time = summ.msf.hh4[[9]]$time, cov = "household n", group = "4", transition = "vacc1 -> vacc2", 
          surv = survhh49, low = lowhh49, upp = upphh49) %>%
  add_row(time = summ.msf.hh5[[9]]$time, cov = "household n", group = "5", transition = "vacc1 -> vacc2", 
          surv = survhh59, low = lowhh59, upp = upphh59) %>%
  add_row(time = summ.msf.hh2[[12]]$time, cov = "household n", group = "2", transition = "vacc2 -> vacc3", 
          surv = survhh212, low = lowhh212, upp = upphh212) %>%
  add_row(time = summ.msf.hh3[[12]]$time, cov = "household n", group = "3", transition = "vacc2 -> vacc3", 
          surv = survhh312, low = lowhh312, upp = upphh312) %>%
  add_row(time = summ.msf.hh4[[12]]$time, cov = "household n", group = "4", transition = "vacc2 -> vacc3", 
          surv = survhh412, low = lowhh412, upp = upphh412) %>%
  add_row(time = summ.msf.hh5[[12]]$time, cov = "household n", group = "5", transition = "vacc2 -> vacc3", 
          surv = survhh512, low = lowhh512, upp = upphh512)

p_ch4 <- ggplot(ch4,(aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), size = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  ylim(0,1) +
  labs(linetype = "Transition", fill = "Household n", colour = "Household n", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)")

## =============================================================================
# save some of this data
cat("saving stuff\n")

qsave(
  pta,
  file = ("results/t_pta.qs")
)
qsave(
  p_ch1,
  file = ("results/p_ch1.qs")
)
qsave(
  ch1,
  file = ("results/t_ch1.qs")
)
qsave(
  p_ch2,
  file = ("results/p_ch2.qs")
)
qsave(
  ch2,
  file = ("results/t_ch2.qs")
)
qsave(
  p_ch3,
  file = ("results/p_ch3.qs")
)
qsave(
  ch3,
  file = ("results/t_ch3.qs")
)
qsave(
  p_ch4,
  file = ("results/p_ch4.qs")
)
qsave(
  ch4,
  file = ("results/t_ch4.qs")
)