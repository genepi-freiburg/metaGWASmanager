FN=$1
if [ "$FN" == "" ]
then
	echo "Need filename"
elif [[ $FN == *_creatinine_* ]] || [[ $FN == *_Creatinine_* ]] || [[ $FN == *Creatinine* ]] || [[ $FN == *creatinine* ]]
then
	echo "creatinine"
elif [[ $FN == *egfr_decline* ]] || [[ $$N == *eGFR_decline* ]]
then
	echo "eGFR_decline"
elif [[ $FN == *rapid3* ]]
then
	echo "rapid3"
elif [[ $FN == *_eGFR_* ]]
then
        echo "eGFR"
elif [[ $FN == *eGFR_* ]]
then
        echo "eGFR"
elif [[ $FN == *_egfr_* ]]
then
        echo "eGFR"
elif [[ $FN == *_ma_* ]] || [[ $FN == *ma.* ]]
then
        echo "MA"
elif [[ $FN == *_MA_* ]] || [[ $FN == *MA* ]]
then
        echo "MA"
elif [[ $FN == *_UACR_* ]]
then
        echo "UACR"
elif [[ $FN == *_uacr_* ]]
then
        echo "UACR"
elif [[ $FN == *UACR* ]]
then
        echo "UACR"
elif [[ $FN == *_BUN_* ]]
then
        echo "BUN"
elif [[ $FN == *_bun_* ]] || [[ $FN == *bun* ]]
then
        echo "BUN"
elif [[ $FN == *_urate_* ]] || [[ $FN == *uricacid* ]]
then
        echo "urate"
elif [[ $FN == *Uric_Acid* ]]
then
        echo "urate"
elif [[ $FN == *uric_acid* ]]
then
        echo "urate"
elif [[ $FN == *Gout* ]] || [[ $FN == *gout* ]]
then
        echo "gout"
elif [[ $FN == *rapid3* ]] 
then
        echo "rapid3"
elif [[ $FN == *_ckd_* ]] || [[ $FN == *_ckd* ]] || [[ $FN == *.ckd* ]] #CAVE: GCKD
then
        echo "CKD"
elif [[ $FN == *_CKD_* ]] || [[ $FN == *_CKD* ]] || [[ $FN == *.CKD* ]] #CAVE: GCKD
then
        echo "CKD"
elif [[ $FN == *CKDi25* ]] 
then
        echo "CKDi25"
elif [[ $FN == *albumin* ]]
then
	echo "albumin"
elif [[ $FN == *calcium* ]]
then
	echo "calcium"
elif [[ $FN == *phosphate* ]]
then
	echo "phosphate"
else
	echo "???"
fi


