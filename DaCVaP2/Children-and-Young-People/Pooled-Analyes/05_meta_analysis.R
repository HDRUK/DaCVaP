## Meta analysis for DCP04 CYP project

## prep
source("r_clear_and_load.R")
install.packages("metafor")
library(metafor)
library(scales)
library(ggsci)
options(scipen = 999)

## load data
cox_w <- read.csv("Wales/cox_model.csv") %>% mutate(country = "wales")
cox_e <- read.csv("England/cox_model.csv") %>% mutate(country = "england") %>% 
  mutate(type = ifelse(type == "M", "Male", type))
cox_s <- read.csv("Scotland/cox_model.csv") %>% mutate(country = "scotland")
cox_ni <- read.csv("Northern_Ireland/cox_model.csv") %>% mutate(country = "northern ireland") %>% filter(type != "5-11")

c1 <- rbind(cox_w,cox_e, cox_s, cox_ni) %>% rename(lower_ci = lower..95, upper_ci = upper..95)

## plot data

c2 <- c1 %>% filter(transition %in% c(2,9,12), !(type == "5-11" & transition == 12)) %>%
  mutate(type = ifelse(type == "m", "Male",
                       ifelse(type == "uv", "Unvaccinated",
                              ifelse(type == "fv", "Fully vaccinated",
                                     ifelse(type == "12_15", "12-15", 
                                            ifelse(type == "5_11", "5-11", 
                                                   ifelse(type == "5", "5+", type)))))),
         #Country = sub("(.)", "\\U\\1",country, perl = TRUE)) 
        Country = str_to_title(country))  %>%
  mutate(type = factor(type, levels = rev(c("Female", "Male","16-17", "12-15", "5-11", 
                                            "2", "3", "4", "5+", 
                                            "Fully vaccinated", "Partially vaccinated", "Unvaccinated"))
                       ),
         transition = ifelse(transition == "2", "1st dose",
                             ifelse(transition == "9", "2nd dose",
                                    ifelse(transition == "12", "3rd dose", transition))),
         #factor(transition, levels = c("2", "9", "12"))
         variable =  factor(ifelse(type %in% c("Male", "Female"), "Sex",
                                   ifelse(type %in% c("16-17", "12-15", "5-11"), "Age",
                                          ifelse(type %in% c("2", "3", "4", "5+"), "Number of residents in household",
                                                 ifelse(type %in% c("Fully vaccinated", "Partially vaccinated", "Unvaccinated"),
                                                        "Vaccination status of adults in household", "X")))),
                            levels = c("Sex", "Age", "Number of residents in household", "Vaccination status of adults in household"))
         )

x <- c2 %>% select(variable, Country, transition) %>% unique() %>%
  mutate(type = factor(
           ifelse(variable == "Age", "16-17",
                  ifelse(variable == "Sex", "Female",
                         ifelse(variable == "Number of residents in household", "3",
                                ifelse(variable == "Vaccination status of adults in household", "Partially vaccinated", na_chr))))),
         exp.coef. = 1.00,
         lower_ci = 1.00,
         upper_ci = 1.00,
         reference_flag = "1"
         )


p1 <- c2 %>% mutate(reference_flag = "0") %>% add_row(x) 
p1 <- p1 %>%
  ggplot(aes(y = type, x = exp.coef.,xmin = lower_ci, xmax = upper_ci, col = Country, shape = reference_flag)) + 
  geom_pointrange() +
  geom_point(
    data = filter(p1, reference_flag == 1), colour = "black", size = 2.5)+ 
  scale_color_npg() +
  scale_fill_npg() +
  guides("none") +
  facet_grid(variable ~ transition, space = "free", scales = "free", labeller = label_wrap_gen(width = 25)) +
  scale_x_continuous(trans = "log2", breaks = log_breaks(5)) + 
  scale_shape_manual(values = c(16, 18)) +
  coord_cartesian(c(0.04, 24)) +
  geom_vline(xintercept = 1, lty = 2, alpha = 0.35) +
  theme(strip.text.y =  element_text(angle = 0)) +
  labs(
    x = "Hazard ratio",
    y = NULL) + 
  theme(legend.position = "bottom", legend.box = "vertical") + 
  guides(shape = FALSE)
p1


## subset data

age.5_11.2 <- c1 %>% filter(type == "5-11" & transition == 2)
age.5_11.9 <- c1 %>% filter(type == "5-11" & transition == 9)
age.5_11.12 <- c1 %>% filter(type == "5-11" & transition == 12)

