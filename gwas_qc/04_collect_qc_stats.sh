source ./folders.config.sh

mkdir -p ${PREFIX}/00_SUMMARY
STATS=${PREFIX}/00_SUMMARY/qc-stats.csv
STATSXLSX=${PREFIX}/00_SUMMARY/qc-stats.xlsx
MYDATE=`date --iso-8601`
mv -v $STATS ${PREFIX}/00_SUMMARY/Archive/qc-stats-${MYDATE}.csv

POSCTRL=${PREFIX}/00_SUMMARY/positive-controls.csv
POSCTRLXLSX=${PREFIX}/00_SUMMARY/positive-controls.xlsx
rm -f $POSCTRL

for STUDY in `ls -d ${PREFIX}/*`
do
	FN=`basename $STUDY`
	if [ "$FN" == "00_SUMMARY" -o "$FN" == "00_ARCHIVE" ]
	then
		continue
	fi

	echo "========================="
	echo "Study: $FN"
	echo "========================="
	OFN=$STUDY/04-collect-qc-stats.csv

	rm -f $OFN

	for STUDY_FILE in `ls $STUDY/qc-output/*.rds`
	do
		#echo "File: $STUDY_FILE"
		PHENO=`$SCRIPTS_DIR/find-main-pheno.sh $STUDY_FILE`
		POP=`$SCRIPTS_DIR/find-population.sh $STUDY_FILE`
		echo " - Pheno: $PHENO, Pop: $POP"
		Rscript ${SCRIPTS_DIR}/04-collect-qc-stats-for-file.R $STUDY_FILE $FN $PHENO $POP $OFN
		RC="$?"
		if [ "$RC" -ne 0 ]
		then
			echo "Problem collecting: $STUDY_FILE"
			exit 3
		fi
	done

	if [ ! -f $STATS ]
	then
		cp $OFN $STATS
	else
		tail -n+2 $OFN >> $STATS
	fi

	POSCTRL_FN=$STUDY/03-check-positive-controls.csv
	if [ -f "$POSCTRL_FN" ]
	then
		if [ ! -f "$POSCTRL" ]
		then
			cp $POSCTRL_FN $POSCTRL
		else
			tail -n+2 $POSCTRL_FN >> $POSCTRL
		fi
		echo " - Collected positive controls"
	else
		echo " - WARNING: positive control file not found: $POSCTRL_FN"
	fi

done >> 04-collect-qc-stats.log

Rscript $SCRIPTS_DIR/ConvertQcStatsToXlsx.R $STATS $STATSXLSX
Rscript $SCRIPTS_DIR/ConvertPosCtrlToXlsx.R $POSCTRL $POSCTRLXLSX
