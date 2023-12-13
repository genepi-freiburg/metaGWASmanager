source ../gwas_qc/folders.config.sh

Phenotype=$1

if [ "$Phenotype" == "" ]
then
	echo "Please, give a phenotype name as first argument."
	exit 3
fi


QUAL=$2

if [ "$QUAL" == "" ]
then
	echo "Please, give a name of MAF threshold as second argument (e.g., HQ_All)"
	exit 3
fi

MA_P_DIR=${PREFIX}/metaanalysis/$Phenotype
MA_PQUAL_DIR=${MA_P_DIR}/$QUAL


MYFILE=${MA_PQUAL_DIR}/metal-params.txt


if [ -f $MYFILE ]
then
	echo "Metal parameters already exist: $MYFILE"
	exit 3
fi

MYFILE1=${MA_PQUAL_DIR}/*.metalparams
if [ -f $MYFILE1 ]
then
        echo "*.metalparams already exist: $MYFILE"
        exit 3
fi

ANALYSISNAME=$Phenotype
OUTPUT=${MA_PQUAL_DIR}/metal_output_$QUAL/output
echo "Analysis name: $ANALYSISNAME"


cat $SCRIPTS_MA/metal-params.txt |
	sed -e "s#%ANALYSISNAME%#$ANALYSISNAME#" -e "s#%OUTPUT%#$OUTPUT#" > $MYFILE

for FN in `cut -f7 -d "/" $MA_P_DIR/input-files-with-path.txt`
do

	LC=$(zcat $MA_PQUAL_DIR/input_$QUAL/$FN | head -n 10 | wc -l)
	if [ "$LC" -gt 3 ]
	then
		echo "PROCESS $MA_PQUAL_DIR/input_$QUAL/$FN" >> $MYFILE
	else
		echo "Skip (empty): $FN"
	fi
done

echo >> $MYFILE
echo "ANALYZE HETEROGENEITY" >> $MYFILE
echo "QUIT" >> $MYFILE

cp $MYFILE ${MA_PQUAL_DIR}/${ANALYSISNAME}.$(date -Is).metalparams

mkdir -p ${MA_PQUAL_DIR}/metal_output_$QUAL/output

mv ${MA_PQUAL_DIR}/metal-params.txt ${MA_PQUAL_DIR}/metal_output_$QUAL
mv ${MA_PQUAL_DIR}/*.metalparams ${MA_PQUAL_DIR}/metal_output_$QUAL
ln -s $MA_PQUAL_DIR/input_$QUAL/$FN $MA_PQUAL_DIR/metal_output_$QUAL

echo "done"
