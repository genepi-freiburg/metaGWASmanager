
#!/bin/bash

STUDY_ID=$1
if [ "$STUDY_ID" == "" ]
then
	echo "Please, give study cleaning ID name as first argument."
	exit 3
fi

source ./folders.config.sh

#IMAGE=/home/mwuttke/SingularityTest/gwasinspector.simg
MYDIR=${GWAS_UPLOAD_DIR}/${STUDY_ID}
CLEAN_DIR=${CLEANING_DIR}/${STUDY_ID}

if [ ! -d "$MYDIR" ]
then
	echo "Study dir not found: $MYDIR"
	exit 5
fi

if [ ! -f "$MYDIR/config.ini" ]
then
	echo "config.ini not found: Creating one."
	cat ${SCRIPTS_DIR}/GWASinspector/config.ini.template | sed -e "s/CLEAN_DIR/$(echo $CLEAN_DIR | sed 's/\//\\\//g')/g" -e "s/REF_DIR/$(echo $REF_DIR | sed 's/\//\\\//g')/g" > $MYDIR/config.ini
fi

mkdir -p ${CLEAN_DIR}/qc-output

echo "Run singularity GWASinspector"
#singularity exec \
#	--bind /storage \
#	$IMAGE 
	cd $MYDIR 
	Rscript ${SCRIPTS_DIR}/GWASinspector/gwasinspector.R \
	2>&1 | tee 02-gwasinspector.log

