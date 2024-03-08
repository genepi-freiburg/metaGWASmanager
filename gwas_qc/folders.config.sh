#!/bin/bash

#Adjusted the script according your requirements

#Add path where you are working on
export PREFIX=/data/cne/ec/ieg/Crew/zulema.rodriguez/storage_regenie

#Add path to scripts gwas_qc directory
export SCRIPTS_DIR=$PREFIX/scripts/gwas_qc

#Add path to phenotype folder in upload directory
export PHENO_UPLOAD_DIR=$PREFIX/uploads/pheno

#Add path to associations folder in upload directory
export GWAS_UPLOAD_DIR=$PREFIX/uploads/assoc

#Add association tool used
export ASSOC_TOOL=regenie #For plink "plink"

#In case you did not use regenie, probably you should change columns names and order
#to properly execute the metaGWASmanager pipeline
#Please provide a script to adjust columns. Here an example in case you use plink
export SUPPORT_SCRIPT=order_assoc_results_columns.sh

#Add name of associations results
export ASSOC_FOLDER=output_regenie_step2  #For plink it would be "output_plink"

#Add path to cleaning directory
export CLEANING_DIR=$PREFIX/cleaning

#Add path to downloaded databases
export REF_DIR=$PREFIX/databases

#Add your phenotypes vector
export PHENOTYPES="ckd ma gout albumin_serum_int egfr_creat_int egfr_cys_int uacr_int urate_serum_int calcium_serum_int phosphate_serum_int egfr_creat_male egfr_creat_female egfr_cys_male egfr_cys_female uacr_ln_male uacr_ln_female urate_serum_male urate_serum_female"

#Add your type of data vector
export STRATA="binary_overall quantitative_overall quantitative_sex_stratified"

#Add your specific ancestry vector
export ANCESTRY="EUR EAS SAS AFR AMR HIS MID"

#Add path to scripts metaanalysis directory
export SCRIPTS_MA=$PREFIX/scripts/metaanalysis


echo "Done."

