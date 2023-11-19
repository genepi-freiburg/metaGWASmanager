source ./folders.config.sh

SCRIPT_DIR=$SCRIPTS_DIR
GSHEET=$URL_GSHEET
QC_STATS=${PREFIX}/00_SUMMARY/qc-stats.csv

Rscript $SCRIPT_DIR/08_compareGsheet.R $GSHEET $QC_STATS

