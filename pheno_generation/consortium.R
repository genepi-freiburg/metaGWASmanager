
print("Welcome to the CKDgen R5 script!")

arguments = commandArgs(trailingOnly = TRUE)
if (length(arguments) != 2) {
  stop("Arguments: <parameter_file_name> <pheno_or_jobs_mode>")
}

mode = arguments[2]
if (mode != "pheno" && mode != "jobs") {
  stop("Expect mode to be 'pheno' or 'jobs'.")
}

#############################################################################
# read, check and dump parameter file
#############################################################################

# TODO do we need to take care of paths?
source("consortium-specifics.R")

parameters = read.table(file = arguments[1], 
                        header = F, 
                        col.names = c("key", "value"),
                        stringsAsFactors = F,
                        colClasses = c("factor", "character"))
if (nrow(parameters) == 0 || ncol(parameters) != 2) {
  stop("Parameters file is invalid: Expect tab-separated file with two columns.")
}

get_parameter = function(key) {
  idx = which(parameters$key == key)
  if (length(idx) == 0) {
    stop(paste0("required parameter missing from parameter input file: ", key))
  } else if (length(idx) > 1) {
    stop(paste0("parameter occurs multiple times in input file: ", key))
  }
  return(parameters$value[idx])
}

get_parameter_with_default = function(key, defaultValue) {
  idx = which(parameters$key == key)
  if (length(idx) == 0) {
    return(defaultValue)
  } else if (length(idx) > 1) {
    stop(paste0("parameter occurs multiple times in input file: ", key))
  }
  return(parameters$value[idx])
}

standard_required_parameters = c(
  "input_file",
  "pc_count",
  "study_name",
  "ancestry",
  "refpanel",
  "analysis_date",
  "additional_covariables",
  "additional_categorical_covariables"
)

required_parameters = c(
  standard_required_parameters,
  get_required_parameters()
)


parameters_list = list()
for (parameter in required_parameters) {
  parameters_list[parameter] = get_parameter(parameter)
}

print("Input parameters:")
print(parameters)

fn_end_string = paste0(parameters_list$study_name, "_", parameters_list$ancestry, "_",
	parameters_list$refpanel, "_", parameters_list$analysis_date)
print(paste0("Analysis file identifier: ", fn_end_string))

if (mode == "pheno") {
  # dump parameters to return folder (to summarize descriptive parameters more easily)
  return_params_fn = paste0("return_pheno/", fn_end_string, "-parameters.txt")
  write.table(parameters, return_params_fn, row.names=F, col.names=T, sep="\t", quote=T)
}

#############################################################################
# read, check and summarize file
#############################################################################

print(paste0("Reading input file: ", parameters_list$input_file))
input = read.table(file = parameters_list$input_file, header = T)
# to account for sample ids that appear numeric and start with leading zeros
# check number of columns, assign ID columns as character
# then reread file, leave other columns unchanged
col_classes <- rep(NA, ncol(input))
id_cols <- match(c("FID", "IID"), names(input))
col_classes[id_cols] <- "character"
input = read.table(file = parameters_list$input_file, header = T, colClasses = col_classes)

print("Summary of input file:")
print(summary(input))

required_columns = c(
  "FID", "IID", "sex"
)

external_ckd = get_parameter_with_default("ckd_calculated_externally", 0)
if (external_ckd == 1) {
  print("Using externally calculated CKD")
  required_columns = c(required_columns, "ckd")
}

external_ma = get_parameter_with_default("ma_calculated_externally", 0)
if (external_ma == 1) {
  print("Using externally calculated MA")
  required_columns = c(required_columns, "ma")
}

# include PC columns
required_columns = c(required_columns, paste0("PC", 1:parameters_list$pc_count))

optional_columns = c(
  "crea_serum",
  "cystc_serum", 
  "urate_serum",
  "albumin_serum", 
  "calcium_serum", 
  "phosphate_serum",
  "crea_urine", 
  "albumin_urine",
  "gout",
  "diabetes_screa",
  "diabetes_urine",
  "htn",
  "age_screa",
  "age_scys",
  "age_salb",
  "age_spho",
  "age_scal",
  "age_suac",
  "age_urine",
  "age_gout"
)

is_column_present = function(col_name) {
  idx = which(col_name %in% colnames(input))
  return(length(idx) > 0)
}

for (col in required_columns) {
  if (!is_column_present(col)) {
    stop(paste0("required input column missing: ", col))
  }
}
print("All required columns are present.")

optional_missing = F
for (col in optional_columns) { 
  if (!is_column_present(col)) {
    print(paste0("Optional input column missing: ", col))
    optional_missing = T
  }
}

if (!optional_missing) {
  print("All optional columns are present.")
}

#############################################################################
# check input parameters
#############################################################################

