cat("Clearing workspace and loading stuff\n")

# try to close connections =====================================================

tryCatch(
  expr = {
    sail_close(con)
  },
  error = function(e) {invisible()}
)

tryCatch(
  expr = {
    sail_close(conn)
  },
  error = function(e) {invisible()}
)

# clear workspace ==============================================================

rm(list = ls())
gc()

# options ======================================================================

options(
  dplyr.summarise.inform = FALSE,
  readr.show_col_types = FALSE,
  lubridate.week.start = 1 # Monday
)

# portable library =============================================================

# if we are using a portable version of R, use only the packages within its
# own library, i.e. ignore user library
if (grepl(x = R.home(), pattern = "R-Portable")) {
  .libPaths(paste0(R.home(), "/library"))
}

# load packages ================================================================

pkgs <- c(
  # load these first to not highjack the other packages
  "purrr",
  "MASS",
  "mgcv",
  # alphabetical
  "assertr",
  "beepr",
#  "broom",
  "changepoint.np",
  "dplyr",
  "dtplyr",
  "egg",
  "forcats",
  "ggfortify",
  "ggplot2",
  "ggthemes",
  "ggrepel",
  "gtsummary",
  "knitr",
  "kableExtra",
  "mice",
  "janitor",
  "lubridate",
  "patchwork",
  "qs",
  "RcppRoll",
  "rlang",
  "rmarkdown",
  "sailr",
  "scales",
  "speedglm",
  "stringr",
  "readr",
  "survey",
  "survival",
  "tibble",
  "tidyquant",
  "tidyr"
)

for (pkg in pkgs) {
  suppressWarnings(
    suppressPackageStartupMessages(
      library(pkg, character.only = TRUE)
    )
  )
}

# useful dates =================================================================

study_end_date      <- ymd("2022-05-31")
start_date_5_to_11  <- ymd("2022-02-15")
start_date_12_to_15 <- ymd("2021-09-14")
start_date_16_over  <- ymd("2021-08-04")
study_start_date    <- start_date_16_over-days(28)


# custom functions =============================================================

s_drive <- function(...) {
  str_c("S:/1151 - Wales Multi-morbidity cohort (0911) - Census Data/Sarah Aldridge/dcp04-vaccine_uptake_in_cyp/", ...)
}

calc_pyears <- function(.data, ...) {
  .data %>%
    lazy_dt() %>%
    group_by(...) %>%
    summarise(
      pyears = sum((tstop - tstart) * sample_weight) / 365.25,
      event = sum(event_flg)
    ) %>%
    ungroup() %>%
    as_tibble()
}

less_than_ten <- function(x) {ifelse(between(x,1,9), 10, x)}

# plot dimensions ==============================================================

p_width  <- 5.2
p_height <- 8.75
