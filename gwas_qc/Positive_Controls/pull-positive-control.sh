STUDY=$1
OUT_FN=$2

SCRIPT_PREFIX=${SCRIPTS_DIR}
EXTRACT_FILE="/tmp/extract-${RANDOM}.txt"
POSITIVE_FILE="/tmp/positive-${RANDOM}.txt"

echo "Determine positive control to use"
echo "---------------------------------"

##################### DETERMINE POP AND PHENO

POP=`$SCRIPT_PREFIX/find-population.sh $STUDY`
echo "Determined population: $POP"
if [ "$POP" == "???" ]
then
	echo "ERROR: No population found - check filename: $STUDY"
	exit 2
fi

PHENO=`$SCRIPT_PREFIX/find-main-pheno.sh $STUDY`
echo "Determined phenotype: $PHENO"
if [ "$PHENO" == "???" ]
then
        echo "ERROR: No phenotype found - check filename: $STUDY"
        exit 8
fi

##################### FIND PARAMETERS

POSITIVE_CONTROLS="$SCRIPT_PREFIX/Positive_Controls/positive-controls.txt"
head -n 1 $POSITIVE_CONTROLS > ${POSITIVE_FILE}
cat $POSITIVE_CONTROLS | grep "$PHENO	" | grep "$POP	" >> ${POSITIVE_FILE}

echo
echo "Use this positive control(s):"
cat ${POSITIVE_FILE}

POSITIVES=`wc -l ${POSITIVE_FILE} | cut -f1 -d" "`
if [ "$POSITIVES" == "1" ]
then
	echo "ERROR: No positive controls available for population $POP and phenotype $PHENO"
	echo "${STUDY},${PHENO},${POP},,,,,,,,,,,,,,,,,NO_CTRL" >> $OUT_FN
	exit 5
fi


##################### EXTRACT STUDY SNPs

FIND_COL="$SCRIPT_PREFIX/find-column-index.pl"

STUDY_CHR=`$FIND_COL CHROM $STUDY`
STUDY_POS=`$FIND_COL GENPOS $STUDY`
STUDY_ALL1=`$FIND_COL ALLELE0 $STUDY`
STUDY_ALL2=`$FIND_COL ALLELE1 $STUDY`
STUDY_FREQ=`$FIND_COL A1FREQ $STUDY`
STUDY_PVAL=`$FIND_COL PVAL $STUDY`
STUDY_BETA=`$FIND_COL BETA $STUDY`
STUDY_N=`$FIND_COL N $STUDY`

#if [ "$STUDY_ALL1" == "-1" ] || [ "$STUDY_ALL2" == "-1" ]
#then
#	STUDY_ALL1=`$FIND_COL noncoded_all $STUDY`
#	STUDY_ALL2=`$FIND_COL coded_all $STUDY`
#fi

#if [ "$STUDY_PVAL" == "-1" ]
#then
#	STUDY_PVAL=`$FIND_COL pval $STUDY`
#fi

echo ""
echo "Column indices in STUDY file"
echo "----------------------------"
echo "Study: $STUDY"
echo -n "Columns: Chromosome = $STUDY_CHR, "
echo -n "Position (b38) = $STUDY_POS, "
echo -n "Allele_1 = $STUDY_ALL1, "
echo -n "Allele_2 = $STUDY_ALL2, "
echo -n "Frequency = $STUDY_FREQ, "
echo -n "p-value = $STUDY_PVAL, "
echo -n "N = $STUDY_N, "
echo "Beta = $STUDY_BETA"

if [ "$STUDY_CHR" == "-1" ] || [ "$STUDY_POS" == "-1" ] || [ "$STUDY_ALL1" == "-1" ] || [ "$STUDY_ALL2" == "-1" ] || [ "$STUDY_FREQ" == "-1" ] || [ "$STUDY_PVAL" == "-1" ] || [ "$STUDY_BETA" == "-1" ] || [ "$STUDY_N" == "-1" ]
then
        echo "Column in STUDY file not found - check indices and header."
	echo "${STUDY},${PHENO},${POP},,,,,,,,,,,,,,,,,,COLUMN_MISSING" >> $OUT_FN
        exit 7
fi


echo ""
echo "Extract SNPs from study file"
echo "----------------------------"

echo "chr	position	noncoded_all	coded_all	AF_coded_all	beta	pvalue	N" > ${EXTRACT_FILE}

I=0
while IFS='' read -r LINE || [[ -n "$LINE" ]]
do

# trait	ethnicity	SNP	gene	chr	pos	ref	alt	MAF_1KGP	direction_alt

if [ "$I" -gt 0 ]
then
	echo "Process positive control $I"
	echo $LINE
	SNP_GENE=`echo $LINE | cut -f 4 -d" "`
	SNP_CHROM=`echo $LINE | cut -f 5 -d" "`
	SNP_POS=`echo $LINE | cut -f 7 -d" "`   #6=b37, 7=b38
	echo -n "Gene: $SNP_GENE, "
	echo -n "chromosome: $SNP_CHROM, position (b38): $SNP_POS, "
	REGION="${SNP_CHROM}:${SNP_POS}-$((SNP_POS))"  # removed +1
	#if [[ "${SNP_CHROM}" -lt "10" ]] ; then
	#	REGION2="0${REGION}"
	#fi
	echo "region: $REGION"
	STUDYGZ=$STUDY
	if [[ "$STUDY" != *gz ]]
	then
		STUDYGZ="${STUDY}.gz"
	fi
	LINE=`tabix ${STUDYGZ} ${REGION}`
	#if [ "$LINE" == "" ]
	#then
	#	LINE=`tabix ${STUDY}.gz ${REGION2}`
	#fi
	#tabix ${STUDY}.gz ${REGION} | \
	echo $LINE | \
        awk -v chr=$STUDY_CHR -v pos=$STUDY_POS -v all1=$STUDY_ALL1 -v all2=$STUDY_ALL2 -v freq=$STUDY_FREQ -v beta=$STUDY_BETA -v pval=$STUDY_PVAL \
	    -v snp_chr=$SNP_CHROM -v snp_pos=$SNP_POS -v n=$STUDY_N \
        'BEGIN { OFS="\t" } {
		if ($(chr+1) == snp_chr && $(pos+1) == snp_pos) {
			print $(chr+1), $(pos+1), $(all1+1), $(all2+1), $(freq+1), $(beta+1), $(pval+1), $(n+1)
		}
	}' >> ${EXTRACT_FILE}
#else
	#echo "(Skip header line)"
fi
I=$((I+1))

done < ${POSITIVE_FILE}

SNP_COUNT=`wc -l ${EXTRACT_FILE} | cut -f1 -d" "`
MY_COUNT=$(($SNP_COUNT - 1))

echo ""
echo "Extraction result (SNP count: $MY_COUNT):"
cat ${EXTRACT_FILE}

echo ""

if [ "${SNP_COUNT}" == "1" ]
then
	echo "ERROR: Did not find any SNPs"
	echo "${STUDY},${PHENO},${POP},,,,,,,,,,,,,,,,,SNP_NOT_FOUND" >> $OUT_FN
	exit 9
fi

if [ "$POSITIVES" -ne "${SNP_COUNT}" ]
then
        echo "WARNING: Did not find a SNP for each positive control"
fi

################## INTERPRET RESULT

Rscript $SCRIPT_PREFIX/Positive_Controls/interpret-positive-controls.R ${EXTRACT_FILE} ${POSITIVE_FILE} ${OUT_FN} ${STUDY} ${POP} ${PHENO}

#rm -vf ${EXTRACT_FILE} ${POSITIVE_FILE}


