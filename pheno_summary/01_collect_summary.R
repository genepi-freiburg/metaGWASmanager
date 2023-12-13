args = commandArgs(trailingOnly = T)
#PATHS
output_folder= args[1]
setwd(paste0(output_folder))

parameters = data.frame()
ids_summaries = data.frame()

collect_parameters = function(fn, row_idx, parameters) {
	params_pattern = "parameters"
	params_fn = list.files(paste0("../", fn), pattern=params_pattern)

	# temp workaround
	if (length(params_fn) == 0) {
		my_name = unlist(strsplit(fn, "_", fixed=T))
		my_name_nodate = my_name[1:length(my_name)-1]
		study_name = paste(my_name_nodate, collapse="_")
		parameters[row_idx, "study_name"] = study_name
		print(paste("WARNING: return GUESSED study name:", study_name))
		return(parameters)
	}

	if (length(params_fn) != 1) {
		stop(paste0("expect single parameters file, but got zero or multiple: ", params_fn, sep="", collapse=";"))
	}
	print(paste0("read parameters file: ", params_fn))

	params_path = paste0("../", fn, "/", params_fn)
	data = read.table(params_path, h=T)
	
	if (!any("key" %in% colnames(data))) {
		print("format unknown, try original format")

		data = read.table(file = params_path, 
                        header = F, 
                        col.names = c("key", "value"),
                        stringsAsFactors = F,
                        colClasses = c("character", "character"))
	}

	print(paste0("got parameters: ", nrow(data)))

	for (kv_idx in 1:nrow(data)) {
		key = data[kv_idx, "key"]
		value = data[kv_idx, "value"]
		parameters[row_idx, key] = value
	}
	return(parameters)
}


collect_ids = function(fn, row_idx, ids_summaries, study) {
        ids_fn = list.files(paste0("../", fn), pattern="*_ids_summary.txt")
        if (length(ids_fn) != 1) {
                stop(paste0("expect single summary file, but got zero or multiple: ", ids_fn, sep="", collapse=";"))
        }
        print(paste0("read summary file: ", ids_fn))
        data = read.delim (paste0("../", fn, "/", ids_fn), h=T)
        print(paste0("got summaries: ", nrow(data)))
        #data <- replace(data, is.na(data), "-")

        ids_summaries[row_idx, "study"] = study

        for (var_idx in 1:nrow(data)) {
                pheno= data[var_idx, "phenotype"]
                var = data[var_idx, "variable"]
                for (stat in c("min", "q1", "med", "q3", "max", "mean", "sd", "kurtosis", "skewness", "n", "na", "cat1", "cat2", "cat3", "categories")) {
                  ids_summaries[row_idx, paste0( pheno,"_",var, "_", stat)] = data[var_idx, stat]
                }
        }

	return(ids_summaries)
}

row_idx = 0
for (fn in list.files("..")) {
	if (fn != "00_SUMMARY" && fn != "00_ARCHIVE") {
		row_idx = row_idx + 1
		print(paste0("===== Collect: ", fn, " (#", row_idx, ")"))
		parameters = collect_parameters(fn, row_idx, parameters)
		study = parameters[row_idx, "study_name"]
		ancestry = parameters[row_idx, "ancestry"]
		study = paste(study, ancestry, sep="_")
		ids_summaries = collect_ids(fn, row_idx, ids_summaries, study)
	}
}

write.table(parameters, "parameter-summary.txt", row.names=F, col.names=T, sep="\t", quote=F)
write.table(ids_summaries, "ids-summaries.txt", row.names=F, col.names=T, sep="\t", quote=F)

# Change id_summaries format:

ids <- read.delim("ids-summaries.txt", h=T)

ids2 <- data.frame(t(ids))
comb <- ids2[-1,]

colnames(comb) <- ids2[1,]
comb$variable <- c(colnames(ids)[2:length(ids)])

write.table(comb, "summaries.txt", row.names=F, col.names=T, sep="\t", quote=F)



