# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

# create logger ----
resultsFolder <- here("Results")
if(!dir.exists(resultsFolder)){
  dir.create(resultsFolder)
}
loggerName <- gsub(":| |-", "", paste0("log_", Sys.Date(),".txt"))
logger <- create.logger()
logfile(logger) <- here(resultsFolder, loggerName)
level(logger) <- "INFO"
info(logger, "LOG CREATED")

# Defining variables ----
covariates <- c("measurements", "treatments", "comorbidities", "procedures")
age_group <- list("18 to 29" = c(18, 29), 
                  "30 to 39" = c(30, 39),
                  "40 to 49" = c(40, 49),
                  "50 to 59" = c(50, 59),
                  "60 to 69" = c(60, 69),
                  "70 to 79" = c(70, 79),
                  ">=80"     = c(80, 150))

window <- list("-Inf to -1"  = c(-Inf, -1),
               "-Inf to -5y" = c(-Inf, -1825),
               "-5y to -3y"  = c(-1824, -1095),
               "-3y to -1y"  = c(-1094, -365),
               "-364 to -181" = c(-364, -181),
               "-180 to -91"  = c(-180, -91),
               "-90 to -1" = c(-90, -1),
               "0" = c(0,0),
               "1 to 90"   = c(1, 90),
               "91 to 180" = c(91, 180),
               "181 to 364" = c(181, 364),
               "1y to 3y"  = c(365, 1094),
               "3y to 5y"  = c(1095, 1824),
               "5y to Inf" = c(1824, Inf))

# instantiate necessary cohorts ----
info(logger, "INSTANTIATING STUDY COHORTS")
source(here("Analyses","Functions.R"))
source(here("Cohorts", "InstantiateCohorts.R"))
info(logger, "STUDY COHORTS INSTANTIATED")

# run analyses ----
info(logger, "RUN ANALYSES")
cohortName <- "hcm_study"
source(here("Analyses", "0-StudyDatabases.R"))
source(here("Analyses", "1-StudyCohorts.R"))
source(here("Analyses", "2-PopulationEstimates.R"))
source(here("Analyses", "3-MatchedEstimates.R"))
info(logger, "ANALYSES FINISHED")

# export results ----
info(logger, "EXPORTING RESULTS")
zip(
  zipfile = file.path(paste0(resultsFolder, "/Results_", cdmName(cdm), ".zip")),
  files = list.files(resultsFolder, full.names = TRUE)
)
