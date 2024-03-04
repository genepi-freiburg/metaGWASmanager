#!/bin/bash

# please adjust these paths
# PLINK=/data/programs/bin/gwas/plink/plink-1.90_beta6.20/plink
PLINK=/data/programs/bin/gwas/plink/plink2_linux_x86_64_20230825/plink2
PLINK=plink2

if [ ! -f all_hg38.pgen ]
then
  $PLINK \
    --zst-decompress all_hg38.pgen.zst > all_hg38.pgen
fi

if [ ! -f all_hg38_rs_noannot.pvar ]
then
  $PLINK \
    --zst-decompress all_hg38_rs_noannot.pvar.zst > all_hg38_rs_noannot.pvar
fi

# # must be upper case here, extract indivudals by ethnicity
ethnicities=("AFR" "AMR" "EAS" "EUR" "SAS")
for eth in "${ethnicities[@]}"; do
    awk -v eth="$eth" '$5 == eth {print $1}' "hg38_corrected.psam" > "hg38_corrected.${eth,,}.psam"
done

# # use lower case fro here on
ethnicities=("afr" "amr" "eas" "eur" "sas")
for eth in "${ethnicities[@]}"; do
	$PLINK \
	  --pgen all_hg38.pgen \
	  --pvar all_hg38_rs_noannot.pvar.zst \
	  --psam hg38_corrected.psam \
	  --set-all-var-ids @:#:\$r:\$a \
	  --new-id-max-allele-len 487 \
	  --autosome \
	  --allow-extra-chr \
	  --keep hg38_corrected.$eth.psam \
	  --geno 0.1 \
	  --hwe 1e-15 \
	  --mac 200 \
	  --maf 0.03 \
	  --mind 0.1 \
	  --out qc_pass.$eth \
	  --no-id-header \
	  --write-samples \
	  --write-snplist allow-dups \
	  --nonfounders \
	  --make-bed
done

# detect a few duplicate IDs
for eth in "${ethnicities[@]}"; do
	$PLINK \
	  --bfile qc_pass.$eth \
	  --rm-dup exclude-all list \
	  --out qc_pass_noDup.$eth
done

# prune variants
for eth in "${ethnicities[@]}"; do
	$PLINK \
	  --bfile qc_pass.$eth \
	  --exclude qc_pass_noDup.$eth.rmdup.list \
	  --indep-pairwise 2000 200 0.3 \
	  --out qc_pass_indep.$eth
done

# rewrite file
for eth in "${ethnicities[@]}"; do
	$PLINK \
	  --bfile qc_pass.$eth \
	  --exclude qc_pass_indep.$eth.prune.out \
	  --make-bed \
	  --out 1000G.$eth.final
done

# for the keep and extract option of regenie step1 write out all individuals and all SNPs
for eth in "${ethnicities[@]}"; do
	awk '{print $2}' 1000G.$eth.final.bim > 1000G.$eth.final.snps
	awk -F'\t' '{print 0"\t"$2}' 1000G.$eth.final.fam > 1000G.$eth.final.indv
done

# clean up
rm -f qc_pass*
rm -f hg38_corrected.*.psam
