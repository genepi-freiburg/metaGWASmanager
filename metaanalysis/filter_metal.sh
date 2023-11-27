FN=$1
if [ "$FN" == "" ]
then
        echo "Please give METAL file as first argument."
        exit 3
fi

if [ ! -f "$FN" ]
then
        echo "Input does not exist: $FN"
        exit 3
fi

cat $FN | awk '{
        if (FNR > 1) {
                af = $4;
                pval = $10;
                isq = $12;
                nstud = $14 + 1;
		if (nstud >= 2) {				
                	print $0;
		}
        } else {
                print $0;
        } }' > ${FN}.filtered

