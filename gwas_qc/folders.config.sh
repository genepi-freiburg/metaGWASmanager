#!/bin/bash

# this script combines REGENIE step 2 outputs per phenotype
# it has some logic to determine the phenotype name from the filename,
# it adds a PVAL column as 10^-LOG10P,
# it uses bgzip and tabix on the file(s)

module load snippy/4.4.1-foss-2018b-Perl-5.28.0
module load HTSlib/1.15.1-GCC-11.3.0

STUDY_ID=$1

if [ ! -d "$STUDY_ID" ]
then
	echo "Please study name as the first argument to this script."
	exit 9
fi

PREFIX=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline_core
SCRIPTS_DIR=$PREFIX/scripts/gwas_qc
PHENO_UPLOAD_DIR=$PREFIX/uploads/pheno/$STUDY_ID
GWAS_UPLOAD_DIR=$PREFIX/uploads/assoc/$STUDY_ID
CLEANING_DIR=$PREFIX/cleaning/$STUDY_ID


bash ./01_combine_chromosomes.sh\
    ${GWAS_UPLOAD_DIR}/output_regenie_step2 \
    ${CLEANING_DIR}/data


echo "Done."

