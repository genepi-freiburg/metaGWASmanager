#!/bin/bash

if [ "$1" == "" ]
then
  echo "Please give your study name as the first argument."
  exit 3
fi

MY_DATE=$(date +%F)
OUTFN=consortium-upload-$1-${MY_DATE}.tgz
echo "Building .tar.gz archive: $OUTFN"
tar czvf $OUTFN return_pheno output_regenie_step2 output_regenie_step1/*.log logs
