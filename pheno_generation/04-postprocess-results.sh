#!/bin/bash

module load R/4.1.0-foss-2021a

echo "Checking log files for completeness"
bash check_step1_logs.sh | grep ERROR | tee return_pheno/check_step1_logs.log
bash check_step2_logs.sh | grep ERROR | tee return_pheno/check_step2_logs.log

echo "Invoke post-process script"
Rscript consortium-postprocess.R $1 | tee return_pheno/postprocess_output.log
