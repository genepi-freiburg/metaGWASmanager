source ./folders.config.sh

for STUDY in `ls -d ${CLEANING_DIR}/*`
do
	FN=`basename $STUDY`
	if [ "$FN" == "00_SUMMARY" -o "$FN" == "00_ARCHIVE" ]
	then
		continue
	fi

	echo "========================="
	echo "Study: $FN"
	echo "========================="

	FREQ_PREFIX=${CLEANING_DIR}/$FN/freqs
	mkdir -p $FREQ_PREFIX

	for STUDY_FILE in `ls $STUDY/data/*.gz`
	do
		POP=`$SCRIPTS_DIR/find-population.sh $STUDY_FILE`

		SIMPLER_NAME=$(basename $STUDY_FILE | sed s/_quantitative// | sed s/_binary// | sed s/.gwas.gz//) 

		FREQ_OUT=$FREQ_PREFIX/${SIMPLER_NAME}.freq.gz
		if [ ! -f $FREQ_OUT ]
		then
			echo "Merging frequencies to: $FREQ_OUT"
			REFPANEL_FILE=${REF_DIR}/1kgp/1kgp_frequencies_b38.txt.gz
			 ${SCRIPTS_DIR}/Frequency_Comparison/join_frequency_files.py $STUDY_FILE $REFPANEL_FILE $FREQ_OUT $POP | tee $FREQ_PREFIX/${SIMPLER_NAME}.freq.log
			RC="$?"
			if [ "$RC" -ne 0 ]
			then
				echo "Problem generating frequencies file: $STUDY_FILE"
				exit 3
			fi
		fi

		PLOT_OUT=$FREQ_PREFIX/${SIMPLER_NAME}.freqPlot.pdf
		if [ ! -f $PLOT_OUT ]
		then
			PLOT_SCRIPT=${SCRIPTS_DIR}/Frequency_Comparison/plot.R
			Rscript $PLOT_SCRIPT $FREQ_OUT $SIMPLER_NAME $PLOT_OUT
		fi
	done

done
