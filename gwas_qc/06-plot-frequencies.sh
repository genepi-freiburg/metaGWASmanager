SCRIPT_DIR="/storage/scripts/ckdgenR5/gwas_qc"

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

	FREQ_PREFIX=/storage/cleaning/ckdgenR5/$FN/freqs
	mkdir -p $FREQ_PREFIX

	for STUDY_FILE in `ls $STUDY/data/*.gz`
	do
		#gckd_EUR_TopMed_20221004_quantitative_overall_4_egfr_creat_int.gwas.gz
		#echo "File: $STUDY_FILE"
		POP=`$SCRIPT_DIR/find-population.sh $STUDY_FILE`

		SIMPLER_NAME=$(basename $STUDY_FILE | sed s/_quantitative// | sed s/_overall// | sed s/_binary// | sed s/_sex_stratified// | sed s/.gwas.gz//)
		echo " - title: $SIMPLER_NAME, pop: $POP"

		FREQ_OUT=$FREQ_PREFIX/${SIMPLER_NAME}.freq.gz
		if [ ! -f $FREQ_OUT ]
		then
			echo "Merging frequencies to: $FREQ_OUT"
			REFPANEL_FILE=/storage/databases/1kgp/1kgp_frequencies_b38.txt.gz
			/storage/scripts/ckdgenR5/gwas_qc/Frequency_Comparison/join_frequency_files.py $STUDY_FILE $REFPANEL_FILE $FREQ_OUT $POP | tee $FREQ_PREFIX/${SIMPLER_NAME}.freq.log
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
			PLOT_SCRIPT=/storage/scripts/ckdgenR5/gwas_qc/Frequency_Comparison/plot.R
			Rscript $PLOT_SCRIPT $FREQ_OUT $SIMPLER_NAME $PLOT_OUT
		fi
	done

done
