STUDY_NAME=$1
SUBMISSION=$2

if [ ! -f "$SUBMISSION" ]
then
	echo "Submission file not found: $SUBMISSION"
	exit 2
fi

echo "Importing $STUDY_NAME"

UPLOAD_DIR=/storage/uploads/ckdgenR5/assoc/$STUDY_NAME
mkdir -p $UPLOAD_DIR
echo "Move file to upload dir: $UPLOAD_DIR"
mv -v $SUBMISSION $UPLOAD_DIR

cd $UPLOAD_DIR
FN=`basename $SUBMISSION`
echo "Extract file: $FN"
tar xvzf $FN > 00-extract.log

CLEAN_DIR=/storage/cleaning/ckdgenR5/$STUDY_NAME
mkdir -p $CLEAN_DIR/data
echo "Combine in: $CLEAN_DIR"
cd $CLEAN_DIR
/storage/scripts/ckdgenR5/gwas_qc/01_combine_chromosomes.sh $UPLOAD_DIR/output_regenie_step2 data | tee 01_combine_chromosomes.log

RC="$?"
if [ ! "$RC" -eq 0 ]
then
	echo "Data seems incomplete - please check."
	exit 9
fi

echo "Run GWASinspector"
/storage/scripts/ckdgenR5/gwas_qc/02-gwasinspector.sh $STUDY_NAME

RC="$?"
if [ ! "$RC" -eq 0 ]
then
        echo "GWASinspector seems to have failed - please check."
        exit 9
fi

echo "Run positive control check"
/storage/scripts/ckdgenR5/gwas_qc/03-check-positive-controls.sh

echo "Collect QC stats"
/storage/scripts/ckdgenR5/gwas_qc/04-collect-qc-stats.sh

echo "Plot QC stats"
Rscript /storage/scripts/ckdgenR5/gwas_qc/05-plot-qc-stats.R

echo "Update website"
/storage/scripts/ckdgenR5/gwas_qc/setup_website.sh

