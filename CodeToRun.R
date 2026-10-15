# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

renv::activate()
renv::restore()

library(CDMConnector)
library(DBI)
library(log4r)
library(dplyr)
library(here)
library(OmopSketch)
library(omopgenerics)
library(CohortConstructor)
library(PhenotypeR)
library(CohortCharacteristics)
library(PatientProfiles)
library(visOmopResults)
library(stringr)
library(CodelistGenerator)
library(odbc)
library(RPostgres)
library(readr)

# database metadata and connection details
# The name/ acronym for the database
dbName <- "..." # DK-DHR or InGef or NAJS or NLHR or SIDIAP

# Database connection details
# In this study we also use the DBI package to connect to the database
# set up the dbConnect details below
# https://darwin-eu.github.io/CDMConnector/articles/DBI_connection_examples.html 
# for more details.
# you may need to install another package for this 
# eg for postgres 
# db <- dbConnect(
#   RPostgres::Postgres(), 
#   dbname = server_dbi, 
#   port = port, 
#   host = host, 
#   user = user,
#   password = password
# )
db <- dbConnect(...)

# The name of the schema that contains the OMOP CDM with patient-level data
cdmSchema <- "..."

# A prefix for all permanent tables in the database
writePrefix <- "..."

# The name of the schema where results tables will be created 
writeSchema <- "..."

# minimum counts that can be displayed according to data governance
minCellCount <- 5

# Create cdm object ----
cdm <- cdmFromCon(
  con = db,
  cdmSchema = cdmSchema, 
  writeSchema = writeSchema, 
  writePrefix = writePrefix,
  cdmName = dbName
)


# Restrict to first observation period
cdm$observation_period <-  cdm$observation_period |>
  addObservationPeriodId(
    indexDate = "observation_period_start_date",
    nameObservationPeriodId = "observation_period_num",
    name = NULL
  ) |>
  filter(observation_period_num == 1) |>
  select(-"observation_period_num") |>
  compute(temporary = FALSE, name = "observation_period")

# Run the study
source(here("RunStudy.R"))

# after the study is run you should have a zip folder in your output folder to share
cli::cli_alert_success("Study finished")
