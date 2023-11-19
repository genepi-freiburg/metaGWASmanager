#!/bin/bash

source ./folders.config.sh

PHENOS=$PHENOTYPES
STRAT=$STRATA
ANC=$ANCESTRY

FN=$(basename $1)
FN_NO_SUFFIX=$(echo $FN | sed s/.gwas.gz//)

if [ "$FN" != "${FN_NO_SUFFIX}.gwas.gz" ]
then
	echo "Suffix problems"
	echo "No suffix: $FN_NO_SUFFIX"
	exit 1
fi

echo "FN without suffix: $FN_NO_SUFFIX"

for STRATUM in $STRAT
do
	if [[ "$FN_NO_SUFFIX" = *${STRATUM}* ]]
	then
		echo "Found stratum: $STRATUM"
		FN_NO_STRATUM=$(echo $FN_NO_SUFFIX | sed s/$STRATUM//)
	fi
done

if [ "$FN_NO_STRATUM" == "" ]
then
	echo "Stratum wrong."
	exit 2
fi

echo "FN without stratum: $FN_NO_STRATUM"

for PHENO in $PHENOS
do
	if [[ "$FN_NO_SUFFIX" == *${PHENO} ]]
	then
		echo "Found phenotype: $PHENO"
		FN_NO_PHENO=$(echo $FN_NO_STRATUM | sed s/$PHENO//)
	fi
done

if [ "$FN_NO_PHENO" == "" ]
then
	echo "Phenotype wrong."
	exit 3
fi

echo "FN without phenotype: $FN_NO_PHENO"

for ANCESTRY in $ANC
do
	if [[ "$FN_NO_PHENO" == *${ANCESTRY}* ]]
	then
		echo "Found ancestry: $ANCESTRY"
		FN_NO_ANCESTRY=$(echo $FN_NO_PHENO | sed s/$ANCESTRY//)
	fi
done

if [ "$FN_NO_ANCESTRY" == "" ]
then
	echo "Ancestry wrong."
	exit 4
fi

echo "FN without ancestry: $FN_NO_ANCESTRY"

UNDERSCORE_COUNT=$(echo "$FN_NO_ANCESTRY" | tr -cd '_' | wc -c)
echo "Underscore count: $UNDERSCORE_COUNT"

NUM=$(echo $FN_NO_ANCESTRY | cut -f$((UNDERSCORE_COUNT+1)) -d"_")
if [ "$NUM" == "" -o $NUM -lt 1 -o $NUM -gt 18 ]
then
	echo "Analysis number not present/wrong"
	exit 5
fi

echo "Analysis number: $NUM"

PANEL=$(echo $FN_NO_ANCESTRY | cut -f$((UNDERSCORE_COUNT-1)) -d"_")
if [ "$PANEL" != "HRC" -a "$PANEL" != "TopMed" -a "$PANEL" != "1KGP" -a "$PANEL" != "1KGPph3v5" \
	-a "$PANEL" != "1KGv3" -a "$PANEL" != "TopMed2" -a "$PANEL" != "TopMedr3" \
	-a "$PANEL" != "Topmed" -a "$PANEL" != "TopMedr3" -a "$PANEL" != "TOPMed" -a "$PANEL" != "3.5KJPNv2.1KGP3" \
	-a "$PANEL" != "HRC1.1" -a "$PANEL" != "WGS" ]
then
	echo "Imputation panel problem: $PANEL"
	echo "(Add panel to script if it seems valid)"
	#exit 6
	PANEL_PROBL=1
fi

echo "Imputation panel: $PANEL"

STUDYDATE=$(echo $FN_NO_ANCESTRY | cut -f$UNDERSCORE_COUNT -d"_")
STUDYDATELEN=${#STUDYDATE}

if [ "$STUDYDATELEN" -ne 8 ]
then
	echo "Invalid study date length"
	exit 7
fi

isnum() { case ${1#[-+]} in ''|.|*[!0-9.]*|*.*.*) return 1;; esac ;}

if isnum $STUDYDATE
then
	echo "Study date ok: $STUDYDATE"
else
	echo "Study date problem: $STUDYDATE"
	exit 7
fi

STUDY=$(echo $FN_NO_ANCESTRY | sed s/_$STUDYDATE// | sed s/_$PANEL// | sed s/_$NUM//)
echo "Study: $STUDY"

if [ "$PANEL_PROBL" == "1" ]
then
	if [ "$STUDY" == "$PANEL" ]
	then
		echo "Panel = Study => No panel. That's ok"
	else
		echo "Panel problem!"
		exit 8
	fi
fi
