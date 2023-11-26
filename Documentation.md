---
title: "metaGWASmanager documentation"
date: "11/11/2023"
---

# **Overview**
This vignette introduces the metaGWASmanager, a comprehensive toolbox leveraging existing software packages and, streamlining the entire GWAS-consortium workflow. This encompasses the phenotype generation, quality control of phenotypes, GWAS, and GWAS-QC, providing an integrated solution for both the participating Study Analysts (SA) and Consortium Analysts (CA). For a description, please see the corresponding manuscript:
Zulema Rodriguez-Hernandez, Mathias Gorski, Maria Tellez Plaza, Pascal Schlosser* and Matthias Wuttke* (2023). “metaGWASmanager: A toolbox for an automated workflow from phenotypes to meta-analysis in GWAS consortia”. under review.

![Workflow](Z:/ftp/zrodriguez/proyectos/GWAS_consortium_standardization_pipeline/workflow_figure/Figure1.png). *Illustration of the metaGWASmanager pipeline, outlining phenotype generation and quality assurance, followed by the GWAS and GWAS-QC steps, along with the required inputs and resulting outputs. Shaded and white sections indicate tasks to be carried out by CA and SA, respectively.*

---

# **Installation**
To set up the toolbox please fork the github repository:
https://github.com/genepi-freiburg/gwas-consortium/tree/main

---

# **Required files, programs and server**
Aside from the documentation and scripts supplied by metaGWASmanager, it is necessary to ensure that the following programs and files are properly installed and downloaded on your system.

