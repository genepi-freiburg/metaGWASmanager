
source ./folders.config.sh
SCRIPT_DIR=$SCRIPTS_DIR
INDIR=$CLEANING_DIR

FILES=`find ${INDIR}/*/data -name "*.gz"`
for FN in $FILES
do
	${SCRIPT_DIR}/checkStudyFilename.sh $FN >/dev/null
	if [ "$?" -ne 0 ]
	then
		BN=`basename $FN`
		echo "ERROR: $BN"
#	else
#		echo "OK: $FN"
	fi
done
