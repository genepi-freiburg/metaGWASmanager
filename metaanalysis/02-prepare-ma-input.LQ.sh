source ../gwas_qc/folders.config.sh

Phenotype=$1

if [ "$Phenotype" == "" ]
then
	echo "Please, give a phenotype name as first argument."
	exit 3
fi


MA_P_DIR=${PREFIX}/metaanalysis/$Phenotype


LOG=${MA_P_DIR}02-prepare-ma-input.LQ.log

# 'secret' param that may be set to skip existing output files
# this speeds up the process if you resume a previous run
# WARNING: take care not to keep partial files
SKIP_EXIST="$1"



echo "LQ_All" | tee $LOG
# mkdir LQ_All
$SCRIPTS_MA/prepare-ma-input.sh ${MA_P_DIR}/input-files-with-path.txt 0 0.3 1 100 20 0 ${MA_P_DIR}/LQ_All/input_LQ_All $SKIP_EXIST | tee -a $LOG







