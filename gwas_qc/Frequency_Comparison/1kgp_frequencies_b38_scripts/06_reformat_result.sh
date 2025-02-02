
#!/bin/bash

echo "CHROM	GENPOS	ALLELE0	ALLELE1	AFR	AMR	EAS	EUR	SAS	ALL" > 1kgp_frequencies_b38.txt

for CHR in `seq 1 22` X
do

cat liftOver_output/1kgp_positions.b38.chr$CHR.bed | \
	awk -v CHR=$CHR '{
		split($4, myfields, ",");
		chr = substr($1, 4);
		if (chr == CHR) {
			a0 = substr(myfields[1], 4);
			a1 = substr(myfields[2], 4);
			afr = substr(myfields[3], 5);
			amr = substr(myfields[4], 5);
			eas = substr(myfields[5], 5);
			eur = substr(myfields[6], 5);
			sas = substr(myfields[7], 5);
			all = substr(myfields[8], 5);
			print chr "\t" $2 "\t" a0 "\t" a1 "\t" afr "\t" amr "\t" eas "\t" eur "\t" sas "\t" all;
		}
	}' >> 1kgp_frequencies_b38.txt

done

gzip 1kgp_frequencies_b38.txt