check_quantitative = function(values, param_name, absolute_min, absolute_max,
                              median_min, median_max) {
  # check optional value not present in data frame
  if (!is.null(values)) {
    non_numeric = which(!is.numeric(values)) 
    if (length(non_numeric) > 0) {
      stop(paste0("non-numeric values for ", param_name, ": rows ",
                  paste(values[non_numeric], collapse=", ")))
    }
    
    below_min = which(values < absolute_min)
    if (length(below_min) > 0) {
      stop(paste0("inconsistent values for ", param_name, ": rows ",
                  paste(values[below_min], collapse=", "),
                  " are below absolute minimum of ", absolute_min))
    }
  
    above_max = which(values > absolute_max)
    if (length(above_max) > 0) {
      stop(paste0("inconsistent values for ", param_name, ": rows ",
                  paste(values[above_max], collapse=", "),
                  " are above absolute maximum of ", absolute_max))
    }
    
    value_median = median(values, na.rm = T)
    if (value_median < median_min) {
      stop(paste0("inconsistent values for ", param_name, 
                  ": median below minimum of ", median_min))
    }
    
    if (value_median < median_min) {
      stop(paste0("inconsistent values for ", param_name, 
                  ": median above maximum of ", median_max))
    }
  
    missing_fraction = length(which(is.na(values))) / length(values)
    if (missing_fraction > 0.1) {
      print(paste0("missingness of ", param_name, " is: ", missing_fraction))
    }
  }
}

print("Check sex distribution")
table(input$sex, useNA = "always")
males = which(input$sex == "M")
females = which(input$sex == "F")
if (length(males) == 0 && length(females) == 0) {
  stop("problems with the sex column: require values to be 'M' or 'F'")
}

print("Check quantitative parameters")
check_quantitative(input$age_screa, "age_screa", 0, 200, 1, 100)
check_quantitative(input$age_scys, "age_scys", 0, 200, 1, 100)
check_quantitative(input$age_salb, "age_salb", 0, 200, 1, 100)
check_quantitative(input$age_spho, "age_spho", 0, 200, 1, 100)
check_quantitative(input$age_scal, "age_scal", 0, 200, 1, 100)
check_quantitative(input$age_urine, "age_urine", 0, 200, 1, 100)
check_quantitative(input$age_gout, "age_gout", 0, 200, 1, 100)
check_quantitative(input$age_suac, "age_suac", 0, 200, 1, 100)

crea_mgdl_to_umoll = 88.4
cystc_mgl_to_nmoll = 74.9
urate_mgdl_to_umoll = 59.48

if (parameters_list$creatinine_serum_unit == 0) { 
  # umol/l
  check_quantitative(input$crea_serum, "crea_serum", 0, 2000, 40, 200)
} else if (parameters_list$creatinine_serum_unit == 1) {
  # mg/dl
  check_quantitative(input$crea_serum, "crea_serum", 0, 20, 0.5, 2.5)
} else {
  if (length(which(!is.na(input$crea_serum))) > 0) {
    stop("Have crea_serum data, but did not give unit.")
  }
}

if (parameters_list$cystatin_serum_unit == 0) { 
  # nmol/l
  check_quantitative(input$cystc_serum, "cystc_serum", 0, 1500, 35, 140)
} else if (parameters_list$cystatin_serum_unit == 1) {
  # mg/l
  check_quantitative(input$cystc_serum, "cystc_serum", 0, 20, 0.5, 2)
} else {
  if (length(which(!is.na(input$cystc_serum))) > 0) {
    stop("Have cystc_serum data, but did not give unit.")
  }
}


if (parameters_list$urate_unit == 0) {
  # umol/l
  check_quantitative(input$urate_serum, "urate_serum", 0, 200 * urate_mgdl_to_umoll, 2 * urate_mgdl_to_umoll, 20 * urate_mgdl_to_umoll)
} else if (parameters_list$urate_unit == 1) {
  # mg/dl
  check_quantitative(input$urate_serum, "urate_serum", 0, 200, 2, 20)
} else {
  if (length(which(!is.na(input$urate_serum))) > 0) {
    stop("Have urate_serum data, but did not give unit.")
  }
}


if (parameters_list$albumin_urine_unit == 1) { 
  # mg/l
  check_quantitative(input$albumin_urine, "albumin_urine", 0, 20000, 0, 2000)
} else if (parameters_list$albumin_urine_unit == 0) {
  # mg/dl
  check_quantitative(input$albumin_urine, "albumin_urine", 0, 2000, 0, 200)
} else {
  if (length(which(!is.na(input$albumin_urine))) > 0) {
    stop("Have albumin_urine data, but did not give unit.")
  }
}

