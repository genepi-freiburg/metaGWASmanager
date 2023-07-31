#!/bin/bash

# please adjust these paths to match your environment
# you may also adjust the job scheduler settings below
# please also adjust your study file name in line 37
REGENIE=regenie

STUDY=$1
ANCESTRY=$2
REFPANEL=$3
ANALYSIS_DATE=$4
BINARY_OR_QUANTITATIVE=$5
PHENOTYPE_COLUMNS=$6
COVARIABLE_COLUMNS=$7
CATEGORIAL_COVARIABLE_COLUMNS=$8
RUN_INDEX=${9}

STEP1=output_regenie_step1/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_${BINARY_OR_QUANTITATIVE}_${RUN_INDEX}_pred.list

BT_OPTION=""
if [ "$BINARY_OR_QUANTITATIVE" == "binary" ]
then
        BT_OPTION="  --bt"
fi

if [ "$CATEGORIAL_COVARIABLE_COLUMNS" != "" ]
then
        CATCOVAR_OPT="  --catCovarList ${CATEGORIAL_COVARIABLE_COLUMNS} \\"$'\n'
else
        CATCOVAR_OPT=""
fi

for CHR in `seq 1 22` X
do
# path to the imputed data
BGEN_SAMPLE_PREFIX=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline/imputed_genotypes/chr${CHR}
#BGEN_SAMPLE_PREFIX=/data/studies/00_GCKD/00_data/01_genotypes/03_imputed_data/02_HRC/bgen/chr${CHR}.rsq03
BGEN_FILE=${BGEN_SAMPLE_PREFIX}.bgen
SAMPLE_FILE=${BGEN_SAMPLE_PREFIX}.sample

# you may also adjust the following job scheduler parameters

cat > jobs/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_regenie_step2_${RUN_INDEX}_${BINARY_OR_QUANTITATIVE}_${PHENOTYPE_COLUMNS}_chr${CHR}.sh << EndOfCommand
#!/bin/bash

#SBATCH --chdir=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline

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
#SBATCH -o logs/slurm-regenie_step2_${BINARY_OR_QUANTITATIVE}_chr${CHR}_${RUN_INDEX}_%j.out

# stderr file name (%j: job ID)
#SBATCH -e logs/slurm-regenie_step2_${BINARY_OR_QUANTITATIVE}_chr${CHR}_${RUN_INDEX}_%j.err

# max run time (hh:mm:ss)
#SBATCH -t 96:00:00

module load regenie/3.2.1

$REGENIE \\
  --step 2 \\
  --bgen $BGEN_FILE \\
  --sample $SAMPLE_FILE \\
  --phenoFile output_pheno/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}.data.txt \\
  --phenoColList ${PHENOTYPE_COLUMNS} \\
  --covarFile output_pheno/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}.data.txt \\
  --covarColList ${COVARIABLE_COLUMNS} \\
$CATCOVAR_OPT  --pred $STEP1 \\
  --bsize 400 \\
  --minINFO 0.3 \\
  --minMAC 2 \\
  --threads 4 \\
  --maxCatLevels 99 \\
  --write-samples \\
  --print-pheno \\
  --gz \\
  --out output_regenie_step2/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_${BINARY_OR_QUANTITATIVE}_${RUN_INDEX}_chr${CHR} \\
$BT_OPTION

EndOfCommand

done
