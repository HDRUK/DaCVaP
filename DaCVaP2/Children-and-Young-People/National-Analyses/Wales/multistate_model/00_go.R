stop("Don't actually source this script, that would be bad for business!")

# Info =========================================================================

# Q: What does vaccine uptake look like in children and young people?

# Convert data to usable format ================================================
# step 1
source("r_clear_and_load.R")
source("01_analysis_table_prep.R")

# step 2
source("r_clear_and_load.R")
source("02_msprep_cheat.R")

# Run the analysis =============================================================

source("r_clear_and_load.R")
source("03_run_multistate_model.R")

# Generate some nice plots======================================================

source("r_clear_and_load.R")
source("04_data_vis.R")

# Report =======================================================================

source("r_clear_and_load.R")
render(
  input = "99_Multistate-model-for-CYP-vaccine-uptake.Rmd",
  output_format = html_document(toc = TRUE),
  quiet = TRUE
)

