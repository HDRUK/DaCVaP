######################################################################
## Title: Meta-analysis of first dose ChAdOx1 and BNT162b2 COVID-19 vaccinations and thrombocytopenic, venous thromboembolic
##        and haemorrhagic events in the UK
##
## Short title: Vaccine safety meta-analysis
##
## Code author: Chris Robertson, Steven Kerr
##
## Description: This does the meta analysis for the SCCS using estimated odds ratios for adverse events
##              following vaccination from each country
######################################################################

library(readxl)
library(tidyverse)
library(meta)

source('./code/sccs_analysis/01_MA_Input.R')

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

vacc <- 'AZ'
event <- 'any_haem'

# Create individual table + meta-analysis for a given vaccine and event
create_ma_plot <- function(vacc, event){
  
  df <- filter(df, vaccine_type == vacc, group == event, `Time period` %in% c('Clearance', 'Risk'))
  
  df <- df[order(df$country),]
  
  ma <- metagen(TE=df$log_OR, seTE=df$se_log_OR, studlab=df$country, byvar= pull(df, 'Time period'),
                backtransf=TRUE, sm="RR", comb.fixed=comb.fixed, comb.random = comb.random,
                bylab = 'Time period')
  
  df$raw_weights <- ma[[weight]]
  
  df <- group_by(df, `Time period`) %>% mutate( norm_weights = raw_weights/sum(raw_weights) )
  
  df <- filter(df, norm_weights > 10**-5)
  
  ma <- metagen(TE=df$log_OR, seTE=df$se_log_OR, studlab=df$country, byvar= pull(df, 'Time period'),
                backtransf=TRUE, sm="RR", comb.fixed=comb.fixed, comb.random = comb.random,
                bylab = 'Time period')
  
  return(ma)
}

###############################################################################

# Named vector of endpoints
endpoints <- c( "Arterial_thromb" = "Arterial thromboembolic events",
                "any_haem" =  "Haemorrhagic events",
                "itp" = "Idiopathic Thrombocytopenic Purpura",
                "itp_gen" = "Thrombocytopenic events (excluding ITP)",
                "throm_cvst" = "Venous thromboembolic events" )

study <- 'SCCS_'

ma_type <- 'FE_RE'

study <- paste0(study, ma_type)

# These are parameters that are used in the metagen function, and also
# in tinkering with the list of value it outputs
if(ma_type == 'FE'){
  comb.fixed <- TRUE
  comb.random <- FALSE
  
  weight <- 'w.fixed'
  
  width <- 1100
  height <- 350
  
} else if(ma_type == 'RE'){
  comb.fixed <- FALSE
  comb.random <- TRUE
  
  weight <- 'w.random'
  
  width <- 1100
  height <- 350

} else if(ma_type == 'FE_RE'){
  comb.fixed <- TRUE
  comb.random <- TRUE
  
  weight <- 'w.fixed'
  
  width <- 1220
  height <- 350

}

path <- paste0('./output/', study, '/')

############################################################################

# Create figures output lists etc in a loop
for (i in 1:length(endpoints) ) { 
  output_list <- list()
  #i <- 1

  output_list$Endpoint = endpoints[[i]]
  output_list$group = names(endpoints)[i]
  
  output_list$az <- create_ma_plot('AZ', output_list$group)
  
  png(paste(path, 'AZ_', output_list$group, '_fig.png', sep = ''), width = width, height = height)
  
  forest(output_list$az, comb.random=comb.random, comb.fixed=comb.fixed, overall=FALSE, leftcols=c("studlab"), leftlabs=c("Country"),
         label.right = "Higher Risk", label.left="Lower Risk", main="log(OR)", plotwidth = unit(8, "cm"),
         colgap=unit(3.25, "cm"), rightcols = c("effect", "ci", weight, 'w.random'),
         rightlabs = c('IRR', '95% CI', 'Weight - fixed effect', 'Weight - random effects') )
  
  
  dev.off()

  output_list$pb <- create_ma_plot('PB', output_list$group) 
  
  png(paste(path, 'PB_', output_list$group, '_fig.png', sep = ''), width = width, height = height)
  
  forest(output_list$pb, comb.random=comb.random, comb.fixed=comb.fixed, overall=FALSE, leftcols=c("studlab"), leftlabs=c("Country"),
         label.right = "Higher Risk", label.left="Lower Risk", main="log(OR)", plotwidth = unit(8, "cm"),
         colgap=unit(3.25, "cm"), rightcols = c("effect", "ci", weight, 'w.random'),
         rightlabs = c('IRR', '95% CI', 'Weight - fixed effect', 'Weight - random effects') )
  
  
  dev.off()
  
  saveRDS(output_list,paste0(path, "/ma_res_" , output_list$group, ".rds"))
}