if (parameters_list$creatinine_urine_unit == 0) { 
  # umol/l
  check_quantitative(input$crea_urine, "crea_urine", 0, 100000, 0, 2000)
} else if (parameters_list$creatinine_urine_unit == 1) {
  # mg/dl
  check_quantitative(input$crea_urine, "crea_urine", 0, 4000, 0, 200)
} else {
  if (length(which(!is.na(input$crea_urine))) > 0) {
    stop("Have crea_urine data, but did not give unit.")
  }
}

# albumin
if (parameters_list$albumin_serum_unit == 0) {
  # g/dl, 3.5-5.4
  check_quantitative(input$albumin_serum, "albumin_serum", 0, 1000, 1, 10)
} else if (parameters_list$albumin_serum_unit == 1) {
  # g/l, 35-54 g/l
  check_quantitative(input$albumin_serum, "albumin_serum", 0, 1000, 10, 100)
} else {
  if (length(which(!is.na(input$albumin_serum))) > 0) {
    stop("Have albumin_serum data, but did not give unit.")
  }
}

# calcium
if (parameters_list$calcium_unit == 0) { 
  # mmol/l
  check_quantitative(input$calcium_serum, "calcium_serum", 0, 10, 1.9, 2.7)
} else if (parameters_list$calcium_unit == 1) {
  # mg/dl
  check_quantitative(input$calcium_serum, "calcium_serum", 0, 40, 7.6, 10.8)
} else {
  if (length(which(!is.na(input$calcium_serum))) > 0) {
    stop("Have calcium_serum data, but did not give unit.")
  }
}

# phosphate
if (parameters_list$phosphate_unit == 0) {
  # mmol/l, 0.84-1.45
  check_quantitative(input$phosphate_serum, "phosphate_serum", 0, 50, 0.5, 1.5) 
} else if (parameters_list$phosphate_unit == 1) {
  # mg/dl; 1 mmol/l = 3.096 mg/dl
  check_quantitative(input$phosphate_serum, "phosphate_serum", 0, 50, 1.5, 4.5)
} else {
  if (length(which(!is.na(input$phosphate_serum))) > 0) {
    stop("Have phosphate_serum data, but did not give unit.")
  }
}

check_categorial = function(variable, variable_name, categories) {
  if (!is.null(variable)) {
    # check that values are valid categories
    invalid_lines = which(!(variable %in% categories))
    if (length(invalid_lines) > 0) {
      for (line in invalid_lines) {
        if (!is.na(variable[line])) {
          stop(paste("Invalid categorial value ", variable[line],
                      " for '", variable_name, "' in input line ", line, sep = ""))
        }
      }
    }
    
    # check subgroup size
    for (category in categories) {
      category_size = length(which(variable == category))
      if (category_size > 0 && category_size < 50) {
        print(paste("Category ", category, " for '", variable_name, 
                    "' only has ", category_size, 
                    " members. Stratification will be difficult.", sep = ""))
      } else if (category_size == 0) {
        print(paste("Category ", category, " for '", variable_name, 
                    "' not present.", sep = ""))
      }
    }
  }
}

check_categorial(input$sex, "sex", c("M", "F"))
check_categorial(input$gout, "gout", c(0, 1))

if (external_ckd == 1) {
  check_categorial(input$ckd, "ckd", c(0, 1))
}

if (external_ma == 1) {
  check_categorial(input$ma, "ma", c(0, 1))
}

# check PCs

for (pc in paste0("PC", 1:parameters_list$pc_count)) {
  # unsure about plausible ranges
  # but good to look at missingness and numeric
  check_quantitative(input[,pc], pc, -100000, 100000, -10, 10)
}

# check study-specific covariables

study_covar_cols = unlist(strsplit(parameters_list$additional_covariables, ","))
study_cat_covar_cols = unlist(strsplit(parameters_list$additional_categorical_covariables, ","))
all_study_covar_cols = c(study_covar_cols, study_cat_covar_cols)

for (covar_col in study_covar_cols) {
  check_quantitative(input[, covar_col], covar_col, -100000, 100000, -1000, 1000)
}

for (covar_col in study_cat_covar_cols) {
  cat_covar_levels = levels(as.factor(input[, covar_col]))
  check_categorial(input[, covar_col], covar_col, cat_covar_levels)
}

#############################################################################
# assemble result file and calculate derived phenotypes
#############################################################################

# copy interesting input columns (and skip the rest)

result = input[,required_columns]
for (optional_column in optional_columns) {
  if (optional_column %in% colnames(input)) {
    result[, optional_column] = input[, optional_column]
  } else {
    result[, optional_column] = NA
  }
}

result$sex_0_female_1_male = NA
result$sex_0_female_1_male[females] = 0
result$sex_0_female_1_male[males] = 1

# standardize units

