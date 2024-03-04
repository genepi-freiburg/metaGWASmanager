source ./folders.config.sh

IN=${CLEANING_DIR}/00_SUMMARY/qc-stats.csv

mkdir -p ${CLEANING_DIR}/00_SUMMARY/plots
OUT=${CLEANING_DIR}/00_SUMMARY/plots

Rscript $SCRIPTS_DIR/05_plot_qc_stats.R $IN $OUT
