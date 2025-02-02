mkdir -p liftOver_input

#id position a0 a1 TYPE AFR AMR EAS EUR SAS ALL

for CHR in `seq 1 22` X
do
INFN="legend/1000GP_Phase3_chr$CHR.legend.gz"
if [ "$CHR" == "X" ]
then
	INFN="legend/1000GP_Phase3_chrX_NONPAR.legend.gz"
fi

echo "Process: $INFN"

zcat $INFN | \
	awk -v CHR=$CHR '{ if (FNR>1) {
			print "chr" CHR, $2, $2+1, "A0=" $3 ",A1=" $4 ",AFR=" $6 ",AMR=" $7 ",EAS=" $8 ",EUR=" $9 ",SAS=" $10 ",ALL=" $11
		} else { print "#chr start end name" }}' > liftOver_input/1kgp_positions.chr$CHR.bed
done

