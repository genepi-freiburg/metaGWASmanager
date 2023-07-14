# adjust this file to fit your consortium


# FUNCTION 1 --- PARAMETERS FILE
# this function should return the names of the parameters
# your end user give in their parameters files;
# don't name the following parameters, but they are required as well
# "input_file", "pc_count", "study_name", "ancestry", "refpanel",
# "analysis_date", "additional_covariables", "additional_categorical_covariables"

get_required_parameters<- function (parameters) {
  # TODO move this to example file and make this vector empty
  required_parameters<- c( "cadmium_urine_unit",  "selenium_urine_unit", "arsenic_urine_unit", "cadmium_plasma_unit",  "selenium_plasma_unit","arsenic_plasma_unit", 
    "cadmium_urine_lod", "selenium_urine_lod", "arsenic_urine_lod",  "cadmium_plasma_lod", "selenium_plasma_lod" ,"arsenic_plasma_lod",
    "urine_metals_available", "blood_metals_available", "plasma_metals_available")
  
  if (parameters$value[parameters$key== "urine_metals_available"]=="yes") {
    required_parameters <- c(required_parameters, 
                             "creatinine_urine_unit","specific_gravity_unit")
  }
  
  if (parameters$value[parameters$key== "plasma_metals_available"]=="yes") {
    required_parameters <- c(required_parameters,   "plasma_or_serum")
  }
}


# FUNCTIONS 2/3 --- REQUIREDNESS OF INPUT FILE COLUMNS
# add two functions that yield required / optional columns
# parent script will check for presence and log
# (get "parameters" list as an argument, thus can use 
# parameters to make a column optional/required)

#A. Required columns function
get_required_columns<- function (parameters_list) {
  #don't name "FID", "IID", "sex". They're in the parent script
  required_columns<-c()
  if (parameters_list$urine_metals_available=="yes") {
    required_columns <- c(required_columns,   
                          "age_urinemetal","smoking_urinemetal", "egfr_urinemetal", "bmi_urinemetal","creatinine_urine")
  }
  
  if (parameters_list$blood_metals_available=="yes") {
    required_columns <- c(required_columns,   
                          "age_bloodmetal", "smoking_bloodmetal", "egfr_bloodmetal", "bmi_bloodmetal")
  }
  
  if (parameters_list$plasma_metals_available=="yes") {
    required_columns <- c(required_columns,   
                          "age_plasmametal", "smoking_plasmametal", "egfr_plasmametal","bmi_plasmametal")
  }
  
}


