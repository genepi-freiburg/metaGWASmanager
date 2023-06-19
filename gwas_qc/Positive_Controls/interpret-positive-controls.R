#chr	position	noncoded_all	coded_all	AF_coded_all	beta	pvalue
#7	1285195	A	T	0.3223	-0.0046111	0.77134
#trait   ethnicity       SNP     gene    chr     pos_b37 pos_b38 ref     alt     MAF_1KGP        direction_alt
#eGFR    EUR     rs13329952      UMOD    16      20366507        20355185        T       C       0.22    pos


args = commandArgs(TRUE)
#cat(paste("Study extraction result file:", args[1]))
#cat(paste("Positive control file:", args[2]))

study = read.table(args[1], h=T, colClasses = c("character"))
posit = read.table(args[2], h=T, colClasses = c("character"))

out_fn = args[3]
study_fn = args[4]
pop = args[5]
pheno = args[6]

study$chr = as.numeric(study$chr)
posit$chr = as.numeric(posit$chr)
result = merge(study, posit, by.x=c("chr", "position"), by.y=c("chr", "pos_b38"))

result$beta = as.numeric(result$beta)
result$AF_coded_all = as.numeric(result$AF_coded_all)
result$MAF_1KGP = as.numeric(result$MAF_1KGP)

#head(result)

all_ok = T

for (i in 1:nrow(result)) {
	cat(paste("Check control #", i, 
                "\n----------------\n", sep=""))

	if (result[i,]$noncoded_all != result[i,]$ref) {
		cat("REF allele MISMATCH, ")
		allele_status1 = "REF_MISMATCH"
	} else {
		cat("REF allele matches, ")
		allele_status1 = "REF_OK"
	}

	if (result[i,]$coded_all != result[i,]$alt) {
		cat("ALT allele MISMATCH\n")
		allele_status2 = "ALT_MISMATCH"
	} else {
		cat("ALT allele matches\n")
		allele_status2 = "ALT_OK"
	}
	allele_status = paste(allele_status1, allele_status2, sep="/")

	if (result[i,]$noncoded_all == result[i,]$alt &&
		result[i,]$coded_all == result[i,]$ref) {
		allele_status = "SWITCH_OK"
		result[i,]$beta = -result[i,]$beta
	}

	if (allele_status != "REF_OK/ALT_OK" &&
		allele_status != "SWITCH_OK") {
		all_ok = F
	}

	direction_status = "OK"
	if (result[i,]$beta < 0 && result[i,]$direction_alt == "neg") {
		cat("Direction of beta matches\n")
	} else if (result[i,]$beta > 0 && result[i,]$direction_alt == "pos") {
		cat("Direction of beta matches\n")
	} else {
		cat("Direction of beta MISMATCH\n")
		direction_status = "MISMATCH"
		all_ok = F
	}

	snp_maf = result[i,]$AF_coded_all
	if (snp_maf > 0.5) {
		snp_maf = 1 - snp_maf
	}

	cat(paste("SNP MAF: ", snp_maf, ", 1KGP MAF: ", result[i,]$MAF_1KGP, ", ", sep=""))
	diff = snp_maf - result[i,]$MAF_1KGP
	cat(paste("Diff: ", abs(diff), " => ", sep=""))
	if (abs(diff) > 0.1) {
		cat("Minor allele frequency DEVIATION (>10%)\n")
		all_ok = F
		maf_status = "MAF_DEVIATION"
	} else {
		cat("Minor allele frequency matches\n")
		maf_status = "OK"
	}

	if ((allele_status == "REF_OK/ALT_OK" || allele_status == "SWITCH_OK") &&
		direction_status == "OK" &&
		maf_status == "OK") {
		overall_status = "OK"
	} else {
		overall_status = "NOT_OK"
	}

	#echo "file_name,pheno,ancestry,chr,pos_b38,noncoded_all,coded_all,beta,pval,maf,std_ref,std_alt,std_dir,std_maf,rate_alleles,rate_dir,rate_maf,rate_overall" > $OUT_FN
	cat(paste0(paste(study_fn, pheno, pop,
		result[i, "chr"], result[i, "position"], result["gene"], result[i, "noncoded_all"], result[i, "coded_all"],
		result[i, "beta"], result[i, "pvalue"], result[i, "N"], snp_maf,
		result[i, "ref"], result[i, "alt"], result[i, "direction_alt"], result[i, "MAF_1KGP"],
		allele_status, direction_status, maf_status, overall_status, sep=","), "\n"),
		append=T, file=out_fn)
}

if (all_ok) {
	cat("Finish: all OK.\n")
} else {
	cat("Finish: there may be problems!\n")
	quit(status=4)
}
