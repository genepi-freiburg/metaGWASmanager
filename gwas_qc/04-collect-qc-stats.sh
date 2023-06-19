SCRIPT_DIR="/storage/scripts/ckdgenR5/gwas_qc"

mkdir -p /storage/cleaning/ckdgenR5/00_SUMMARY
STATS=/storage/cleaning/ckdgenR5/00_SUMMARY/qc-stats.csv
STATSXLSX=/storage/cleaning/ckdgenR5/00_SUMMARY/qc-stats.xlsx
MYDATE=`date --iso-8601`
mv -v $STATS /storage/cleaning/ckdgenR5/00_SUMMARY/Archive/qc-stats-${MYDATE}.csv

POSCTRL=/storage/cleaning/ckdgenR5/00_SUMMARY/positive-controls.csv
POSCTRLXLSX=/storage/cleaning/ckdgenR5/00_SUMMARY/positive-controls.xlsx
rm -f $POSCTRL

for STUDY in `ls -d /storage/cleaning/ckdgenR5/*`
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
		PHENO=`$SCRIPT_DIR/find-main-pheno.sh $STUDY_FILE`
		POP=`$SCRIPT_DIR/find-population.sh $STUDY_FILE`
		echo " - Pheno: $PHENO, Pop: $POP"
		Rscript ${SCRIPT_DIR}/04-collect-qc-stats-for-file.R $STUDY_FILE $FN $PHENO $POP $OFN
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

done

Rscript $SCRIPT_DIR/ConvertQcStatsToXlsx.R $STATS $STATSXLSX
Rscript $SCRIPT_DIR/ConvertPosCtrlToXlsx.R $POSCTRL $POSCTRLXLSX
