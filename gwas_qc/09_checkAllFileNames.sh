FILES=`find /storage/cleaning/ckdgenR5/*/data -name "*.gz"`
for FN in $FILES
do
	/storage/scripts/ckdgenR5/gwas_qc/checkStudyFilename.sh $FN >/dev/null
	if [ "$?" -ne 0 ]
	then
		BN=`basename $FN`
		echo "ERROR: $BN"
#	else
#		echo "OK: $FN"
	fi
done
