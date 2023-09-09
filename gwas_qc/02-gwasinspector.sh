
#!/bin/bash

STUDY_NAME=$1
if [ "$STUDY_NAME" == "" ]
then
	echo "Give study cleaning dir name as first argument."
	exit 3
fi

#IMAGE=/home/mwuttke/SingularityTest/gwasinspector.simg
MYDIR=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline_core/uploads/assoc/$STUDY_NAME

if [ ! -d "$MYDIR" ]
then
	echo "Study dir not found: $MYDIR"
	exit 5
fi

if [ ! -f "$MYDIR/config.ini" ]
then
	echo "config.ini not found: Creating one."
	cat /data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline_core/scripts/gwas_qc/GWASinspector/config.ini.template | sed s/STUDY_NAME/$STUDY_NAME/g > $MYDIR/config.ini
fi

mkdir -p /data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline_core/cleaning/$STUDY_NAME/qc-output

echo "Run singularity GWASinspector"
#singularity exec \
#	--bind /storage \
#	$IMAGE 
	cd $MYDIR 
	Rscript /storage/scripts/ckdgenR5/gwas_qc/GWASinspector/gwasinspector.R \
	2>&1 | tee 02-gwasinspector.log

