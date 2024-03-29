# National Analysis

The national level analysis was performed by each nation within their trusted research environments (TREs). Each nation produced a harmonised cohort of CYP that was suitable for modelling in parallel across all cohorts. A uniform Cox proportional hazard multistate model was performed by each nation on their cohorts, and the results exported and shared for a meta-analysis.

## Cohort construction

Each nation constructed a cohort of CYP age 5-17 using the scripts stored in this repo.

All cohorts generated by each nation were subjected to the following parameters to clean the data.

* In cohort between July 2021 and May 2022 (this allows us to determine if they were infected up to 28 days prior to the start of the study).
* Has week of birth and sex recorded
* Is aged between 5 and 17 between Aug 2021 and May 2022
* Is resident in country of analysis from Jan 2020
* Has unique residential ID
* Household less than 10
* Minimum of 1 adult in household
* Registered with GP accessible to the countries data linkage.
* Does not have a hospital spell of more than 1 week during study period
* Has good vaccine records (UK vaccination, valid vaccine name and date, before today, valid dose sequence, minimum 28 days between vaccinations) 
* If CYP has 1st and 2nd dose then with ChAdOx1 adenoviral (Oxford-AstraZeneca), mRNA-1273 (Moderna) or BNT162b2 mRNA (PfizerBioNTech)
* If CYP has booster then with Oxford-AstraZeneca, Moderna or PfizerBioNTech
* Date of dose 1 is after age group eligibility

## Local analysis

Each nation performed a bi directional multi-state model within their TRE using Cox proportional hazards regression to estimate the transition between states using the R scripts stored in this repo. The modelling scripts were created by sjaldridge and performed an identical analysis on each cohort. The model exports adjusted hazard ratios and 95% confidence intervals along with a sumamry report.
