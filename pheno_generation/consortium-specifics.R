# Adjust this file to fit your consortium

#FUNCTION 0 ---- NAME OF THE CONSORTIUM
#Add the name of your consortium
get_consortium_name <- function() {
  c("MetalGWAS")
}


##############################################
###              Mode =  "Pheno"            ##
##############################################
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
  
  variables <- c("blood_metals_available", "urine_metals_available", "plasma_metals_available")
  for (var in variables) {
    if (!(parameters$value[parameters$key == var] %in% c("yes", "no"))) {
      stop(paste0("Please provide ", var, " in your parameter file as either 'yes' or 'no'"))
    }
  }
  
  if (parameters$value[parameters$key== "urine_metals_available"]=="yes") {
    required_parameters <- c(required_parameters, 
                             "creatinine_urine_unit","specific_gravity_unit")
  }
  
  if (parameters$value[parameters$key== "plasma_metals_available"]=="yes") {
    required_parameters <- c(required_parameters,   "plasma_or_serum")
    return(required_parameters)
  }
}


# FUNCTIONS 2/3 --- REQUIREDNESS OF INPUT FILE COLUMNS
# add two functions that yield required / optional columns
# parent script will check for presence and log
# (get "parameters" list as an argument, thus can use 
# parameters to make a column optional/required)

#FUNCTION 2. Required columns function
get_required_columns<- function (parameters_list) {
  #don't name "FID", "IID", "sex". They're in the parent script
  required_columns<-c()
  if (parameters_list$urine_metals_available=="yes") {
    required_columns <- c(required_columns,   
                          "age_urinemetal","smoking_urinemetal", "egfr_urinemetal", "bmi_urinemetal","creatinine_urine")
  }
  
  if (parameters_list$blood_metals_available=="yes") {
    required_columns <- c(required_columns,   
                          "age_bloodmetal", "smoking_bloodmetal", "bmi_bloodmetal")
  }
  
  if (parameters_list$plasma_metals_available=="yes") {
    required_columns <- c(required_columns,   
                          "age_plasmametal", "smoking_plasmametal","bmi_plasmametal")
  }
  return(required_columns)
  
}


