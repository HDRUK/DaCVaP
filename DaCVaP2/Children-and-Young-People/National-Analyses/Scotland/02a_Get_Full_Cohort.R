##########################################################
# Name of file: 02a_Get_Full_Cohort.R
# Data release (if applicable):
# Original author(s): Chris Robertson chris.robertson@phs.scot
# Original date: 10 Nov 2021
# Latest update author (if not using version control) - Chris Robertson chris.robertson@phs.scot
# Latest update date (if not using version control) - 
# Latest update description (if not using version control)
# Type of script: Descriptive stats
# Written/run onL: R Studio SERVER
# Version of R that the script was most recently run on: R 3.6.1
# Description of content: creates full cohort for vaccine effect relative to unvaccinated
# Approximate run time: Unknown
#
#   run 01a_Input_Data.R to read in data
#
##########################################################

library(survival)

output_list <- list()

a_begin_16_17 = as.Date("2021-07-07")
a_begin <- a_begin_16_17  #beginning of vaccination
a_end = as.Date("2022-05-31") # Our end date
min_age = 5 # Minimum age of the cohort we are interested in
max_age = 17 # Maximum age of the cohort we are interested in

#looking only at 12-17 year olds
output_list$a_begin <- a_begin

z_df <- Vaccinations

# Join in the entire EAVE cohort
z_df <- z_df %>% right_join(dplyr::select(df_cohort, EAVE_LINKNO, ageYear), by="EAVE_LINKNO")  #df_cohort is the 5-17 at March 2021

z_x = nrow(df_cohort)
z_df <- z_df %>% filter(ageYear >= min_age & ageYear <= max_age) %>% 
   dplyr::select(-ageYear)

print("Removing people not in the age range")
print(z_x - nrow(z_df))

#link in deaths and remove any who died before vaccination started
z_df <- z_df %>% left_join(dplyr::select(all_deaths, EAVE_LINKNO, NRS.Date.Death), by="EAVE_LINKNO")
z_x = nrow(z_df)
z_df <- z_df %>% filter(NRS.Date.Death > a_begin | is.na(NRS.Date.Death))
print("Removed this number of people who died")
print(z_x - nrow(z_df))

print(sum(z_df$date_vacc_1 > a_end, na.rm=TRUE))
print(sum(z_df$date_vacc_2 > a_end, na.rm=TRUE))
print(sum(z_df$date_vacc_3 > a_end, na.rm=TRUE))

# Set anyone who recevied their vaccine after the end of the study to 
# unvaccinated
z_df = z_df %>% mutate(date_vacc_1 = as.Date(if_else(date_vacc_1 <= a_end, date_vacc_1, NA_Date_)),
                       vacc_type = ifelse(date_vacc_1 <= a_end, vacc_type, NA))
z_df = z_df %>% mutate(date_vacc_2 = as.Date(if_else(date_vacc_2 <= a_end, date_vacc_2, NA_Date_)), 
                       vacc_type_2 = ifelse(date_vacc_2 <= a_end, vacc_type_2, NA))
z_df = z_df %>% mutate(date_vacc_3 = as.Date(if_else(date_vacc_3 <= a_end, date_vacc_3, NA_Date_)), 
                       vacc_type_3 = ifelse(date_vacc_1 <= a_end, vacc_type_3, NA))

#we need the first event post a_begin for the endpoints
#covid_hospitalisations is unique

output_list$endpoint <- "covid_hosp"  # "covid_hosp_death", "covid_hosp"

z_event <- covid_hosp %>%  filter(covid_hosp_date > a_begin) %>% 
                           arrange(EAVE_LINKNO, covid_hosp_date) %>% 
                           filter(!duplicated(EAVE_LINKNO)) %>% 
                           dplyr::select(EAVE_LINKNO, covid_hosp_date)

print(nrow(z_event))
print(table(z_event$EAVE_LINKNO %in% EAVE_cohort$EAVE_LINKNO))

z <- z_df %>% left_join(z_event, by="EAVE_LINKNO")

df_all <- z %>% dplyr::select(-NRS.Date.Death) #keep df_all - this has all subjects in the study
#add in the covariates to df_all for descriptives of the cohort
df_all <- df_all %>% left_join(df_cohort, by="EAVE_LINKNO")
z_x = nrow(df_all)
df_all <- df_all %>%  filter(!is.na(ageYear))  # drop those who do not link into EAVE
print("Dropping people who don't link into EAVE")
print(z_x - nrow(df_all))

