#!/bin/bash
WD=`pwd`
cd /home/mwuttke/qc_html/Associations
mkdir -p /home/mwuttke/qc_html/Freq_Plots

rm -f *
for FN in `ls /storage/cleaning/ckdgenR5`
do
	BN=`basename $FN`
	if [ "$BN" == "00_SUMMARY" -o "$BN" == "00_ARCHIVE" ]
	then
		continue
	fi
	rm -f $BN
	ln -s /storage/cleaning/ckdgenR5/$FN/qc-output $BN

	for PDF in `ls /storage/cleaning/ckdgenR5/$FN/freqs/*.pdf`
	do
		PDFBN=`basename $PDF`
		DEST="/home/mwuttke/qc_html/Freq_Plots/$PDFBN"
		if [ ! -f $DEST ]
		then
			ln -s -f $PDF $DEST
			#cp $PDF $BN/
		fi
	done
done


cd /home/mwuttke/qc_html/Phenotypes
rm -f *
for FN in `ls /storage/uploads/ckdgenR5/pheno`
do
	if [ "$FN" == "00_SUMMARY" -o "$FN" == "00_ARCHIVE" ]
	then
		continue
	fi
	rm -f $FN
	ln -s /storage/uploads/ckdgenR5/pheno/$FN $FN
done

cd $WD

