#!/bin/bash

# please adjust these paths to match your environment
# you may also adjust the job scheduler settings below

REGENIE=regenie
# path to the genotype data
PLINK_DATA_PREFIX=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline/chip_Genotypes/qc/change_ID2/sample_number/vhsCDK_def2ns
PLINK_SNP_QC=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline/chip_Genotypes/qc/change_ID2/sample_number/vhsCDK_def2ns.snplist
PLINK_INDIV_QC=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline/chip_Genotypes/qc/change_ID2/sample_number/vhsCDK_def2ns.id

TEMP_DIR=./regenie_temp
mkdir -p $TEMP_DIR logs output_regenie_step1 output_regenie_step2 jobs

# parameters to this script
STUDY=$1
ANCESTRY=$2
REFPANEL=$3
ANALYSIS_DATE=$4
BINARY_OR_QUANTITATIVE=$5
PHENOTYPE_COLUMNS=$6
COVARIABLE_COLUMNS=$7
CATEGORIAL_COVARIABLE_COLUMNS=$8
RUN_INDEX=${9}

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

cat > jobs/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_regenie_step1_${RUN_INDEX}_${BINARY_OR_QUANTITATIVE}_${PHENOTYPE_COLUMNS}.sh << EndOfCommand
#!/bin/bash

#SBATCH --chdir=/data/cne/ec/ieg/Crew/zulema.rodriguez/Consortium_pipeline

# job name (abbreviated)
#SBATCH -J r1_${BINARY_OR_QUANTITATIVE::1}${RUN_INDEX}

#SBATCH --partition=long_idx

# number of nodes
#SBATCH -N 1

# number of MPI processes per node
#SBATCH -n 1

# memory allocation
#SBATCH --mem=20G

# number of cpu cores
#SBATCH --cpus-per-task=8

# stdout file name (%j: job ID)
#SBATCH -o logs/slurm-regenie_step1_${BINARY_OR_QUANTITATIVE}_${RUN_INDEX}_%j.out

# stderr file name (%j: job ID)
#SBATCH -e logs/slurm-regenie_step1_${BINARY_OR_QUANTITATIVE}_${RUN_INDEX}_%j.err

# max run time (hh:mm:ss)
#SBATCH -t 96:00:00

module load regenie/3.2.1

$REGENIE \\
  --step 1 \\
  --bed ${PLINK_DATA_PREFIX} \\
  --extract ${PLINK_SNP_QC} \\
  --keep ${PLINK_INDIV_QC} \\
  --phenoFile output_pheno/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}.data.txt \\
  --phenoColList ${PHENOTYPE_COLUMNS} \\
  --covarFile output_pheno/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}.data.txt \\
  --covarColList ${COVARIABLE_COLUMNS} \\
$CATCOVAR_OPT  --bsize 1000 \\
  --lowmem \\
  --lowmem-prefix ${TEMP_DIR}/regenie_temp_predictors_${RUN_INDEX} \\
  --threads 8 \\
  --maxCatLevels 99 \\
  --gz \\
  --out output_regenie_step1/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_${BINARY_OR_QUANTITATIVE}_${RUN_INDEX} \\
$BT_OPTION
EndOfCommand