if (parameters_list$creatinine_serum_unit == "0") {
  print("Convert serum creatinine from umol/l to mg/dl")
  result$crea_serum = result$crea_serum / crea_mgdl_to_umoll
}

if (parameters_list$creatinine_urine_unit == "0") {
  print("Convert urinary creatinine from umol/l to mg/dl")
  result$crea_urine = result$crea_urine / crea_mgdl_to_umoll
}

if (parameters_list$cystatin_serum_unit == "0") {
  print("Convert serum cystatin c from nmol/l to mg/l")
  result$cystc_serum = result$cystc_serum / cystc_mgl_to_nmoll
}

if (parameters_list$correct_jaffe == "1") {
  print("Correcting serum creatinine for Jaffe assay before 2009")
  result$crea_serum = result$crea_serum * 0.95
}

if (parameters_list$urate_unit == "0") {
  print("Convert urate from umol/l to mg/dl")
  result$urate_serum = result$urate_serum / urate_mgdl_to_umoll
}

if (parameters_list$calcium_unit == "1") {
  print("Convert calcium from mg/dl to mmol/l")
  result$calcium_serum = result$calcium_serum / 4
}

if (parameters_list$albumin_serum_unit == "0") {
  print("Convert serum albumin from g/dl to g/l")
  result$albumin_serum = result$albumin_serum * 10
}

if (parameters_list$albumin_urine_unit == "0") {
  print("Convert urinary albumin from mg/dl to mg/l")
  result$albumin_urine = result$albumin_urine * 10
}

if (parameters_list$phosphate_unit == "1") {
  print("Convert serum phosphate from g/dl to mmol/l")
  result$phosphate_serum = result$phosphate_serum / 3.096
}

# this code has been taken directly from the Nephro package
# it is copied here in order not to require package installation
CKDEpi.creat.rf <- function (creatinine, sex, age) 
{
  if (!is.null(creatinine) & !is.null(sex) & !is.null(age)) {
    creatinine <- as.numeric(creatinine)
    sex <- as.numeric(sex)
    age <- as.numeric(age)
    n <- length(creatinine)
    
    if (length(sex) == n & length(age) == n)
    {
      # Identify missing data and store the index
      idx <- c(1:n)[is.na(creatinine) | is.na(sex) | is.na(age)]
      
      # Replace missing data with fake data to avoid problems with formulas
      creatinine[is.na(creatinine)] <- 10
      sex[is.na(sex)] <- 10
      age[is.na(age)] <- 10
      
      # CKD-Epi equation
      k <- a <- numeric(n)
      k[sex == 0] <- 0.7
      k[sex == 1] <- 0.9
      a[sex == 0] <- -0.241
      a[sex == 1] <- -0.302
      one <- rep(1, n)
      eGFR <- apply(cbind(creatinine/k, one), 1, min, na.rm = T)^a * apply(cbind(creatinine/k, one), 1, max, na.rm = T)^-1.200 * 0.9938^age
      eGFR[sex == 0] <- eGFR[sex == 0] * 1.012
      
      # Restore missing data at the indexed positions
      eGFR[idx] <- NA
      
      # Output
      142 * eGFR
    } else
      stop("Different number of observations between variables")
  } else 
    stop("Some variables are not defined")
}


CKDEpi.cys <- function(cystatin, sex, age)
{ 
  if (!is.null(cystatin) & !is.null(sex) & !is.null(age))
  {
    cystatin <- as.numeric(cystatin)
    sex <- as.numeric(sex)
    age <- as.numeric(age)
    n <- length(cystatin)
    
    if (length(sex) == n & length(age) == n)
    {
      # Identify missing data and store the index
      idx <- c(1:n)[is.na(cystatin) | is.na(sex) | is.na(age)]
      
      # Replace missing data with fake data to avoid problems with formulas
      cystatin[is.na(cystatin)] <- 10
      sex[is.na(sex)] <- 10
      age[is.na(age)] <- 10
      
      # CKD-Epi equation
      k_sex <- rep(1,n)
      k_sex[sex==0] <- 0.932
      one <- rep(1,n)
      eGFR <- 133 * apply(cbind(cystatin/0.8,one),1,min,na.rm=T)^-0.499 * apply(cbind(cystatin/0.8,one),1,max,na.rm=T)^-1.328 * 0.996^age * k_sex
      
      # Restore missing data at the indexed positions
      eGFR[idx] <- NA
      
      # Output
      eGFR
    } else
      stop ("Different number of observations between variables") 
  } else
    stop ("Some variables are not defined") 
}

# U-Albumin LOD
if (as.numeric(parameters_list$lod_urinary_albumin) > 0) {
	lod = as.numeric(parameters_list$lod_urinary_albumin)
	result$albumin_urine = ifelse(result$albumin_urine < lod, lod, result$albumin_urine)
}