age.12_15.2 <- c1 %>% filter(type == "12-15" & transition == 2)
age.12_15.9 <- c1 %>% filter(type == "12-15" & transition == 9)
age.12_15.12 <- c1 %>% filter(type == "12-15" & transition == 12)

sex.2 <- c1 %>% filter(type == "Male" & transition == 2)
sex.9 <- c1 %>% filter(type == "Male" & transition == 9)
sex.12 <- c1 %>% filter(type == "Male" & transition == 12)

hh_n.2.2 <- c1 %>% filter(type == "2" & transition == 2)
hh_n.2.9 <- c1 %>% filter(type == "2" & transition == 9)
hh_n.2.12 <- c1 %>% filter(type == "2" & transition == 12)

hh_n.4.2 <- c1 %>% filter(type == "4" & transition == 2)
hh_n.4.9 <- c1 %>% filter(type == "4" & transition == 9)
hh_n.4.12 <- c1 %>% filter(type == "4" & transition == 12)

hh_n.5.2 <- c1 %>% filter(type == "5" & transition == 2)
hh_n.5.9 <- c1 %>% filter(type == "5" & transition == 9)
hh_n.5.12 <- c1 %>% filter(type == "5" & transition == 12)

hh_v.uv.2 <- c1 %>% filter(type == "Unvaccinated" & transition == 2)
hh_v.uv.9 <- c1 %>% filter(type == "Unvaccinated" & transition == 9)
hh_v.uv.12 <- c1 %>% filter(type == "Unvaccinated" & transition == 12)

hh_v.fv.2 <- c1 %>% filter(type == "Fully vaccinated" & transition == 2)
hh_v.fv.9 <- c1 %>% filter(type == "Fully vaccinated" & transition == 9)
hh_v.fv.12 <- c1 %>% filter(type == "Fully vaccinated" & transition == 12)

## to do - need to group the ages and have transition separate
reml.5_11.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = age.5_11.2, method = "REML")
reml.5_11.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = age.5_11.9, method = "REML")
#reml.5_11.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = age.5_11.12, method = "REML")

reml.12_15.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = age.12_15.2, method = "REML")
reml.12_15.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = age.12_15.9, method = "REML")
reml.12_15.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = age.12_15.12, method = "REML")

reml.m.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = sex.2, method = "REML")
reml.m.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = sex.9, method = "REML")
reml.m.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = sex.12, method = "REML")

reml.2.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.2.2, method = "REML")
reml.2.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.2.9, method = "REML")
reml.2.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.2.12, method = "REML")

reml.4.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.4.2, method = "REML")
reml.4.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.4.9, method = "REML")
reml.4.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.4.12, method = "REML")

reml.5.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.5.2, method = "REML")
reml.5.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.5.9, method = "REML")
reml.5.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_n.5.12, method = "REML")

reml.uv.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_v.uv.2, method = "REML")
reml.uv.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_v.uv.9, method = "REML")
reml.uv.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_v.uv.12, method = "REML")

reml.fv.2 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_v.fv.2, method = "REML")
reml.fv.9 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_v.fv.9, method = "REML")
reml.fv.12 <- rma(yi = coef, sei = se.coef., weighted = TRUE, data = hh_v.fv.12, method = "REML")

y <- c("reml.5_11.2","reml.5_11.9", "reml.12_15.2", "reml.12_15.9", "reml.12_15.12", 
       "reml.m.2", "reml.m.9", "reml.m.12",
       "reml.2.2", "reml.2.9", "reml.2.12", "reml.4.2", "reml.4.9", "reml.4.12", 
       "reml.5.2", "reml.5.9", "reml.5.12", 
       "reml.uv.2", "reml.uv.9", "reml.uv.12", "reml.fv.2", "reml.fv.9", "reml.fv.12")

combo <- data.frame(type = character(), transition = character(), coeff = numeric(), ci.lb = numeric(), ci.ub = numeric(),
                    tau = numeric(), I2 = numeric())
  for (i in 1:length(y)) {
    coeff <- paste0(y[[i]],"$beta[1]")
    lb <- paste0(y[[i]],"$ci.lb")
    ub <- paste0(y[[i]],"$ci.ub")
    type <- sapply(strsplit(y[[i]],".", fixed = TRUE), `[`,2)
    transition <- sapply(strsplit(y[[i]],".", fixed = TRUE), `[`,3)
    tau <- paste0(y[[i]], "$tau2")
    I2 <- paste0(y[[i]], "$I2")
    combo <- combo %>% add_row(type = type,
                               transition = transition,
                               coeff = exp(eval(parse(text = coeff))),
                               ci.lb = exp(eval(parse(text = lb))),
                               ci.ub = exp(eval(parse(text = ub))),
                               tau = eval(parse(text = tau)),
                               I2 = eval(parse(text = I2))
                               )
  }
