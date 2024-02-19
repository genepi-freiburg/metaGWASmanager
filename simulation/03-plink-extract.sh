#!/bin/bash

# please adjust these paths
# PLINK=/data/programs/bin/gwas/plink/plink-1.90_beta6.20/plink
PLINK=/data/programs/bin/gwas/plink/plink2_linux_x86_64_20230825/plink2

$PLINK \
  --pgen all_hg38.pgen \
  --pvar all_hg38_rs_noannot.pvar.zst \
  --psam hg38_corrected.psam \
  --allow-extra-chr \
  --snp rs4293393 \
  --export A \
  --out extract_rs4293393