#ageYear does not exist but ageYear.x and ageYear.y which came from the df_all and df_cohort
#datasets respectively. Both age vrbs have no NAs so just keep one of them and rename it
# df_all <- df_all %>% mutate(ageYear = ageYear.x) %>% 
#                      select(-ageYear.x, -ageYear.y)

#get positive test before a_begin variable
z <- df_all %>% dplyr::select(EAVE_LINKNO, date_vacc_1)
# Handle someone never being vaccinated
z = z %>% mutate(date = if_else(is.na(date_vacc_1), a_end, date_vacc_1))
z <- z %>% left_join(Positive_Tests, by="EAVE_LINKNO") %>% filter(!is.na(date_ecoss_specimen)) %>% 
   filter(date_ecoss_specimen < date) #keep thise sample before a_begin
z <- z %>% group_by(EAVE_LINKNO) %>% dplyr::summarise(N=n()) %>% 
  mutate(pos_before_vacc = 1) %>% dplyr::select(-N)
#now link back
df_all <- df_all %>% left_join(z, by="EAVE_LINKNO") %>% 
  mutate(pos_before_vacc=if_else(is.na(pos_before_vacc), 0,pos_before_vacc))

#get number of tests before vaccination variable
z <- df_all %>% dplyr::select(EAVE_LINKNO, date_vacc_1)
# Handle someone never being vaccinated
z = z %>% mutate(date = if_else(is.na(date_vacc_1), a_end, date_vacc_1))
z <- z %>% left_join(dplyr::select(cdw_full, EAVE_LINKNO, date_ecoss_specimen), by="EAVE_LINKNO") %>%
  filter(!is.na(date_ecoss_specimen)) %>% #omit those never tested
  filter(date_ecoss_specimen < date) #keep those sample before a_begin
z <- z %>% group_by(EAVE_LINKNO) %>% dplyr::summarise(N=n()) 
#now link back
df_all <- df_all %>% left_join(z, by="EAVE_LINKNO") %>% 
  mutate(N=if_else(is.na(N), 0L,N))
df_all <- df_all %>% mutate(n_tests_gp = cut(N, breaks=c(-1,0,1,2,max(N)), labels=c("0","1","2","3+")))
df_all$N <- NULL 


df_all <- df_all %>% mutate(Q_DIAG_DIABETES = if_else(Q_DIAG_DIABETES_1==1,Q_DIAG_DIABETES_1,Q_DIAG_DIABETES_2 ),
                            Q_DIAG_CKD = if_else(Q_DIAG_CKD_LEVEL >=1, 1, Q_DIAG_CKD_LEVEL))

#add in deaths and change event_date
#have checked no event_dates after date death
#this bit just checks and does no changes to the z_df data frame
z <- z_df %>% left_join(all_deaths, by="EAVE_LINKNO")

#merge in the covariates and calculate other covariates
df <- z_df %>% 
  left_join(dplyr::select(df_all, -date_vacc_1, -date_vacc_2, -date_vacc_3, vacc_type_2), by="EAVE_LINKNO") %>%
  filter(!is.na(ageYear)) # %>%  #drop those who do not link into EAVE

  

# Add in the household information
z_hid_data = hid_data %>% filter(!duplicated(EAVE_LINKNO))

df = df %>% left_join(select(z_hid_data, EAVE_LINKNO, March_hid), by="EAVE_LINKNO")

# Check if the person is shielding
df = df %>% mutate(shielding = EAVE_LINKNO %in% shielding$EAVE_LINKNO)

# Link in ethnicity data
df = df %>% left_join(ethnicity, by="EAVE_LINKNO")

#merge the sampling weights and eave_weights
df <- df %>% mutate(ew = eave_weight)


variables_hosp <- c("Sex", "simd2020_sc_quintile", "ur6_2016_name", "pos_before_test", "n_tests_gp",
                    "Q_DIAG_ASTHMA", "Q_DIAG_BLOOD_CANCER", "Q_DIAG_CEREBRALPALSY", "Q_DIAG_CONGEN_HD", "Q_DIAG_EPILEPSY",
                    "Q_DIAG_FRACTURE", "Q_DIAG_SEV_MENT_ILL", "Q_LEARN_CAT",
                     "n_oth_risk_gps")
df$age_gp <- factor(df$ageYear)
df$Q_LEARN_CAT <- factor(df$Q_LEARN_CAT)

z_vars <- names(df_all)[grepl("Q_DIAG", names(df_all))]
z_vars <- z_vars[!(z_vars %in% variables_hosp)]
z_vars <- z_vars[!(z_vars %in% c("Q_DIAG_DIABETES_1"  ,  "Q_DIAG_DIABETES_2" , "Q_DIAG_CKD_LEVEL"))]
#z_vars <- c(z_vars, "Q_HOME_CAT","Q_LEARN_CAT")  - no homeless children and learn cat included

