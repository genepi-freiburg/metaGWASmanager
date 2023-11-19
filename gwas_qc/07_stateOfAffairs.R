pheno_dir <- commandArgs(trailingOnly = TRUE)[1]
assoc_dir <- commandArgs(trailingOnly = TRUE)[2]
cleaning_dir <- commandArgs(trailingOnly = TRUE)[3]
#final_dir = ""
qc_stats_file <-commandArgs(trailingOnly = TRUE)[4]

#"STUDY","PHENO","POP","PVALUE_MIN_ALL","PVALUE_Q1_ALL","PVALUE_MED_ALL","PVALUE_MEAN_ALL","PVALUE_Q3_ALL","PVALUE_MAX_ALL","EFF_ALL_FREQ_MIN_ALL","EFF_ALL_FREQ_Q1_ALL","EFF_ALL_FREQ_MED_ALL","EFF_ALL_FREQ_MEAN_ALL","EFF_ALL_FREQ_Q3_ALL","EFF_ALL_FREQ_MAX_ALL","IMP_QUALITY_MIN_ALL","IMP_QUALITY_Q1_ALL","IMP_QUALITY_MED_ALL","IMP_QUALITY_MEAN_ALL","IMP_QUALITY_Q3_ALL","IMP_QUALITY_MAX_ALL","BETA_MIN_ALL","BETA_Q1_ALL","BETA_MED_ALL","BETA_MEAN_ALL","BETA_Q3_ALL","BETA_MAX_ALL","STDERR_MIN_ALL","STDERR_Q1_ALL","STDERR_MED_ALL","STDERR_MEAN_ALL","STDERR_Q3_ALL","STDERR_MAX_ALL","PVALUE_MIN_HQ","PVALUE_Q1_HQ","PVALUE_MED_HQ","PVALUE_MEAN_HQ","PVALUE_Q3_HQ","PVALUE_MAX_HQ","EFF_ALL_FREQ_MIN_HQ","EFF_ALL_FREQ_Q1_HQ","EFF_ALL_FREQ_MED_HQ","EFF_ALL_FREQ_MEAN_HQ","EFF_ALL_FREQ_Q3_HQ","EFF_ALL_FREQ_MAX_HQ","IMP_QUALITY_MIN_HQ","IMP_QUALITY_Q1_HQ","IMP_QUALITY_MED_HQ","IMP_QUALITY_MEAN_HQ","IMP_QUALITY_Q3_HQ","IMP_QUALITY_MAX_HQ","BETA_MIN_HQ","BETA_Q1_HQ","BETA_MED_HQ","BETA_MEAN_HQ","BETA_Q3_HQ","BETA_MAX_HQ","STDERR_MIN_HQ","STDERR_Q1_HQ","STDERR_MED_HQ","STDERR_MEAN_HQ","STDERR_Q3_HQ","STDERR_MAX_HQ","INPUT_VARIANT_COUNT","HQ_VARIANT_COUNT","AF_CORRELATION_ALL","LAMBDA","SAMPLE_SIZE","IS_SAMPLE_SIZE_FIXED","VARIANTS_CHR_1","VARIANTS_CHR_2","VARIANTS_CHR_3","VARIANTS_CHR_4","VARIANTS_CHR_5","VARIANTS_CHR_6","VARIANTS_CHR_7","VARIANTS_CHR_8","VARIANTS_CHR_9","VARIANTS_CHR_10","VARIANTS_CHR_11","VARIANTS_CHR_12","VARIANTS_CHR_13","VARIANTS_CHR_14","VARIANTS_CHR_15","VARIANTS_CHR_16","VARIANTS_CHR_17","VARIANTS_CHR_18","VARIANTS_CHR_19","VARIANTS_CHR_20","VARIANTS_CHR_21","VARIANTS_CHR_22","VARIANTS_CHR_23"

study_phenos = list.files(pheno_dir)
study_assocs = list.files(assoc_dir)
study_cleaning = list.files(cleaning_dir)

qc_stats = read.csv(qc_stats_file)

found_assoc = c()
found_cleaning = c()

#for (study_pheno in study_phenos) {
#	if (study_pheno == "00_ARCHIVE" || study_pheno == "00_SUMMARY") {
#		next
#	}
#	print(paste0("Study with phenotypes: ", study_pheno))
#
#	idx = which(study_pheno %in% study_assocs)
#	if (length(idx) > 0) {
#		print("found assoc")
#	} else {
#		print("no assoc found!")
#	}
#}