#B. optional columns function
get_optional_columns<- function () {
  urine_metals<- c ("cadmium_urine", "selenium_urine", "arsenic_urine")
  blood_metals <- c ()
  plasma_metals<- c ("cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  
  optional_columns<- c(urine_metals, blood_metals, plasma_metals) 
}




# FUNCTION 4 --- UNIT CONVERSIONS
# unit conversions:
# function gets the whole input data set
# needs to use the parameters to determine
# which unit conversions are necessary
# needs to check for wrong parameters/unit
# returns the normalized data set

perform_unit_normalization <- function (input, parameters_list) {
  #metals variable  
  optional.variables <- optional_columns[optional_columns %in% names(input)]
  for(variable in optional.variables){
    # -1 = "not provided unit"; 0 = ug/l; 1 =ug/dl
    unit.name = paste0(variable, "_unit")
    if (length(!is.na(input[, variable])) > 0 & parameters_list[unit.name] == -1) {
      stop(paste0( variable, " in input file, but units not given in parameter file."))
    } 
    
    if (length(!is.na(input[, variable])) > 0 & parameters_list[unit.name] == 1) {
      input[, variable] <- input[, variable]*10  #conversion from ug/dl to ug/l
    }
  }
  
  #other variables
  other.variables<- c ("creatinine_urine")
  for (variable in other.variables) {
    #0 = g/l, 1 = mg/dl, give -1 if you do not have
    unit.name = paste0(variable, "_unit")
    if (length(!is.na(input[, variable])) > 0 & parameters_list[unit.name] == -1) {
      stop(paste0( variable, " in input file, but units not given in parameter file."))
    } 
    
    if (length(!is.na(input[, variable])) > 0 & parameters_list[unit.name] == 1) {
      input[, variable] <- input[, variable]/100  #conversion from mg/dl to g/l
    }
  }
  return(input)  
}


# FUNCTION 5 --- CHECK QUANTITATIVE INPUT COLUMNS

# check quantitative trait summaries
# needs to return a data frame with the
# columns: trait variable name, absolute_min, absolute_max,
#  median_min, median_max 

#Function 5A. Get a vector with the quantitative  variables
get_quantitative_variables <- function() {
  quant_vec1 <- c("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  quant_vec2 <- c("creatinine_urine")
  quant_vec3 <- c("age_urinemetal", "age_plasmametal")
  quant_vec4<- c("egfr_urinemetal", "egfr_plasmametal")
  quant_vec5<- c("bmi_urinemetal", "bmi_plasmametal")
  quant_vec6<- c("seafood_intake")
  
  c(quant_vec1, quant_vec2, quant_vec3, quant_vec4, quant_vec5, quant_vec6)
}
 
 
#Function 5b. Get a db with the reference parameter of the quantitative  variables
get_quantitative_trait_check_params <- function(variable, input) {
  #Define vectors
  quant_vec1 <- c("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  quant_vec2 <- c("creatinine_urine")
  quant_vec3 <- c("age_urinemetal", "age_plasmametal")
  quant_vec4<- c("egfr_urinemetal", "egfr_plasmametal")
  quant_vec5<- c("bmi_urinemetal", "bmi_plasmametal")
  quant_vec6<- c("seafood_intake")
  
  #parameters creation
  absolute_min <- NA
  absolute_max <- NA
  median_min <- NA
  median_max <- NA
  
  # Check type of variable
  if (variable %in% quant_vec1) {
    mean <- mean(input[ , variable], na.rm = T)
    sd <- sd(input[ , variable], na.rm = T)
    absolute_min <- 0
    absolute_max <- mean+3*sd
    median_min <- 0
    median_max <- mean+3*sd
  } else if (variable %in% quant_vec2) {
    absolute_min <- 0
    absolute_max <- 100000 
    median_min <- 0
    median_max <- 2000
  }  else if (variable %in% quant_vec3) {
    absolute_min <- 0
    absolute_max <- 200 
    median_min <- 1
    median_max <- 100
  }  else if (variable %in% quant_vec4) {  
    absolute_min <- 0
    absolute_max <- 160 
    median_min <- 60
    median_max <- 120
  }  else if (variable %in% quant_vec5) {
    absolute_min <- 12
    absolute_max <- 50 
    median_min <- 18
    median_max <- 30
  } else if (variable %in% quant_vec6) {
    absolute_min <- 0
    absolute_max <- 5000 
    median_min <- 10
    median_max <- 120
  } 

  # df creation
  quantitative_param <- data.frame(variable = variable,
                          absolute_min = absolute_min,
                          absolute_max = absolute_max,
                          median_min = median_min,
                          median_max = median_max)
  return(quantitative_param)
}
  
 
# FUNCTION 6 ---- CHECK ORDINAL INPUT COLUMNS


# FUNCTION 7 ---- CHECK CATEGORICAL INPUT COLUMNS
#Function 7A. Get a vector with the categorical  variables
get_categorical_variables <- function() {
  c("sex", "smoking_urinemetal", "smoking_bloodmetal", "smoking_plasmametal")
}


#Function 7b. Get a db with the reference parameter of the categorical  variables
get_categorical_trait_check_params <- function(variable) {
  #Define vectors categories
  cat_vec1 <- c("sex")
  cat_vec2 <- c("smoking_urinemetal", "smoking_bloodmetal", "smoking_plasmametal")

  categories <- c()
  # Check type of variable
  if (variable %in% cat_vec1) {
    categories <- c("M", "F")
  } else if (variable %in% cat_vec2) {
    categories <- c("N", "F", "C")
  } 
  
  # df creation
  categorical_param <- data.frame(variable = variable,
                                  categories = paste(categories, collapse = ", "))
  return(categorical_param)
}


# FUNCTION 8 --- IMPUTE VALUES BELOW LOD   [LOD/sqrt(2)]
# 8A. Get vector with the name of variables to impute
get_variables_to_impute <- function() {
  c("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
}

# 8B. Create the inputation function
imputation<- function(var.to.impute, parameters_list, result) {
  for(variable in var.to.impute){
    lod.name <- paste0(variable, "_lod")
    lod <- as.numeric(parameters_list[lod.name])
    result[, variable] <- ifelse(result[, variable] < lod, lod/sqrt(2), result[, variable])
  }
  return(result)
}


# FUNCTION 9 --- CALCULATE DERIVED PHENOTYPES BASED ON INPUT
# including INT, etc.
# including sex stratification (or other stratifications)

calculate_derived_phenotypes <- function(result) {
  #vectors
  log2_phenos<- c ("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  int_phenos<- c ()
  vars.to.sex.strat<- c ("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  var.smoke.strat <- c ("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  
  for (colname in colnames(result)) {
    #log2 transformation
    if (colname %in% log2_phenos) {
      #Check if there are 0s ¡be careful wit Nas
      result[, colname] <- ifelse(result[, colname] == 0, result[, colname] + 0.00001, result[, colname])
      #apply transformation
      result[, colname] <- log2(result[, colname])
    }
    
    #Inverse normal transformation
    if (colname %in% int_phenos) {
      result[, colname]<- qnorm((rank(result[, colname], na.last = "keep", ties.method = "random") - 0.5) / sum(!is.na(result[, colname])))
    }
    
    
    #Sex stratification
    if (colname %in% vars.to.sex.strat){
      col.male <- paste0(colname, "_male")
      col.female <- paste0(colname, "_female")
      result[, col.male] <- ifelse(result$sex == "M", result[, colname], NA)
      result[, col.female] <- ifelse(result$sex == "F", result[, colname], NA)
    }
    
    #Smoking status stratification (Never smoker)
    if (colname %in% var.smoke.strat){
      col.neversmk <- paste0(colname, "_neversmk")
      result[, col.neversmk] <- ifelse(result$smoking_urinemetal == "N", result[, colname], NA)
    }
  }
  return(result)
}


# FUNCTIONS 10 --- PERFORM SPECIALIZED QC
# works on all data, including normalized / derived phenotpes

#Function 10.a. vector with unrelevant variable
get_unrelevant_cols<- function () {
 c("sex_0_female_1_male") 
}

#Function 10.b. vector with binary variable
get_binary_cols<- function() {
  c("sex")
}

#Function 10.c. vector with number of minmum cases to study the variable
get_number_cases<- function() {
  c(500)
}

#Function 10.d. vector with categorical variables
get_cat_cols<- function() {
  c("smoking_urinemetal", "smoking_plasmametal")
}

#Function 10.e. Create a vector with the age_variable (names of this vector are the specific variables)
get_age_for_phenotype<- function() {
  urine_metals<- c ("cadmium_urine", "selenium_urine", "arsenic_urine")
  blood_metals <- c ()
  plasma_metals<- c ("cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  all_metals <- c(urine_metals, blood_metals, plasma_metals)
  
  age_vector <- rep(c("age_urinemetal", "age_bloodmetal", "age_plasmametal"), times = c(length(urine_metals), length(blood_metals), length(plasma_metals)))
  names(age_vector)<- all_metals
  return(age_vector)

}
  

# FUNCTION 11 --- PERFORM ADDITIONAL / SPECIALIZED PLOTS
# e.g., combining two phenotypes

perform_additional_plots <- function(parameters, input) {
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

determine_phenotypes_covariables <- function(parameters_list) {
  phenotype1<- c("cadmium_urine", "cadmium_urine_female", "cadmium_urine_male", 
                "selenium_urine", "selenium_urine_female", "selenium_urine_male",
                "arsenic_urine", "arsenic_urine_female", "arsenic_urine_male")
  
  phenotype2<- c("cadmium_plasma", "cadmium_plasma_female", "cadmium_plasma_male",
                 "selenium_plasma", "selenium_plasma_female", "selenium_plasma_male",
                 "arsenic_plasma", "arsenic_plasma_female", "arsenic_plasma_male")
  
  quant_covariables1<- c("age_urinemetal", "bmi_urinemetal", "egfr_urinemetal",
                         paste0("PC", 1:parameters_list$pc_count))
  
  quant_covariables2<- c("age_plasmametal", "bmi_plasmametal", "egfr_plasmametal",
                         paste0("PC", 1:parameters_list$pc_count))
  
  cat_covariables1<- c("smoking_urinemetal")
  
  cat_covariables2<- c("smoking_plasmametal")
  
    data_frame <- data.frame(
    phenotype <- c(phenotype1, phenotype2),
    quant_covar <- c(rep(paste(quant_covariables1, collapse = ", "), length(phenotype1)), 
                    rep(paste(quant_covariables2, collapse = ", "), length(phenotype2))),
    cat_covar <- c(rep(paste(cat_covariables1, collapse = ", "), length(phenotype1)), 
                  rep(paste(cat_covariables2, collapse = ", "), length(phenotype2)))
  )
  
  colnames(data_frame) <- c("Phenotypes", "Quant_covar", "Cat_covar")
  return(data_frame)
    
}
 
