ethnicities=c("EUR","EAS","SAS","AFR","AMR")
smoking=c("N","F","C")

for (eth in ethnicities){

	infile=paste0("simulated-input-",eth,".txt")
	tblIn=read.table(infile,h=T,stringsAsFactors=F,comment.char="")
	N=nrow(tblIn)

	# set the 1000Genomes-$eth data to random and pre-defined values
	tblIn$FID=0
	tblIn$sex=tblIn$SEX
	tblIn$age_urinemetal=tblIn$age
	tblIn$smoking_urinemetal=sample(smoking, N, replace = TRUE)
	tblIn$egfr_urinemetal=round(runif(N, min = 20, max = 160), 2)
	tblIn$bmi_urinemetal=round(runif(N, min = 20, max = 40), 2)
	tblIn$creatinine_urine=round(runif(N, min = 5, max = 200), 2)
	tblIn$age_bloodmetal=tblIn$age
	tblIn$smoking_bloodmetal=sample(smoking, N, replace = TRUE)
	tblIn$bmi_bloodmetal=round(runif(N, min = 20, max = 40), 2)
	tblIn$age_plasmametal=tblIn$age
	tblIn$smoking_plasmametal=sample(smoking, N, replace = TRUE)
	tblIn$bmi_plasmametal=round(runif(N, min = 20, max = 40), 2)
	tblIn$selenium_urine=tblIn$egfr
	tblIn$arsenic_urine=round(runif(N, min = 20, max = 40), 2)
	tblIn$cadmium_plasma=round(runif(N, min = 20, max = 40), 2)
	tblIn$selenium_plasma=round(runif(N, min = 20, max = 40), 2)
	tblIn$arsenic_plasma=round(runif(N, min = 20, max = 40), 2)

	write.table(tblIn,paste0("1000Genomes-",eth,".txt"),quote = FALSE, sep="\t",row.names = FALSE, col.names = TRUE)
}
