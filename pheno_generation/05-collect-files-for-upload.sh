#!/bin/bash
module load R/4.1.0-foss-2021a

if [ "$1" == "" ]
then
  echo "Please give your study name as the first argument."
  exit 3
fi

MY_DATE=$(date +%F)
OUTFN=consortium-upload-$1-${MY_DATE}.tgz
echo "Building .tar.gz archive: $OUTFN"
 Rscript consortium-postprocess.R $1 collect $OUTFN
