
STUDY_ID=$1

if [ "$STUDY_ID" == "" ]
then
        echo "Please, give study cleaning ID name as first argument."
        exit 3
fi

source ./folders.config.sh 

INDIR=$CLEANING_DIR/${STUDY_ID}/data

${SCRIPTS_DIR}/Positive_Controls/check-positive-controls.sh $INDIR \
	$CLEANING_DIR/${STUDY_ID}/03-check-positive-controls.csv | tee $CLEANING_DIR/${STUDY_ID}/03-check-positive-controls.log