upl_assoc_clean_ok = 0
upl_assoc_clean_err = 0
upl_assoc_pheno_ok = 0
upl_assoc_pheno_err = 0

for (study_assoc in study_assocs) {
	if (study_assoc == "00_ARCHIVE") {
		next
	}

       idx = which(study_assoc %in% study_cleaning)
       if (length(idx) > 0) {
	       #print(paste0("Found cleaning for study with uploaded associations: ", study_assoc))
		my_rows = qc_stats[qc_stats$STUDY == study_assoc,]
		if (nrow(my_rows) == 0) {
			upl_assoc_clean_err = upl_assoc_clean_err + 1
			print(paste0("DID NOT FIND QC-STATS for study with uploaded associations and cleaning dir: ", study_assoc))
		} else {
			upl_assoc_clean_ok = upl_assoc_clean_ok + 1
			#print(paste0("Found ", nrow(my_rows), " phenotype QC stats for study: ", study_assoc))
		}

       } else {
		upl_assoc_clean_err = upl_assoc_clean_err + 1
		print(paste0("DID NOT FIND CLEANING DIR for study with uploaded associations: ", study_assoc))
		# either dir not present at all, or need to fix name
       }

       idx2 = which(study_assoc %in% study_phenos)
       if (length(idx2) > 0) {
		upl_assoc_pheno_ok = upl_assoc_pheno_ok + 1
                #print(paste0("Found pheno for study with uploaded associations: ", study_assoc))
       } else {
		upl_assoc_pheno_err = upl_assoc_pheno_err + 1
		print(paste0("DID NOT FIND PHENO DIR for study with uploaded associations: ", study_assoc))
		# either dir not present at all, or need to fix name
       }
                
}

print(paste0("upl_assoc_clean_ok: ", upl_assoc_clean_ok))
print(paste0("upl_assoc_clean_err: ", upl_assoc_clean_err))
print(paste0("upl_assoc_pheno_ok: ", upl_assoc_pheno_ok))
print(paste0("upl_assoc_pheno_err: ", upl_assoc_pheno_err))

for (clean in study_cleaning) {
	if (clean == "00_ARCHIVE" || clean == "00_SUMMARY") {
		next
	}
	idx = which(clean %in% study_assocs)
	if (length(idx) == 0) {
		print(paste0("DID NOT FIND UPLOADED ASSOC for cleaning results: ", clean))
	}
}


# check cleaning is final




qc_stats$STUDY = as.factor(qc_stats$STUDY)
qc_stats$PHENO = as.factor(qc_stats$PHENO)
qc_stats$POP = as.factor(qc_stats$POP)

print("NUMBER OF STUDIES")
print(length(levels(qc_stats$STUDY)))

print("FILE/STUDY COUNT BY PHENOTYPE")
table(qc_stats$PHENO)

print("FILE COUNT PER ANCESTRY (ACROSS PHENOTYPES!)")
table(qc_stats$POP)


library(dplyr)
library(ggplot2)
library(scales)

print("SAMPLE SIZE BY PHENOTYPE")
qc_stats %>% group_by(PHENO) %>% summarise(N = sum(SAMPLE_SIZE))

print("SAMPLE SIZE BY PHENOTYPE AND ANCESTRY")
sample_size_by_pheno_ancestry = qc_stats %>% group_by(PHENO,POP) %>% summarise(N = sum(SAMPLE_SIZE))
print(sample_size_by_pheno_ancestry, n=1000)

pdf("sampleSize.pdf")

my_plot = ggplot(sample_size_by_pheno_ancestry, aes(fill=POP, y=N, x=PHENO)) +
      geom_bar(position="stack", stat="identity") +
      scale_y_continuous(labels = label_comma()) +
      scale_x_discrete(guide = guide_axis(angle = 60)) +
      labs(x="Phenotype", y="Sample Size", 
           title="CKDGen R5 Sample Size by Population and Phenotype",
           fill="Population")
  
print(my_plot)

sample_size_by_ancestry = qc_stats %>% group_by(POP) %>% summarise(N = sum(SAMPLE_SIZE))

print(sample_size_by_ancestry, n=20)

pie_plot = ggplot(sample_size_by_ancestry, aes(x="", y=N, fill=POP)) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  theme_void() # remove background, grid, numeric labels

print(pie_plot)

dev.off()

