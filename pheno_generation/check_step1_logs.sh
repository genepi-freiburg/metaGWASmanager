for JOB_NUM in `ls -l jobs/*step1* | cut -d"_" -f7 | sort -n`
do
	LOG_FILE=$(ls output_regenie_step1/*_${JOB_NUM}.log 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo "ERROR: Step 1 log file for job $JOB_NUM does not exist."
	else
		end_time=$(grep "End time" $LOG_FILE)
		if [ "$end_time" == "" ]
		then
			echo "ERROR: Step 1 run $JOB_NUM did not complete successfully: $LOG_FILE"
		else
			echo "OK: Step 1 run $JOB_NUM: $end_time"
		fi
	fi
done



