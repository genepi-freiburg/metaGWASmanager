# TODO do we need to take care of paths?
source("consortium-specifics.R")

# Use "get_consortium_name" function modified by the consortium core
print(paste0("Welcome to the ",get_consortium_name (), " script!"))

#Check if the two required arguments are given
arguments = commandArgs(trailingOnly = TRUE)
if (length(arguments) != 2) {
  stop("Arguments: <parameter_file_name> or <mode> missing")
}

#Check if mode is given in the .sh script
mode = arguments[2]
if (mode != "pheno" && mode != "jobs" && mode != "submit") {
  stop("Expect mode to be 'pheno', 'jobs' or 'submit'.")
}

#############################################################################
# A. Read, check and dump parameter file                                  
#############################################################################
#Read the parameters file
parameters <- read.table(file = arguments[1], 
                        header = F, 
                        col.names = c("key", "value"),
                        stringsAsFactors = F,
                        colClasses = c("factor", "character"))
if (nrow(parameters) == 0 || ncol(parameters) != 2) {
  stop("Parameters file is invalid: Expect tab-separated file with two columns.")
}

#Function used to search for and retrieve the value of a specific parameter (It also check repeated or missing columns).
get_parameter = function(key) {
  idx <- which(parameters$key == key)
  if (length(idx) == 0) {
    stop(paste0("required parameter missing from parameter input file: ", key))
  } else if (length(idx) > 1) {
    stop(paste0("parameter occurs multiple times in input file: ", key))
  }
  return(parameters$value[idx])
}


#Get the standard parameters
standard_required_parameters<-  c(
  "input_file",
  "pc_count",
  "study_name",
  "ancestry",
  "refpanel",
  "analysis_date",
  "additional_covariables",
  "additional_categorical_covariables"
)

#Total required parameters. Use "get_required_parameters" function modified by the consortium core
required_parameters<-  c(
  standard_required_parameters,
  get_required_parameters(parameters)
) 

#Get parameters list using  "get_parameter" function.
parameters_list <- list()
for (parameter in required_parameters) {
  parameters_list[parameter] = get_parameter(parameter)
}

# Check if required parameters are provided/missing in the parameters list
check_missing_values <- function(parameters_list) {
  missing <- character(0)  #save missings
  
  for (i in 1:length(parameters_list)) {
    if (parameters_list[[i]] == "") {
      missing <- c(missing, names(parameters_list)[i])
    }
  }
  
  if (length(missing) == 0) {
    print("All required parameters are provided.")
  } else {
    print("The following required parameters are missings:")
      print(missing)
  }
}

#Apply previous function (check_missing_values)
check_missing_values(parameters_list)

#Sum up of requiered parameters and save them.
print("Input parameters:")
print(parameters)

#Obtain the file name
fn_end_string <- paste0(parameters_list$study_name, "_", parameters_list$ancestry, "_",
                       parameters_list$refpanel, "_", parameters_list$analysis_date)
print(paste0("Analysis file identifier: ", fn_end_string))

if (mode == "pheno") {
  # dump parameters to return folder (to summarize descriptive parameters more easily)
  return_params_fn = paste0("return_pheno/", fn_end_string, "-parameters.txt")
  write.table(parameters, return_params_fn, row.names=F, col.names=T, sep="\t", quote=T)
}



#############################################################################
# B. Read, check and summarize file
#############################################################################
#Read input file
print(paste0("Reading input file: ", parameters_list$input_file))

if(!file.exists(parameters_list$input_file))
	stop(paste("The provided input file",parameters_list$input_file,"does not exist!\nPlease check if the file exists and if you provided the correct file name!"))

input <- read.table(file = parameters_list$input_file, header = T)
# to account for sample ids that appear numeric and start with leading zeros
# check number of columns, assign ID columns as character
# then reread file, leave other columns unchanged
col_classes <- rep(NA, ncol(input))
id_cols <- match(c("FID", "IID"), names(input))
col_classes[id_cols] <- "character"
input <- read.table(file = parameters_list$input_file, header = T, colClasses = col_classes) 

#Get summary of input file
print("Summary of input file:")
print(summary(input))

required_columns <- c( "FID", "IID", "sex")

#Get required columns. Use "get_required_columns" function modified by the consortium core
#include PC columns
required_columns <- c(required_columns, get_required_columns(parameters_list), paste0("PC", 1:parameters_list$pc_count));  # length(required_columns)

#Get optional columns Use "get_optional_columns" function modified by the consortium core
optional_columns <- c( get_optional_columns());  # length(optional_columns)

#Check presence of required columns
is_column_present <- function(col_name) {
  idx <- which(col_name %in% colnames(input))
  return(length(idx) > 0)
}

for (col in required_columns) {
  if (!is_column_present(col)) {
    stop(paste0("Required input column missing: ", col))
  }
}
print("All required columns are present.")


