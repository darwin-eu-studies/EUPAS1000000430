# **License:**
#   
#   This software is distributed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# For more information about DARWIN EU<sup>®</sup> see [www.darwin-eu.org](https://www.darwin-eu.org).
# 
# Copyright 2026 European Medicines Agency. 

info(logger, "- Read Excel file")
data <- read_csv(here("Cohorts","HCM_CGsearch.csv")) 

info(logger, "- Get HCM codelist")
codelist <- list()
for(name in c("narrow", "obstructive", "non_obstructive")){
  codelist[[paste0("hcm_",name)]] <- data |> 
    filter(.data[[name]]) |>
    pull(concept_id)
}

info(logger, "- Instantiate HCM cohort")
info(logger, "  Creating HCM study outcome cohort")
cdm[["hcm_study_outcome"]] <- conceptCohort(cdm,
                                    conceptSet = codelist,
                                    exit = "event_start_date",
                                    name = "hcm_study_outcome") |>
  requireIsFirstEntry() |>
  exitAtObservationEnd()

info(logger, "  Creating HCM study cohort")
cdm[["hcm_study"]] <- cdm[["hcm_study_outcome"]] |>
  compute(temporary = FALSE, name = "hcm_study")

info(logger, "  Removing participants with concepts while they were not in observation")
cdm[["hcm_study"]] <- cdm[["hcm_study"]] |>
  requireConceptIntersect(
    conceptSet = codelist["hcm_narrow"],
    window = c(-Inf, -1),
    intersections = 0,
    indexDate = "cohort_start_date",
    targetStartDate = "event_start_date",
    targetEndDate = "event_end_date",
    inObservation = FALSE,
    censorDate = NULL,
    name = "hcm_study"
  )

info(logger, "  Adding additional restrictions")
cdm[["hcm_study"]] <- cdm[["hcm_study"]] |>
  requirePriorObservation(minPriorObservation = 365, 
                          cohortId = NULL, 
                          indexDate = "cohort_start_date") |>
  requireAge(ageRange = c(18, 150)) |>
  requireInDateRange(dateRange = c(as.Date("2010-01-01"),NA))

info(logger, "  Removing HCM empty cohorts")
hcm_study_cohort_names <- cdm[["hcm_study"]] |>
  cohortCount() |>
  filter(number_subjects != 0) |>
  pull("cohort_definition_id")
hcm_study_cohort_names <- gsub("hcm_","",as.character(getCohortName(cohort = cdm$hcm_study, hcm_study_cohort_names)))

info(logger, "- Creating denominator table")
cdm <- IncidencePrevalence::generateDenominatorCohortSet(
  cdm  = cdm,
  name = "denominator",
  ageGroup = append(age_group, list("18 to 150" = c(18, 150))),
  sex = c("Both", "Male", "Female"),
  daysPriorObservation = 365,
  requirementInteractions = TRUE, 
  cohortDateRange = c(as.Date("2010-01-01"),NA)
)

info(logger, "  Adding indexes to the denominator cohort")
cdm[["denominator"]] <- cdm[["denominator"]] |>
  addCohortTableIndex()

info(logger, "  Extracting records of HCM from condition table")
cdm[["hcm_condition_records"]] <- cdm[["condition_occurrence"]] |>
  filter(condition_concept_id %in% !!codelist[["hcm_narrow"]]) |>
  compute(temporary = FALSE, name = "hcm_condition_records")

info(logger, "  Keeping records recorded while not in observation")
cdm[["hcm_condition_records"]] <- cdm[["hcm_condition_records"]] |>
  select("subject_id" = "person_id", "condition_concept_id", "condition_start_date", "condition_end_date") |>
  addInObservation(indexDate = "condition_start_date", nameStyle = "in_observation") |>
  filter(in_observation == 0) |>
  select("subject_id") |>
  distinct() |> 
  compute(temporary = FALSE, name = "hcm_condition_records")

info(logger, "  Removing participants with records while not in observation")
cdm[["denominator"]] <- cdm[["denominator"]] |>
  anti_join(
    cdm[["hcm_condition_records"]],
    by = "subject_id"
  ) |>
  compute(temporary = FALSE, name = "denominator")


info(logger, "- Creating matched cohort table")
matchedCohortTable <- paste0(omopgenerics::tableName(cdm[["hcm_study"]]),
                             "_matched")
cdm[[matchedCohortTable]] <- cdm[["hcm_study"]] |>
  dplyr::compute(name = matchedCohortTable, temporary = FALSE)

info(logger, "- Generating a age and sex matched cohorts") 
cdm[[matchedCohortTable]] <- CohortConstructor::matchCohorts(cdm[[matchedCohortTable]],
                                                             name = matchedCohortTable)
cdm[[matchedCohortTable]]  <- cdm[[matchedCohortTable]] |>
  PatientProfiles::addDemographics(age = TRUE,
                                   ageGroup = age_group,
                                   sex = TRUE,
                                   priorObservation = FALSE,
                                   futureObservation = FALSE,
                                   dateOfBirth = FALSE,
                                   name = matchedCohortTable)

info(logger, "- Instantiate comorbidities, measurements and procedures cohorts")
for(type in covariates[covariates != "treatments"]){
  info(logger, paste0("  Getting ",type, " codelist"))
  
  codelist <- list()
  codes <- read_csv(here("Cohorts",paste0(type,"_codelist.csv"))) 
  cohort_name_list <- codes$cohort_name |> unique()
  
  for(i in cohort_name_list){
    # Get codelist
    subtable_included <- codes |> filter(cohort_name == i, keep == TRUE)
    subtable_excluded <- codes |> filter(cohort_name == i, keep == FALSE)
    
    concept_table <- getDescendants(cdm, conceptId = as.numeric(subtable_included$code))
    
    to_lower_i    <- gsub(" ","_",str_to_lower(i))
    codelist[[to_lower_i]] <- as.numeric(unique(c(subtable_included$code, concept_table$concept_id)))
    codelist[[to_lower_i]] <- codelist[[to_lower_i]][!codelist[[to_lower_i]] %in% subtable_excluded$code & !is.na(codelist[[to_lower_i]])]
  }
  
  name <- str_to_lower(type)
  
  info(logger, paste0("  Intantiating ",type, " cohort"))
  cdm[[name]] <- cdm |>
    CohortConstructor::conceptCohort(
      subsetCohort = matchedCohortTable,
      conceptSet = codelist,
      exit = "event_start_date",
      name = name)
}

info(logger, "- Intanciate treatments cohort")
codelist <- list()
codes <- read_csv(here("Cohorts","treatments_codelist.csv"))

for(i in codes$`CONCEPT_ID`){
  
  concept_name  <- codes$CONCEPT_NAME[codes$CONCEPT_ID == i]
  concept_table <- getDescendants(cdm, conceptId = i)
  
  codelist[[gsub(" ","_",str_to_lower(concept_name))]] <- concept_table$concept_id
  
  if(concept_name == "Heparin group"){
    codelist[[gsub(" ","_",str_to_lower(concept_name))]] <- append(codelist[[gsub(" ","_",str_to_lower(concept_name))]],
                                                                   1301025)
  }
}

cdm[["treatments"]] <- cdm |>
  CohortConstructor::conceptCohort(
    subsetCohort = matchedCohortTable,
    conceptSet = codelist,
    exit = "event_end_date",
    name = "treatments")

cdm[["treatments"]] <- cdm[["treatments"]] |>
  collapseCohorts(cohortId = NULL, gap = 90)