# calculate eGFR and UACR
result$egfr_creat = CKDEpi.creat.rf(result$crea_serum, result$sex_0_female_1_male, result$age_screa)
result$egfr_cys = CKDEpi.cys(result$cystc_serum, result$sex_0_female_1_male, result$age_scys)
result$uacr = result$albumin_urine / result$crea_urine * 100
result$uacr_ln = log(result$uacr, base=exp(1))
result$sex_0_female_1_male = NULL

if (external_ckd == 0) {
  # calculate CKD
  result$ckd = ifelse(result$egfr_creat < 60, 1, 0)
}

if (external_ma == 0) {
  # calculate MA
  result$ma = NA
  uacr_high = which(result$uacr > 30)
  uacr_low = which(result$uacr < 10)
  uacr_medium = which(result$uacr >= 10 & result$uacr <= 30)
  result[uacr_high, "ma"] = 1
  result[uacr_low, "ma"] = 0
  result[uacr_medium, "ma"] = NA
}

# inverse-normal transformation
set.seed(42)

INT = function(values) {
  qnorm((rank(values, na.last = "keep", ties.method = "random") - 0.5) / sum(!is.na(values)))
}

result$egfr_creat_int = INT(result$egfr_creat)
result$egfr_cys_int = INT(result$egfr_cys)
result$uacr_int = INT(result$uacr)

# winsorize eGFRcrea and eGFRcys at 15 and 200
result$egfr_creat=ifelse(result$egfr_creat < 15, 15, result$egfr_creat)
result$egfr_creat=ifelse(result$egfr_creat > 200, 200, result$egfr_creat)
result$egfr_cys=ifelse(result$egfr_cys < 15, 15, result$egfr_cys)
result$egfr_cys=ifelse(result$egfr_cys > 200, 200, result$egfr_cys)

result$urate_serum_int = INT(result$urate_serum)
result$calcium_serum_int = INT(result$calcium_serum)
result$phosphate_serum_int = INT(result$phosphate_serum)
result$albumin_serum_int = INT(result$albumin_serum)

# sex stratification
result$egfr_creat_male = ifelse(result$sex == "M", result$egfr_creat, NA)
result$egfr_creat_female = ifelse(result$sex == "F", result$egfr_creat, NA)
result$egfr_cys_male = ifelse(result$sex == "M", result$egfr_cys, NA)
result$egfr_cys_female = ifelse(result$sex == "F", result$egfr_cys, NA)
result$uacr_ln_male = ifelse(result$sex == "M", result$uacr_ln, NA)
result$uacr_ln_female = ifelse(result$sex == "F", result$uacr_ln, NA)
result$urate_serum_male = ifelse(result$sex == "M", result$urate_serum, NA)
result$urate_serum_female = ifelse(result$sex == "F", result$urate_serum, NA)

# include study-specific covariables
if (length(all_study_covar_cols) > 0) {
  print(paste0("Include study-specific covariables: ", paste(all_study_covar_cols, collapse = ", ")))
  result[, all_study_covar_cols] = input[, all_study_covar_cols]
}
  
data_fn = paste0("output_pheno/", fn_end_string, ".data.txt");
print(paste0("Write full data set (rows/cols) to: ", data_fn))
print(dim(result))
write.table(result, data_fn, 
            row.names = F, col.names = T, sep = "\t", quote = F)


#############################################################################
# Calculate QT summary statistics
#############################################################################

if (mode == "pheno") {
  plots_fn = paste0("return_pheno/", fn_end_string, "_plots.pdf")
  pdf(plots_fn)
}

# the following two functions have been taken from the "moments" R package
# in order to avoid the installation of this package

kurtosis = function(x, na.rm = FALSE) {
  if (is.matrix(x)) {
    apply(x, 2, kurtosis, na.rm = na.rm)
  } else if (is.vector(x)) {
    if (na.rm) {
      x = x[!is.na(x)] 
    }
    n = length(x)
    n * sum((x - mean(x))^4) / (sum((x - mean(x))^2)^2)
  } else if (is.data.frame(x)) {
    sapply(x, kurtosis, na.rm = na.rm)
  } else {
    kurtosis(as.vector(x), na.rm = na.rm)
  }
}

skewness = function(x, na.rm = FALSE) {
  if (is.matrix(x)) {
    apply(x, 2, skewness, na.rm = na.rm)
  } else if (is.vector(x)) {
    if (na.rm) {
      x = x[!is.na(x)]
    }
    n = length(x)
    (sum((x - mean(x))^3) / n) / (sum((x - mean(x))^2) / n)^(3/2)
  } else if (is.data.frame(x)) {
    sapply(x, skewness, na.rm = na.rm)
  } else {
    skewness(as.vector(x), na.rm = na.rm)
  }
}

