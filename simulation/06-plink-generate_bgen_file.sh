# please adjust these paths
# PLINK=/data/programs/bin/gwas/plink/plink-1.90_beta6.20/plink
PLINK=/data/programs/bin/gwas/plink/plink2_linux_x86_64_20230825/plink2
PLINK=plink2

# do it for these ethnicities
ethnicities=("afr" "amr" "eas" "eur" "sas")

# set up the folders for the imputed genotypes
for eth in "${ethnicities[@]}"; do
	if [ ! -d imputed/${eth} ]; then
		mkdir -p imputed/${eth}
	else
		echo `date` "Folder 'imputed/${eth}' already exists."
	fi
done

if [ ! -e "imputed/1000G_imputed.pgen" ]; then
    echo `date` "Generating 1000G pgen file to erase phase"
    # important: ERASE PHASE for regenie step2
	$PLINK \
		--pgen all_hg38.pgen \
		--pvar all_hg38_rs_noannot.pvar.zst \
		--psam hg38_corrected.psam \
		--allow-extra-chr \
		--chr 1-22,X \
		--make-pgen erase-phase \
		--out imputed/1000G_imputed
else
    echo `date` "File 'imputed/1000G_imputed.pgen' already exists. Skipping the conversion"
fi

# extract autosomal data
for eth in "${ethnicities[@]}"; do
	for CHR in `seq 1 22`
	do
		$PLINK \
		--pgen imputed/1000G_imputed.pgen \
		--pvar imputed/1000G_imputed.pvar \
		--psam imputed/1000G_imputed.psam \
		--chr $CHR \
		--keep 1000G.${eth}.final.indv \
		--export bgen-1.2 bits='8' \
		--out imputed/${eth}/1000G_imputed.${eth}.chr$CHR
	done
done
