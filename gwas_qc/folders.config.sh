#!/bin/bash

#Adjusted the script according your requirements

#Add path where you are working on
export PREFIX=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline_core

#Add path to scripts directory
export SCRIPTS_DIR=$PREFIX/scripts/gwas_qc

#Add path to phenotype folder in upload directory
export PHENO_UPLOAD_DIR=$PREFIX/uploads/pheno

#Add path to associations folder in upload directory
export GWAS_UPLOAD_DIR=$PREFIX/uploads/assoc

#Add path to cleaning directory
export CLEANING_DIR=$PREFIX/cleaning

#Add path to downloaded databases
export REF_DIR=$PREFIX/databases

#Add path to your google sheet
export URL_GSHEET=https://docs.google.com/spreadsheets/d/e/SH9l5_nyjckvtnZBtASFdw-fToluOPIU-CEIWw_xdeqdd7ry2SbLzPd-Zx/pub?output=csv

#Add your phenotypes vector
export PHENOTYPES="ckd ma gout albumin_serum_int egfr_creat_int egfr_cys_int uacr_int urate_serum_int calcium_serum_int phosphate_serum_int egfr_creat_male egfr_creat_female egfr_cys_male egfr_cys_female uacr_ln_male uacr_ln_female urate_serum_male urate_serum_female"

#Add your type of data vector
export STRATA="binary_overall quantitative_overall quantitative_sex_stratified"

#Add your specific ancestry vector
export ANCESTRY="EUR EAS SAS AFR AMR HIS MID"

#Add to input file name needed for meta-analysisis
export INPUT_MA_FILE=$PREFIX/metaanalysis/input-file-list.txt

echo "Done."