unrelevant_cols = c("FID", "IID")
binary_cols = c("sex", "ckd", "ma", "gout", "diabetes_screa", "diabetes_urine", "htn")
quant_cols = colnames(result)[!(colnames(result) %in% c(unrelevant_cols, binary_cols, all_study_covar_cols))]

summary_statistics = data.frame(
  variable = "",
  min = 0,
  q1 = 0,
  med = 0,
  q3 = 0,
  max = 0,
  n = 0,
  na = 0,
  mean = 0,
  sd = 0,
  kurtosis = 0,
  skewness = 0
)

summary_statistics$variable = as.character(summary_statistics$variable)

i = 0
for (column_name in quant_cols) {
  # variable row counter
  i = i + 1
  summary_statistics[i, "variable"] = column_name
  
  if (length(which(!is.na(result[,column_name]))) == 0) {
    # column is completely NA
    summary_statistics[i, "min"] = NA
    summary_statistics[i, "q1"] = NA
    summary_statistics[i, "med"] = NA
    summary_statistics[i, "q3"] = NA
    summary_statistics[i, "max"] = NA
    summary_statistics[i, "n"] = 0
    summary_statistics[i, "na"] = nrow(result)
    summary_statistics[i, "mean"] = NA
    summary_statistics[i, "sd"] = NA
    summary_statistics[i, "kurtosis"] = NA
    summary_statistics[i, "skewness"] = NA
    next
  }
  
  summ = summary(result[, column_name])

  my_na = 0
  if (length(summ) > 6) {
    my_na = summ[7]
  }
  
  summary_statistics[i, "min"] = summ[1]
  summary_statistics[i, "q1"] = summ[2]
  summary_statistics[i, "med"] = summ[3]
  summary_statistics[i, "q3"] = summ[5]
  summary_statistics[i, "max"] = summ[6]
  summary_statistics[i, "n"] = length(which(!is.na(result[,column_name])))
  summary_statistics[i, "na"] = my_na
  summary_statistics[i, "mean"] = summ[4]
  summary_statistics[i, "sd"] = sd(result[,column_name], na.rm = T)
  summary_statistics[i, "kurtosis"] = kurtosis(result[,column_name], na.rm = T)
  summary_statistics[i, "skewness"] = skewness(result[,column_name], na.rm = T)
}

if (mode == "pheno") {
summary_fn = paste0("return_pheno/", fn_end_string, "_qt_summary.txt")
print(paste0("Write summary statistics for quantitative traits to: ", summary_fn))
print(dim(summary_statistics))
write.table(summary_statistics, summary_fn,
            row.names = F, col.names = T, sep = "\t", quote = F)

# plot

for (idx in 1:nrow(summary_statistics)) {
  variable = summary_statistics$variable[idx]
  
  non_missing_records = length(which(!is.na(result[, variable])))
  missing_records = length(which(is.na(result[, variable])))
  
  if (non_missing_records < 2) {
    next
  }
  
  summ = summary(result[, variable])
  boxplot(result[, variable],
        main = variable, 
        horizontal = T,
        sub = paste(
          "min: ", round(summ[1], 2), 
          ", q1: ", round(summ[2], 2),
          ", med: ", round(summ[3], 2),
          ", mean: ", round(summ[4], 2), ",\n",
          "q3: ", round(summ[5], 2),
          ", max: ", round(summ[6], 2),
          ", na: ", ifelse(is.na(summ[7]), 0, summ[7]),
          sep = ""),
        cex.sub = 0.9
  )
  
  histogram = hist(result[, variable],
                   breaks = 40, 
                   prob = TRUE,
                   col = "grey",
                   main = variable, 
                   xlab = variable, 
                   ylab = "Probability", 
                   sub = paste(non_missing_records, " non-missing records (", missing_records, " NA)", sep = ""),
                   cex.sub = 0.9)
  
  lines(density(result[, variable], na.rm = TRUE), col="red", lwd=2)
  
  xfit = seq(min(result[, variable], na.rm = TRUE), 
             max(result[, variable], na.rm = TRUE), length = 40)
  yfit = dnorm(xfit, 
               mean = mean(result[, variable], na.rm = TRUE), 
               sd = sd(result[, variable], na.rm = TRUE))
  lines(xfit, yfit, col="blue", lwd = 2) 
  
}


# if eGFRcrea AND eGFRcys are present, then plot the scatterplot cys versus crea
if (!all(is.na(result$egfr_creat)) & !all(is.na(result$egfr_cys))){
	# plot the eGFRcrea versus eGFRcys, red line is bisecting line, males and females colour coded
	sexColour=NA
	sexColour[which(result$sex == "F")]<-"pink"
	sexColour[which(result$sex == "M")]<-"darkblue"
	min=min(result$egfr_creat,result$egfr_cys,na.rm=T); max=max(result$egfr_creat,result$egfr_cys,na.rm=T)
	plot(x=result$egfr_creat,y=result$egfr_cys,xlab="eGFRcrea",ylab="eGFRcys",pch=21,col="black",bg=sexColour,xlim=c(min, max),ylim=c(min, max))
	loess_F <- loess(egfr_cys ~ egfr_creat, result[which(result$sex == "F"),])
	loess_M <- loess(egfr_cys ~ egfr_creat, result[which(result$sex == "M"),])
	vec <- seq(min,max,1)
	lines(x=vec, predict(newdata=vec,loess_F), col = "pink",lwd=3)
	lines(x=vec, predict(newdata=vec,loess_M), col = "darkblue",lwd=3)
	legend("topleft", col="black",pt.bg=c("pink","darkblue"), pch=c(21,21),legend=c("female","male"), cex=1)
	abline(0,1,col="red",lty=2,lwd=2)
}

# end of 'if mode == pheno'
}

