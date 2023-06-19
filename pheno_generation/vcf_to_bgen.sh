#!/bin/bash

# You may use this script if your imputed data is in vcf format to
# convert it to bgen format. If your data is already in bgen format,
# you do not need to run this script.

### please modify these paths
IMPUTED_VCF=/data/imputed/TOPMedR2/vcf
IMPUTED_BGEN=/data/imputed/TOPMedR2/bgen
PLINK2=plink2
### end of path specification

# step 1
for chr in `seq 1 22` X
do

	$PLINK2 --vcf ${IMPUTED_VCF}/chr${chr}.vcf.gz dosage=DS \
		--make-pgen erase-phase \
		--out ${IMPUTED_BGEN}/chr${chr}_unphased # include an & for parallel submission if sufficient memory is available
done

wait

# step 2
for chr in `seq 1 22` X
do
	$PLINK2 --pfile ${IMPUTED_BGEN}/chr${chr}_unphased \
		--export bgen-1.2 bits=8 \
		--out ${IMPUTED_BGEN}/chr${chr} # include an & for parallel submission if sufficient memory is available
done

wait

rm ${IMPUTED_BGEN}/chr${chr}_unphased.pgen
rm ${IMPUTED_BGEN}/chr${chr}_unphased.pvar
rm ${IMPUTED_BGEN}/chr${chr}_unphased.psam

# step 3
# the bgen .sample file has zeros as FID, which results
# in the error that all samples have missing phenotypes in
# the regienie run.
for chr in `seq 1 22` X
do
	cut -d " " -f 2 ${IMPUTED_BGEN}/chr${chr}.sample | sed "s/ID_2/ID_1/g" > ${IMPUTED_BGEN}/chr${chr}.IID
	cut -d " " -f 2-4 ${IMPUTED_BGEN}/chr${chr}.sample > ${IMPUTED_BGEN}/chr${chr}.rest
	paste -d " " ${IMPUTED_BGEN}/chr${chr}.IID ${IMPUTED_BGEN}/chr${chr}.rest > ${IMPUTED_BGEN}/chr${chr}.sample
	rm ${IMPUTED_BGEN}/chr${chr}.IID
	rm ${IMPUTED_BGEN}/chr${chr}.rest
done
