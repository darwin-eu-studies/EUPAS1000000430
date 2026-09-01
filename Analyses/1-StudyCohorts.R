# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

info(logger, "STARTING STUDY COHORTS")

info(logger, "- Defining parameters")
prefix <- omopgenerics::tmpPrefix()
tempCohortName  <- paste0(prefix, cohortName)
results <- list()

info(logger, "- Adding age and sex to the study cohort")
cdm[[tempCohortName]]  <- cdm[[cohortName]] |>
  PatientProfiles::addDemographics(age = TRUE,
                                   ageGroup = age_group,
                                   sex = TRUE,
                                   priorObservation = FALSE,
                                   futureObservation = FALSE,
                                   dateOfBirth = FALSE,
                                   name = tempCohortName)

info(logger, "- Getting cohort summary")
for(type in covariates){
  info(logger, paste0("- Add ",type))
  
  for(w in names(window)){
    info(logger, paste0("- Add window ",w))
    ww <- gsub("[ -]", "_", w)
    
    results[[paste0("cohort_summary_", type, "_window_", ww)]] <- cdm[[tempCohortName]] |>
      summariseCovariateCharacteristics(type, window = setNames(list(window[[w]]), w)) |>
      splitAdditional() |>
      mutate(covariate_group = if_else(str_detect(pattern = str_to_sentence(type), variable_name), str_to_sentence(type), "Baseline characteristics")) |>
      uniteAdditional(c("window", "value", "covariate_group", "table"), keep = FALSE) 
  }
}

info(logger, "- Removing temporal tables")
omopgenerics::dropTable(cdm, dplyr::starts_with(prefix))

info(logger, "- Getting cohort attrition")
results[["cohort_attrition"]] <- cdm[[cohortName]] |>
  CohortCharacteristics::summariseCohortAttrition()

info(logger, "- Getting cohort overlap")
results[["cohort_overlap"]] <-  cdm[[cohortName]] |>
  CohortCharacteristics::summariseCohortOverlap()

info(logger, "- Binding results")
results <- results |>
  omopgenerics::bind()


info(logger, "- Export cohort diagnostics")
results |>
  exportSummarisedResult(minCellCount = minCellCount, 
                         fileName = "{cdm_name}_study_cohorts.csv", 
                         path = resultsFolder)

info(logger, "FINISH STUDY COHORTS")