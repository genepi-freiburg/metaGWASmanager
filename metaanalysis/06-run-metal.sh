SCRIPTS_DIR=/storage/scripts/ckdgenR5/metaanalysis

MYFILE=metal-params.txt
if [ ! -f $MYFILE ]
then
	echo "Metal parameters do not exist: $MYFILE"
	exit 3
fi

WD=`pwd`
parent_dir=$(dirname "$WD")

ANALYSISNAME=$(basename $parent_dir)
METALLOG="metal.$(date -Is).log"

echo "Analysis name: $ANALYSISNAME"
echo "METAL params: $MYFILE"
echo "METAL log: $METALLOG"

$SCRIPTS_DIR/metal $MYFILE | tee $METALLOG

echo "Done"
