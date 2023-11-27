LOG=02-prepare-ma-input.HQ.log

# 'secret' param that may be set to skip existing output files
# this speeds up the process if you resume a previous run
# WARNING: take care not to keep partial files
SKIP_EXIST="$1"



echo "HQ_All" | tee $LOG

/storage/scripts/ckdgenR5/metaanalysis/prepare-ma-input.sh input-files-with-path.txt 0 0.6 1 100 20 0 input_HQ_All $SKIP_EXIST | tee -a $LOG


echo "HQ_MAF1" | tee $LOG

/storage/scripts/ckdgenR5/metaanalysis/prepare-ma-input.sh input-files-with-path.txt 0.05 0.6 1 100 20 0 input_HQ_MAF1 $SKIP_EXIST | tee -a $LOG

echo "HQ_MAF2" | tee $LOG

/storage/scripts/ckdgenR5/metaanalysis/prepare-ma-input.sh input-files-with-path.txt 0.005 0.6 1 100 20 0 input_HQ_MAF2 $SKIP_EXIST | tee -a $LOG

echo "HQ_MAF3" | tee $LOG

/storage/scripts/ckdgenR5/metaanalysis/prepare-ma-input.rare.sh input-files-with-path.txt 0.005 0.8 0 100 20 0 input_HQ_MAF3 $SKIP_EXIST | tee -a $LOG








