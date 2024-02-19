#!/bin/bash

# please adjust these paths
# PLINK=/data/programs/bin/gwas/plink/plink-1.90_beta6.20/plink
PLINK=/data/programs/bin/gwas/plink/plink2_linux_x86_64_20230825/plink2

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

$PLINK \
  --pgen all_hg38.pgen \
  --pvar all_hg38_rs_noannot.pvar.zst \
  --psam hg38_corrected.psam \
  --set-all-var-ids @:#:\$r:\$a \
  --new-id-max-allele-len 487 \
  --autosome \
  --allow-extra-chr \
  --geno 0.1 \
  --hwe 1e-15 \
  --mac 200 \
  --maf 0.03 \
  --mind 0.1 \
  --out qc_pass \
  --no-id-header \
  --write-samples \
  --write-snplist allow-dups \
  --nonfounders \
  --make-bed

# detect a few duplicate IDs
$PLINK \
  --bfile qc_pass \
  --rm-dup list \
  --out qc_pass_indep

# prune variants
$PLINK \
  --bfile qc_pass \
  --exclude qc_pass_indep.rmdup.mismatch \
  --indep-pairwise 2000 200 0.3 \
  --out qc_pass_indep

# rewrite file
$PLINK \
  --bfile qc_pass \
  --exclude qc_pass_indep.prune.out \
  --make-bed \
  --out qc_pass_indep


