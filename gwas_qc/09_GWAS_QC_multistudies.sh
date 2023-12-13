
source ./folders.config.sh

QC_STATS=${CLEANING_DIR}/00_SUMMARY/qc-stats.csv
POS_CTR=${CLEANING_DIR}/00_SUMMARY/positive-controls.csv
PLUG_IN=$PREFIX/scripts/pheno_generation/consortium-specifics.R
OUTPUT=${CLEANING_DIR}/00_SUMMARY/GWAS-QC_results

mkdir -p $OUTPUT

Rscript ${SCRIPTS_DIR}/GWAS_QC_multistudies.R $QC_STATS $POS_CTR $PLUG_IN $OUTPUT