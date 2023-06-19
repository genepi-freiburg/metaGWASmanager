#!/bin/bash

# this script is a derivate of the 01 combine script
# it works with a single file p phenotype,
# i.e. if the study pre-combined the file.
# expected "chrAll" to be in the name
# "recodes" the file both for space/tab and for PVAL column
# tabix, but no sort (assumes to be sorted correctly)

IN_PATH=$1
OUT_PATH=$2

if [ ! -d "$IN_PATH" ]
then
	echo "Please give a path to the REGENIE step 2 output dir as the first argument to this script."
	exit 9
fi

if [ ! -d "$OUT_PATH" ]
then
	echo "Please give a path to the output dir as the second argument to this script."
	exit 9
fi

REQ_COLS="CHROM GENPOS ID ALLELE0 ALLELE1 A1FREQ INFO N BETA SE LOG10P"

# find path
SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# this makes the path absolute and removes a trailing slash
OUT_PATH=$(realpath $OUT_PATH)

# process all phenotypes
PHENOS=`ls $IN_PATH/*_chrAll_*`
for PHENO in $PHENOS
do
	# build names
	CHR1_FILE=$PHENO
	COMPRESSED="0"
	if [ "${CHR1_FILE: -3}" == ".gz" ]
	then
		echo "Detected compressed input."
		COMPRESSED="1"
	fi

	if [ "${CHR1_FILE: -4}" == ".ids" ]
	then
		# skip ID file
		continue
	fi

	PHENO=`basename $PHENO | sed s/_chr1_/_/ | sed s/.regenie// | sed s/.gz//`
	OUT_FN=${OUT_PATH}/${PHENO}.gwas
	echo "Process phenotype: $PHENO => $OUT_FN"

	if [ -f "${OUT_FN}.gz" ]
	then
		echo "WARNING: Output file already exists. Will be skipped!!"
		continue
	fi

	# check required columns
	for COL in $REQ_COLS
	do
		IDX=`$SCRIPTPATH/find-column-index.pl $COL $CHR1_FILE`
		echo -n " - Check if required column $COL is present: $IDX => "
		if [ $IDX == -1 ]
		then
			echo "required column missing: $COL"
			exit 9
		else
			echo "OK."
		fi
	done

	PVAL_IDX=`$SCRIPTPATH/find-column-index.pl LOG10P $CHR1_FILE`

	# collect chromosomes and convert
	if [ "$COMPRESSED" == "0" ]
	then
		head -n1 $CHR1_FILE | awk '{ print $0, "PVAL" }' | sed 's/ /	/g' > $OUT_FN
	else
		zcat $CHR1_FILE | head -n 1 | awk '{ print $0, "PVAL" }' | sed 's/ /	/g' > $OUT_FN
	fi

	CHR="All"
	# this is a NOOP
	INFN=`echo $CHR1_FILE | sed s/chrAll/chr$CHR/`
	echo -n " - Process chr$CHR - $INFN: "

	if [ ! -f "$INFN" ]
	then
		if [ "$CHR" == "X" ]
		then
			echo "ChrX missing - OK."
		else
			echo "ERROR: chromosome missing: $CHR"
			exit 2
		fi
	fi

	if [ "$COMPRESSED" == "0" ]
	then
		tail -n+2 -q $INFN | awk -v pvalIdx=$PVAL_IDX '{ print $0, 10^(-$(pvalIdx+1)) }' | sed 's/ /	/g' >> $OUT_FN
	else
		zcat $INFN | tail -n+2 -q | awk -v pvalIdx=$PVAL_IDX '{ print $0, 10^(-$(pvalIdx+1)) }' | sed 's/ /	/g' >> $OUT_FN
	fi

	echo "OK."

	echo -n " - BGZIP: "
	bgzip $OUT_FN
	echo -n "OK: "
	ls -lah $OUT_FN.gz

	echo -n " - Tabix: "
	tabix $OUT_FN.gz -s 1 -b 2 -e 2 -S 1
	echo -n "OK: "
	ls -lah $OUT_FN.gz.tbi
done

echo "Done."

