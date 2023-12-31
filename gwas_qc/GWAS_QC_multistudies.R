############################################################################################
########                                                                            ########
########                            CKDGen R5 GWAS QC 230609                        ########
########                                                                            ########
############################################################################################

args = commandArgs(trailingOnly = T)
#PATHS
qc_stats_file= args[1]
positive_controls_file= args[2]
plug_in= args[3]
folder= args[4]

source(paste0(plug_in))

## LIBRARIES
library(data.table)


##Get QC table thresholds
tolerance_table<- get_QC_tolerance()
print(tolerance_table)

############################################################################################################
#   STEP 1.  Read qc-stats.cvs file
############################################################################################################
qc_stats<- read.csv(paste0(qc_stats_file)); dim(qc_stats)  

############################################################################################################
#   STEP 2.  Transform db into a list (one element of a list  by study population)
###########################################################################################################
# Step 2.1. Check how many cohorts are in db  ----------------------------------------------------------------------------
ids <- unique(qc_stats[, "STUDY"]); length(ids) 

# Step 2.2. List creation ----------------------------------------------------------------------------
qc_list <- list()
for (id in ids){ 
  db_sub<- qc_stats [qc_stats [, "STUDY"] == id, ]
  qc_list[[id]] <- db_sub
}

############################################################################################################
#   STEP 3.  Create GWAS-QC function
###########################################################################################################