z <- df_all %>% dplyr::select_at(c("EAVE_LINKNO", z_vars))
z <- z %>% mutate(N = apply(z[,z_vars], 1, sum))
z <- z %>% mutate(n_oth_risk_gps = cut(N, breaks=c(-1,0,max(N)), labels=c("0","1+")) )
z <- z %>% dplyr::select(EAVE_LINKNO, n_oth_risk_gps)

df_all <- df_all %>% left_join(z, by="EAVE_LINKNO")
df <- df %>% left_join(z, by="EAVE_LINKNO")

#add flag for symptomatic and lh - not done
z <- cdw_full  %>% filter(test_result=="POSITIVE") %>% 
  dplyr::select(EAVE_LINKNO, date_ecoss_specimen, test_result_record_source, date_onset_of_symptoms, flag_covid_symptomatic) %>% 
  arrange(EAVE_LINKNO, date_ecoss_specimen) %>%
  filter(!duplicated(paste(EAVE_LINKNO, date_ecoss_specimen))) %>% 
  mutate(lab = if_else(test_result_record_source == "ECOSS", "nhs","lh") ) %>% 
  mutate(date_onset_of_symptoms = as.Date(date_onset_of_symptoms )) %>% 
  mutate(flag_covid_symptomatic = if_else(!is.na(flag_covid_symptomatic) & flag_covid_symptomatic=="true", 1L, 0L))
z <- z %>% filter(date_ecoss_specimen >= a_begin) %>% #get first positive test in the study period
  filter(!duplicated(EAVE_LINKNO))  # then take first record

z_df <- df_all %>% left_join(dplyr::select(z, EAVE_LINKNO, date_ecoss_specimen, lab, flag_covid_symptomatic),
                             by=c("EAVE_LINKNO"))
df_all <- z_df

print("Adding in test data")

print(nrow(df))
print(length(unique(df$EAVE_LINKNO)))
z_df <- df %>% left_join(dplyr::select(z, EAVE_LINKNO, date_ecoss_specimen, lab, flag_covid_symptomatic),
                         by=c("EAVE_LINKNO"))

print(nrow(df))
print(length(unique(df$EAVE_LINKNO)))

df <- z_df

# Define the beginning of vaccination for the various age groups
a_begin_16_17 = as.Date("2021-08-06")
a_begin_12_15 = as.Date("2021-09-20")
a_begin_5_11 = as.Date("2021-12-22")


# Create category variables for the age ranges
df = df %>% mutate(age_range_group = case_when(
  5 <= z_df$ageYear & 11 >= z_df$ageYear ~ 1,
  12 <= z_df$ageYear & 15 >= z_df$ageYear ~ 2,
  16 <= z_df$ageYear & 17 >= z_df$ageYear ~ 3)) %>% mutate(age_range_group = factor(age_range_group, labels=c("5 - 11", "12 - 15", "16 - 17")))

# Store the old df for debugging purposes as we're missing a few people

z_df = df

# The merging process can leave us with .x and .y fields so
# here we tidy them up
stopifnot(all.equal(z_df$vacc_type.x, z_df$vacc_type.y))
stopifnot(all.equal(z_df$vacc_type_2.x, z_df$vacc_type_2.y))
stopifnot(all.equal(z_df$vacc_type_3.x, z_df$vacc_type_3.y))
stopifnot(all.equal(z_df$vacc_booster.x, z_df$vacc_booster.y))
stopifnot(all.equal(z_df$flag_incon.x, z_df$flag_incon.y))

z_df = z_df %>% rename(vacc_type = vacc_type.x, vacc_type_2 = vacc_type_2.x, vacc_type_3 = vacc_type_3.x,
                       vacc_booster = vacc_booster.x, flag_incon = flag_incon.x)
# Remove all the y fields
z_df = z_df %>% select(-vacc_type.y, -vacc_type_2.y, -vacc_type_3.y, -vacc_booster.y, -flag_incon.y)

df = z_df

# Count the number of doses given out
print("Number of 1st doses")
print(sum(df[!is.na(df$date_vacc_1), ]$eave_weight))
print(sum(df[!is.na(df$date_vacc_1), ]$eave_weight)/sum(df$eave_weight))
print("Number of 2nd doses")
print(sum(df[!is.na(df$date_vacc_2), ]$eave_weight))
print(sum(df[!is.na(df$date_vacc_2), ]$eave_weight)/sum(df$eave_weight))
print("Number of boosters")
print(sum(df[!is.na(df$date_vacc_3), ]$eave_weight))
print(sum(df[!is.na(df$date_vacc_3), ]$eave_weight)/sum(df$eave_weight))