## For SAs
- [REGENIE](https://rgcgithub.github.io/regenie/)
- [PLINK](https://zzz.bwh.harvard.edu/plink/) or [PLINK 2.0](https://www.cog-genomics.org/plink/2.0/).
- [VCFtools](https://vcftools.sourceforge.net/man_latest.html) and [BCFtools](https://samtools.github.io/bcftools/bcftools.html)
- [R](https://www.r-project.org/) software
- Analysis plan, scripts and examples files for conducting phases 2 and 4 will be provided by the CAs.


## For CAs
Same as SAs, but also:

- [GWASInspector](https://cran.r-project.org/web/packages/GWASinspector/index.html) R package
  - SQLite reference data available [here](http://gwasinspector.com/#download)

- [Perl](https://www.perl.org/)
- [HTSlib](https://www.htslib.org/)
- [FlexiBLAS](https://www.mpi-magdeburg.mpg.de/projects/flexiblas)
- [Python](https://www.python.org/)

### Server structure
We outline the recommended structure for the consortium server to ensure effective and efficient data management:

#### Scripts
They should be separate from data, in a different folder. This folder will contain of scripts needed by CA.

```{r, eval=FALSE}
"/storage/consortium_name/scripts/"
```


#### Pheno Upload
The phenotypes results (output of **Phase 2 - SA:  Prepare Phenotypes (SAs)**, *pheno* mode) submitted by the SAs will be stored in the *uploads/pheno* directory. This directory will contain a folder for each study that has submitted summary statistics.

```{r, eval=FALSE}
"/storage/consortium_name/uploads/pheno/Specific_study_name"
```

In addition, it should contain two additional directories:
- *00_ARCHIVE*. If a specific-study re-upload the phenotype summary statistics, perhaps due to the detection of an error, CA will archive the previous version in this directory. 
- *00_SUMMARY*. It has the code to generate cross-study phenotype summaries in the **Phase 3 - CA: Check & Approve Phenotypes Files**. The output of executing these scripts will be saved here.


#### GWAS Upload
The GWAS results (output of **Phase 4 - SA: Perform Associations Analysis**) submitted by the SAs will be stored in the *uploads/assoc* directory. This directory will contain a folder for each study that has submitted summary statistics.

```{r, eval=FALSE}
"/storage/consortium_name/uploads/assoc/Specific_study_name"
```

It is advised to maintain consistency in the naming of studies withing both the *uploads/pheno* and *uploads/assoc* folders to prevent potential problems when cross-referencing files between the two folders.

#### Cleaning
Contains intermediate files, logs and summary files resulting from **Phase 5 - CA: Check Associations & Metaanalysis**. The sub-folder "*data*" contains the merged REGENIE results by chromosomes.

```{r, eval=FALSE}
"/storage/consortium_name/cleaning/Specific_study_name"
```


---

# **Step by step guide**

## **Phase 1 - CA: Customize Toolbox (Analysis Plan & SA Materials)**
The initial stage involves generating Consortium-specific files (*consortium-specifics.R* and *parameters.txt* plug-in) and formulating the Analysis Plan, in which CAs will define, based on the provided metaGWASmanager examples, the required settings for conducting the pool-cohort GWAS.


A) ***consortium-specifics.R***. 
The consortium-specifics.R plug-in file should be edited according to the CA specifications. This file contains several functions such as unit conversion, traits transformations, verification of the input and parameteres files, setting quality control parameters, determination of covariates, stratification etc. These functions will be applied in subsequent stages of the workflow process. 
The *consortium-specifics.R* file will be provided, along the Analysis Plan and required scripts, to each SAs.

B) **Parameters file**. 
CA will customize the *parameters.txt* file to match the particular traits to study. It must included important points, which must be filled out by the SAs, such as the name of the input file and the participant-study, SAs contact information, the study's ancestral background, the analysis date, the units of the variables to be studied, along with laboratory particular settings (e.g., limits of detection), the imputation reference panel, the number of genetic principal components, and some more optional fields.


C) **Analysis Plan**.
The Analysis Plan PDF document should provided comprehensive information for SAs on to proceed with the different analyses, including **Phase 2 - SA:  Prepare Phenotypes** and **Phase 4 - SA: Perform Associations Analysis**. It is also essential to include contact details for CA in case any questions arise.
See [here](add) an example of Analysis Plan file.


## **Phase 2 - SA:  Prepare Phenotypes**
In a first step, CA will ask for preparation the phenotypic data for all participating studies. CA will supply an Analysis Plan and scripts (including the *consortium-specifics.R* plug-in) that automatically generate descriptive statistics. Every available script will be executed by SAs on a Linux server using the *bash* command line.

Input files for each participanting study, include an input data (*input.txt*) and a parameter file (*parameters.txt*) that SAs will create and complete, respectively, according the CA guide standards.

During this initial phase (*pheno* mode), a comprehensive examination of the input and parameters files will be carried out. This involves issuing warnings and identifying errors to guarantee high-quality phenotypic data and prevent common pitfalls such as unit conversion discrepancies or variations in assay methods. Additionally, the pipeline executes essential trait transformations and calculations, ensuring uniformity in the phenotypic data.

The files generated by phenotype preparation scripts include the phenotype summary statistics ("*STUDYNAME_ids_summary.txt"*) and plots files, which will submit to CA for review.

More information on how to run **Phase 2 - SA:  Prepare Phenotypes** is provided in the [Analysis Plan](TOADD) example.

## **Phase 3 - CA: Check & Approve Phenotypes Files**
The graphical an summary statistics of phenotypes submitted by each SAs, will be stored in the *upload/pheno* directory, within the folder corresponding to the specific participating study.


```{r, eval=FALSE}
"/storage/consortium_name/uploads/pheno/Specific_study_name"
```

Subsequently, CA will manually inspect these files in order to indentify potential issues and inconsistencies. Furthermore, CA will run the cross-study validation scripts (*"01_collect_summary.R" and "02_plot_summaries.R"*), located in the *"pheno_summary"* directory of the metaGWASmanager toolkit. Both scripts summarize phenotype summary-statistics submissions ("*STUDYNAME_ids_summary.txt"*)  across studies and also facilitate their representation for improved inter-study comparison and to detect potential outliers.

Note that the generated outputs of the inter-study comparison analyses will be automatically saved in the *"00_SUMMARY"* folder located at the path mentioned above.

After the inspection of submitted pthenotype summary statistics files, CA will provide feedback to SAs. In the case CA detects an issue, it will be clearly outlined and assistance will be offered to the SAs in oder to resolve it.  The SAs will then revisit  **Phase 2 - SA:  Prepare Phenotypes** and re-submit the corresponding outputs files. Contrary, if no problems are identified, SAs are authorized to proceed with **Phase 4 - SA: Perform Associations Analysis**.


## **Phase 4 - SA: Perform Associations Analysis**
To initiate this step, SAs should have received the approval from CA. Additionally, they must have prepared the genotype and imputed data for *regenie* steps 1 and 2 following the instructions provided in the Analysis Plan.

Every available script will be executed by SAs on a Linux server using the *bash* command line.

A) **Create job files**.
The *02-ckdgen-r5-make-regenie-jobs.sh* script will be executed by SAs, in which the same scripts that were previously run in **Phase 2 - SA:  Prepare Phenotypes** will be employed again, but this time using the *jobs* mode, instead the *pheno* mode.The process will generate two files: one containing the phenotypes and covariates details, and the other holding the command lines. Both files are required for creating the different job files.
Keep in mind that CA should prompt SAs (e.g.,in the Analysis Plan) to adjust the paths in where genotypic and imputed data are found in the *make-regenie-step1-job-scripts.sh* and *make-regenie-step2-job-scripts.sh*,respectively.
Here, one job will be created for each phenotype for *regenie* step 1, and one job for each phenotype and chromosome for *regenie* step 2.
These scripts are set up to utilize a Slurm job scheduler and will need to be adapted to the server infrastructure of participating studies.


B) **Run GWAS using *regenie***.
SAs will executed a shell script (*03-submit-all-jobs.sh*) to submit all GWAS according to the jobs generated in the preceding step for both steps 1 and 2 of *regenie*.


C) **Create Summary Statistics** and **Collect & Upload results**.
The SAs will then run the *04-postprocess-results.sh* script, which investigate the different log files generated during the *regenie* process to ensure the successful execution of each GWAS. It also produces tailored summary tables for each GWAS.  Finally, the results will be compiled into a compressed folder using *05-collect-files-for-upload.sh*,  which will then be submitted to the CA server for further validation.

Extended explanation regarding  **Phase 4 - SA: Perform Associations Analysis** can be found in the [Analysis Plan](TOADD) example.


## **Phase 5 - CA: Check Associations & Meta-analysis**
The compressed folder submitted by the SA, will be stored in the *upload/assoc* directory, within the folder corresponding to the specific participating study.

```{r, eval=FALSE}
"/storage/consortium_name/uploads/assoc/Specific_study_name"
```

CA will then proceed to unzip the folder and run scripts located in the *gwas_qc* folder of the metaGWASmanager toolbox.


#### *folders.config.sh* file
Includes details regarding essential pathways (like the script folder path, working directory, uploaded data, etc) and specific variables (phenotypes, ancestry and strata vectors) needed for executing GWAS-QC analyses. CAs should customize these fields and may also incorporate important settings to align with particular requirements, such as server specifications. 

To make **Phase 5 - CA: Check Associations & Meta-analysis** automatic, their different scripts located in the *gwas_qc* folder,  will call the *folders.config.sh* plug-in. Therefore, there is no need to make any modifications to any other scripts.

Reminder: Ensure that the  *gwas_qc* folder is stored, in the same format provided by metaGWASmanager, inside the *"script"* folder of the consortium directory.

```{r, eval=FALSE}
"/storage/consortium_name/scripts/"
```

 
After making the necessary settings to the *folders.config.sh* file, CA is ready to carry out the subsequent steps:

A) ***01_combine_chromosomes.sh***.

First, this script will check if any files are missing from the *output_regenie_step2* folder (one file for each phenotype and chromosome) ensuring the presence of the required columns using *find-column-index.pl* script. Once the validation process is successfully finalized, it merge all chromosomes into a single file for each trait. Subsequently, each file is then compressed and a corresponding tabix file is generated.

Command line to run:

```{r, eval=FALSE}
bash 01_combine_chromosomes.sh study_name
```


B) ***02_gwasinspector.sh***.

Command line to run:

```{r, eval=FALSE}
bash 02_combine_chromosomes.sh study_name
```


C) ***03_check_positive_controls.sh***

First, CAs should create a GWAS positive control .txt file containing the hits (specific to each target trait) widely validated in the literature and stratified by ethnicity, whenever possible. 

This file must contain the fields shown below:

```{r, eval=FALSE}
TO ADD EXAMPLE TABLE???
```

CAs can also find an example in the *Positive_Controls* folder (please, replace the provided example by your own customized *positive-controls.txt* file): 

```{r, eval=FALSE}
"/storage/consortium_name/scripts/gwas_qc/Positive_Controls"
```

This directory also contains the necessary scripts for conducting the positive control validation (no modifications needed). 

By running *03_check_positive_controls.sh*, each file within the cleaning directory will be checked.

```{r, eval=FALSE}
/storage/consortium_name/cleaning/Specific_study_name/data
```

Checks:
- Population
- Phenotype
- Check positive control presence
- Extraction of hits 
- Check positive control: alleles, beta estimate direction, build, MAF

 


Command line to run:

```{r, eval=FALSE}
bash 03_check_positive_controls.sh study_name
```




*pull-positive-control.sh* According the different phenotypes and ancestry

Results will be saved in *03-check-positive-controls.csv* file




D) ***04_collect_qc_stats.sh***

