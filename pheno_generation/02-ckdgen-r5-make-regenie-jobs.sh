#!/bin/bash

if [ "$1" == "" ]
then
        echo "Please pass the parameter file name as the first argument."
        exit 1
fi

mkdir -p regenie_temp logs output_regenie_step1 output_regenie_step2 jobs
Rscript ckdgen-r5.R $1 jobs | tee return_pheno/jobs_script_output_1.log

echo "Generate job scripts"
chmod 0755 ./output_pheno/*.sh
./output_pheno/make-regenie-jobs.sh | tee return_pheno/jobs_script_output_2.log

