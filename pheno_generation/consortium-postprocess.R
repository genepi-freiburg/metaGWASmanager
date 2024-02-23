# TODO do we need to take care of paths?
source("consortium-specifics.R")

arguments = commandArgs(trailingOnly = TRUE)


mode = arguments[2]

# Use "get_GWAS_tool_name" function modified by the consortium core
GWAS_tool<-get_GWAS_tool_name() 

if (mode == "log") {
  if (length(arguments) != 2) {
    stop("Arguments: <parameter_file_name> or <mode> missing")
  }
  
  ############################################################################################################
  #   STEP 0.  Check log files
  ############################################################################################################
  print("Checking log files")
  check_log_files(GWAS_tool)
}


if (mode == "post") {
  ############################################################################################################
  #   STEP 1.  Get Identifier name
  ############################################################################################################
  if (length(arguments) != 2) {
    stop("Arguments: <parameter_file_name> or <mode> missing")
  }
  
  print("Post-process steps")
  
  # Use "get_consortium_name" function modified by the consortium core
  print(paste0("Welcome to the ",get_consortium_name (), " post-processing script!"))
  
  parameters = read.table(file = arguments [1], 
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
  
  ############################################################################################################
  #   STEP 2.  Read output_pheno db
  ############################################################################################################
  data = read.table(paste0("output_pheno/", fn_end_string, ".data.txt"), h=T, sep="\t")
  summary(data)
  
  ############################################################################################################
  #   STEP 3.  Create functions for quantitative traits
  ############################################################################################################
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
  
  
  ############################################################################################################
  #   STEP 4.  Create functions for summarize phenotypes and variables
  ############################################################################################################
  # Step 4.1. Create objetcs with the phenotypes/variables of interest ----------------------------------------------------------------------------
  # Use "determine_phenotypes_covariables" function modified by the consortium core
  summary_all<- determine_phenotypes_covariables (parameters_list)
  
  #Get different types of phenotypes and variables:
  #Quantitative phenotypes and variables:
  quantitative_phenotypes <- summary_all$Phenotypes[summary_all$Type == "quantitative"]
  quantitative_variables<- c(trimws(unlist(strsplit(summary_all$Quant_covar, ","))))
  quantitative_variables <- unique(quantitative_variables[!grepl("^PC\\d+$", quantitative_variables)])
  
  #Binary phenotypes and binary/categorical variables:
  binary_phenotypes <- summary_all$Phenotypes[summary_all$Type == "binary"]
  
  # Step 4.2. Create table summary_statistics all variables (binary,categorical and quantitative) and phenotypes (binary, quantitative) ----------------------------------------------------------------------------
  all_summary_statistics = data.frame(
    phenotype = "",
    variable = "",
    min = 0,
    q1 = 0,
    med = 0,
    q3 = 0,
    max = 0,
    mean = 0,
    sd = 0,
    kurtosis = 0,
    skewness = 0,
    n = 0,
    na = 0,
    cat1 = 0,
    cat2 = 0,
    cat3= 0,
    categories = 0
    
  )
  
  # Step 4.3. Create function that sumarize all variables ----------------------------------------------------------------------------
  summarize_all_variable = function(all_summary_statistics, pheno_data, pheno, var) {
    print(paste0(" - summarize variable: ", pheno, "/", var))
    
    # variable row counter
    i = nrow(all_summary_statistics) + 1
    if (i == 2) {
      if (all_summary_statistics[1, "variable"] == "") {
        i = 1
      }
    }
    
    all_summary_statistics[i, "phenotype"] = pheno
    all_summary_statistics[i, "variable"] = var
    
    if (length(which(!is.na(pheno_data[,var]))) == 0) {
      print("   - variable is completely NA")
      all_summary_statistics[i, "min"] = NA
      all_summary_statistics[i, "q1"] = NA
      all_summary_statistics[i, "med"] = NA
      all_summary_statistics[i, "q3"] = NA
      all_summary_statistics[i, "max"] = NA
      all_summary_statistics[i, "mean"] = NA
      all_summary_statistics[i, "sd"] = NA
      all_summary_statistics[i, "kurtosis"] = NA
      all_summary_statistics[i, "skewness"] = NA
      all_summary_statistics[i, "n"] = 0
      all_summary_statistics[i, "na"] = nrow(pheno_data)
      all_summary_statistics[i, "cat1"] = NA
      all_summary_statistics[i, "cat2"] = NA
      all_summary_statistics[i, "cat3"] = NA
      all_summary_statistics[i, "categories"] = NA
      
      return(all_summary_statistics)
    }
    
    #Different approach if variables or phenotypes are quantitative
    if (var %in% c(quantitative_phenotypes, quantitative_variables)) {
      summ = summary(pheno_data[, var])
      
      all_summary_statistics[i, "min"] = summ[1]
      all_summary_statistics[i, "q1"] = summ[2]
      all_summary_statistics[i, "med"] = summ[3]
      all_summary_statistics[i, "q3"] = summ[5]
      all_summary_statistics[i, "max"] = summ[6]
      all_summary_statistics[i, "mean"] = summ[4]
      all_summary_statistics[i, "sd"] = sd(pheno_data[,var], na.rm = T)
      all_summary_statistics[i, "kurtosis"] = kurtosis(pheno_data[,var], na.rm = T)
      all_summary_statistics[i, "skewness"] = skewness(pheno_data[,var], na.rm = T)
      all_summary_statistics[i, "n"] = length(which(!is.na(pheno_data[,var])))
      all_summary_statistics[i, "na"] = length(which(is.na(pheno_data[,var])))
      all_summary_statistics[i, "cat1"] = NA
      all_summary_statistics[i, "cat2"] = NA
      all_summary_statistics[i, "cat3"] = NA
      all_summary_statistics[i, "categories"] = NA
      
    } else {  #Variables and phenotypes not quantitative
      all_summary_statistics[i, "min"] = NA
      all_summary_statistics[i, "q1"] = NA
      all_summary_statistics[i, "med"] = NA
      all_summary_statistics[i, "q3"] = NA
      all_summary_statistics[i, "max"] = NA
      all_summary_statistics[i, "mean"] = NA
      all_summary_statistics[i, "sd"] = NA
      all_summary_statistics[i, "kurtosis"] = NA
      all_summary_statistics[i, "skewness"] = NA
      all_summary_statistics[i, "n"] = length(which(!is.na(pheno_data[,var])))
      all_summary_statistics[i, "na"] = length(which(is.na(pheno_data[,var])))
      cat1 <- names(table(pheno_data[,var]))[1]
      cat2 <- names(table(pheno_data[,var]))[2]
      cat3 <- names(table(pheno_data[,var]))[3]
      all_summary_statistics[i, "cat1"] = length(which(pheno_data[,var] == cat1))
      all_summary_statistics[i, "cat2"] = length(which(pheno_data[,var] == cat2))
      all_summary_statistics[i, "cat3"] = length(which(pheno_data[,var] == cat3))
      
      if (var %in% binary_phenotypes) { 
        all_summary_statistics[i, "categories"] = paste0("Cases = ", table(pheno_data[,var])[1], 
                                                         " ; Controls = ",table(pheno_data[,var])[2])
      } else {
        all_summary_statistics[i, "categories"] = paste(names(table(pheno_data[,var])), "=", table(pheno_data[,var]), collapse = "; ")
      }
    }
    return(all_summary_statistics)
  }
  
  
  # Step 4.4. Function that Summarizes phenotypes  ----------------------------------------------------------------------------
  summarize_all_phenotypes = function(all_summary_statistics, pheno_data, pheno) {
    print(paste0("summarize phenotype: ", pheno))
    #Quantitative variables
    vars.q <- c(pheno,
                trimws(unlist(strsplit(summary_all$Quant_covar[summary_all$Phenotypes == pheno], ","))))
    vars.q <- vars.q[!grepl("^PC\\d+$", vars.q)]
    
    #Cateogircal variables
    vars.c<- c(trimws(unlist(strsplit(summary_all$Cat_covar[summary_all$Phenotypes == pheno], ","))))
    
    #All types of variables
    if(!is.na(vars.c)){  #Do not worry about the warning if appear
      vars<- c(vars.q, vars.c)
    } else {
      vars<- c(vars.q)
    }
    names(vars)<- pheno
    
    #Apply function "summarize_all_variable" for each variable present in the "vars" vector. 
    for (var in vars) {
      all_summary_statistics <- summarize_all_variable(all_summary_statistics, pheno_data, pheno, var)
    }
    return(all_summary_statistics)
  }
  
  
  ############################################################################################################
  #   STEP 5. Apply function to get summary statistics
  ############################################################################################################
  # Step 5.1. Read "regenie.ids" files  ----------------------------------------------------------------------------
  for (pheno in c(quantitative_phenotypes, binary_phenotypes)) { 
    # Use "get_assoc_ids" function modified by the consortium core
    id_file<- get_assoc_ids(GWAS_tool)

    if (length(id_file) != 1) {
      print(paste0("ERROR: No (or multiple) ID file(s) found: ", id_file, "; SKIP phenotype: ", pheno))
      next
    }
    
    # Use "get_read_ids" function modified by the consortium core
    pheno_iid = get_read_ids(GWAS_tool)[,2]
    
    # Step 5.2. Subset db  ----------------------------------------------------------------------------
    pheno_data = data[data$IID %in% pheno_iid,]
    
    # Step 5.3. Apply function that sumarizes all phenotypes  --------------------------------------------
    all_summary_statistics <- summarize_all_phenotypes(all_summary_statistics, pheno_data, pheno)
  }
  
  ##################################################################################
  # Write summary statistics
  ##################################################################################
  
  print("Write summary statistics")
  write.table(all_summary_statistics, paste0("return_pheno/", fn_end_string, "_ids_summary.txt"),
              row.names = F, col.names = T, quote = F, sep = "\t")

}


if (mode == "collect") {
  if (length(arguments) != 3) {
    stop("Arguments: <parameter_file_name> or <mode> or <file_name> missing")
  }
  ############################################################################################################
  #   STEP 6.  Collect files for upload
  ############################################################################################################
  # Use "get_folder_for_upload" function modified by the consortium core
  folder_upload<- get_folder_for_upload(GWAS_tool)
  
  system(paste0("tar czvf ", arguments[3], " ", folder_upload))
  
}