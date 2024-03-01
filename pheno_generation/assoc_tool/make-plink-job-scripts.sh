# please adjust these paths to match your environment
# you may also adjust the job scheduler settings below
# please also adjust your study file name in line 37
PLINK=plink2

STUDY=$1
ANCESTRY=$2
REFPANEL=$3
ANALYSIS_DATE=$4
BINARY_OR_QUANTITATIVE=$5
PHENOTYPE_COLUMNS=$6
COVARIABLE_COLUMNS=$7
RUN_INDEX=${8}


for CHR in `seq 1 22` X
do
# path to the imputed data
BGEN_SAMPLE_PREFIX=/data/cne/ec/ieg/Data/CKD/Aragon/imputed_genotypes/bgen/chr${CHR}
#BGEN_SAMPLE_PREFIX=/data/studies/00_GCKD/00_data/01_genotypes/03_imputed_data/02_HRC/bgen/chr${CHR}.rsq03
BGEN_FILE=${BGEN_SAMPLE_PREFIX}.bgen
SAMPLE_FILE=${BGEN_SAMPLE_PREFIX}.sample

# you may also adjust the following job scheduler parameters

cat > jobs/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_plink_${RUN_INDEX}_${BINARY_OR_QUANTITATIVE}_${PHENOTYPE_COLUMNS}_chr${CHR}.sh << EndOfCommand
#!/bin/bash

# job name (abbreviated)
#SBATCH -J r2_c${CHR}_${BINARY_OR_QUANTITATIVE::1}${RUN_INDEX}

#SBATCH --partition=long_idx

# number of nodes
#SBATCH -N 1

# number of MPI processes per node
#SBATCH -n 1

# memory allocation
#SBATCH --mem=10G

# number of cpu cores
#SBATCH --cpus-per-task=4

# stdout file name (%j: job ID)
#SBATCH -o logs/slurm-plink_${BINARY_OR_QUANTITATIVE}_chr${CHR}_${RUN_INDEX}_%j.out

# stderr file name (%j: job ID)
#SBATCH -e logs/slurm-plink_${BINARY_OR_QUANTITATIVE}_chr${CHR}_${RUN_INDEX}_%j.err

# max run time (hh:mm:ss)
#SBATCH -t 96:00:00

module load  PLINK/2.00a3.6-GCC-11.3.0

$PLINK \\
  --bgen $BGEN_FILE ref-last \\
  --sample $SAMPLE_FILE \\
  --pheno output_pheno/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}.data.txt \\
  --pheno-name ${PHENOTYPE_COLUMNS} \\
  --covar-name ${COVARIABLE_COLUMNS} \\
  --covar-variance-standardize \\
  --glm hide-covar allow-no-covars no-firth single-prec-cc cc-residualize cols=chrom,pos,ref,alt,a1freq,test,nobs,beta,se,p \\
  --maf 0.01 \\
  --pfilter 0.01 \\
  --threads 4 \\
  --memory 10000 \\
  --write-samples \\
  --out output_plink/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_${BINARY_OR_QUANTITATIVE}_${RUN_INDEX}_chr${CHR} \\

EndOfCommand

done