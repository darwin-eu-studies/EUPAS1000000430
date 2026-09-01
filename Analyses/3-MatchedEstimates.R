# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

info(logger, "STARTING MATCHED ESTIMATES")

info(logger, "- Defining parameters")
results <- list()

info(logger, "- Summarising characteristics of the matched cohorts") 
for(type in covariates){
  info(logger, paste0("- Add ",type))
  
  for(w in names(window)){
    info(logger, paste0("- Add window ",w))
    ww <- gsub("[ -]", "_", w)
    
    results[[paste0("cohort_summary_", type, "_window_", ww)]] <- cdm[[matchedCohortTable]]|>
      summariseCovariateCharacteristics(type, window = setNames(list(window[[w]]), w)) |>
      splitAdditional() |>
      mutate(covariate_group = if_else(str_detect(pattern = str_to_sentence(type), variable_name), str_to_sentence(type), "Baseline characteristics")) |>
      uniteAdditional(c("window", "value", "covariate_group"), keep = FALSE) |>
      select(-c("table")) 
  }
}

info(logger, "- Running large scale characteristics")
results[["lsc"]] <- CohortCharacteristics::summariseLargeScaleCharacteristics(
  strata = c("age_group","sex"),
  cohort = cdm[[matchedCohortTable]],
  window = window,
  eventInWindow = c("condition_occurrence", "visit_occurrence",
                    "measurement", "procedure_occurrence",
                    "observation"),
  episodeInWindow = c("drug_exposure"),
  minimumFrequency = 0.0005,
  includeSource = TRUE
)

info(logger, "- Binding results")
results <- results |>
  omopgenerics::bind()

info(logger, "- Exporting summarised result")
results |> 
  exportSummarisedResult(minCellCount = minCellCount, 
                         fileName = "{cdm_name}_matched_estimates.csv", 
                         path = resultsFolder)

info(logger, "- FINISHED MATCHED ESTIMATES")
