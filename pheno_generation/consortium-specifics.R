# adjust this file to fit your consortium
g

# FUNCTION 1 --- PARAMETERS FILE

# this function should return the names of the parameters
# your end user give in their parameters files;
# don't name the following parameters, but they are required as well
# "input_file", "pc_count", "study_name", "ancestry", "refpanel",
# "analysis_date", "additional_covariables", "additional_categorical_covariables"

function get_required_parameters() {
  # TODO move this to example file and make this vector empty
  c(
    "correct_jaffe",
    "creatinine_serum_unit",
    "creatinine_urine_unit",
    "cystatin_serum_unit",
    "urate_unit",
    "calcium_unit",
    "albumin_serum_unit",
    "albumin_urine_unit",
    "phosphate_unit",
    "lod_urinary_albumin",
  )
}


# FUNCTIONS 2/3 --- REQUIREDNESS OF INPUT FILE COLUMNS

# add two functions that yield required / optional columns
# parent script will check for presence and log
# (get "parameters" list as an argument, thus can use
# parameters to make a column optional/required)

# FUNCTION 4 --- VALIDATE INTERDEPENDENT INPUT FILE COLUMNS / MISSINGNESS

# add a function that can validate the already-read-in input file
# with all required columns present and can return errors
# (esp. useful for inter-dependent columns - they should be marked optional
# and dependency checked in this function)
# (get "parameters" list as an argument)


# FUNCTION 5 --- UNIT CONVERSIONS

# unit conversions:
# function gets the whole input data set
# needs to use the parameters to determine
# which unit conversions are necessary
# needs to check for wrong parameters/unit
# returns the normalized data set
function perform_unit_normalization(input_data, parameters) {
}


# FUNCTION 6 --- CHECK QUANTITATIVE INPUT COLUMNS

# check quantitative trait summaries
# needs to return a data frame with the
# columns: trait variable name, absolute_min, absolute_max,
#  median_min, median_max 
function get_quantitative_trait_check_params(parameters) {
   data.frame(
     variable=c("age_screa" "cystc_serum"),
     absolute_min=c(0, 0),
     absolute_max=c(200, 1500),
     median_min=c(1, 35),
     median_max=c(100, 140)
  )
}


# FUNCTION 7 ---- CHECK ORDINAL INPUT COLUMNS
# FUNCTION 8 ---- CHECK CATEGORICAL INPUT COLUMNS



# FUNCTION 9 --- CALCULATE DERIVED PHENOTYPES BASED ON INPUT
# including INT, etc.
# including sex stratification (or other stratifications)


# FUNCTION 10 --- PERFORM SPECIALIZED QC
# works on all data, including normalized / derived phenotpes


# FUNCTION 11 --- PERFORM ADDITIONAL / SPECIALIZED PLOTS
# e.g., combining two phenotypes

perform_additional_plots = function(parameters, input) {
}


# FUNCTION 12 --- DETERMINE PHENOTYPES/COVARIABLES
# returns a data.frame with the following columns
# phenotype - name of the data to be used as a phenotype
# covariables - comma-separated list of quantitative covariables to use in this analysis
# catCovariables - comma-separated list of categorical covariables to use in this analysis
# "colon notation" - PC{1:40} ok for covariables

#phenotype          covariables   catCovariables
#egfr_creat_female  age,PC{1:40}  studycenter
#egfr_creat_int     age,PC{1:40}  sex,studycenter


determine_phenotypes_covariables = function(parameters, input) {
}