combo <- combo %>% 
  mutate(type = ifelse(type == "m", "Male",
                       ifelse(type == "uv", "Unvaccinated",
                              ifelse(type == "fv", "Fully vaccinated",
                                     ifelse(type == "12_15", "12-15", 
                                            ifelse(type == "5_11", "5-11", 
                                                   ifelse(type == "5", "5+", type))))))) %>%
  mutate(type = factor(type, levels = rev(c("16-17", "12-15", "5-11", "Female", "Male",
                                            "2", "3", "4", "5+", 
                                            "Fully vaccinated", "Partially vaccinated", "Unvaccinated"
                                            )
                                          )
                       ),
  transition = ifelse(transition == "2", "1st dose",
                      ifelse(transition == "9", "2nd dose",
                             ifelse(transition == "12", "3rd dose", transition))),
  #factor(transition, levels = c("2", "9", "12"))
  variable =  factor(ifelse(type %in% c("Male", "Female"), "Sex",
                            ifelse(type %in% c("16-17", "12-15", "5-11"), "Age",
                                   ifelse(type %in% c("2", "3", "4", "5+"), "Number of residents in household",
                                          ifelse(type %in% c("Fully vaccinated", "Partially vaccinated", "Unvaccinated"),
                                                 "Vaccination status of adults in household", "X")))),
                     levels = c("Sex", "Age", "Number of residents in household", "Vaccination status of adults in household"))
  )

p2 <- combo %>% mutate(reference_flag = "0") %>% add_row(x %>% mutate(coeff = exp.coef., ci.lb = lower_ci, ci.ub = upper_ci)%>% 
                                                           select(variable,transition, type, coeff, ci.lb, ci.ub, reference_flag)) 
## plot combined results 
p2 <- p2 %>%
  ggplot(aes(y = type, x = coeff,xmin = ci.lb, xmax = ci.ub, shape = reference_flag)) + 
  geom_pointrange() +
  geom_point(
    data = filter(p2, reference_flag == 1), colour = "black", size = 2.5)+ 
  scale_color_npg() +
  scale_fill_npg() +
  scale_shape_manual(values = c(16, 18)) +
#  facet_wrap(~ transition, ncol = 3) + 
  facet_grid(variable ~ transition, space = "free", scales = "free", labeller = label_wrap_gen(width = 25)) +
  scale_x_continuous(trans = "log2", breaks = log_breaks(5), labels = label_number_auto()) + 
  coord_cartesian(c(0.04, 24)) +
  geom_vline(xintercept = 1, lty = 2, alpha = 0.35) + 
  theme(strip.text.y =  element_text(angle = 0)) +
  labs(
    x = "Adjusted Hazard ratio",
    y = NULL
  ) + 
  guides(shape = FALSE)
p2

# create table for cox and meta results
d1 <- c1 %>% mutate_at(vars(coef, exp.coef., se.coef., z, Pr...z.., lower_ci, upper_ci), funs(round(.,2))) %>%
  mutate(Pr...z.. = ifelse(Pr...z.. < 0.01, "***",
                           ifelse(Pr...z.. < 0.05, "**",
                                  ifelse(Pr...z.. <0.1, "*", ""))))
d1$upper_ci[d1$upper_ci > 1000] <- Inf
d1$Pr...z..[is.na(d1$Pr...z..)] <- ""
d1 <- d1 %>% 
  mutate(coef = paste0(exp.coef., " (", lower_ci, ", ", upper_ci, ")", paste(Pr...z..))) %>%
  select(type, transition, country, coef) %>%
  pivot_wider(names_from = type, values_from = coef) %>%
  select(country, transition, Male,"12-15", "5-11", "2","4","5", Unvaccinated, "Fully vaccinated")

d2 <- d1 %>% filter(transition %in% c(2,9,12))

d3 <- combo %>% select(variable, type, transition, coeff, "CI lower" = ci.lb,  "CI upper" = ci.ub, "tau2" = tau, I2) %>%
  mutate_at(vars(coeff, "CI lower", "CI upper", tau2, I2), funs(round(.,2)))


write.csv(d1, "cox_pre_meta.csv", row.names = FALSE)
write.csv(d2, "cox_pre_meta_vacc.csv", row.names = FALSE)
write.csv(d3, "cox_meta.csv", row.names = FALSE)
