#!/bin/bash

module load R/4.1.0-foss-2021a
# this script assumes Slurm
# this will work different with your job scheduler
# but the principles should be the same


if [ "$1" == "" ]
then
        echo "Please pass the parameter file name as the first argument."
        exit 1
fi

Rscript consortium.R $1 submit 

echo "Submit all association jobs"
chmod 0755 ./submit-all-jobs.sh
./submit-all-jobs.sh 
