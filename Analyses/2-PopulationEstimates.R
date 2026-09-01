# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

info(logger, "STARTING POPULATION ESTIMATES")

info(logger, "- Defining parameters")
results <- list()

info(logger, "- Estimating incidence")
results[["incidence"]] <- IncidencePrevalence::estimateIncidence(
  cdm = cdm,
  denominatorTable = "denominator",
  outcomeTable = "hcm_study_outcome",
  interval = c("years"),
  repeatedEvents = FALSE,
  outcomeWashout = Inf,
  completeDatabaseIntervals = FALSE)

info(logger, "- Estimating period prevalence")
results[["prevalence"]] <- IncidencePrevalence::estimatePeriodPrevalence(
  cdm = cdm,
  denominatorTable = "denominator",
  outcomeTable = "hcm_study_outcome",
  interval = "years",
  completeDatabaseIntervals = TRUE,
  fullContribution = FALSE)

info(logger, "- Estimating point prevalence")
results[["point_prevalence"]] <- IncidencePrevalence::estimatePointPrevalence(
  cdm = cdm,
  denominatorTable = "denominator",
  outcomeTable = "hcm_study_outcome",
  interval = "years",
  timePoint = "start")

info(logger, "- Binding results")
results <- results |>
  omopgenerics::bind()

info(logger, "- Exporting results")
results |>
  exportSummarisedResult(minCellCount = minCellCount, 
                         fileName = "{cdm_name}_population_estimates.csv", 
                         path = resultsFolder)

info(logger, "FINISHED POPULATION ESTIMATES")
