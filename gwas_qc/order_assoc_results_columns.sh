#!/bin/bash
#Plink example
# If you use another assoc tool, you should adjust it
for file in "$IN_PATH"/*glm*; do
	echo "Converter file: $file "

    awk 'BEGIN { OFS="\t"; print "CHROM\tGENPOS\tID\tALLELE0\tALLELE1\tA1FREQ\tINFO\tN\tBETA\tSE\tLOG10P" }
    NR>1 { print $1, $2, $3, $4, $6, $7, $8, $9, $10, $11, $12 }' "$file" > temp_file

    mv "$file" "${file}_old"
	
	#Change name
	new_file=$(echo "$file" | awk -F '_' '{gsub(/chr[0-9X]+/, "&_")}1')

    mv temp_file "$new_file"
done
