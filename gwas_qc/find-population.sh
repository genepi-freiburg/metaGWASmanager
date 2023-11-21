FN=$1

NEW_ANCESTRY=$(echo $ANCESTRY | sed 's/ /_ /g')
NEW_ANCESTRY="${NEW_ANCESTRY}_"


for ANC in $NEW_ANCESTRY
do
    if [[ $FN == *$ANC* ]]
    then
		ANC_F=$(echo "$ANC" | sed 's/_$//')
        echo "${ANC_F}"  
    fi
done

