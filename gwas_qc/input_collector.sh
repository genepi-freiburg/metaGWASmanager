for FN in `ls /data/sftp/sftp01`
do
	echo "Found submission: $FN"
#ckdgen-r5-upload-MGBB-221031-AFR.tar
	SN=$(echo $FN | sed 's/ckdgen-r5-upload-//' | sed 's/.tgz//')
	echo "Study name: $SN"
	/storage/scripts/ckdgenR5/gwas_qc/input_pipeline.sh $SN /data/sftp/sftp01/$FN
done