df = z_df %>% rename(age_at_vacc_1 = age_at_vacc_1.x) %>% select(-age_at_vacc_1.y) %>% mutate(age_at_vacc_1 = factor(age_at_vacc_1))

print("Number of people we end up with")
print(nrow(df))
print("Weighted number of people")
print(round(sum(df$eave_weight), digits=0))

# Put anyone who was vaccinated before the start of the program in their own category 
z_df_vulnerable_16_17 = z_df %>% filter(age_range_group == "16 - 17") %>%
  filter(date_vacc_1 < a_begin_16_17)
z_df_vulnerable_12_15 = z_df %>% filter(age_range_group == "12 - 15") %>%
  filter(date_vacc_1 < a_begin_12_15)
z_df_vulnerable_5_11 = z_df %>% filter(age_range_group == "5 - 11") %>%
  filter(date_vacc_1 < a_begin_5_11)

df_vulnerable = z_df_vulnerable_16_17 %>%
  bind_rows(z_df_vulnerable_12_15) %>%
  bind_rows(z_df_vulnerable_5_11)

print(nrow(df))
print(length(unique(df$EAVE_LINKNO)))

# Set up the test dataframe containing tests from the cohort we're interested in
df_tests = cdw_full %>% filter(test_result_record_source == "NHS DIGITAL") %>%
  filter(date_ecoss_specimen > a_begin) %>%
  select(EAVE_LINKNO, date_ecoss_specimen, test_result, flag_covid_symptomatic) %>%
  inner_join(dplyr::select(df, -date_ecoss_specimen, -lab, -flag_covid_symptomatic), by="EAVE_LINKNO")

# Calculate the vaccination status of the household
household_vacc_status_fn = function (vacc_2_status) {
  if (all(!vacc_2_status)) {
    return(2)
  } else if (any(!vacc_2_status)) {
    return (1) 
  } else {
    return (0)
  }
}

z_vacc = Vaccinations %>% 
  filter(age_at_vacc_1 > 17) %>% 
  left_join(select(hid_data, EAVE_LINKNO, March_hid), by="EAVE_LINKNO") %>%
  mutate(vacc_2_status = is.na(date_vacc_2)) %>%
  group_by(March_hid) %>%
  summarise(household_vacc_status=household_vacc_status_fn(vacc_2_status))

z_vacc$household_vacc_status = factor(z_vacc$household_vacc_status, levels = c(0, 1, 2),
                                      labels = c("Unvaccinated", "Partially Vaccinated", "Fully Vaccinated"))

print(nrow(df))

df = df %>% left_join(z_vacc, by="March_hid")

# Check if the person tested positive before their vaccination date

# Add in the number of people in the household
## THIS IS A POTENTIAL BUG if it's discarding duplicates
z_hid = hid_data %>% select(EAVE_LINKNO, March_hid_count) %>%
  filter(!duplicated(EAVE_LINKNO)) 

# Remove anyone with more than 10 people in the house
z_hid = z_hid %>% filter(March_hid_count < 10)

z_hid$num_people_in_household = cut(z_hid$March_hid_count, c(0, 1, 2, 3, 4, max(z_hid$March_hid_count)))
z_hid = z_hid %>% select(-March_hid_count)
z_hid$num_people_in_household = factor(z_hid$num_people_in_household, labels = c("1", "2", "3", "4", "5+"))
df = df %>% left_join(z_hid, by="EAVE_LINKNO")

# Check if someone has someone shielding in their house
#z_shielding_in_house = hid_data %>% select(EAVE_LINKNO, March_hid) %>%
#  filter(EAVE_LINKNO %in% df$EAVE_LINKNO) %>%
#  group_by(March_hid) %>%
#  summarise(shielding_in_house =any(EAVE_LINKNO %in% shielding$EAVE_LINKNO))

#print(nrow(df))
#df = df %>% left_join(z_shielding_in_house, by="March_hid")
#print(nrow(df))
# Remove any NAs
# df = df %>% mutate(shielding_in_house = factor(if_else(is.na(shielding_in_house), FALSE, shielding_in_house)))
# Somehow have a duplicate arrived so we remove
df = df %>% filter(!duplicated(EAVE_LINKNO))

remove(list=ls(pa="^z"))

