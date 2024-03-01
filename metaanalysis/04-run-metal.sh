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
	echo "Please, give a name of MAF threshold as second argument."
	exit 3
fi

MA_P_DIR=${PREFIX}/metaanalysis/$Phenotype
MA_PQUAL_DIR=${MA_P_DIR}/$QUAL


# MYFILE=${MA_PQUAL_DIR}/metal_output_$QUAL/metal-params.txt
MYFILE=${MA_PQUAL_DIR}/metal-params.txt

if [ ! -f $MYFILE ]
then
	echo "Metal parameters do not exist: $MYFILE"
	exit 3
fi

ANALYSISNAME=$Phenotype
METALLOG="metal.$(date -Is).log"

echo "Analysis name: $ANALYSISNAME"
echo "METAL params: $MYFILE"
echo "METAL log: $METALLOG"

$SCRIPTS_MA/metal $MYFILE | tee ${MA_PQUAL_DIR}/$METALLOG

echo "Done"
