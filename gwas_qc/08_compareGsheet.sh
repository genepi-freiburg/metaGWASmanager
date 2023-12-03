source ./folders.config.sh

QC_STATS=${CLEANING_DIR}/00_SUMMARY/qc-stats.csv

Rscript $SCRIPTS_DIR/08_compareGsheet.R ${URL_GSHEET} $QC_STATS

