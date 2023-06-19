for JOB_NUM in `ls -l jobs/*step1* | cut -d"_" -f7 | sort -n`
do
for CHR in `seq 1 22` X
do
	LOG_FILE=$(ls output_regenie_step2/*_${JOB_NUM}_chr${CHR}.log 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo "ERROR: Step 2 log file for job $JOB_NUM / chromosome $CHR does not exist."
	else
		end_time=$(grep "End time" $LOG_FILE)
		if [ "$end_time" == "" ]
		then
			echo "ERROR: Step 2 run $JOB_NUM / chromosome $CHR did not complete successfully: $LOG_FILE"
		else
			echo "OK: Step 2 run $JOB_NUM / chromosome $CHR: $end_time"
		fi
	fi
done
done



