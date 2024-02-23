#!/bin/bash

module load R/4.1.0-foss-2021a
# this script assumes Slurm
# this will work different with your job scheduler
# but the principles should be the same

echo "Checking log files for completeness"
Rscript consortium-postprocess.R $1 log 

 echo "Invoke post-process script"
 Rscript consortium-postprocess.R $1 post | tee return_pheno/postprocess_output.log