#Check if optional columns are missing or not
optional_missing <- F
for (col in optional_columns) { 
  if (!is_column_present(col)) {
    print(paste0("Optional input column missing: ", col))
    optional_missing <- T
  }
}

if (!optional_missing) {
  print("All optional columns are present.")
}


#############################################################################
# C. Check input parameters
#############################################################################
# STEP 1. Check units. Use "perform_unit_normalization" function modified by the consortium core ----------------------------------
input<- perform_unit_normalization(input, parameters_list) 

# STEP 2. Check quantitative tratis ----------------------------------
print("Check quantitative parameters")

#Creation of data.frame with information about quantitative parameters
#Use "get_quantitative_trait_check_params" function modified by the consortium core
parameters_quantitative_df <- as.data.frame (get_quantitative_trait_check_params(input))

#Function: Check if values are in the given range
check_quantitative <- function(values, param_name, absolute_min, absolute_max,
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
		# suggestion my Mathias:
      stop(paste0("There are ",length(which(values > absolute_max)),
				" values of ",param_name, " above absolute maximum of ", absolute_max,"\n"
				,"Listed here are the first 10 row numbers that are above the maximum: ",
				paste(head(which(values > absolute_max),10), collapse=", ")))
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


#Apply "check_quantitative" function using the created df "parameters_quantitative".
for (i in parameters_quantitative_df$variable) {
  absolute_min <- as.numeric (subset(parameters_quantitative_df, variable == i)$absolute_min)
  absolute_max <- as.numeric (subset(parameters_quantitative_df, variable == i)$absolute_max)
  median_min <- as.numeric (subset(parameters_quantitative_df, variable == i)$median_min)
  median_max <- as.numeric (subset(parameters_quantitative_df, variable == i)$median_max)

  if(i %in% colnames(input)){
    check_quantitative(values=input[, i], param_name =i, absolute_min = absolute_min,
                       absolute_max = absolute_max, median_min = median_min, median_max = median_max)
  }
}


# STEP 3. Check sex distribution ----------------------------------
print("Check sex distribution")
table(input$sex, useNA = "always")
males <- which(input$sex == "M")
females <- which(input$sex == "F")
if (length(males) == 0 && length(females) == 0) {
  stop("Problems with the sex column: require values to be 'M' or 'F'")
}

#Check presence of males and females
if (length(males) == 0 | length(females) == 0) {
  print("WARNING: Only one sex. Cannot perform sex-stratified analyses.")
}

# STEP 4. Check categorical traits ----------------------------------
print("Check categorical parameters")

#Creation of data.frame with information about categorical parameters
#Use "get_categorical_trait_check_params" function modified by the consortium core
parameters_categorical_df <- as.data.frame (get_categorical_trait_check_params())

#Function: Check if categories are correct
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


#Apply "check_categorial" function using the created df "parameters_categorical".
for (i in parameters_categorical_df$variable) {
  categories <- subset(parameters_categorical_df, variable == i)$categories
  categories <- unlist(strsplit(categories, ", "))

  if(i %in% colnames(input)){
    check_categorial(variable=input[, i], variable_name =i, categories = categories)
  }
}


# STEP 5. Check PCs ----------------------------------
for (pc in paste0("PC", 1:parameters_list$pc_count)) {
  # unsure about plausible ranges
  # but good to look at missingness and numeric
  check_quantitative(input[,pc], pc, -100000, 100000, -10, 10)
}

# STEP 6. Check study-specific covariables ----------------------------------
study_covar_cols <- unlist(strsplit(parameters_list$additional_covariables, ","))
study_cat_covar_cols <- unlist(strsplit(parameters_list$additional_categorical_covariables, ","))
all_study_covar_cols <- c(study_covar_cols, study_cat_covar_cols)

for (covar_col in study_covar_cols) {
  check_quantitative(input[, covar_col], covar_col, -100000, 100000, -1000, 1000)
}

for (covar_col in study_cat_covar_cols) {
  cat_covar_levels <- levels(as.factor(input[, covar_col]))
  check_categorial(input[, covar_col], covar_col, cat_covar_levels)
}



#############################################################################
# D. Assemble result file and calculate derived phenotypes
#############################################################################
# Copy interesting input columns (and skip the rest)
result <- input[,required_columns]
for (optional_column in optional_columns) {
  if (optional_column %in% colnames(input)) {
    result[, optional_column] <- input[, optional_column]
  } else {
    result[, optional_column] <- NA
  }
}

# STEP 1. Calculate derived phenotypes ----------------------------------
#Use "calculate_derived_phenotypes" function modified by the consortium core
result<- calculate_derived_phenotypes (result, parameters_list)

# include study-specific covariables
if (length(all_study_covar_cols) > 0) {
  print(paste0("Include study-specific covariables: ", paste(all_study_covar_cols, collapse = ", ")))
  result[, all_study_covar_cols] <- input[, all_study_covar_cols]
}

#Get name of the file to save  
data_fn = paste0("output_pheno/", fn_end_string, ".data.txt");
print(paste0("Write full data set (rows/cols) to: ", data_fn))
print(dim(result))
write.table(result, data_fn, 
            row.names = F, col.names = T, sep = "\t", quote = F)


#############################################################################
# E. Calculate QT summary statistics
#############################################################################
print("Calculate QT summary statistics")

if (mode == "pheno") {
plots_fn <- paste0("return_pheno/", fn_end_string, "_plots.pdf")
pdf(plots_fn)
}

# the following two functions have been taken from the "moments" R package
# in order to avoid the installation of this package
kurtosis <- function(x, na.rm = FALSE) {
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

skewness <- function(x, na.rm = FALSE) {
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


# QUANTITATIVE Summary statistics ----------------------------------
print("Quantitative")

#Vector with irrelevant columns for the summary statistics
unrelevant_cols <- c("FID", "IID")
quant_cols <- colnames(result)[!(colnames(result) %in% c(unrelevant_cols, parameters_categorical_df$variable, all_study_covar_cols))]

#Use "get_binary_cols" function modified by the consortium core
binary_cols <- c (get_binary_cols())

#create the summary_statistics dt
summary_statistics <- data.frame(
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


#Complete df
summary_statistics$variable <- as.character(summary_statistics$variable)

i <- 0
for (column_name in quant_cols) {
  # variable row counter
  i <- i + 1
  summary_statistics[i, "variable"] <- column_name
  
  if (length(which(!is.na(result[,column_name]))) == 0) {
    # column is completely NA
    summary_statistics[i, "min"] <- NA
    summary_statistics[i, "q1"] <-  NA
    summary_statistics[i, "med"] <-  NA
    summary_statistics[i, "q3"] <-  NA
    summary_statistics[i, "max"] <-  NA
    summary_statistics[i, "n"] <-  0
    summary_statistics[i, "na"] = nrow(result)
    summary_statistics[i, "mean"] <-  NA
    summary_statistics[i, "sd"] <-  NA
    summary_statistics[i, "kurtosis"] <-  NA
    summary_statistics[i, "skewness"] <-  NA
    next
  }
  
  summ <- summary(result[, column_name])

  my_na <- 0
  if (length(summ) > 6) {
    my_na <- summ[7]
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


#Save summary statistics
if (mode == "pheno") {
summary_fn <- paste0("return_pheno/", fn_end_string, "_qt_summary.txt")
print(paste0("Write summary statistics for quantitative traits to: ", summary_fn))
print(dim(summary_statistics))
write.table(summary_statistics, summary_fn,
            row.names = F, col.names = T, sep = "\t", quote = F)



#PLOTS
for (idx in 1:nrow(summary_statistics)) {
  variable <- summary_statistics$variable[idx]
  
  non_missing_records <- length(which(!is.na(result[, variable])))
  missing_records <- length(which(is.na(result[, variable])))
  
  if (non_missing_records < 2) {
    next
  }
  
  summ <- summary(result[, variable])
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
  
  histogram <- hist(result[, variable],
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

#dev.off()

# end of 'if (mode == "pheno")'
}

#############################################################################
# F.  Calculate BT summary statistics
#############################################################################
print("Binary")

#Use "get_number_cases" function modified by the consortium core
n.cases<- get_number_cases()

summary_statistics <- data.frame(
  variable = "",
  n = 0,
  na = 0,
  no_or_male = 0,
  yes_or_female = 0)

summary_statistics$variable <- as.character(summary_statistics$variable)

only_one_sex <- F

i <- 0
for (column_name in binary_cols) {
  cat1 <- "0"
  cat2 <- "1"
  if (column_name == "sex") {
    cat1 <- "M"
    cat2 <- "F"
  }
  
  # variable row counter
  i <- i + 1
  summary_statistics[i, "variable"] <- column_name
  
  if (length(which(!is.na(result[,column_name]))) == 0) {
    # column is completely NA
    summary_statistics[i, "n"] <- 0
    summary_statistics[i, "na"] <- nrow(result)
    summary_statistics[i, "no_or_male"] <- 0
    summary_statistics[i, "yes_or_female"] <- 0
    next
  }
  
  summary_statistics[i, "n"] <- length(which(!is.na(result[,column_name])))
  summary_statistics[i, "na"] <- length(which(is.na(result[,column_name])))
  summary_statistics[i, "no_or_male"] <- length(which(result[,column_name] == cat1))
  summary_statistics[i, "yes_or_female"] <- length(which(result[,column_name] == cat2))

  if (column_name != "sex") {
    if (summary_statistics[i, "no_or_male"] < n.cases) {
      print(paste0("WARNING: Less than ",n.cases , " cases for ", column_name))
    }

    if (summary_statistics[i, "yes_or_female"] < n.cases) {
      print(paste0("WARNING: Less than ",n.cases , " controls for ", column_name))
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
  categorial_variable <- summary_statistics$variable[idx]
  zero <- summary_statistics$no_or_male[idx]
  one <- summary_statistics$yes_or_female[idx]
  nav <- summary_statistics$na[idx]
  n <- summary_statistics$n[idx]
  
  barplot(c(zero, one, nav),
          names.arg = c("no / male", "yes / female", "NA"),
          col = c("gray50", "gray", "gray90"),
          main = categorial_variable, 
          sub = paste0(nrow(result), " records; no/male = ", zero, ", yes/female = ", one, 
                       ", n = ", n, ", NA = ", nav),
          cex.sub = 0.9)
}

# end of 'if (mode == "pheno")'
}

#############################################################################
# G.  Calculate CT summary statistics
#############################################################################
print("Categorical")
#Use "get_cat_cols" function modified by the consortium core
cat_cols <- c (get_cat_cols())

#Table preparation
summary_statistics <- c()
for (column_name in cat_cols) {
  categories <- unique(result[, column_name])
  for(category in categories[!is.na(categories)]){
    N <- sum(result[, column_name]== category, na.rm = T)
    summary_statistics <- rbind(summary_statistics, c(column_name, category, N))
  }
  
  NAs <- sum(is.na(result[, column_name]))
  summary_statistics <- rbind(summary_statistics, c(column_name, "NA", NAs))
}

summary_statistics <- as.data.frame(summary_statistics)
colnames(summary_statistics) <- c("Variable", "Category", "N")

if (mode == "pheno") {
  #  CT summary statistics
  summary_fn = paste0("return_pheno/", fn_end_string, "_ct_summary.txt")
  print(paste0("Write summary statistics for categorical traits to: ", summary_fn))
  print(dim(summary_statistics))
  write.table(summary_statistics, summary_fn, row.names = F, col.names = T, sep = "\t", quote = F)
  
  # Plot
  for(column_name in cat_cols){
    sub_sum_stat<- subset(summary_statistics, Variable == column_name)
    values <- as.numeric(sub_sum_stat$N)
    barplot(values, names.arg = sub_sum_stat$Category,
            main = column_name)
  }
  dev.off()
}  
  

# PC1 check 
print("PC1 check ")
if (length(which(is.na(result$PC1))) > 0) {
  print("WARNING: there is missingness in PC1. You are supposed to input only individuals that have genotypes. We do not expect individuals with genotypes to have missing genetic principal components. Please double-check you do not include individuals without genotypes as this distorts summary statistics.")
} else {
  print("OK: No missingness in PC1.")
}

# Age check
print("Age check ")
#Use "get_age_for_phenotype" function modified by the consortium core
age_for_phenotype <- get_age_for_phenotype ()

#Check if ages is given for all the phenotypes.  
for (phenotype in names(age_for_phenotype)) {
        age = age_for_phenotype[phenotype]
	pheno_non_na = length(which(!is.na(result[,phenotype])))
	age_non_na = length(which(!is.na(result[,age])))
        print(paste0("Checking age '", age, "' for phenotype '", phenotype, "': age non-NA: ", age_non_na, "; pheno non-NA: ", pheno_non_na))
        if (pheno_non_na > 0 && age_non_na == 0) {
                stop(paste0("ERROR: age '", age, "' is missing, this will cause the phenotype '", phenotype, "' not to be available for analysis!"))
        }
}


if (mode == "jobs") {
  #############################################################################
  ## F. Output association commands
  #############################################################################
  # Use "get_GWAS_tool_name" function modified by the consortium core
  GWAS_tool<-get_GWAS_tool_name() 
  print(paste0("Association tool to use: ",get_GWAS_tool_name ()))
  
  #Use "determine_phenotypes_covariables" function modified by the consortium core
  jobs_phenos <- determine_phenotypes_covariables (parameters_list)
  
  #Use "make_assoc_jobs" function modified by the consortium core. It creates association jobs
  make_assoc_jobs(jobs_phenos, GWAS_tool, parameters_list, study_covar_cols, study_cat_cols)
  
}

#############################################################################
## G. Submit jobs
#############################################################################
if (mode == "submit") {
  # Use "get_GWAS_tool_name" function modified by the consortium core
  GWAS_tool<-get_GWAS_tool_name() 
  print(paste0("Association tool to use: ",get_GWAS_tool_name ()))
  
  #Use "create_submit_all_jobs_script" function modified by the consortium core
  create_submit_all_jobs_script(GWAS_tool)
  
}


print("Script finished successfully.")

