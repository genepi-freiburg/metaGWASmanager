
##############################################
###             Mode =  "Jobs"              ##
##############################################

# FUNCTION 1 --- MAKE JOBS ACCORDING TO THE SELECTED ASSOCIATION TOOL
make_assoc_jobs <- function(jobs_phenos, GWAS_tool, parameters_list, study_covar_cols, study_cat_cols) {
  script_fn <- paste0("output_pheno/make-assoc-jobs.sh")
  cat("#!/bin/bash
", file = script_fn, append = F)
  
  run_idx = 0
  phenos<- jobs_phenos$Phenotypes
  
  missing_phenos <- c()
  for (i in 1:length(phenos)) {
    pheno = phenos[i]
    if (length(which(!is.na(result[, pheno]))) == 0) {
      print(paste("Omitting phenotype", pheno, "as it is missing completely."))
      missing_phenos = c(missing_phenos, i)
    }
  }
  
  if (length(missing_phenos) > 0) {
    phenos <- phenos[-missing_phenos]
  }
  
  for (pheno in phenos) {
    age <- age_for_phenotype[pheno]
    if (is.na(age)) {
      stop(paste0("unexpected phenotype: ", pheno))
    }
    
    quant_covars <- c(jobs_phenos[jobs_phenos$Phenotypes == pheno, "Quant_covar"], study_covar_cols)
    cat_covars <- c(jobs_phenos[jobs_phenos$Phenotypes == pheno, "Cat_covar"], study_cat_covar_cols)
    type <- jobs_phenos[jobs_phenos$Phenotypes == pheno, "Type"]
    
    run_idx = run_idx + 1
    print(paste0("== RUN ", run_idx, ": ", type))
    print(paste0("Phenotype: ", pheno))
    print(paste0("Quantitative covariates: ", paste(quant_covars, collapse=", ")))
    if(!is.na(cat_covars)) {
      print(paste0("Categorical covariates: ", paste(cat_covars, collapse=", ")))
    }
    
    if (GWAS_tool=="regenie"){
      folders <- c("regenie_temp", "logs", "output_regenie_step1", "output_regenie_step2", "jobs")
      # Create regenie folders
      for (folder in folders) {
        dir.create(folder, recursive = TRUE, showWarnings = FALSE)
      }
      
      #Create jobs
      for (step in c("step1", "step2")) {  
        if(is.na(cat_covars)){
          cat(paste0("assoc_tool/make-regenie-", step, "-job-scripts.sh ",
                     parameters_list$study_name, " ",
                     parameters_list$ancestry, " ",
                     parameters_list$refpanel, " ", 
                     parameters_list$analysis_date, " ",
                     type, " ",
                     pheno, " '",
                     quant_covars, "' '",
                     "' ",
                     run_idx, "\n"),
              append = T, file = script_fn)
        } else {
          cat(paste0("assoc_tool/make-regenie-", step, "-job-scripts.sh ",
                     parameters_list$study_name, " ",
                     parameters_list$ancestry, " ",
                     parameters_list$refpanel, " ", 
                     parameters_list$analysis_date, " ",
                     type, " ",
                     pheno, " '",
                     quant_covars, "' '",
                     cat_covars, "' ",
                     run_idx, "\n"),
              append = T, file = script_fn)
        }
      }
      
    } else {
      if (GWAS_tool=="plink") {
        
        #Create folders
        folders <- c("plink_temp", "logs", "output_plink","jobs")
        # Create folders
        for (folder in folders) {
          dir.create(folder, recursive = TRUE, showWarnings = FALSE)
        }
        
        #Create plink jobs
        if(is.na(cat_covars)){
          covars<- paste(quant_covars, sep = ",") 
        } else {
          covars<- paste(cat_covars, quant_covars, sep = ",")
          cat_covars_s<-strsplit(cat_covars, ",")[[1]]
          result[cat_covars_s] <- lapply(result[cat_covars_s], function(x) replace(x, is.na(x), "NONE"))
          write.table(result, data_fn, 
                      row.names = F, col.names = T, sep = "\t", quote = F)
        }
        cat(paste0("assoc_tool/make-plink-job-scripts.sh ",
                   parameters_list$study_name, " ",
                   parameters_list$ancestry, " ",
                   parameters_list$refpanel, " ", 
                   parameters_list$analysis_date, " ",
                   type, " ",
                   pheno, " '",
                   covars, "' ",
                   run_idx, "\n"),
            append = T, file = script_fn)
        
      }#Plink assoc tool
      
    }
    
  }
  
  if (run_idx == 0) {
    print("ERROR: No runs planned. Everything missing?")
  } else {
    print(paste0("Planned ", run_idx, " runs."))
  }
}


# FUNCTION 2 --- SUBMIT ALL JOBS ACCORDING TO THE SELECTED ASSOCIATION TOOL
create_submit_all_jobs_script <- function(GWAS_tool) {
  if (GWAS_tool=="regenie"){
    
    bash_script <- "
#!/bin/bash

for STEP1_JOB_FN in $(ls jobs/*_regenie_step1_*.sh)
do
    # we need the AWK command to extract the job ID (sbatch returns 'Submitted batch job 123')
    STEP1_JOB=$(sbatch $STEP1_JOB_FN | awk '{ print $4 }')
    echo \"Submitted REGENIE step 1 job: ID = $STEP1_JOB, File = $STEP1_JOB_FN\"

    STEP2_JOB_FNS=$(echo $STEP1_JOB_FN | sed 's/step1/step2/' | sed 's/.sh/_chr*.sh/')

    for STEP2_JOB_FN in $(ls $STEP2_JOB_FNS)
    do
        sbatch -d afterok:$STEP1_JOB $STEP2_JOB_FN
        echo \"Submitted REGENIE step 2 job after step 1 is ok: $STEP2_JOB_FN\"
    done
done
"
    #write
    writeLines(bash_script, "submit-all-jobs.sh")
    
  } else {
    if ((GWAS_tool=="plink")) {
      bash_script <- "
#!/bin/bash
for JOB_FN in `ls jobs/*_plink_*.sh`
		do
		JOB=$(sbatch $JOB_FN | awk '{ print $4 }')
		echo \"Submitted PLINK : ID = $JOB, File = $JOB_FN\"
	done
"
      #write
      writeLines(bash_script, "submit-all-jobs.sh")
      
    }
  }
  
}

##############################################
###             GWAS_post-process           ##
##############################################
# FUNCTION 3 --- CHECK LOG FILES ACCORDING TO THE SELECTED ASSOCIATION TOOL
check_log_files <- function(GWAS_tool) {
  if (GWAS_tool=="regenie"){
    
    bash_script1 <- "
#!/bin/bash

for JOB_NUM in `ls -l jobs/*step1* | cut -d\"_\" -f7 | sort -n`
do
	LOG_FILE=$(ls output_regenie_step1/*_${JOB_NUM}.log 2>/dev/null)
	if [ \"$?\" -ne 0 ]
	then
		echo \"ERROR: Step 1 log file for job $JOB_NUM does not exist.\"
	else
		end_time=$(grep \"End time\" $LOG_FILE)
		if [ \"$end_time\" == \"\" ]
		then
			echo \"ERROR: Step 1 run $JOB_NUM did not complete successfully: $LOG_FILE\"
		else
			echo \"OK: Step 1 run $JOB_NUM: $end_time\"
		fi
	fi
done
"
    bash_script2 <- "
#!/bin/bash

for JOB_NUM in `ls -l jobs/*step1* | cut -d\"_\" -f7 | sort -n`
do
for CHR in `seq 1 22` X
do
	LOG_FILE=$(ls output_regenie_step2/*_${JOB_NUM}_chr${CHR}.log 2>/dev/null)
	if [ \"$?\" -ne 0 ]
	then
		echo \"ERROR: Step 2 log file for job $JOB_NUM / chromosome $CHR does not exist.\"
	else
		end_time=$(grep \"End time\" $LOG_FILE)
		if [ \"$end_time\" == \"\" ]
		then
			echo \"ERROR: Step 2 run $JOB_NUM / chromosome $CHR did not complete successfully: $LOG_FILE\"
		else
			echo \"OK: Step 2 run $JOB_NUM / chromosome $CHR: $end_time\"
		fi
	fi
done
done
"
    #write
    writeLines(bash_script1, "check_step1_logs.sh")
    writeLines(bash_script2, "check_step2_logs.sh")
    
    #submit
    system("bash check_step1_logs.sh | grep ERROR | tee return_pheno/check_step1_logs.log")
    system("bash check_step2_logs.sh | grep ERROR | tee return_pheno/check_step2_logs.log")
    
    
  } else {
    if ((GWAS_tool=="plink")) {
      bash_script1 <- "
#!/bin/bash

for JOB_NUM in `ls -l jobs/*plink* | cut -d\"_\" -f6 | sort -n`
do
for CHR in `seq 1 22` X
do
	LOG_FILE=$(ls output_plink/*_${JOB_NUM}_chr${CHR}.log 2>/dev/null)
	if [ \"$?\" -ne 0 ]
	then
		echo \"ERROR: log file for job $JOB_NUM / chromosome $CHR does not exist.\"
	else
		end_time=$(grep \"End time\" $LOG_FILE)
		if [ \"$end_time\" == \"\" ]
		then
			echo \"ERROR: plink run $JOB_NUM / chromosome $CHR did not complete successfully: $LOG_FILE\"
		else
			echo \"OK: plink run $JOB_NUM / chromosome $CHR: $end_time\"
		fi
	fi
done
done
"
      #write
      writeLines(bash_script1, "check_logs.sh")
      
      #submit
      system("bash check_logs.sh | grep ERROR | tee return_pheno/check_logs.log")
      
    }
  }
  
}


# FUNCTION 4 --- GET IDS FILE FOR SUMSTATS ACCORDING TO THE SELECTED ASSOCIATION TOOL
get_assoc_ids<- function(GWAS_tool) {
  if (GWAS_tool=="regenie"){
    id_file_pattern = paste0(fn_end_string, "_.*_chr1_", pheno, ".regenie.ids")
    id_file = list.files(path = "output_regenie_step2", 
                         pattern = id_file_pattern)
  } else {
    if ((GWAS_tool=="plink")) {
      id_file_pattern = paste0(fn_end_string, "_.*_.*_chr1.", pheno, "\\.glm..*")
      id_file = list.files(path = "output_plink", 
                           pattern = id_file_pattern)
      id_file<-sub(paste0(pheno, ".*"), "id", id_file)
    }
  }
  return(id_file)
}

# FUNCTION 15 --- GET IDs FILE ACCORDING TO THE SELECTED ASSOCIATION TOOL
get_read_ids<- function(GWAS_tool) {
  if (GWAS_tool=="regenie"){
    pheno_ids = read.table(paste0("output_regenie_step2/", id_file), h=T)
  } else {
    if ((GWAS_tool=="plink")) {
      pheno_ids = read.table(paste0("output_plink/", id_file), h=F)
    }
  }
  return(pheno_ids)
}


# FUNCTION 5 --- SELECT FOLDER TO UPLOAD (NO INDIVUAL DATA) ACCORDING TO THE SELECTED ASSOCIATION TOOL
get_folder_for_upload<- function(GWAS_tool) { # Separete folder by spaces
  if (GWAS_tool=="regenie"){
    folders <- c("return_pheno output_regenie_step2 output_regenie_step1/*.log logs")
  } else {
    if ((GWAS_tool=="plink")) {
      folders <- c("return_pheno logs output_plink/ | grep -v '\\.id$'")
    }
  }
  return(folders)
}