#############################################################################
# Calculate BT summary statistics
#############################################################################

summary_statistics = data.frame(
  variable = "",
  n = 0,
  na = 0,
  no_or_male = 0,
  yes_or_female = 0)

summary_statistics$variable = as.character(summary_statistics$variable)

only_one_sex = F

i = 0
for (column_name in binary_cols) {
  cat1 = "0"
  cat2 = "1"
  if (column_name == "sex") {
    cat1 = "M"
    cat2 = "F"
  }
  
  # variable row counter
  i = i + 1
  summary_statistics[i, "variable"] = column_name
  
  if (length(which(!is.na(result[,column_name]))) == 0) {
    # column is completely NA
    summary_statistics[i, "n"] = 0
    summary_statistics[i, "na"] = nrow(result)
    summary_statistics[i, "no_or_male"] = 0
    summary_statistics[i, "yes_or_female"] = 0
    next
  }
  
  summary_statistics[i, "n"] = length(which(!is.na(result[,column_name])))
  summary_statistics[i, "na"] = length(which(is.na(result[,column_name])))
  summary_statistics[i, "no_or_male"] = length(which(result[,column_name] == cat1))
  summary_statistics[i, "yes_or_female"] = length(which(result[,column_name] == cat2))

  if (column_name != "sex") {
    if (summary_statistics[i, "no_or_male"] < 500) {
      print(paste0("WARNING: Less than 500 controls for ", column_name))
    }

    if (summary_statistics[i, "yes_or_female"] < 500) {
      print(paste0("WARNING: Less than 500 cases for ", column_name))
    }
  }

  if (column_name == "sex" && 
      (summary_statistics[i, "no_or_male"] == 0 || summary_statistics[i, "yes_or_female"] == 0)) {
    print("WARNING: Detected only one sex. Cannot adjust for sex. Cannot perform sex-stratified analyses.")
    only_one_sex = T
  }
}

if (mode == "pheno") {
summary_fn = paste0("return_pheno/", fn_end_string, "_bt_summary.txt")
print(paste0("Write summary statistics for binary traits to: ", summary_fn))
print(dim(summary_statistics))
write.table(summary_statistics, summary_fn,
            row.names = F, col.names = T, sep = "\t", quote = F)

# plot

for (idx in 1:nrow(summary_statistics)) {
  categorial_variable = summary_statistics$variable[idx]
  zero = summary_statistics$no_or_male[idx]
  one = summary_statistics$yes_or_female[idx]
  nav = summary_statistics$na[idx]
  n = summary_statistics$n[idx]
  
  barplot(c(zero, one, nav),
          names.arg = c("no / male", "yes / female", "NA"),
          col = c("gray50", "gray", "gray90"),
          main = categorial_variable, 
          sub = paste0(nrow(result), " records; no/male = ", zero, ", yes/female = ", one, 
                       ", n = ", n, ", NA = ", nav),
          cex.sub = 0.9)
}

dev.off()

# end of 'if (mode == "pheno")'
}

# PC1 check
if (length(which(is.na(result$PC1))) > 0) {
  print("WARNING: there is missingness in PC1. You are supposed to input only individuals that have genotypes. We do not expect individuals with genotypes to have missing genetic principal components. Please double-check you do not include individuals without genotypes as this distorts summary statistics.")
} else {
  print("OK: No missingness in PC1.")
}

# age check

