######################################################################
## Title: Meta-analysis of first dose ChAdOx1 and BNT162b2 COVID-19 vaccinations and thrombocytopenic, venous thromboembolic
##        and haemorrhagic events in the UK
##
## Short title: Vaccine safety meta-analysis
##
## Code author: Chris Robertson, Steven Kerr
##
## Description: This does the meta analysis for the case-control study using estimated odds ratios for adverse events
##              following vaccination from each country
######################################################################

library(readxl)
library(tidyverse)
library(meta)
library(stringr)

####################### FUNCTIONS #############################################

# This sets upper and lower confidence interval entries for treatment effects
# to NA if either of their exponentials is infinite.
setNA <- function(upper, lower){
  
  indices <- is.infinite(exp(upper)) | is.infinite(exp(lower))
  
  upper[indices] <- NA
  lower[indices] <- NA
  
  return(list(upper, lower))
}

# This sets upper and lower confidence interval entries for treatment effects
# to 0 if either of their exponentials is infinite.
set0 <- function(upper, lower){
  
  indices <- is.infinite(exp(upper)) | is.infinite(exp(lower))
  
  upper[indices] <- 0
  lower[indices] <- 0
  
  return(list(upper, lower))
}

# Replace time entries with something more readable.
time_replace <- function(vector){
  str_replace_all(vector, c("v1_0:6" = 'Day 0-6', 
                            "v1_7:13" = 'Day 7-13',
                            "v1_14:20" = 'Day 14-20',
                            "v1_21:27" = 'Day 21-27',
                            "v1_0:27" = 'Day 0-27',
                            "v1_28" = 'Day 28'))
}


# Create individual table + meta-analysis for a given vaccine and event
create_table_ma_plot <- function(vacc, event){
  
  df$time <- time_replace(df$time)
  
  names(df) <- gsub('time', 'Time period', names(df))
  
  df <- filter(df, group == event & vaccine %in% c(vacc, 'uv') )
  
  df <- df[order( match(pull(df, 'Time period'), c('uv', times)),  match(df$country, countries)), ]
  
  table <- select(df, `Time period`, country, N, R, percent)
  
  #table[, c('N', 'R')][ table[, c('N', 'R')] < 5 & table[, c('N', 'R')] > 0 ] <- '<5'
  
  table$R <- paste(table$R, table$percent, sep=' ' )
  
  table <- select(table, -percent)
  
  table <- pivot_wider(table, id_cols= `Time period`, names_from=country, values_from=c(N,R)) %>%
          select(`Time period`, `N_England - RCGP`, `R_England - RCGP`, N_Scotland, R_Scotland, N_Wales, R_Wales)
  
  table <- table[match(c('uv', times), pull(table, 'Time period')),]
  
  # Format numbers with commas per three decimal places
  table <- mutate_if(table, is.numeric, ~formatC(round(.), format = "f", big.mark = ",", drop0trailing = TRUE) )
  
  new_row <- c(endpoints[[event]], rep('', 8))
  
  table <- rbind(new_row, table)
  
  df <- filter(df, vaccine != 'uv')

  ma <- metagen(TE=df$log_rr, seTE=df$se_log_rr, studlab=df$country, byvar= pull(df, 'Time period'),
                  backtransf=TRUE, sm="RR", comb.fixed=comb.fixed, comb.random = comb.random,
                bylab = 'Time period')
  
  df$raw_weights <- ma[[weight]]
  
  df <- group_by(df, `Time period`) %>% mutate( norm_weights = raw_weights/sum(raw_weights) )

  df <- filter(df, norm_weights > 10**-5 & R!= 0)
  
  ma <- metagen(TE=df$log_rr, seTE=df$se_log_rr, studlab=df$country, byvar= pull(df, 'Time period'),
                backtransf=TRUE, sm="RR", comb.fixed=comb.fixed, comb.random = comb.random,
                bylab = 'Time period')

  return(list(table, ma))
}