Command line to run:

```{r, eval=FALSE}
bash 04_collect_qc_stats.sh
```

E) ***05_plot_qc_stats.sh***

Command line to run:
```{r, eval=FALSE}
bash 05_plot_qc_stats.sh
```

F) ***06_plot_frequencies.sh***

Command line to run:
```{r, eval=FALSE}
bash 06_plot_frequencies.sh
```

G) ***07_stateOfAffairs.sh***

Command line to run:
```{r, eval=FALSE}
bash 07_stateOfAffairs.sh
```


H) ***08_compareGsheet.sh***

Command line to run:
```{r, eval=FALSE}
bash 08_compareGsheet.sh
```

I) ***09_checkAllFileNames.sh***

Command line to run:
```{r, eval=FALSE}
bash 09_checkAllFileNames.sh
```

J) ***10_GWAS_QC_multistudies.sh***

By combining the summary statistics from GWAS-QC (*qc-stats.csv*) and the results of positive controls analysis (*positive-controls.csv*) across all participating studies, CA will perform a final checking process. A set of relevant items will be checked, including:  wrong genomic build, allele switches and swaps, missing data, file and number formatting issues, unaccounted inflation, and wrong transformations, among others.

metaGWASmanager provides a script (*GWAS_QC_multistudies.R*), which automatically evaluates the list of potential problems, mentioned above. For its execution, CA will require the previously created *consortium-specifics.R* plug-in, which supplies a tolerance table, establishing the thresholds to apply at each verification stage based on the different phenotypes and covariates to be tested. In the end, a conclusive-summary table will be generated, indicating whether each trait for each assessed item is categorized as "OKAY" or "NOT OKAY". CA should scan all entries and emphasizing those labeled as  "NOT OKAY", as  well as,  plots produced in the **Phase 5 - CA: Check Associations & Metaa-nalysis**. If an explanation for any identified issues cannot be determined, CA must reach out to the SAs to collaboratively work towards a resolution.

Command line to run:
```{r, eval=FALSE}
bash 10_GWAS_QC_multistudies.sh
```


