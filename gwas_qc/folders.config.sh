#!/bin/bash

# this script combines REGENIE step 2 outputs per phenotype
# it has some logic to determine the phenotype name from the filename,
# it adds a PVAL column as 10^-LOG10P,
# it uses bgzip and tabix on the file(s)

#If it is necesary
module load snippy/4.4.1-foss-2018b-Perl-5.28.0
module load HTSlib/1.15.1-GCC-11.3.0
module load R/4.1.0-foss-2021a
module load FlexiBLAS/3.2.0-GCC-11.3.0

STUDY_ID=$1

if [ ! -d "$STUDY_ID" ]
then
	echo "Please study name as the first argument to this script."
	exit 9
fi

export PREFIX=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline_core
export SCRIPTS_DIR=$PREFIX/scripts/gwas_qc
export PHENO_UPLOAD_DIR=$PREFIX/uploads/pheno/$STUDY_ID
export GWAS_UPLOAD_DIR=$PREFIX/uploads/assoc/$STUDY_ID
export CLEANING_DIR=$PREFIX/cleaning/$STUDY_ID
export REF_DIR=$PREFIX/databases

echo "Done."

