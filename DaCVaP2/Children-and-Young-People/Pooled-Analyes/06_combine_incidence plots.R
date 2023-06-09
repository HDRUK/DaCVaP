## combines cumulative incidence plots


## prep
source("r_clear_and_load.R")
library(viridis)
library(ggsci)

##  age

age_s <- read.csv("Scotland/cumulative_hazards_age.csv") %>% mutate(country = "Scotland")
age_w <- read.csv("Wales/cumulative_hazards_age.csv") %>% mutate(country = "Wales")
age_e <- read.csv("England/cumulative_hazards_age.csv") %>% mutate(country = "England")
age_ni <- read.csv("Northern_Ireland/cumulative_hazards_age.csv") %>% mutate(country = "Northern Ireland")

age <- rbind(age_s, age_w, age_e, age_ni)
age_t <- age %>% #filter(group == "12-15") %>% 
#  mutate(diff = head(surv) - tail(surv))
  mutate_all(funs(diff = surv - lag(surv))) %>%
  na.omit %>%
  filter(surv_diff >= 0)
  
x = ggplot(age_t, aes(x= time, y = surv_diff, col = country)) +
  geom_smooth(span = 0.1, se = FALSE) +
  facet_grid(group ~ transition) + 
  theme(panel.grid.major = element_line(colour = "black"),
        panel.grid.minor = element_line(colour = "grey")) + 
  scale_x_continuous(minor_breaks = seq(0, 300, 5), breaks = seq(0,300,20))

p_age <- age %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), linewidth = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~country) +
  labs(linetype = "Transition", fill = "Age in years", colour = "Age in years", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")

p_age <- age %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = country))) + 
  geom_line(aes(colour = country), linewidth = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~ group + transition) +
  labs(linetype = "Transition", fill = "Age in years", colour = "Age in years", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")


## household vaccination

hhv_s <- read.csv("Scotland/cumulative_hazards_hh_vacc.csv") %>% mutate(country = "Scotland")
hhv_w <- read.csv("Wales/cumulative_hazards_hh_vacc.csv") %>% mutate(country = "Wales")
hhv_e <- read.csv("England/cumulative_hazards_hh_vacc.csv") %>% mutate(country = "England")
hhv_ni <- read.csv("Northern_Ireland/cumulative_hazards_hh_vacc.csv") %>% mutate(country = "Northern Ireland")

hhv <- rbind(hhv_s, hhv_w, hhv_e, hhv_ni)

p_hhv <- hhv %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), size = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~country) +
  labs(linetype = "Transition", fill = "Household vaccination status", colour = "Household vaccination status", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")

p_hhv <- hhv %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = country))) + 
  geom_line(aes(colour = country), linewidth = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~ group + transition) +
  labs(linetype = "Transition", fill = "Age in years", colour = "Age in years", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")

## sex

sex_s <- read.csv("Scotland/cumulative_hazards_sex.csv") %>% mutate(country = "Scotland")
sex_w <- read.csv("Wales/cumulative_hazards_sex.csv") %>% mutate(country = "Wales")
sex_e <- read.csv("England/cumulative_hazards_sex.csv") %>% mutate(country = "England")
sex_ni <- read.csv("Northern_Ireland/cumulative_hazards_sex.csv") %>% mutate(country = "Northern Ireland")

sex <- rbind(sex_s, sex_w, sex_e, sex_ni) %>% mutate(group = ifelse(group == "F", "Female",
                                                                    ifelse( group == "M", "Male", group)))

p_sex <- sex %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), size = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~country) +
  labs(linetype = "Transition", fill = "Sex", colour = "Sex", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")

p_sex <- sex %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = country))) + 
  geom_line(aes(colour = country), linewidth = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~ group + transition) +
  labs(linetype = "Transition", fill = "Age in years", colour = "Age in years", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")

## household number

hhn_s <- read.csv("Scotland/cumulative_hazards_hh_n.csv") %>% mutate(country = "Scotland")
hhn_w <- read.csv("Wales/cumulative_hazards_hh_n.csv") %>% mutate(country = "Wales")
hhn_e <- read.csv("England/cumulative_hazards_hh_n.csv") %>% mutate(country = "England")
hhn_ni <- read.csv("Northern_Ireland/cumulative_hazards_hh_n.csv") %>% mutate(country = "Northern Ireland")

hhn <- rbind(hhn_s, hhn_w, hhn_e, hhn_ni) %>%
  mutate(
    group = ifelse(group == "5", "5+",group) ,
    group = factor(group, levels = c("1", "2", "3", "4", "5+")))
  


p_hhn <- hhn %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = group, linetype = transition))) + 
  geom_line(aes(colour = group), size = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~country) +
  labs(linetype = "Transition", fill = "Number of residents in household", colour = "Number of residents in household", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")

p_hhn <- hhn %>% filter(!(low == 0 & upp == 1)) %>%
  ggplot((aes(x = time, y = surv, fill = country))) + 
  geom_line(aes(colour = country), linewidth = 1) +
  geom_ribbon(aes(ymin = low, ymax = upp), alpha = 0.2) + 
  scale_color_npg() +
  scale_fill_npg() +
  ylim(0,1) +
  facet_wrap(~ group + transition) +
  labs(linetype = "Transition", fill = "Age in years", colour = "Age in years", 
       y = "Cumulative incidence of receiving each vaccine", x = "Time (days)") + 
  theme(legend.position = "bottom", legend.box = "vertical")

p_age
p_hhv
p_sex
p_hhn
