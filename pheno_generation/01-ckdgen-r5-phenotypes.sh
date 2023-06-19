#!/bin/bash

if [ "$1" == "" ]
then
	echo "Please pass the parameter file name as the first argument."
	exit 1
fi

chmod 0755 *.jobs
mkdir -p return_pheno output_pheno regenie_temp logs
Rscript ckdgen-r5.R $1 pheno | tee return_pheno/pheno_script_output.log

