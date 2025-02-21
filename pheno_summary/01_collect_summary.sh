source ../gwas_qc/folders.config.sh

PHENO_SUMSSTATS=${PHENO_UPLOAD_DIR}/00_SUMMARY

mkdir -p $PHENO_SUMSSTATS

Rscript 01_collect_summary.R $PHENO_SUMSSTATS