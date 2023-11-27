SCRIPTS_DIR=/storage/scripts/ckdgenR5/metaanalysis
QUAL=$1
WD=`pwd`

MYFILE=metal-params.txt
if [ -f $MYFILE ]
then
	echo "Metal parameters already exist: $MYFILE"
	exit 3
fi

MYFILE1=*.metalparams
if [ -f $MYFILE1 ]
then
        echo "*.metalparams already exist: $MYFILE"
        exit 3
fi

ANALYSISNAME=$(basename `pwd`)
echo "Analysis name: $ANALYSISNAME"


cat $SCRIPTS_DIR/metal-params.txt |
	sed s/%ANALYSISNAME%/$ANALYSISNAME/ > $MYFILE

for FN in `cut -f7 -d "/" input-files-with-path.txt`
do

	LC=$(zcat input_$QUAL/$FN | head -n 10 | wc -l)
	if [ "$LC" -gt 3 ]
	then
		echo "PROCESS input_$QUAL/$FN" >> $MYFILE
	else
		echo "Skip (empty): $FN"
	fi
done

echo >> $MYFILE
echo "ANALYZE HETEROGENEITY" >> $MYFILE
echo "QUIT" >> $MYFILE

cp $MYFILE ${ANALYSISNAME}.$(date -Is).metalparams

mkdir -p metal_output_$1/output

mv metal-params.txt metal_output_$1
mv *.metalparams metal_output_$1
ln -s $WD/input_$1 $WD/metal_output_$1

echo "done"
