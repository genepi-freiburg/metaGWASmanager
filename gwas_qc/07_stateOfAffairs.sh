source ./folders.config.sh

QC_STATS=${CLEANING_DIR}/00_SUMMARY/qc-stats.csv

Rscript $SCRIPTS_DIR/07_stateOfAffairs.R $PHENO_UPLOAD_DIR $GWAS_UPLOAD_DIR $CLEANING_DIR $QC_STATS
