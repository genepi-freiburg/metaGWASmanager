#!/bin/bash

# this script assumes Slurm
# this will work different with your job scheduler
# but the principles should be the same

for STEP1_JOB_FN in `ls jobs/*_regenie_step1_*.sh`
do
	# we need the AWK command to extract the job ID (sbatch returns "Submitted batch job 123")
	STEP1_JOB=$(sbatch $STEP1_JOB_FN | awk '{ print $4 }')
	echo "Submitted REGENIE step 1 job: ID = $STEP1_JOB, File = $STEP1_JOB_FN"

	STEP2_JOB_FNS=$(echo $STEP1_JOB_FN | sed s/step1/step2/ | sed s/.sh/_chr*.sh/)

	for STEP2_JOB_FN in `ls $STEP2_JOB_FNS`
	do
		sbatch -d afterok:$STEP1_JOB $STEP2_JOB_FN
		echo "Submitted REGENIE step 2 job after step 1 is ok: $STEP2_JOB_FN"
	done
done

