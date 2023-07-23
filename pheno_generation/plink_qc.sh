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





# if your sample differs for the analyzed traits in the consortium you might want to run the snp filters per trait (e.g. to ensure that minor alleles of the filtered SNPs are present for the traits with high missinigness)
# some of below code might be helpful for that

# create id files for all traits
R
tmp <- read.table("myData.txt",header=TRUE)
# traits <- c("age","bmi","egfr")
for(trait in traits){
index <- complete.cases(tmp[,trait])
write.table(tmp[index,c("FAM_ID","id")],file=paste0(trait,"_IND.txt"),col.names=FALSE,row.names=FALSE,quote=FALSE)
}
q()


for TRAIT in `ls *_IND.txt`
do
OUT=$(basename -s "_IND.txt" ${TRAIT})
FILE=qc_pass_${OUT}.snplist
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else
$PLINK \
--bfile $PLINK_DATA_PREFIX \
--keep $TRAIT \
--geno 0.1 \
--hwe 1e-15 \
--mac 100 \
--maf 0.01 \
--mind 0.1 \
--out qc_pass_${OUT} \
--no-id-header \
--write-snplist
fi
done

R
files <- list.files(pattern="*.snplist")
snps <- read.table(files[1])[[1]]
for(file in files[-1]){
snps2 <- read.table(file)[[1]]
snps <- intersect(snps,snps2)
print(length(snps))
}
write.table(file="../qc_pass_strict.snplist",snps,row.names=FALSE,col.names=FALSE,quote=FALSE)

# check if qc_pass_strict.snplist (overlap of the per trait snplists) still includes enough snps. If so run Regenie with qc_pass_strict.snplist (change PLINK_SNP_QC in make-regenie-step1-job-scripts.sh)
