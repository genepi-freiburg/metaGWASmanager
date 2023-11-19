
STUDY_NAME=$1

if [ "$STUDY_NAME" == "" ]
then
        echo "Give study cleaning dir name as first argument."
        exit 3
fi

source ./folders.config.sh 

INDIR=$CLEANING_DIR/${STUDY_NAME}/data

${SCRIPTS_DIR}/Positive_Controls/check-positive-controls.sh $INDIR \
	03-check-positive-controls.csv | tee 03-check-positive-controls.log

