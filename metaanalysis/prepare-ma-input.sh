#!/bin/bash

if [[ "$#" -lt "7" ]] || [[ "$#" -gt "9" ]]
then
	echo "Usage: $0 <INPUT_FILE_LIST> <MAF_FILTER> <INFO_FILTER> <MAC_FILTER> <EFF_SAMPLE_SIZE> <BETA_FILTER> <INDEL_REMOVAL> [<OUTDIR> [<SKIPEXIST>]]"
	exit 3
fi

INPUT_FILE_LIST=$1
MAF_FILTER=$2
INFO_FILTER=$3
MAC_FILTER=$4
EFF_SAMPLE_SIZE=$5
BETA_FILTER=$6
INDEL_REMOVAL=$7
OUTDIR=$8
SKIP_EXIST=$9

if [ ! -f "$INPUT_FILE_LIST" ]
then
	echo "Input file list file does not exist: $INPUT_FILE_LIST"
	exit 3
fi

I=0
for FN in `cat $INPUT_FILE_LIST`
do
	if [ ! -f $FN ]
	then
		echo "Input file does not exist: $FN"
		exit 3
	fi
	I=$((I+1))
done

if [ "$OUTDIR" == "" ]
then
	OUTDIR="input"
fi
mkdir -p $OUTDIR

echo "Input file list: $INPUT_FILE_LIST (has $I files)"
echo "MAF filter: >= $MAF_FILTER"
echo "INFO filter: >= $INFO_FILTER"
echo "MAC (minor allele count) filter: >= $MAC_FILTER"
echo "Effective sample size filter: >= $EFF_SAMPLE_SIZE"
echo "BETA filter: > -${BETA_FILTER} && < ${BETA_FILTER}"
echo "INDEL removal: $INDEL_REMOVAL"
echo "OUTDIR: $OUTDIR"

if [ "$INDEL_REMOVAL" != "1" ] && [ "$INDEL_REMOVAL" != "0" ]
then
	echo "INDEL removal must be '0' (off) or '1' (on)."
	exit 3
fi

ERRORS=`awk -v maf=$MAF_FILTER -v info=$INFO_FILTER -v mac=$MAC_FILTER -v eff=$EFF_SAMPLE_SIZE -v beta=$BETA_FILTER \
	'BEGIN { 
		if (maf < 0 || maf > 0.5) {
			print("MAF filter must be in [0..0.5]!");
		}
		if (info < 0 || info > 1) {
			print("INFO filter must be in [0..1]!");
		}
		if (mac < 0) {
			print("MAC filter must be >= 0!");
		}
		if (eff < 0) {
			print("EFF filter must be >= 0!");
		}
		if (beta < 0) {
			print("BETA filter must be >= =0!");
		}
	}'`

if [ "$ERRORS" != "" ]
then
	echo "$ERRORS"
	exit 3
else
	echo "Parameters OK"
fi

FIND_COL="${SCRIPTS_MA}/find-column-index.pl"

for FN in `cat $INPUT_FILE_LIST`
do