age_for_phenotype = c(
  "egfr_creat_int" = "age_screa",
  "egfr_creat_male" = "age_screa",
  "egfr_creat_female" = "age_screa",
  "ckd" = "age_screa",

  "egfr_cys_int" = "age_scys",
  "egfr_cys_male" = "age_scys",
  "egfr_cys_female" = "age_scys",

  "uacr_int" = "age_urine",
  "uacr_ln_male" = "age_urine",
  "uacr_ln_female" = "age_urine",
  "ma" = "age_urine",

  "urate_serum_int" = "age_suac",
  "urate_serum_male" = "age_suac",
  "urate_serum_female" = "age_suac",

  "gout" = "age_gout",

  "calcium_serum_int" = "age_scal",
  "phosphate_serum_int" = "age_spho",
  "albumin_serum_int" = "age_salb"
)

for (phenotype in names(age_for_phenotype)) {
        age = age_for_phenotype[phenotype]
	pheno_non_na = length(which(!is.na(result[,phenotype])))
	age_non_na = length(which(!is.na(result[,age])))
        print(paste0("Checking age '", age, "' for phenotype '", phenotype, "': age non-NA: ", age_non_na, "; pheno non-NA: ", pheno_non_na))
        if (pheno_non_na > 0 && age_non_na == 0) {
                stop(paste0("ERROR: age '", age, "' is missing, this will cause the phenotype '", phenotype, "' not to be available for analysis!"))
        }

	age_lt_18 = length(which(result[,age] < 18))
	if (age_lt_18 > 0) {
		print(paste0("WARNING: There are ", age_lt_18, " individuals with ", age, " less than 18. We haven't used a pediatric eGFR equation."))
	}
}


if (mode == "jobs") {
#############################################################################
## Output REGENIE commands
#############################################################################

script_fn = paste0("output_pheno/make-regenie-jobs.sh")
cat("#!/bin/bash
  
", file = script_fn, append = F)

run_idx = 0
  
strata = c("overall", "sex_stratified")
if (only_one_sex) {
  strata = c("overall")
}

for (stratum in strata) {
  for (type in c("binary", "quantitative")) {
    if (stratum != "overall" && type == "binary") {
      # no sex-stratified analyses for binary traits
      next
    }

    print(paste("Building jobs for", stratum, type))
    
    if (type == "quantitative") {
      phenos = quant_cols[grepl("_int|_male|_female", quant_cols)]

      #if (stratum ==  "sex_stratified") {
        # don't INT for the sex-stratified analyses
        #phenos = gsub("_int", "", phenos)
      #}
    } else {
      phenos = binary_cols[!(binary_cols %in% c("sex","diabetes_screa", "diabetes_urine", "htn"))]
    }

    missing_phenos = c()
    
    for (i in 1:length(phenos)) {
      pheno = phenos[i]
      if (length(which(!is.na(result[, pheno]))) == 0) {
        print(paste("Omitting phenotype", pheno, "as it is missing completely."))
        missing_phenos = c(missing_phenos, i)
      }
    }
    
    if (length(missing_phenos) > 0) {
      phenos = phenos[-missing_phenos]
    }
    
    if (stratum != "overall") {
      # this keeps only phenos that have 'male' in their name, which includes _male and _female
      phenos = phenos[grepl("male", phenos)]
      use_sex = F
    } else {
      # this keeps only phenos that don't have 'male' in their name, which excludes _male and _female
      phenos = phenos[!grepl("male", phenos)]
      use_sex = T
    }
    
    for (pheno in phenos) {
      age = age_for_phenotype[pheno]
      if (is.na(age)) {
        stop(paste0("unexpected phenotype: ", pheno))
      }
    
      covars = c(age, paste0("PC", 1:parameters_list$pc_count), study_covar_cols)

      if (use_sex && !only_one_sex) {
        catCovars = c("sex", study_cat_covar_cols)
      } else {
        catCovars = study_cat_covar_cols
      }
    
      run_idx = run_idx + 1
      print(paste0("== RUN ", run_idx, ": ", type, ", stratum: ", stratum))
      print(paste0("Phenotype: ", pheno))
      print(paste0("Quantitative covariates: ", paste(covars, collapse=", ")))
      print(paste0("Categorical covariates: ", paste(catCovars, collapse=", ")))
    
      for (step in c("step1", "step2")) {  
        cat(paste0("./make-regenie-", step, "-job-scripts.sh ",
                 parameters_list$study_name, " ",
                 parameters_list$ancestry, " ",
                 parameters_list$refpanel, " ",
                 parameters_list$analysis_date, " ",
                 type, " ",
                 stratum, " ",
                 pheno, " '",
                 paste(covars, collapse=","), "' '",
                 paste(catCovars, collapse=","), "' ",
                 run_idx, "\n"),
          append = T, file = script_fn)
      }
    }
  }
}

if (run_idx == 0) {
  print("ERROR: No runs planned. Everything missing?")
} else {
  print(paste0("Planned ", run_idx, " runs."))
}
}

print("Script finished successfully.")