#FUNCTION 3. optional columns function
get_optional_columns<- function () {
  urine_metals<- c ("cadmium_urine", "selenium_urine", "arsenic_urine")
  blood_metals <- c ()
  plasma_metals<- c ("cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  
  optional_columns<- c(urine_metals, blood_metals, plasma_metals)
  return(optional_columns)
}


# FUNCTION 4 --- UNIT CONVERSIONS
# unit conversions:
# function gets the whole input data set
# needs to use the parameters to determine
# which unit conversions are necessary
# needs to check for wrong parameters/unit
# returns the normalized data set
perform_unit_normalization <- function (input, parameters_list) {
  #A. Unit normalization for metals variables: 
  #Get vector to perform unit normalization
  optional.variables <- optional_columns[optional_columns %in% names(input)]
  for(variable in optional.variables){
    # Values define in parameters file:  -1 = "not provided unit"; 0 = ug/l; 1 =ug/dl
    unit.name = paste0(variable, "_unit")
    #Check if the units are given in the parameter file.
    if (length(!is.na(input[, variable])) > 0 & parameters_list[unit.name] == -1) {
      stop(paste0( variable, " in input file, but units not given in parameter file."))
    } 
    #Perform unit conversion
    if (length(!is.na(input[, variable])) > 0 & parameters_list[unit.name] == 1) {
      input[, variable] <- input[, variable]*10  #conversion from ug/dl to ug/l
    }
  }

  #B. Unit normalization for other variables (same structure as above)
  other.variables<- c ("creatinine_urine")
  for (variable in other.variables) {
    #Values define in parameters file: 0 = g/l, 1 = mg/dl, give -1 if you do not have
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
get_quantitative_trait_check_params <- function(input) {
  #Define the quantitative vectors
  quant_vec1 <- c("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  quant_vec2 <- c("creatinine_urine")
  quant_vec3 <- c("age_urinemetal", "age_plasmametal")
  quant_vec4<- c("egfr_urinemetal", "egfr_plasmametal")
  quant_vec5<- c("bmi_urinemetal", "bmi_plasmametal")
  quant_vec6<- c("seafood_intake")
  
  #Merge quantitative vectors into a single one
  quantitative_variables <- c(quant_vec1, quant_vec2, quant_vec3, quant_vec4, quant_vec5, quant_vec6)

  # restrict to existing columns 
  quantitative_variables=quantitative_variables[which(quantitative_variables %in% names(input))]

  #Create the required parameters for the quantitative variables
  absolute_min <- NA
  absolute_max <- NA
  median_min <- NA
  median_max <- NA
  
  #Create empty table
  table <-  as.numeric()
  
  # Check type of variable and assign a value per required parameters
  for (variable in quantitative_variables) {
    if (variable %in% quant_vec1) {
      mean <- mean(input[ , variable], na.rm = T)
      sd <- sd(input[ , variable], na.rm = T)
      absolute_min <- 0
      absolute_max <- mean+1000*sd   
      median_min <- 0
      median_max <- mean+1000*sd   
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
    #Name of the tested variable
    variable<- variable
    
    # Complete table
    result <- c(variable, absolute_min, absolute_max, median_min, median_max)
    table <- rbind(table, result)
  }
  colnames(table)<- c("variable", "absolute_min", "absolute_max", "median_min", "median_max")
  return(table)
}
  

# FUNCTION 6 ---- CHECK CATEGORICAL INPUT COLUMNS
# check categorical trait summaries
# needs to return a data frame with the
# types of categories
get_categorical_trait_check_params <- function() {
  #Define categorical vectors
  cat_vec1 <- c("sex")
  cat_vec2 <- c("smoking_urinemetal", "smoking_bloodmetal", "smoking_plasmametal")
  
  #Merge categorical vectors into a single one
  categorical_variables<- c(cat_vec1, cat_vec2)
  
  #Create the required categories for the categorical variables
  categories <- c()
  
  #Create empty table
  table<- as.character()
  
  # Check type of variable and assign categories
  for (variable in categorical_variables) {
    if (variable %in% cat_vec1) {
      categories <- c("M", "F")
    } else if (variable %in% cat_vec2) {
      categories <- c("N", "F", "C")
    } 
    variable<- variable
    categories <- paste(categories, collapse = ", ")
    
    # Complete table
    result<- c (variable, categories)
    table <- rbind(table, result)
  }
  colnames(table)<- c("variable", "categories")
  return(table)
}


# FUNCTION 7 --- CALCULATE DERIVED PHENOTYPES BASED ON INPUT
# including INT, etc.
# including sex stratification (or other stratifications)
calculate_derived_phenotypes <- function(result, parameters_list) {
  ###Define type of vectors###
  #Vector with variables to impute 
  vars.to.impute<- c ("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  
  #Vector with variables to correct by creatinine
  vars.to.creat.correct<- c("cadmium_urine", "selenium_urine", "arsenic_urine")
  
  #Vector with variables to perform log2-transformation
  log2_phenos<- c ("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  
  #Vector with variables to perform the inverse normal transformation
  int_phenos<- c ()
  
  #Vector with variables to perform the sex stratification
  vars.to.sex.strat<- c ("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  
  #Vector with variables to perform the smoking stratification
  var.smoke.strat <- c ("cadmium_urine", "selenium_urine", "arsenic_urine", "cadmium_plasma", "selenium_plasma", "arsenic_plasma")
  
  
  #1. Imputation [LOD/sqrt(2)] metals values <LOD LOD/sqrt(2)
    for(colname in colnames(result)){
      if (colname %in% vars.to.impute) {
        lod.var <- paste0(colname, "_lod")
        lod <- as.numeric(parameters_list[lod.var])
        if (!lod >= 0) {
          stop(paste0("Please provide a correct LOD (positive and numeric value) for ", lod.var))
        }
        result[, colname] <- ifelse(result[, colname] < lod, lod/sqrt(2), result[, colname])
      }
    }
 
  #2. Urine metals needed to be divided by creatinine
  for(colname in colnames(result)){
    if (colname %in% vars.to.creat.correct) {
      result[, colname] <- result[, colname]/result[, "creatinine_urine"]
    }
  }
  
  #3. Values transformation: log / INT
  for (colname in colnames(result)) {
    #log2 transformation
    if (colname %in% log2_phenos) {
      #Check if there are 0 values. They are a problem in logtransformation
      if (any(result[, colname] == 0, na.rm = TRUE)) {
      print(paste0("Zero values in variable:", colname, ". Need to sum 0.00001 to avoid problems in logtransformation"))
      }
      result[, colname] <- ifelse(result[, colname] == 0, result[, colname] + 0.00001, result[, colname])
      
      #Apply logtransformation
      result[, colname] <- log2(result[, colname])
    }
    
    #Inverse normal transformation
    if (colname %in% int_phenos) {
      result[, colname]<- qnorm((rank(result[, colname], na.last = "keep", ties.method = "random") - 0.5) / sum(!is.na(result[, colname])))
    }
    
    
    #4. Perform sex stratification
    if (colname %in% vars.to.sex.strat){
      col.male <- paste0(colname, "_male")
      col.female <- paste0(colname, "_female")
      result[, col.male] <- ifelse(result$sex == "M", result[, colname], NA)
      result[, col.female] <- ifelse(result$sex == "F", result[, colname], NA)
    }
    
    #5. Perform smoking status stratification (Never smoker)
    if (colname %in% var.smoke.strat){
      col.neversmk <- paste0(colname, "_neversmk")
      result[, col.neversmk] <- ifelse(result$smoking_urinemetal == "N", result[, colname], NA)
    }
  }
  return(result)
}


# FUNCTIONS 8 --- PERFORM SPECIALIZED QC
# works on all data, including normalized / derived phenotpes

#Function 8.a. Get binary variables
get_binary_cols<- function() {
  c("sex")
}

#Function 8.b. Get  number of minimum cases to study the variable
get_number_cases<- function() {
  c(500)
}

#Function 8.c. vector with categorical variables
get_cat_cols<- function() {
  c("smoking_urinemetal", "smoking_plasmametal")
}

#Function 8.d. Create a vector with the age_variable (names of this vector are the specific variables)
get_age_for_phenotype<- function() {
  urine_metals<- c ("cadmium_urine", "cadmium_urine_female", "cadmium_urine_male", "cadmium_urine_neversmk",
                      "selenium_urine", "selenium_urine_female", "selenium_urine_male", "selenium_urine_neversmk",
                      "arsenic_urine", "arsenic_urine_female", "arsenic_urine_male", "arsenic_urine_neversmk")
  blood_metals <- c ()
  plasma_metals<- c("cadmium_plasma", "cadmium_plasma_female", "cadmium_plasma_male", "cadmium_plasma_neversmk",
                      "selenium_plasma", "selenium_plasma_female", "selenium_plasma_male", "selenium_plasma_neversmk",
                      "arsenic_plasma", "arsenic_plasma_female", "arsenic_plasma_male", "arsenic_plasma_neversmk" )
  all_metals <- c(urine_metals, blood_metals, plasma_metals)
  
  age_vector <- rep(c("age_urinemetal", "age_bloodmetal", "age_plasmametal"), times = c(length(urine_metals), length(blood_metals), length(plasma_metals)))
  names(age_vector)<- all_metals
  return(age_vector)

}
  

##############################################
###             Mode =  "Jobs"              ##
##############################################

# FUNCTION 9 --- DETERMINE PHENOTYPES/COVARIABLES
# returns a data.frame with the following columns
# phenotype - name of the data to be used as a phenotype
# covariables - comma-separated list of quantitative covariables to use in this analysis
# catCovariables - comma-separated list of categorical covariables to use in this analysis
# "colon notation" - PC{1:40} ok for covariables

#phenotype          covariables   catCovariables
#egfr_creat_female  age,PC{1:40}  studycenter
#egfr_creat_int     age,PC{1:40}  sex,studycenter
determine_phenotypes_covariables <- function(parameters_list) {
  #1.Define your quantitative phenotypes vectors:
  quant_pheno1<- c("cadmium_urine", "cadmium_urine_female", "cadmium_urine_male", "cadmium_urine_neversmk",
                   "selenium_urine", "selenium_urine_female", "selenium_urine_male", "selenium_urine_neversmk",
                   "arsenic_urine", "arsenic_urine_female", "arsenic_urine_male", "arsenic_urine_neversmk")
  
  quant_pheno2<- c("cadmium_plasma", "cadmium_plasma_female", "cadmium_plasma_male", "cadmium_plasma_neversmk",
                   "selenium_plasma", "selenium_plasma_female", "selenium_plasma_male", "selenium_plasma_neversmk",
                   "arsenic_plasma", "arsenic_plasma_female", "arsenic_plasma_male", "arsenic_plasma_neversmk" )
  
  #2. Define your binary phenotypes
  binary_pheno1<-c()
  binary_pheno2<-c()
  
  #3. Define covariates##
  #3.A. Quantitative covariates:
  quant_covar1<- c("age_urinemetal", "bmi_urinemetal", "egfr_urinemetal",
                   paste0("PC", 1:parameters_list$pc_count))
  
  quant_covar2<- c("age_plasmametal", "bmi_plasmametal",
                   paste0("PC", 1:parameters_list$pc_count))
  
  #3.B. Categorical covariates:
  cat_covar1<- c("sex", "smoking_urinemetal")
  cat_covar2<- c("sex" ,"smoking_plasmametal")
  
  #3. Create a data frame
  data_frame <- data.frame(
    #Define type of phenotype. In this example we only have quantitative outcomes.
    type = c(rep("quantitative", length(quant_pheno1)), 
             rep("quantitative", length(quant_pheno2)), 
             rep("binary", length(binary_pheno1)), 
             rep("binary", length(binary_pheno2))),
    phenotype = c(quant_pheno1, quant_pheno2),
    
    #Define quantitative covariates. 
    quant_covar = c(rep(paste(quant_covar1, collapse = ","), length(quant_pheno1)), 
                    rep(paste(quant_covar2, collapse = ","), length(quant_pheno2))),
    
    #Define categorical covariates. 
    cat_covar = c(rep(paste(cat_covar1, collapse = ","), length(quant_pheno1)), 
                  rep(paste(cat_covar2, collapse = ","), length(quant_pheno2)))
  )
  
  colnames(data_frame) <- c("Type" ,"Phenotypes", "Quant_covar", "Cat_covar")
  
   #Be careful with  stratification (omit sex and smk variable in sex_stratified and Smk_stratified, respectively)
  for (i in 1:nrow(data_frame)) {
    if (grepl(",", data_frame$Cat_covar[i])) {
      if (grepl("_male$|_female$", data_frame$Phenotypes[i])) {
        data_frame$Cat_covar[i] <- gsub("sex,", "", data_frame$Cat_covar[i])
      }
    } else {
      if (grepl("_male$|_female$", data_frame$Phenotypes[i])) {
        data_frame$Cat_covar[i] <- NA
      }
    }
  }
  data_frame$Cat_covar<- ifelse(grepl("_neversmk$", data_frame$Phenotypes), "sex",data_frame$Cat_covar)
  
  return(data_frame)
    
}



# FUNCTION 10 --- CHOOSE THE DESIRED ASSOCIATION TOOL
get_GWAS_tool_name <- function() {
  c("regenie") #plink, regenie, BOLT
}



##############################################
###                  GWAS QC                ##
##############################################
# FUNCTION 11 --- DEFINE QC THRESHOLDs
# returns a data.frame with the threshold values
get_QC_tolerance <- function() {
  
  #1.Define your quantitative phenotypes vectors:
  quant_pheno1<- c("cadmium_urine", "cadmium_urine_female", "cadmium_urine_male", "cadmium_urine_neversmk",
                   "selenium_urine", "selenium_urine_female", "selenium_urine_male", "selenium_urine_neversmk",
                   "arsenic_urine", "arsenic_urine_female", "arsenic_urine_male", "arsenic_urine_neversmk")
  
  quant_pheno2<- c("cadmium_plasma", "cadmium_plasma_female", "cadmium_plasma_male", "cadmium_plasma_neversmk",
                   "selenium_plasma", "selenium_plasma_female", "selenium_plasma_male", "selenium_plasma_neversmk",
                   "arsenic_plasma", "arsenic_plasma_female", "arsenic_plasma_male", "arsenic_plasma_neversmk" )
  
  #2. Define your binary phenotypes
  binary_pheno<-c()

  #3. Define QC tolerance
  pval.tolerance<- 0.05
  lambda.tolerance<- 0.04
  lambda.tolerance.binary<- 0.1  #Less restrictive
  impqual.tolerance<- 0.1
  beta.tolerance<- 0.05
  beta.tolerance.stratified<- 5 ##Less restrictive
  afreq.corr.tolerance<- 0.1

  #4. Create a data frame
  data_frame <- data.frame(
    #Define type of phenotype. In this example we only have quantitative outcomes.
    type = c(rep("quantitative", length(quant_pheno1)), 
             rep("quantitative", length(quant_pheno2)), 
             rep("binary", length(binary_pheno))), 
    
    phenotype = c(quant_pheno1, quant_pheno2, binary_pheno),
    
    pval.tol= c(rep(pval.tolerance, length(quant_pheno1)),
                rep(pval.tolerance, length(quant_pheno2)),
                rep(pval.tolerance, length(binary_pheno))),

    lambda.tol = c(rep(lambda.tolerance, length(quant_pheno1)),
                   rep(lambda.tolerance, length(quant_pheno2)),
                   rep(lambda.tolerance.binary, length(binary_pheno))),

    beta.tol= c(rep(beta.tolerance, length(quant_pheno1)),
                rep(beta.tolerance, length(quant_pheno2)),
                rep(beta.tolerance, length(binary_pheno))),

    afreq.tol= c(rep(afreq.corr.tolerance, length(quant_pheno1)),
                 rep(afreq.corr.tolerance, length(quant_pheno2)),
                 rep(afreq.corr.tolerance, length(binary_pheno))),

    impqual.tol= c(rep(impqual.tolerance, length(quant_pheno1)),
                 rep(impqual.tolerance, length(quant_pheno2)),
                 rep(impqual.tolerance, length(binary_pheno)))
  )

  #Be careful with  stratification (omit sex and smk variable in sex_stratified and Smk_stratified, respectively)
  data_frame$beta.tol <- ifelse(grepl("_male$", data_frame$phenotype) | grepl("_female$", data_frame$phenotype) | grepl("_neversmk$", data_frame$phenotype), beta.tolerance.stratified, beta.tolerance)

  return(data_frame)
  
}