#CHROM   GENPOS  ID      ALLELE0 ALLELE1 A1FREQ  INFO    N       TEST    BETA    SE      CHISQ   LOG10P  EXTRA   PVAL
#1       60113   chr1:60113:CTTCAT:C     CTTCAT  C       0.000275287     0.474757        4993    ADD     0.229715        0.782146        0.0862586       0.11408 NA   0

	# identify columns
	SNP_COL=`$FIND_COL ID $FN`
	## alternative names for SNP col?
	CHR_COL=`$FIND_COL CHROM $FN`
	POS_COL=`$FIND_COL GENPOS $FN`
	REF_ALL_COL=`$FIND_COL ALLELE0 $FN`
	CODED_ALL_COL=`$FIND_COL ALLELE1 $FN`
	AF_COL=`$FIND_COL A1FREQ $FN`
	INFO_COL=`$FIND_COL INFO $FN`
	BETA_COL=`$FIND_COL BETA $FN`
	SE_COL=`$FIND_COL SE $FN`
	PVAL_COL=`$FIND_COL PVAL $FN`
	N_COL=`$FIND_COL N $FN`

	if [ "$SNP_COL" == "-1" ] || [ "$CHR_COL" == "-1" ] || [ "$POS_COL" == "-1" ] || \
		[ "$REF_ALL_COL" == "-1" ] || [ "$CODED_ALL_COL" == "-1" ] || [ "$AF_COL" == "-1" ] || \
		[ "$INFO_COL" == "-1" ] || [ "$BETA_COL" == "-1" ] || [ "$SE_COL" == "-1" ] || \
		[ "$PVAL_COL" == "-1" ] || [ "$N_COL" == "-1" ]
	then
		echo "COLUMN NAME PROBLEMS in file: $FN"
		echo "SNP_COL=$SNP_COL CHR_COL=$CHR_COL POS_COL=$POS_COL REF_ALL_COL=$REF_ALL_COL CODED_ALL_COL=$CODED_ALL_COL"
		echo "AF_COL=$AF_COL INFO_COL=$INFO_COL BETA_COL=$BETA_COL SE_COL=$SE_COL PVAL_COL=$PVAL_COL N_COL=$N_COL"
		#	exit 3
		echo "SKIP FILE"
		continue
	fi

	# filter file
	OUTFN=`basename $FN`
	echo "Process $FN ==> $OUTDIR/$OUTFN"

	if [ -f "$OUTDIR/$OUTFN" ]
	then
		echo "Output file exists!"
		if [ "$SKIP_EXIST" == "1" ]
		then
			echo "Skip file!"
			continue
		fi
	fi

	zcat $FN | awk -v mafFilter=$MAF_FILTER -v infoFilter=$INFO_FILTER -v macFilter=$MAC_FILTER -v effFilter=$EFF_SAMPLE_SIZE -v betaFilter=$BETA_FILTER \
		-v indelRemove=$INDEL_REMOVAL \
		-v snpCol=$SNP_COL -v chrCol=$CHR_COL -v posCol=$POS_COL -v refAllCol=$REF_ALL_COL -v codedAllCol=$CODED_ALL_COL \
		-v afCol=$AF_COL -v infoCol=$INFO_COL -v nCol=$N_COL \
		-v betaCol=$BETA_COL -v seCol=$SE_COL -v pvalCol=$PVAL_COL \
		'BEGIN {
			print "MARKER", "chr", "position_b38", "coded_all", "noncoded_all", 
				"AF_coded_all", "MAF", "MAC", "n_total", "n_effective", "oevar_imp",
				"beta", "SE", "pval";
		} {
			if (FNR > 1) {
				chr = $(chrCol+1);
				af = $(afCol+1);
				n = $(nCol+1);
				info = $(infoCol+1) + 0;
				if (chr == "X") {
                                        chr = 23;
                                }
				if (info > 1) {
					info = 1;
				}
				if (af > 0.5) {
					maf = 1-af;
				} else {
					maf = af;
				}
				mac = 2 * maf * n;
				n_eff = n * info;
				if (n == "NA") {
					n_eff = 999999;
					mac = 999999;
				}
				beta = $(betaCol+1);
				marker = $(snpCol+1);
				if (indelRemove == 1 && marker ~ /_I$/) {
					next;
				}
				pos = $(posCol+1)
				all1 = $(codedAllCol+1)
				all2 = $(refAllCol+1)
				if (all1 > all2) {
  					marker = chr ":" pos ":" all2 ":" all1;
				} else {
 					marker = chr ":" pos ":" all1 ":" all2;
				}
				se = $(seCol+1);
				pval = $(pvalCol+1);
				if (beta > -betaFilter && beta < betaFilter && maf >= mafFilter &&
				    info >= infoFilter && mac >= macFilter && n_eff >= effFilter && 
                                    se >= 0 && pval >= 0 && se != "NA" && se != "Inf" && pval != "Inf" && pval != "NA") {
					print marker, chr, $(posCol+1), $(codedAllCol+1), $(refAllCol+1),
					      af, maf, mac, n, n_eff, info, beta, $(seCol+1), $(pvalCol+1);
				}
			}
		}' | gzip > $OUTDIR/$OUTFN
done
