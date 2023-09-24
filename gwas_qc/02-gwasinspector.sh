
#!/bin/bash

STUDY_NAME=$1
if [ "$STUDY_NAME" == "" ]
then
	echo "Give study cleaning dir name as first argument."
	exit 3
fi

source ./folders.config.sh $STUDY_NAME

#IMAGE=/home/mwuttke/SingularityTest/gwasinspector.simg
MYDIR=$GWAS_UPLOAD_DIR

echo $MYDIR

if [ ! -d "$MYDIR" ]
then
	echo "Study dir not found: $MYDIR"
	exit 5
fi

if [ ! -f "$MYDIR/config.ini" ]
then
	echo "config.ini not found: Creating one."
	cat ${SCRIPTS_DIR}/GWASinspector/config.ini.template | sed -e "s/CLEANING_DIR/$(echo $CLEANING_DIR | sed 's/\//\\\//g')/g" -e "s/REF_DIR/$(echo $REF_DIR | sed 's/\//\\\//g')/g" > $MYDIR/config.ini
fi

mkdir -p ${CLEANING_DIR}/qc-output

echo "Run singularity GWASinspector"
#singularity exec \
#	--bind /storage \
#	$IMAGE 
	cd $MYDIR 
	Rscript ${SCRIPTS_DIR}/GWASinspector/gwasinspector.R \
	2>&1 | tee 02-gwasinspector.log

