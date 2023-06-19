print("Welcome to the CKDgen R5 post-processing script!")

##################################################################################

arguments = commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1) {
  stop("Please give the name of the parameter file as the first and only argument.")
}

parameters = read.table(file = arguments, 
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

required_parameters = c(
  "pc_count",
  "study_name",
  "ancestry",
  "refpanel",
  "analysis_date"
)

parameters_list = list()
for (parameter in required_parameters) {
  parameters_list[parameter] = get_parameter(parameter)
}

print("Parameters:")
print(parameters_list)

fn_end_string = paste0(parameters_list$study_name, "_", parameters_list$ancestry, "_",
                       parameters_list$refpanel, "_", parameters_list$analysis_date)
print(paste0("Analysis file identifier: ", fn_end_string))

##################################################################################

data = read.table(paste0("output_pheno/", fn_end_string, ".data.txt"), h=T, sep="\t")

summary(data)

##################################################################################

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

##################################################################################
# summarize phenotypes
##################################################################################

summary_per_quantitative_phenotype = c(
  "egfr_creat_int" = "egfr_creat, crea_serum, age_screa",
  "egfr_creat_male" = "egfr_creat, crea_serum, age_screa",
  "egfr_creat_female" = "egfr_creat, crea_serum, age_screa",
  
  "egfr_cys_int" = "egfr_cys, cystc_serum, age_scys",
  "egfr_cys_male" = "egfr_cys, cystc_serum, age_scys",
  "egfr_cys_female" = "egfr_cys, cystc_serum, age_scys",
  
  "uacr_int" = "uacr, age_urine",
  "uacr_ln_male" = "uacr, age_urine",
  "uacr_ln_female" = "uacr, age_urine",
  
  "urate_serum_int" = "urate_serum, age_suac",
  "urate_serum_male" = "age_suac",
  "urate_serum_female" = "age_suac",
  
  "calcium_serum_int" = "calcium_serum, age_scal",
  "phosphate_serum_int" = "phosphate_serum, age_spho",
  "albumin_serum_int" = "albumin_serum, age_salb"
)
quantitative_phenotypes = names(summary_per_quantitative_phenotype)

summary_per_binary_phenotype = c(
  "ckd" = "egfr_creat, age_screa",
  "ma" = "uacr, age_urine",
  "gout" = "age_gout"
)

binary_phenotypes = names(summary_per_binary_phenotype)

binary_summary_statistics = data.frame(
  phenotype = "",
  variable = "",
  n = 0,
  na = 0,
  no_or_male = 0,
  yes_or_female = 0)
binary_summary_statistics$phenotype = as.character(binary_summary_statistics$phenotype)
binary_summary_statistics$variable = as.character(binary_summary_statistics$variable)

quantitative_summary_statistics = data.frame(
  phenotype = "",
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
quantitative_summary_statistics$phenotype = as.character(binary_summary_statistics$phenotype)
quantitative_summary_statistics$variable = as.character(binary_summary_statistics$variable)

summarize_binary_variable = function(binary_summary_statistics, pheno_data, pheno, var) {
  print(paste0(" - summarize binary variable: ", pheno, "/", var))
  
  cat1 = "0"
  cat2 = "1"

  # variable row counter
  i = nrow(binary_summary_statistics) + 1
  if (i == 2) {
    if (binary_summary_statistics[1, "variable"] == "") {
      i = 1
    }
  }

  binary_summary_statistics[i, "phenotype"] = pheno
  binary_summary_statistics[i, "variable"] = var
  
  if (length(which(!is.na(pheno_data[,var]))) == 0) {
    print("   - variable is completely NA")
    binary_summary_statistics[i, "n"] = 0
    binary_summary_statistics[i, "na"] = nrow(pheno_data)
    binary_summary_statistics[i, "no_or_male"] = 0
    binary_summary_statistics[i, "yes_or_female"] = 0
    return(binary_summary_statistics)
  }
  
  binary_summary_statistics[i, "n"] = length(which(!is.na(pheno_data[,var])))
  binary_summary_statistics[i, "na"] = length(which(is.na(pheno_data[,var])))
  binary_summary_statistics[i, "no_or_male"] = length(which(pheno_data[,var] == cat1))
  binary_summary_statistics[i, "yes_or_female"] = length(which(pheno_data[,var] == cat2))
  return(binary_summary_statistics)
}

summarize_quantitative_variable = function(quantitative_summary_statistics, pheno_data, pheno, var, var_label) {
  print(paste0(" - summarize quantitative variable: ", pheno, "/", var, "/", var_label))
  
  # variable row counter
  i = nrow(quantitative_summary_statistics) + 1
  if (i == 2) {
    if (quantitative_summary_statistics[1, "variable"] == "") {
      i = 1
    }
  }
  
  quantitative_summary_statistics[i, "phenotype"] = pheno
  quantitative_summary_statistics[i, "variable"] = var_label
  
  if (length(which(!is.na(pheno_data[,var]))) == 0) {
    print("   - variable is completely NA")
    quantitative_summary_statistics[i, "min"] = NA
    quantitative_summary_statistics[i, "q1"] = NA
    quantitative_summary_statistics[i, "med"] = NA
    quantitative_summary_statistics[i, "q3"] = NA
    quantitative_summary_statistics[i, "max"] = NA
    quantitative_summary_statistics[i, "n"] = 0
    quantitative_summary_statistics[i, "na"] = nrow(pheno_data)
    quantitative_summary_statistics[i, "mean"] = NA
    quantitative_summary_statistics[i, "sd"] = NA
    quantitative_summary_statistics[i, "kurtosis"] = NA
    quantitative_summary_statistics[i, "skewness"] = NA
    return(quantitative_summary_statistics)
  }
  
  summ = summary(pheno_data[, var])
  
  my_na = 0
  if (length(summ) > 6) {
    my_na = summ[7]
  }
  
  quantitative_summary_statistics[i, "min"] = summ[1]
  quantitative_summary_statistics[i, "q1"] = summ[2]
  quantitative_summary_statistics[i, "med"] = summ[3]
  quantitative_summary_statistics[i, "q3"] = summ[5]
  quantitative_summary_statistics[i, "max"] = summ[6]
  quantitative_summary_statistics[i, "n"] = length(which(!is.na(pheno_data[,var])))
  quantitative_summary_statistics[i, "na"] = my_na
  quantitative_summary_statistics[i, "mean"] = summ[4]
  quantitative_summary_statistics[i, "sd"] = sd(pheno_data[,var], na.rm = T)
  quantitative_summary_statistics[i, "kurtosis"] = kurtosis(pheno_data[,var], na.rm = T)
  quantitative_summary_statistics[i, "skewness"] = skewness(pheno_data[,var], na.rm = T)
  return(quantitative_summary_statistics)
}

summarize_quantitative_phenotype = function(quantitative_summary_statistics, pheno_data, pheno) {
  print(paste0("summarize quantitative phenotype: ", pheno))
  vars = c(pheno, 
           trimws(unlist(strsplit(summary_per_quantitative_phenotype[pheno], ","))))
  for (var in vars) {
    quantitative_summary_statistics = 
      summarize_quantitative_variable(quantitative_summary_statistics, pheno_data, pheno, var, var)
  }
  return(quantitative_summary_statistics)
}

summarize_binary_phenotype = function(binary_summary_statistics, quantitative_summary_statistics, pheno_data, pheno) {
  print(paste0("summarize binary phenotype: ", pheno))
  vars = trimws(unlist(strsplit(summary_per_binary_phenotype[pheno], ",")))
  binary_summary_statistics = summarize_binary_variable(binary_summary_statistics, pheno_data, pheno, pheno)
  for (var in vars) {
    cases_data = pheno_data[pheno_data[pheno] == 1,]
    controls_data = pheno_data[pheno_data[pheno] == 0,]
    quantitative_summary_statistics = summarize_quantitative_variable(quantitative_summary_statistics, pheno_data, pheno, var, var)
    quantitative_summary_statistics = summarize_quantitative_variable(quantitative_summary_statistics, cases_data, pheno, var, paste0(var, "_cases"))
    quantitative_summary_statistics = summarize_quantitative_variable(quantitative_summary_statistics, controls_data, pheno, var, paste0(var, "_controls"))
  }
  return(list(bt=binary_summary_statistics, qt=quantitative_summary_statistics))
}

for (pheno in c(quantitative_phenotypes, binary_phenotypes)) { 
  id_file_pattern = paste0(fn_end_string, "_.*_chr1_", pheno, ".regenie.ids")
  id_file = list.files(path = "output_regenie_step2", 
                       pattern = id_file_pattern)
  if (length(id_file) != 1) {
    print(paste0("ERROR: No (or multiple) ID file(s) found: ", id_file_pattern, "; SKIP phenotype: ", pheno))
    next
  }
  
  pheno_ids = read.table(paste0("output_regenie_step2/", id_file), h=T)
  pheno_iid = pheno_ids[,2]
  pheno_data = data[data$IID %in% pheno_iid,]
  
  if (pheno %in% binary_phenotypes) {
    bt_and_qt = summarize_binary_phenotype(
      binary_summary_statistics, quantitative_summary_statistics, pheno_data, pheno)
    quantitative_summary_statistics = bt_and_qt$qt
    binary_summary_statistics = bt_and_qt$bt
  } else {
    quantitative_summary_statistics = summarize_quantitative_phenotype(
      quantitative_summary_statistics, pheno_data, pheno)
  }
}

##################################################################################

print("Write summary statistics")

write.table(quantitative_summary_statistics, paste0("return_pheno/", fn_end_string, "_qt_ids_summary.txt"),
            row.names = F, col.names = T, quote = F, sep = "\t")

write.table(binary_summary_statistics, paste0("return_pheno/", fn_end_string, "_bt_ids_summary.txt"),
            row.names = F, col.names = T, quote = F, sep = "\t")

