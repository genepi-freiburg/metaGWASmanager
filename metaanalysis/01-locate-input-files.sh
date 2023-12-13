source ../gwas_qc/folders.config.sh

Phenotype=$1

if [ "$Phenotype" == "" ]
then
	echo "Please, give a phenotype name as first argument."
	exit 3
fi

INPUT_MA_FILE=$PREFIX/metaanalysis/input-file-list.txt
MA_P_DIR=${PREFIX}/metaanalysis/$Phenotype


LOGFILE=${MA_P_DIR}/01-locate-input-files.log
OUTPUTFILE=${MA_P_DIR}/input-files-with-path.txt

rm -f $LOGFILE
rm -f $OUTPUTFILE

cut -f 1 $INPUT_MA_FILE > ${MA_P_DIR}/input-file-list-col1.txt

bash $SCRIPTS_MA/find-paths.sh ${MA_P_DIR}/input-file-list-col1.txt $OUTPUTFILE $1| tee -a $LOGFILE

#rm -f input-file-list-col1.txt

echo "TOTAL FILE COUNT (without/with paths)" | tee -a $LOGFILE

wc -l $INPUT_MA_FILE $OUTPUTFILE | tee -a $LOGFILE
