#!/bin/bash

module load R/4.1.0-foss-2021a

if [ "$1" == "" ]
then
        echo "Please pass the parameter file name as the first argument."
        exit 1
fi

Rscript consortium.R $1 jobs | tee return_pheno/jobs_script_output_1.log

echo "Generate job scripts"
chmod 0755 ./output_pheno/*.sh
./output_pheno/make-assoc-jobs.sh | tee return_pheno/jobs_script_output_2.log

