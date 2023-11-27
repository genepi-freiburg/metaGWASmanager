INPUTFILE=input-file-list.txt
SCRIPTS=/storage/scripts/ckdgenR5/metaanalysis
LOGFILE=01-locate-input-files.log
OUTPUTFILE=input-files-with-path.txt
Phenotype=$1


rm -f $LOGFILE
rm -f $OUTPUTFILE

cut -f 1 $INPUTFILE > input-file-list-col1.txt

bash $SCRIPTS/find-paths.sh input-file-list-col1.txt $OUTPUTFILE $1| tee -a $LOGFILE

#rm -f input-file-list-col1.txt

echo "TOTAL FILE COUNT (without/with paths)" | tee -a $LOGFILE

wc -l $INPUTFILE $OUTPUTFILE | tee -a $LOGFILE
