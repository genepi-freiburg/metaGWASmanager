#!/bin/bash

# this script combines REGENIE step 2 outputs per phenotype
# it has some logic to determine the phenotype name from the filename,
# it adds a PVAL column as 10^-LOG10P,
# it uses bgzip and tabix on the file(s)

module load snippy/4.4.1-foss-2018b-Perl-5.28.0

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
PHENOS=`ls $IN_PATH/*_chr1_*`
LEADING_ZERO=""
FILES_ALREADY_CONCATENATED=""

if [ "$PHENOS" == "" ]
then
	echo "ERROR: Did not find files with _chr1_"
	PHENOS=`ls $IN_PATH/*_chr01_*`
	if [ "$PHENOS" == "" ]
	then
		echo "ERROR: Did not find files with _chr01_"
		PHENOS=`ls $IN_PATH/*_chrAll_*`
		if [ "$PHENOS" == "" ]
		then
			echo "ERROR: Did not find files with _chrAll_"
			exit 2
		else
			echo "Detected concatenated files"
			FILES_ALREADY_CONCATENATED="1"
		fi
	else
		echo "Detected leading zero"
		LEADING_ZERO="0"
	fi
fi


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

	PHENO=`basename $PHENO | sed s/_chr1_/_/ | sed s/_chrAll_/_/ | sed s/.regenie// | sed s/.gz//`
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

	CHRS="$(seq 1 22) X"
	if [ "$FILES_ALREADY_CONCATENATED" != "" ]
	then
		CHRS="All"
	fi

	for CHR in $CHRS
	do
		if [ "$CHR" != "X" -a "$CHR" != "All" ]
		then
			if [ "$CHR" -lt 10 ]
			then
				CHR="${LEADING_ZERO}$CHR"
			fi
		fi
		if [ "$FILES_ALREADY_CONCATENATED" == "" ]
		then
			INFN=`echo $CHR1_FILE | sed s/chr${LEADING_ZERO}1/chr$CHR/`
		else
			INFN=$CHR1_FILE
		fi

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

		if [ "$FILES_ALREADY_CONCATENATED" == "" ]
		then
			# only sort on pos
			if [ "$COMPRESSED" == "0" ]
			then
				tail -n+2 -q $INFN | awk -v pvalIdx=$PVAL_IDX '{ print $0, 10^(-$(pvalIdx+1)) }' | sed 's/ /	/g' | sort -k2 -n >> $OUT_FN
			else
				zcat $INFN | tail -n+2 -q | awk -v pvalIdx=$PVAL_IDX '{ print $0, 10^(-$(pvalIdx+1)) }' | sed 's/ /	/g' | sort -k2 -n >> $OUT_FN
			fi
		else
			# sort on chr and pos, hope that X goes to the end
			if [ "$COMPRESSED" == "0" ]
			then
				tail -n+2 -q $INFN | awk -v pvalIdx=$PVAL_IDX '{ print $0, 10^(-$(pvalIdx+1)) }' | sed 's/ /	/g' | sort -k1 -k2 -n >> $OUT_FN
			else
				zcat $INFN | tail -n+2 -q | awk -v pvalIdx=$PVAL_IDX '{ print $0, 10^(-$(pvalIdx+1)) }' | sed 's/ /	/g' | sort -k1 -k2 -n >> $OUT_FN
			fi
		fi

		echo "OK."
	done

	echo -n " - BGZIP: "
	bgzip $OUT_FN
	echo -n "OK: "
	ls -lah $OUT_FN.gz

	echo -n " - Tabix: "
	tabix $OUT_FN.gz -s 1 -b 2 -e 2 -S 1

	if [ -e $OUT_FN.gz.tbi ]
	then
		echo -n "OK: "
		ls -lah $OUT_FN.gz.tbi
	else
		echo -n "ERROR - Could not generate tabix file, please check if file is ordered and correctly bgzipped"
		exit -1
	fi
done

echo "Done."