function_QCGWAS<-function(qc_list){
  table <- character()
  #-----------------------------------------------#
  #                  Information                  #
  #-----------------------------------------------#
  study<-qc_list [, "STUDY"]
  pheno<-qc_list [, "PHENO"]
  pop<- qc_list [, "POP"]
  
  #-----------------------------------------------#
  #                Summary stats                  #
  #-----------------------------------------------#
  # A) p-value ("PVAL")
  pval_results<- character()
  for (ph in pheno) {
    pval.tolerance <- tolerance_table$pval.tol[tolerance_table$phenotype == ph]
    pval.conditions <- c(qc_list[qc_list$PHENO== ph, "PVALUE_MAX_ALL"] <= 1 & qc_list[qc_list$PHENO== ph, "PVALUE_MAX_HQ"] <= 1 &
                           abs(qc_list[qc_list$PHENO== ph, "PVALUE_MED_ALL"] - 0.5) <= pval.tolerance & abs(qc_list[qc_list$PHENO== ph, "PVALUE_MED_HQ"] - 0.5)  <= pval.tolerance & 
                           abs(qc_list[qc_list$PHENO== ph, "PVALUE_Q1_ALL"] - 0.25) <= pval.tolerance  & abs(qc_list[qc_list$PHENO== ph, "PVALUE_Q1_HQ"] - 0.25)  <= pval.tolerance &
                           abs(qc_list[qc_list$PHENO== ph, "PVALUE_Q3_ALL"] - 0.75) <= pval.tolerance  & abs(qc_list[qc_list$PHENO== ph, "PVALUE_Q3_HQ"] - 0.75)  <= pval.tolerance &
                           !is.unsorted(qc_stats[qc_list$PHENO== ph, c("PVALUE_MIN_ALL", "PVALUE_Q1_ALL", "PVALUE_MED_ALL", "PVALUE_Q3_ALL", "PVALUE_MAX_ALL")]) &
                           !is.unsorted(qc_stats[qc_list$PHENO== ph, c("PVALUE_MIN_HQ", "PVALUE_Q1_HQ", "PVALUE_MED_HQ", "PVALUE_Q3_HQ", "PVALUE_MAX_HQ")]))
    pval <- ifelse(pval.conditions, "OK", "NOT OK")
    pval_results<- cbind(pval_results, pval)
  }
  pval_results<- as.vector(pval_results)
  
  # B) Lambda ("LAMBDA)  #Differentiate among  traits
  lambda_results<- character()
  for (ph in pheno) {
    lambda.tolerance<- tolerance_table$lambda.tol[tolerance_table$phenotype == ph]
    lambda.conditions<- c(abs(qc_list[qc_list$PHENO== ph, "LAMBDA"] - 1) <= lambda.tolerance)
    lambda<- ifelse(lambda.conditions, "OK", "NOT OK")
    lambda_results<- cbind(lambda_results, lambda)
  }
  
  lambda_results<- as.vector(lambda_results)

  # C) Effect allele frequency ("A1FREQ")
  e.afreq.conditions<- c(qc_list[, "EFF_ALL_FREQ_MAX_ALL"] <= 1 & qc_list[, "EFF_ALL_FREQ_MAX_HQ"] <= 1 &
                         qc_list[, "EFF_ALL_FREQ_MIN_ALL"] >= 0 & qc_list[, "EFF_ALL_FREQ_MIN_HQ"] >= 0 &  
                         !is.unsorted(qc_stats[, c("EFF_ALL_FREQ_MIN_ALL", "EFF_ALL_FREQ_Q1_ALL", "EFF_ALL_FREQ_MED_ALL", "EFF_ALL_FREQ_Q3_ALL", "EFF_ALL_FREQ_MAX_ALL")]) &
                         !is.unsorted(qc_stats[, c("EFF_ALL_FREQ_MIN_HQ", "EFF_ALL_FREQ_Q1_HQ", "IMP_QUALITY_MED_HQ", "IMP_QUALITY_Q3_HQ", "IMP_QUALITY_MAX_HQ")]))
  e.afreq <- ifelse(e.afreq.conditions, "OK", "NOT OK")

  
  # D) Imputation quality ("IMPQUAL")
  impqual_results<- character()
  for (ph in pheno) {
    impqual.tolerance<- tolerance_table$impqual.tol[tolerance_table$phenotype == ph]
    impqual.conditions<- c(qc_list[qc_list$PHENO== ph, "IMP_QUALITY_MIN_ALL"]>= 0.3 & qc_list[qc_list$PHENO== ph, "IMP_QUALITY_MIN_HQ"]>= 0.3 &
                             qc_list[qc_list$PHENO== ph, "IMP_QUALITY_MAX_ALL"]== 1 & qc_list[qc_list$PHENO== ph, "IMP_QUALITY_MAX_HQ"]== 1 &
                             abs(qc_list[qc_list$PHENO== ph, "IMP_QUALITY_MED_ALL"] - 1)<= impqual.tolerance & abs(qc_list[qc_list$PHENO== ph, "IMP_QUALITY_MED_HQ"] - 1)  <= impqual.tolerance &
                             !is.unsorted(qc_list[qc_list$PHENO== ph, c("IMP_QUALITY_MIN_ALL", "IMP_QUALITY_Q1_ALL", "IMP_QUALITY_MED_ALL", "IMP_QUALITY_Q3_ALL", "IMP_QUALITY_MAX_ALL")]) == "TRUE" &
                             !is.unsorted(qc_list[qc_list$PHENO== ph, c("IMP_QUALITY_MIN_HQ", "IMP_QUALITY_Q1_HQ", "IMP_QUALITY_MED_HQ", "IMP_QUALITY_Q3_HQ", "IMP_QUALITY_MAX_HQ")]) == "TRUE")
    impqual<- ifelse(impqual.conditions, "OK", "NOT OK") 
    impqual_results<- cbind(impqual_results, impqual)
  }
  impqual_results<- as.vector(impqual_results)
  
  
  # E) Effect size ("BETA")
  beta_results<- character()
  for (ph in pheno) {
    beta.tolerance<- tolerance_table$beta.tol[tolerance_table$phenotype == ph]
    beta.conditions<- c(abs(qc_list[qc_list$PHENO== ph, "BETA_MED_ALL"] - 0) <= beta.tolerance & abs(qc_list[qc_list$PHENO== ph, "BETA_MED_HQ"] - 0)  <= beta.tolerance &
                          abs(qc_list[qc_list$PHENO== ph, "BETA_MIN_ALL"]) >= abs(qc_list[qc_list$PHENO== ph, "BETA_MIN_HQ"]) &
                          abs(qc_list[qc_list$PHENO== ph, "BETA_Q1_ALL"]) >= abs(qc_list[qc_list$PHENO== ph, "BETA_Q1_HQ"]) &
                          abs(qc_list[qc_list$PHENO== ph, "BETA_MED_ALL"]) >= abs(qc_list[qc_list$PHENO== ph, "BETA_MED_HQ"]) &
                          abs(qc_list[qc_list$PHENO== ph, "BETA_Q3_ALL"]) >= abs(qc_list[qc_list$PHENO== ph, "BETA_Q3_HQ"]) &
                          abs(qc_list[qc_list$PHENO== ph, "BETA_MAX_ALL"]) >= abs(qc_list[qc_list$PHENO== ph, "BETA_MAX_HQ"]) &
                          !is.unsorted(qc_list[qc_list$PHENO== ph, c("BETA_MIN_ALL", "BETA_Q1_ALL", "BETA_MED_ALL", "BETA_Q3_ALL", "BETA_MAX_ALL")]) == "TRUE" &
                          !is.unsorted(qc_list[qc_list$PHENO== ph, c("BETA_MIN_HQ", "BETA_Q1_HQ", "BETA_MED_HQ", "BETA_Q3_HQ", "BETA_MAX_HQ")]) == "TRUE")
    beta<- ifelse(beta.conditions, "OK", "NOT OK")
    beta_results<- cbind(beta_results, beta)
  }
  beta_results<- as.vector(beta_results)
  
  # F) Standard error ("STDERR")
  stderr.conditions<- c(qc_list[, "STDERR_MIN_ALL"] >= 0  & qc_list[, "STDERR_Q1_ALL"] >= 0  & qc_list[, "STDERR_MEAN_ALL"] >= 0  & qc_list[, "STDERR_MED_ALL"]>= 0  & qc_list[, "STDERR_Q3_ALL"] >= 0  & qc_list[, "STDERR_MAX_ALL"] >= 0 &
                          qc_list[, "STDERR_MIN_HQ"] >= 0  & qc_list[, "STDERR_Q1_HQ"] >= 0  & qc_list[, "STDERR_MEAN_HQ"] >= 0  & qc_list[, "STDERR_MED_HQ"] >= 0  & qc_list[, "STDERR_Q3_HQ"]>= 0  & qc_list[, "STDERR_MAX_HQ"] >= 0 &
                          abs(qc_list[, "STDERR_MIN_ALL"]) >= abs(qc_list[, "STDERR_MIN_HQ"]) &
                          abs(qc_list[, "STDERR_Q1_ALL"]) >= abs(qc_list[, "STDERR_Q1_HQ"]) &
                          abs(qc_list[, "STDERR_MEAN_ALL"]) >= abs(qc_list[, "STDERR_MEAN_HQ"]) &
                          abs(qc_list[, "STDERR_MED_ALL"]) >= abs(qc_list[, "STDERR_MED_HQ"]) &
                          abs(qc_list[, "STDERR_Q3_ALL"]) >= abs(qc_list[, "STDERR_Q3_HQ"]) &
                          abs(qc_list[, "STDERR_MAX_ALL"]) >= abs(qc_list[, "STDERR_MAX_HQ"]) &
                          !is.unsorted(qc_stats[, c("STDERR_MIN_ALL", "STDERR_Q1_ALL", "STDERR_MED_ALL", "STDERR_Q3_ALL", "STDERR_MAX_ALL")]) == "TRUE" &
                          !is.unsorted(qc_stats[, c("STDERR_MIN_HQ", "STDERR_Q1_HQ", "STDERR_MED_HQ", "STDERR_Q3_HQ", "STDERR_MAX_HQ")]) == "TRUE")
  stderr<- ifelse(stderr.conditions, "OK", "NOT OK")

  #-----------------------------------------------#
  #          Allele frequency correlation         #  ###### Somth BES-610 Sample size? should we add a if?
  #-----------------------------------------------#
  afreq.corr_results<- character()
  for (ph in pheno) {
    afreq.corr.tolerance<- tolerance_table$afreq.tol[tolerance_table$phenotype == ph]
    afreq.corr.conditions<- c(abs(qc_list[qc_list$PHENO== ph, "AF_CORRELATION_ALL"] - 1)<= afreq.corr.tolerance)
    afreq.corr<- ifelse(afreq.corr.conditions, "OK", "NOT OK") 
    afreq.corr_results<- cbind(afreq.corr_results, afreq.corr)
  }
  afreq.corr_results<- as.vector(afreq.corr_results)
  
  #-----------------------------------------------#
  #            Variants per chromosome            #
  #-----------------------------------------------#
  # Should be consistent across phenotypes (gaps might indicate lost chunks)
  # Expect lower counts for analyses with lower N (such as sex-stratified)
  # Extract Variants columns and converto to numeric
  variants <- qc_list[, grep("^VARIANTS", colnames(qc_list))]
  convert_numeric <- function(variants) {
    if (grepl(",", variants)) {
      return(as.numeric(gsub(",", "", variants)))
    } else {
      return(as.numeric(variants))
    }
  }
  variants <- as.data.frame(apply(variants, c(1, 2), convert_numeric))
  rownames(variants)<-qc_list [, "PHENO"]
  
  #Intra pheno comparison 
  #Diference between columns no more than X %of the max column. Be careful betwen chr20 and chr 21
  intra_pheno_comp <- data.frame(matrix(FALSE, nrow = nrow(variants), ncol = ncol(variants) -1))
  for (i in 1:(ncol(variants) - 2)) {
    per_threshold <- if (i == 20) 0.5 else 0.25
    intra_pheno_comp[, i] <- abs(variants[, i + 1] - variants[, i] ) <= per_threshold * pmax(variants[, i], variants[, i + 1])
  }
  intra_pheno_comp[, 22]<- ifelse(variants$VARIANTS_CHR_23 < variants$VARIANTS_CHR_1 & 
                                variants$VARIANTS_CHR_23 > variants$VARIANTS_CHR_22, TRUE, FALSE)
  
  #Inter pheno comparison 
  #Create list with type of phenotype categories
  quantitative_rows <- tolerance_table[tolerance_table$type == "quantitative", ]
  category_suff <- unique(sapply(strsplit(quantitative_rows$phenotype, "_"), function(x) tail(x, 1)))
  categories_list<-list()
  for (suff in category_suff) {
    categories_list[[suff]] <- variants[grep(paste0(suff, "$"), rownames(variants)), ]
  }
  categories_list[["other"]] <- variants[!grepl(paste0("(", paste(category_suff, collapse = "|"), ")$"), rownames(variants)) , ]
  
  # Create df to save reuslts
  inter_pheno_comp <- as.character()
  #Comparisons between categories
  for (category in categories_list) {
    if(dim(category)[1] != 0 & dim(category)[1] != 1) { #=0--> cat doesnt exist; =1 --> impossible to compare (min 2 pheno same cat)
      for (i in 1:(nrow(category) - 1)) {
        result<- abs(category[i + 1 ,] - category[i ,] ) <= 0.40 * pmax(category[i, ], category[i + 1,])
        inter_pheno_comp<- rbind(inter_pheno_comp, result)
      }
    }
  }
  
  if (is.data.frame(inter_pheno_comp)) {
    var.per.chr.conditons<- c(!any(variants == 0) & apply(intra_pheno_comp, 1, all) &  apply(inter_pheno_comp, 1, all) &
                                variants$VARIANTS_CHR_1 >= 700000)
  } else {
    var.per.chr.conditons<- c(!any(variants == 0) & apply(intra_pheno_comp, 1, all) & variants$VARIANTS_CHR_1 >= 700000)
  }
  var.per.chr<-ifelse(var.per.chr.conditons, "OK", "NOT OK")
  

  #-----------------------------------------------#
  #                Positive controls              #
  #-----------------------------------------------#
  positive_controls<- read.csv(paste0(positive_controls_file)); dim(positive_controls)  
  
  #Subset positive controls  
  subset_positive_controls <- subset(positive_controls, positive_controls$study_name %in% qc_list$STUDY)
  #Create table results
  posit.control<-as.data.frame(qc_list$PHENO)
  posit.control$result<-"NO_DATA"
  if (!is.null(subset_positive_controls) && nrow(subset_positive_controls) > 0) {
    for (i in 1:length(qc_list$PHENO %in% subset_positive_controls$PHENO)) {
      posit.control[i, "result"] <- subset_positive_controls[i, "rate_overall"] 
    }
  }

  result <- cbind(study, pheno, pop, pval_results, lambda_results, e.afreq, impqual_results, beta_results, stderr,afreq.corr_results, var.per.chr, posit.control$result)
  table <- rbind(table, result)
  return(table)
}


############################################################################################################
#   STEP 4.  Let's apply the function!!!!
###########################################################################################################
start<-Sys.time()
res_sub <- lapply(qc_list, function_QCGWAS) 
stop<- Sys.time()
print(stop- start)


# Step 4.4. Join results (elements of a list) and write ----------------------------------------------------------------------------
res_final<-do.call("rbind",res_sub); print(dim(res_final)) #413   7
res_final <- as.data.frame(res_final, row.names = F)
names(res_final) <- c("study", "pheno", "pop", "pval","lambda", "effect_afreq", "impqual", "beta","stderr", "allel_freq", "vars.per.chr", "positive_control") 
write.csv(res_final,  paste0(folder,"/Auto_QC_", get_consortium_name (), ".csv"), row.names = F)






