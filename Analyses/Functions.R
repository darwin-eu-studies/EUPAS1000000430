# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

summariseCovariateCharacteristics <- function(x, targetCohortTable, window){
  
  x <- x |> 
    mutate(diagnose_year = clock::get_year(cohort_start_date)) |>
    mutate(diagnose_year = if_else(diagnose_year < 2020, "< 2020", ">= 2020"))
    
  if(names(window) %in% c("-Inf to -1", "-Inf to -5y", "-5y to -3y", "-3y to -1y", 
                          "-364 to -181", "-180 to -91", "-90 to -1")){
    summariseCharacteristics(x,
                             strata = list("age_group", "sex", "diagnose_year"),
                             cohortIntersectFlag = list(targetCohortTable = targetCohortTable,
                                                        targetCohortId = NULL,
                                                        indexDate  = "cohort_start_date",
                                                        censorDate = NULL,
                                                        targetStartDate = "cohort_start_date",
                                                        targetEndDate   = "cohort_end_date",
                                                        window = window),
                             cohortIntersectDays = list(targetCohortTable = targetCohortTable,
                                                        targetCohortId = NULL, 
                                                        indexDate = "cohort_start_date",
                                                        censorDate = NULL,
                                                        targetDate = "cohort_start_date",
                                                        order = "first",
                                                        window = window))
  }else{
    summariseCharacteristics(x,
                             strata = list("age_group", "sex", "diagnose_year"),
                             cohortIntersectFlag = list(targetCohortTable = targetCohortTable,
                                                        targetCohortId = NULL,
                                                        indexDate  = "cohort_start_date",
                                                        censorDate = NULL,
                                                        targetStartDate = "cohort_start_date",
                                                        targetEndDate   = "cohort_end_date",
                                                        window = window)
    )
  }
}

getConceptIdColumnName <- function(table_name){
  case_when(
    table_name == "condition_occurrence" ~ "condition_concept_id",
    table_name == "measurement" ~ "measurement_concept_id",
    table_name == "procedure_occurrence" ~ "procedure_concept_id",
    table_name == "observation" ~ "observation_concept_id",
    table_name == "drug_exposure" ~ "drug_concept_id"
  )
}

getSourceConceptIdColumnName <- function(table_name){
  case_when(
    table_name == "condition_occurrence" ~ "condition_source_concept_id",
    table_name == "measurement" ~ "measurement_source_concept_id",
    table_name == "procedure_occurrence" ~ "procedure_source_concept_id",
    table_name == "observation" ~ "observation_source_concept_id",
    table_name == "drug_exposure" ~ "drug_source_concept_id"
  )
}

getSourceConceptNameColumnName <- function(table_name){
  case_when(
    table_name == "condition_occurrence" ~ "condition_source_concept_name",
    table_name == "measurement" ~ "measurement_source_concept_name",
    table_name == "procedure_occurrence" ~ "procedure_source_concept_name",
    table_name == "observation" ~ "observation_source_concept_name",
    table_name == "drug_exposure" ~ "drug_source_concept_name"
  )
}