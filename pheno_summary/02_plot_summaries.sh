source ../gwas_qc/folders.config.sh

PHENO_SUMSSTATS=${PHENO_UPLOAD_DIR}/00_SUMMARY

mkdir -p $OUTPUT

Rscript 02_plot_summaries.R $PHENO_SUMSSTATS