# Combine individual tables into one for publication
create_pub_table <- function(){
  
  AZ_table <- data.frame()
  PB_table <- data.frame()
  
  for (i in 1:length(endpoints)) { 
    #i <- 2

    input <- readRDS(paste0(path, 'ma_res_', names(endpoints)[i],".rds") )
    
      AZ_table <- bind_rows(AZ_table, input$az_tab)
      PB_table <- bind_rows(PB_table, input$pb_tab)
  }

  
  names(AZ_table) <- c(' ', 'England - RCGP', ' ', 'Scotland', ' ', 'Wales', ' ')
  names(PB_table) <- c(' ', 'England - RCGP', ' ', 'Scotland', ' ', 'Wales', ' ')
  
  new_row <- c('Time period', rep( c('Number of controls', 'Number of cases'), 3))
  
  AZ_table <- rbind(new_row, AZ_table)
  PB_table <- rbind(new_row, PB_table)
  
  write.csv(AZ_table, paste(path, 'AZ_table.csv', sep='' ), row.names = FALSE)
  write.csv(PB_table, paste(path, 'PB_table.csv', sep='' ), row.names = FALSE) 
}

###############################################################################

# Named vector of endpoints
endpoints <- c( "Arterial_thromb" = "Arterial thromboembolic events",
                "any_haem" =  "Haemorrhagic events",
                "itp" = "Idiopathic Thrombocytopenic Purpura",
                "itp_gen" = "Thrombocytopenic events (excluding ITP)",
                "throm_cvst" = "Venous thromboembolic events" )

# Time periods, in order we want them to appear in tables/figures
times <- c("Day 0-6", "Day 7-13", "Day 14-20", "Day 21-27","Day 28+", "Day 0-27")

countries <- c('England - RCGP', 'Scotland', 'Wales')

# Change this depending on whether main analysis, sensitivty analysis, fixed effects, random effects etc
#study <- 'case_control_'
study <- 'case_control_sensitivity_'

# This should be FE for fixed effectts, or RE for random effects
ma_type <- 'FE_RE'

study <- paste0(study, ma_type)

# These are parameters that are used in the metagen function, and also
# in tinkering with the list of value it outputs
if(ma_type == 'FE'){
  comb.fixed <- TRUE
  comb.random <- FALSE
  
  weight <- 'w.fixed'
  
  width <- 1050
  height <- 750

} else if(ma_type == 'RE'){
  comb.fixed <- FALSE
  comb.random <- TRUE
  
  weight <- 'w.random'
  
  width <- 1100
  height <- 750
} else if(ma_type == 'FE_RE'){
  comb.fixed <- TRUE
  comb.random <- TRUE
  
  weight <- 'w.fixed'
  
  width <- 1220
  height <- 800
}

path <- paste0('./output/', study, '/')

############################################################################

source('./code/case_control_analysis/01_MA_Input.R')

# Create figures output lists etc in a loop
for (i in 1:length(endpoints) ) { 
  output_list <- list()
  #i <- 1
  
  print(i)
  
  output_list$Endpoint = endpoints[[i]]
  output_list$group = names(endpoints)[i]

  analysis_objects <- create_table_ma_plot('AZ', output_list$group) 
  
  output_list$az_tab <- analysis_objects[[1]]
  output_list$az <- analysis_objects[[2]]
  
  png(paste(path, 'AZ_', output_list$group, '_fig.png', sep = ''), width = width, height = height)

  forest(output_list$az, comb.random=comb.random, comb.fixed=comb.fixed, overall=FALSE, leftcols=c("studlab"), leftlabs=c("Country"),
       label.right = "Higher Risk", label.left="Lower Risk", main="log(OR)", plotwidth = unit(8, "cm"),
       colgap=unit(3.2, "cm"), rightcols = c("effect", "ci", weight, 'w.random'),
       rightlabs = c('IRR', '95%-CI', 'Weight - fixed effect', 'Weight - random effects') )

  dev.off()
  
  analysis_objects <- create_table_ma_plot('PB', output_list$group) 
  
  output_list$pb_tab <- analysis_objects[[1]]
  output_list$pb <- analysis_objects[[2]]
  
  png(paste(path, 'PB_', output_list$group, '_fig.png', sep = ''), width = width, height = height)
  
  forest(output_list$pb, comb.random=comb.random, comb.fixed=comb.fixed, overall=FALSE, leftcols=c("studlab"), leftlabs=c("Country"),
         label.right = "Higher Risk", label.left="Lower Risk", main="log(OR)", plotwidth = unit(8, "cm"),
         colgap=unit(3.2, "cm"), rightcols = c("effect", "ci", weight, 'w.random'),
         rightlabs = c('IRR', '95%-CI', 'Weight - fixed effect', 'Weight - random effects') )
  
  dev.off()


saveRDS(output_list,paste0(path, "/ma_res_" , output_list$group, ".rds"))
}


create_pub_table()