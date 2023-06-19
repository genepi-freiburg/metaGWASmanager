#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
STURY_DIR=$1
if [ ! -d "$1" ]
then
	echo "ERROR: please give directory with result files as first argument"
	exit 3
fi

OUT_FN=$2
if [ "$2" == "" ]
then
	echo "ERROR: please give output CSV file name as second argument"
	exit 3
fi

echo "file_name,pheno,ancestry,chr,pos_b38,gene,noncoded_all,coded_all,beta,pval,n,maf,std_ref,std_alt,std_dir,std_maf,rate_alleles,rate_dir,rate_maf,rate_overall" > $OUT_FN

OK=""
NOT_OK=""
NO_POSCTRL=""
for FN in `ls $1/*.gz`
do
	BN=`basename $FN`
	echo ""
	echo "==================================================================="
	echo "$BN"
	echo "==================================================================="
	echo ""
	$SCRIPT_DIR/pull-positive-control.sh $FN $OUT_FN
	MYRC=$?
	if [ "$MYRC" == 0 ]
	then
		OK=${OK}${BN}$'\n'
	elif [ "$MYRC" == 5 ]
	then
		NO_POSCTRL=${NO_POSCTRL}${BN}$'\n'
	else
		NOT_OK=${NOT_OK}${BN}$'\n'
	fi
done

echo ""
echo "==================================================================="
echo "SUMMARY"
echo "==================================================================="
echo ""
echo "Files which are ok:"
echo "$OK"
echo "Files which do not have a positive control (depending on ancestry/phenotype, might be a problem):"
echo "$NO_POSCTRL"
echo "Files which might have other problems (please check!):"
echo "$NOT_OK"
