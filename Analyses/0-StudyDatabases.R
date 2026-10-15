# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

info(logger, "- RUN STUDY DATABASES AND CODELIST")

result <- list()
result[["snapshot"]] <- summariseOmopSnapshot(cdm)

codelist <- list()
data     <- read_csv(here("Cohorts","HCM_CGsearch.csv")) 
for(name in hcm_study_cohort_names){
  codelist[[paste0("hcm_",name)]] <- data |> 
    filter(.data[[name]]) |>
    pull(concept_id)
  
  id <- getCohortId(cohort = cdm[[cohortName]],
                    cohortName = paste0("hcm_",name))
  
  result[[paste0("cohort_code_use_hcm_", name)]] <- summariseCohortCodeUse(x = codelist[paste0("hcm_",name)],
                                                                           cdm = cdm,
                                                                           cohortTable = cohortName,
                                                                           cohortId = id,
                                                                           timing = "entry",
                                                                           countBy = c("record", "person"),
                                                                           byConcept = TRUE,
                                                                           byYear = FALSE,
                                                                           bySex  = FALSE,
                                                                           ageGroup = NULL)
}

result <- bind(result)

omopgenerics::exportSummarisedResult(result, fileName = "{cdm_name}_database_and_codelist.csv", path = resultsFolder)
info(logger, "- FINISH STUDY DATABASES AND CODELIST")

