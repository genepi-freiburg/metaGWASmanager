#!/bin/bash

# this script combines REGENIE step 2 outputs per phenotype
# it has some logic to determine the phenotype name from the filename,
# it adds a PVAL column as 10^-LOG10P,
# it uses bgzip and tabix on the file(s)

#If it is necesary
#module load snippy/4.4.1-foss-2018b-Perl-5.28.0
#module load HTSlib/1.15.1-GCC-11.3.0
#module load R/4.1.0-foss-2021a
#module load FlexiBLAS/3.2.0-GCC-11.3.0


export PREFIX=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline_core
export SCRIPTS_DIR=$PREFIX/scripts/gwas_qc
export PHENO_UPLOAD_DIR=$PREFIX/uploads/pheno
export GWAS_UPLOAD_DIR=$PREFIX/uploads/assoc
export CLEANING_DIR=$PREFIX/cleaning
export REF_DIR=$PREFIX/databases
export URL_GSHEET=https://docs.google.com/spreadsheets/d/e/2PACX-1vQjwLVm9EI9mpOOIyt3zdSH9l5_nyjckvtnZBtASFdw-fToluOPIU-CEIWw_xdeqdd7ry2SbLzPd-Zx/pub?output=csv
export PHENOTYPES="_ckd _ma _gout _albumin_serum_int _egfr_creat_int _egfr_cys_int _uacr_int _urate_serum_int _calcium_serum_int _phosphate_serum_int _egfr_creat_male _egfr_creat_female _eg
fr_cys_male _egfr_cys_female _uacr_ln_male _uacr_ln_female _urate_serum_male _urate_serum_female"
export STRATA="binary_overall_ quantitative_overall_ quantitative_sex_stratified_"
export ANCESTRY="EUR_ EAS_ SAS_ AFR_ AMR_ HIS_ MID_"


echo "Done."

