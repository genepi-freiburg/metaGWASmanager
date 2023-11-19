source ./folders.config.sh

SCRIPT_DIR=$SCRIPTS_DIR

IN=${PREFIX}/00_SUMMARY/qc-stats.csv

mkdir -p ${PREFIX}/00_SUMMARY/plots
OUT=${PREFIX}/00_SUMMARY/plots

Rscript $SCRIPT_DIR/05-plot-qc-stats.R $IN $OUT
