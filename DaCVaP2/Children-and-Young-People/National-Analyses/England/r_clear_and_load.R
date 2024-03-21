cat("setup\n")
# clear workspace ==============================================================

rm(list = ls())
gc()

# options ======================================================================

options(
  dplyr.summarise.inform = FALSE,
  readr.show_col_types = FALSE,
  lubridate.week.start = 1 # Monday
)

# load packages ================================================================

pkgs <- c(
  # load these first to not highjack the other packages
  "purrr",
  "MASS",
  "mgcv",
  # alphabetical
  #"assertr",
  #"beepr",
  "broom",
  #"changepoint.np",
  "data.table",
  "dplyr",
  "dtplyr",
  #"egg",
  "forcats",
  #"ggfortify",
  "ggplot2",
  #"ggthemes",
  "ggrepel",
  #"gtsummary",
  "knitr",
  "kableExtra",
  "mice",
  "mstate",
  "janitor",
  "lubridate",
  #"patchwork",
  #"qs",
  "RcppRoll",
  "rlang",
  "rmarkdown",
  #"sailr",
  "scales",
  #"speedglm",
  "stringr",
  "readr",
  "survey",
  "survival",
  "survminer",
  "tibble",
  #"tidyquant",
  "tidyr"
)

for (pkg in pkgs) {
  suppressWarnings(
    suppressPackageStartupMessages(
      library(pkg, character.only = TRUE)
    )
  )
}

s_drive <- function(...) {
  str_c("/intermediate_tables", ...)
}

# useful dates =================================================================

study_end_date      <- ymd("2022-05-31")
start_date_5_to_11  <- ymd("2022-02-15")
start_date_12_to_15 <- ymd("2021-09-14")
start_date_16_over  <- ymd("2021-08-04")

# plot dimensions ==============================================================

p_width  <- 5.2
p_height <- 8.75