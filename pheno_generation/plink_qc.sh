#!/bin/bash

# please adjust these paths
PLINK=/data/programs/bin/gwas/plink/plink-1.90_beta6.20/plink
PLINK=/data/programs/bin/gwas/plink/plink2_linux_x86_64_20220322/plink2

# path to the genotype data
PLINK_DATA_PREFIX=/data/studies/00_GCKD/00_data/01_genotypes/02_clean_data/02_Common_Genotyped_Maf1_Call96_HWE5/GCKD_Common_Clean

# if your genotype data is in vcf format instead of plink format,
# you may use this command to convert to plink format first
: '
GENOTYPE_DATA_VCF=/data/genotypes/genotypes.vcf.gz
$PLINK --make-bed --vcf $GENOTYPE_DATA_VCF \
    --out $PLINK_DATA_PREFIX
'

mkdir -p qc

# you might also want to prune your SNPs if your marker array is too dense
# you might use: --indep-pairwise 1000 100 0.9
# recommended are <1 mio SNPs for step 1

$PLINK \
  --bfile $PLINK_DATA_PREFIX \
  --geno 0.1 \
  --hwe 1e-15 \
  --mac 100 \
  --maf 0.01 \
  --mind 0.1 \
  --out qc/qc_pass \
  --no-id-header \
  --write-samples \
  --write-snplist

