FN=$1

NEW_PHENOTYPES=$(echo "$PHENOTYPES" | sed 's/[^ ][^ ]*/_&\./g')

for PHENO in $NEW_PHENOTYPES
do
    if [[ $FN == *$PHENO* ]]
    then
		CLEAN_PHENO=$(echo "${PHENO}" | sed 's/^_//;s/\.$//')
        echo "${CLEAN_PHENO}"  
    fi
done