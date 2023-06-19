#!/bin/bash

# please adjust these paths to match your environment
# you may also adjust the job scheduler settings below

REGENIE=/data/programs/bin/gwas/regenie/regenie_v2.2.4.gz_x86_64_Linux
# path to the genotype data
PLINK_DATA_PREFIX=/data/studies/00_GCKD/00_data/01_genotypes/02_clean_data/02_Common_Genotyped_Maf1_Call96_HWE5/regenieQc/GCKD_Common_Clean_REGENIE
PLINK_SNP_QC=qc/qc_pass.snplist
PLINK_INDIV_QC=qc/qc_pass.id

TEMP_DIR=./regenie_temp
mkdir -p $TEMP_DIR logs output_regenie_step1 output_regenie_step2 jobs

# parameters to this script
STUDY=$1
ANCESTRY=$2
REFPANEL=$3
ANALYSIS_DATE=$4
BINARY_OR_QUANTITATIVE=$5
OVERALL_OR_SEXSTRATIFIED=$6
PHENOTYPE_COLUMNS=$7
COVARIABLE_COLUMNS=$8
CATEGORIAL_COVARIABLE_COLUMNS=$9
RUN_INDEX=${10}

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

cat > jobs/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_regenie_step1_${RUN_INDEX}_${BINARY_OR_QUANTITATIVE}_${OVERALL_OR_SEXSTRATIFIED}_${PHENOTYPE_COLUMNS}.sh << EndOfCommand
#!/bin/bash

# job name (abbreviated)
#SBATCH -J r1_${BINARY_OR_QUANTITATIVE::1}${OVERALL_OR_SEXSTRATIFIED::1}_${RUN_INDEX}

# number of nodes
#SBATCH -N 1

# number of MPI processes per node
#SBATCH -n 1

# memory allocation
#SBATCH --mem=20G

# number of cpu cores
#SBATCH --cpus-per-task=8

# stdout file name (%j: job ID)
#SBATCH -o logs/slurm-regenie_step1_${BINARY_OR_QUANTITATIVE}_${OVERALL_OR_SEXSTRATIFIED}_${RUN_INDEX}_%j.out

# stderr file name (%j: job ID)
#SBATCH -e logs/slurm-regenie_step1_${BINARY_OR_QUANTITATIVE}_${OVERALL_OR_SEXSTRATIFIED}_${RUN_INDEX}_%j.err

# max run time (hh:mm:ss)
#SBATCH -t 96:00:00

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
  --out output_regenie_step1/${STUDY}_${ANCESTRY}_${REFPANEL}_${ANALYSIS_DATE}_${BINARY_OR_QUANTITATIVE}_${OVERALL_OR_SEXSTRATIFIED}_${RUN_INDEX} \\
$BT_OPTION
EndOfCommand

