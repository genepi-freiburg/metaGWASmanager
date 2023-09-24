INDIR=data

STUDY_ID=$1

source ./folders.config.sh $STUDY_ID

${SCRIPTS_DIR}/Positive_Controls/check-positive-controls.sh $INDIR \
	03-check-positive-controls.csv | tee 03-check-positive-controls.log

