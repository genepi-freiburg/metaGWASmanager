source ../gwas_qc/folders.config.sh

Phenotype=$1

if [ "$Phenotype" == "" ]
then
	echo "Please, give a phenotype name as first argument."
	exit 3
fi


MA_P_DIR=${PREFIX}/metaanalysis/$Phenotype


LOG=${MA_P_DIR}/02-prepare-ma-input.HQ.log

# 'secret' param that may be set to skip existing output files
# this speeds up the process if you resume a previous run
# WARNING: take care not to keep partial files
SKIP_EXIST="$1"



echo "HQ_All" | tee $LOG
mkdir HQ_All
$SCRIPTS_MA/prepare-ma-input.sh ${MA_P_DIR}/input-files-with-path.txt 0 0.6 1 100 20 0 ${MA_P_DIR}/HQ_All/input_HQ_All $SKIP_EXIST | tee -a $LOG

echo "HQ_MAF1" | tee $LOG
mkdir HQ_MAF1
$SCRIPTS_MA/prepare-ma-input.sh ${MA_P_DIR}/input-files-with-path.txt 0.05 0.6 1 100 20 0 ${MA_P_DIR}/HQ_MAF1/input_HQ_MAF1 $SKIP_EXIST | tee -a $LOG

echo "HQ_MAF2" | tee $LOG
mkdir HQ_MAF2
$SCRIPTS_MA/prepare-ma-input.sh ${MA_P_DIR}/input-files-with-path.txt 0.005 0.6 1 100 20 0 ${MA_P_DIR}/HQ_MAF1/input_HQ_MAF2 $SKIP_EXIST | tee -a $LOG

echo "HQ_MAF3" | tee $LOG
mkdir HQ_MAF3
$SCRIPTS_MA/prepare-ma-input.rare.sh ${MA_P_DIR}/input-files-with-path.txt 0.005 0.8 0 100 20 0 ${MA_P_DIR}/HQ_MAF1/input_HQ_MAF3 $SKIP_EXIST | tee -a $LOG








