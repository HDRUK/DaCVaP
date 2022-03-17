# clear the environment ========================================================
rm(list=ls())
gc()

# load options, packages and functions =========================================

source("01_load.r")

# create data ==================================================================

# Run '02', '03' and '04' scripts in Eclipse

# prepare data for analysis ====================================================

source("06a_save_data.r")

source("06b_tidy.r")

# analyse ======================================================================

source("07a_sample_selection_summary.r")
source("07b_count_individuals_events_by_vaccine.r")
source("07c_describe_case_control_matching.r")
source("07d_describe_VITT_events.r")

source("08a_model_fit.r")

source("09a_vacc_incident_obs_vs_exp.r")

# report =======================================================================

# for gitlab
render(
	input = "README.Rmd",
	output_format = md_document(),
	quiet = TRUE
)

# for local viewing
render(
	input = "README.rmd",
	output_file = "README.html",
	quiet = TRUE
)

render(
  input = "08b_sccs_model_fit.rmd",
  output_file = "08b_sccs_model_fit.html",
  quiet = TRUE
)
