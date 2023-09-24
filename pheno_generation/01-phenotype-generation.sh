#!/bin/bash
# module load R/4.1.0-foss-2021a


if [ "$1" == "" ]
then
	echo "Please pass the parameter file name as the first argument."
	exit 1
fi

mkdir -p jobs return_pheno output_pheno regenie_temp logs
# chmod 0755 *.jobs

Rscript consortium.R $1 pheno | tee return_pheno/pheno_script_output.log