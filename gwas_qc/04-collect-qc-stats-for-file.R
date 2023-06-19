args = commandArgs(trailingOnly = T)

fn = args[1]
study = args[2]
pheno = args[3]
pop = args[4]
out = args[5]

# pheno is too "rough"
# /storage/cleaning/ckdgenR5/SHIP_0-2022-10-24/qc-output/QC_SHIP_0_R4c_EUR_TopMed_20220725_quantitative_sex_stratified_18_urate_serum_female.gwas_object.rds
# /storage/cleaning/ckdgenR5/FHS_EUR_2022-11-17/qc-output/QC_FHS_EUR_TopMed_20221118_quantitative_overall_calcium_serum_int.gwas_object.rds
pheno = gsub(".*_\\d?\\d_(.*)\\.gwas_object\\.rds", "\\1", fn)

# fix bad file names (w/o these numbers)
pheno = gsub(".*overall_(.*)\\.gwas_object\\.rds", "\\1", pheno)
pheno = gsub(".*stratified_(.*)\\.gwas_object\\.rds", "\\1", pheno)


cat(paste0("Process: ", fn, ", study: ", study, ", pheno: ", pheno, ", pop: ", pop, ", out: ", out, "\n"))

data = readRDS(fn)

result = data.frame()

if (file.exists(out)) {
	result = read.table(out, h=T, sep=",")
	cat(paste0("Adding to existing file for study, rows (before) = ", nrow(result)))
	my_row = which(result$STUDY == study & result$PHENO == pheno & result$POP == pop)
	if (length(my_row) > 0) {
		result = result[-my_row,]
	}
	cat(paste0(", rows (after) = ", nrow(result), "\n"))
	
} else {
	cat("Starting new results file for study.\n")
}

row_idx = nrow(result) + 1
result[row_idx, "STUDY"] = study
result[row_idx, "PHENO"] = pheno
result[row_idx, "POP"] = pop

hq_all = c("ALL", "HQ")
vars = c("PVALUE", "EFF_ALL_FREQ", "IMP_QUALITY", "BETA", "STDERR")
nums = c("MIN", "Q1", "MED", "MEAN", "Q3", "MAX")

for (i in 1:2) {
	for (v in 1:length(vars)) {
		for (n in 1:length(nums)) {
			name = paste(vars[v], nums[n], hq_all[i], sep="_")
			#print(paste(name,v,n))
			if (i == 1) {
				result[row_idx, name] = data$tables$variable.summary[n,v]
			} else {
				result[row_idx, name] = data$tables$variable.summary.HQ[n,v]
			}
		}
	}
}

result[row_idx, "INPUT_VARIANT_COUNT"] = data$input.data.rowcount
result[row_idx, "HQ_VARIANT_COUNT"] = data$HQ.count
result[row_idx, "AF_CORRELATION_ALL"] = data$AFcor.std_ref
result[row_idx, "LAMBDA"] = data$lambda
result[row_idx, "SAMPLE_SIZE"] = data$MAX_N_TOTAL
result[row_idx, "IS_SAMPLE_SIZE_FIXED"] = data$fixed.n_total

chr_table = data$tables$CHR.tbl
for (chr in 1:23) {
	idx = which(chr_table$CHR == chr)
	if (length(idx) > 0) {
		result[row_idx, paste0("VARIANTS_CHR_", chr)] = chr_table[idx, "N"]
	} else {
		result[row_idx, paste0("VARIANTS_CHR_", chr)] = 0
	}
}

#> d$tables$variable.summary
#        PVALUE      EFF_ALL_FREQ IMP_QUALITY BETA        STDERR
#Min.    "7.408e-10" "0.0002003"  "0.3"       "-4.779"    "0.01396"
#1st Qu. "0.2491"    "0.0003401"  "0.8298"    "-0.1132"   "0.05128"
#Median  "0.4983"    "0.001215"   "0.9469"    "0.000682"  "0.2743"
#Mean    "0.499"     "0.08344"    "0.8854"    "-0.001641" "0.3067"
#3rd Qu. "0.7485"    "0.03441"    "0.9948"    "0.1202"    "0.517"
#Max.    "1"         "0.9998"     "1"         "3.696"     "1.157"

write.table(result, out, row.names=F, col.names=T, sep=",", quote=T)
